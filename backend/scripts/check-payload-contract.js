#!/usr/bin/env node
/**
 * Payload contract check: for every Flutter call that sends a literal body or
 * query map, the backend handler must actually READ each key it is sent.
 *
 * `check:api` only proves the URL and method exist. This goes one level deeper
 * and catches the quiet kind of drift where a screen works on paper but the
 * server ignores what it sends, e.g. the app posting `review` while the
 * handler reads `comment`.
 *
 *   node scripts/check-payload-contract.js            # report, exit 1 on a mismatch
 *   node scripts/check-payload-contract.js --unused   # also list query options the app never sends
 *
 * How it works: it loads the real Express routers, takes each route's handler
 * source (plus express-validator field lists), and looks for `req.body.key`,
 * `req.body['key']`, `{ key } = req.body` and aliases of req.body (and the same
 * for req.query). A handler that passes req / req.body on to something else is
 * reported as "not verifiable" rather than guessed at. Reviewed exceptions go in
 * scripts/payload-contract.allow.json with a reason.
 */
process.env.NODE_ENV = process.env.NODE_ENV || 'test';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'x'.repeat(40);
const fs = require('fs');
const path = require('path');
const {
    readBackendRoutes, segmentsMatch, join, walk, BACKEND, FLUTTER_LIB
} = require('./check-api-contract');

const ALLOW_FILE = path.join(__dirname, 'payload-contract.allow.json');
const METHODS = ['get', 'post', 'put', 'patch', 'delete'];

// ─── Dart: find `_api.<method>(path, ... data: {...} / params: {...})` ────────
function skipString(src, i) {
    const quote = src[i];
    for (i++; i < src.length; i++) {
        if (src[i] === '\\') { i++; continue; }
        if (src[i] === quote) return i;
    }
    return i;
}

function matchingClose(src, open) {
    const pairs = { '(': ')', '[': ']', '{': '}' };
    const stack = [];
    for (let i = open; i < src.length; i++) {
        const c = src[i];
        if (c === '"' || c === "'") { i = skipString(src, i); continue; }
        if (pairs[c]) stack.push(pairs[c]);
        else if (c === ')' || c === ']' || c === '}') {
            if (stack.pop() !== c) return -1;
            if (stack.length === 0) return i;
        }
    }
    return -1;
}

// Top-level keys of a Dart map literal: 'key': value  (also after `if (cond)`)
function topLevelKeys(mapSrc) {
    const keys = [];
    let depth = 0;
    for (let i = 0; i < mapSrc.length; i++) {
        const c = mapSrc[i];
        if (c === '"' || c === "'") {
            const end = skipString(mapSrc, i);
            const after = mapSrc.slice(end + 1).match(/^\s*:/);
            const before = mapSrc.slice(0, i).match(/[{,]\s*(?:if\s*\([^)]*\)\s*)?$/);
            if (depth === 1 && after && before) keys.push(mapSrc.slice(i + 1, end));
            i = end;
            continue;
        }
        if (c === '{' || c === '(' || c === '[') depth++;
        else if (c === '}' || c === ')' || c === ']') depth--;
    }
    return keys;
}

function namedMap(argsSrc, name) {
    const m = argsSrc.match(new RegExp(`\\b${name}\\s*:\\s*\\{`));
    if (!m) return null;
    const open = m.index + m[0].length - 1;
    const close = matchingClose(argsSrc, open);
    return close < 0 ? null : argsSrc.slice(open, close + 1);
}

function readFlutterPayloads() {
    const calls = [];
    for (const file of walk(FLUTTER_LIB)) {
        const src = fs.readFileSync(file, 'utf8');
        const rel = path.relative(path.join(BACKEND, '..'), file);
        for (const m of src.matchAll(/_api\s*\.\s*(get|post|put|patch|delete)\(\s*(['"])((?:\\.|(?!\2).)*)\2/g)) {
            const open = m.index + m[0].indexOf('(');
            const close = matchingClose(src, open);
            if (close < 0) continue;
            const args = src.slice(open, close + 1);
            const body = namedMap(args, 'data');
            const query = namedMap(args, 'params');
            const rawPath = m[3];
            const inlineQuery = (rawPath.split('?')[1] || '').split('&').map(p => p.split('=')[0]).filter(Boolean);
            const apiPath = '/api' + rawPath.split('?')[0]
                .replace(/\$\{[^}]*\}/g, ':param').replace(/\$[A-Za-z_]\w*/g, ':param').replace(/\/$/, '');
            calls.push({
                method: m[1].toUpperCase(), path: apiPath,
                bodyKeys: body ? topLevelKeys(body) : [],
                queryKeys: [...(query ? topLevelKeys(query) : []), ...inlineQuery],
                where: `${rel}:${src.slice(0, m.index).split('\n').length}`
            });
        }
    }
    return calls;
}

// ─── Backend: handler source for each route ─────────────────────────────────
function loadHandlers() {
    const { routes, mounts } = readBackendRoutes();
    const handlers = [];
    for (const { prefix, file } of mounts) {
        let router;
        try { router = require(path.join(BACKEND, 'src', 'routes', file)); } catch (e) { continue; }
        for (const layer of router.stack || []) {
            if (!layer.route) continue;
            const stack = layer.route.stack;
            const controller = stack[stack.length - 1].handle;
            const validatorFields = stack.flatMap(l => (l.handle && l.handle.builder && l.handle.builder.fields) || []);
            for (const method of Object.keys(layer.route.methods)) {
                handlers.push({
                    method: method.toUpperCase(), path: join(prefix, layer.route.path), file,
                    name: controller.name || '(anonymous)', source: controller.toString(), validatorFields
                });
            }
        }
    }
    return { handlers, routes };
}

// What a handler reads from req.<where> ("body" or "query")
function analyseReads(rawSource, where) {
    // Comments (e.g. `addressId // also accepted`) must not confuse the destructuring parser
    const source = rawSource.replace(/\/\*[\s\S]*?\*\//g, ' ').replace(/(^|[^:'"`])\/\/[^\n]*/g, '$1');
    const aliases = [where];
    for (const m of source.matchAll(new RegExp(`(?:const|let|var)\\s+(\\w+)\\s*=\\s*req\\.${where}\\s*(?:;|\\n|\\|\\|)`, 'g'))) aliases.push(m[1]);
    const reads = new Set();
    let remaining = source;
    const strip = (re) => { remaining = remaining.replace(re, ' '); };

    for (const alias of aliases) {
        const base = alias === where ? `req\\.${where}` : `\\b${alias}`;
        for (const m of source.matchAll(new RegExp(`${base}\\s*\\.\\s*(\\w+)`, 'g'))) reads.add(m[1]);
        for (const m of source.matchAll(new RegExp(`${base}\\s*\\[\\s*['"]([^'"]+)['"]\\s*\\]`, 'g'))) reads.add(m[1]);
        for (const m of source.matchAll(new RegExp(`\\{([^{}]*)\\}\\s*=\\s*${base}\\b`, 'g'))) {
            for (const part of m[1].split(',')) {
                const name = part.replace(/^\s*\.\.\./, '').split(/[:=]/)[0].trim();
                if (/^\w+$/.test(name)) reads.add(name);
            }
        }
        strip(new RegExp(`${base}\\s*\\.\\s*\\w+`, 'g'));
        strip(new RegExp(`${base}\\s*\\[[^\\]]*\\]`, 'g'));
        strip(new RegExp(`\\{[^{}]*\\}\\s*=\\s*${base}\\b`, 'g'));
    }
    // Anything left that mentions req.<where> or passes req on is handed to other code
    const passesThrough = new RegExp(`req\\.${where}\\b`).test(remaining) ||
        aliases.slice(1).some(a => new RegExp(`\\b${a}\\b(?!\\s*[.\\[=])`).test(remaining.replace(new RegExp(`(?:const|let|var)\\s+${a}\\s*=`), ' '))) ||
        /[\w.]+\(\s*req\s*[,)]/.test(remaining);
    return { reads, passesThrough };
}

function loadAllow() {
    try { return JSON.parse(fs.readFileSync(ALLOW_FILE, 'utf8')); } catch (e) { return []; }
}

function check() {
    const { handlers } = loadHandlers();
    const allow = loadAllow();
    const problems = [];
    const unverifiable = [];
    let verified = 0;

    for (const call of readFlutterPayloads()) {
        const handler = handlers.find(h => h.method === call.method && segmentsMatch(call.path, h.path));
        if (!handler) continue; // a missing route is check-api-contract's job
        for (const [where, keys] of [['body', call.bodyKeys], ['query', call.queryKeys]]) {
            if (!keys.length) continue;
            const { reads, passesThrough } = analyseReads(handler.source, where);
            if (passesThrough) { unverifiable.push({ ...call, where_: where, handler: handler.name }); continue; }
            verified++;
            const known = new Set([...reads, ...(where === 'body' ? handler.validatorFields : [])]);
            for (const key of keys) {
                if (known.has(key)) continue;
                const excused = allow.find(a => a.method === call.method && a.path === handler.path && a.key === key);
                if (excused) continue;
                problems.push({ where, key, method: call.method, path: call.path, handler: handler.name, handlerFile: handler.file, at: call.where });
            }
        }
    }
    return { problems, unverifiable, verified };
}

// Query options a handler understands that no app call ever sends (informational)
function unusedQueryOptions() {
    const { handlers } = loadHandlers();
    const calls = readFlutterPayloads();
    const out = [];
    for (const h of handlers.filter(x => x.method === 'GET')) {
        const sent = new Set(calls.filter(c => c.method === 'GET' && segmentsMatch(c.path, h.path)).flatMap(c => c.queryKeys));
        if (!calls.some(c => c.method === 'GET' && segmentsMatch(c.path, h.path))) continue;
        const { reads } = analyseReads(h.source, 'query');
        const unused = [...reads].filter(k => !sent.has(k));
        if (unused.length) out.push({ route: `GET ${h.path}`, unused });
    }
    return out;
}

if (require.main === module) {
    const { problems, unverifiable, verified } = check();
    console.log(`Checked ${verified} request payload(s) against the backend handlers that read them.`);
    if (unverifiable.length) {
        console.log(`Not verifiable (handler passes the request on to other code): ${unverifiable.length}`);
        if (process.argv.includes('--verbose')) unverifiable.forEach(u => console.log(`  ${u.method} ${u.path} (${u.where_})  ${u.at}`));
    }
    if (process.argv.includes('--unused')) {
        console.log('\nQuery options the backend supports but the app never sends:');
        unusedQueryOptions().forEach(u => console.log(`  ${u.route}: ${u.unused.join(', ')}`));
    }
    if (problems.length) {
        console.log(`\n✗ ${problems.length} key(s) the app sends that the backend handler never reads:`);
        for (const p of problems) {
            console.log(`  ${p.method.padEnd(6)} ${p.path}  ${p.where}.${p.key}   (handler ${p.handler}, sent from ${p.at})`);
        }
        console.log('\nFix the app or the backend so they agree, or, if the key is read some other way, add it to scripts/payload-contract.allow.json with a reason.');
        process.exit(1);
    }
    console.log('\n✓ Every key the app sends is read by the backend handler.');
}

module.exports = { check, unusedQueryOptions, analyseReads, topLevelKeys, readFlutterPayloads };

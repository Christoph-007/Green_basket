#!/usr/bin/env node
/**
 * API contract check: every HTTP call the Flutter app makes must match a
 * route the backend actually serves (same method and path).
 *
 *   node scripts/check-api-contract.js            # report + exit 1 on mismatch
 *   node scripts/check-api-contract.js --json     # machine-readable output
 *
 * Backend routes are read from the app.use(...) mounts in server.js and the
 * router.<method>(...) / router.route(...) definitions in src/routes/*.js.
 * Flutter calls are read from `_api.<method>('...')` in flutter_app/lib.
 * Dart string interpolation ($id, ${x.id}) and Express params (:id) both
 * match any single path segment.
 */
const fs = require('fs');
const path = require('path');

const BACKEND = path.join(__dirname, '..');
const FLUTTER_LIB = path.join(BACKEND, '..', 'flutter_app', 'lib');
const METHODS = ['get', 'post', 'put', 'patch', 'delete'];

// ─── Backend routes ─────────────────────────────────────────────────────────
function readBackendRoutes() {
    const server = fs.readFileSync(path.join(BACKEND, 'server.js'), 'utf8');

    // const fooRoutes = require('./src/routes/fooRoutes');
    const varToFile = {};
    for (const m of server.matchAll(/const\s+(\w+)\s*=\s*require\(['"]\.\/src\/routes\/(\w+)['"]\)/g)) {
        varToFile[m[1]] = m[2];
    }

    // app.use('/api/foo', [middleware,] fooRoutes)  or  app.use('/api/foo', ..., require('./src/routes/x'))
    const mounts = [];
    for (const m of server.matchAll(/app\.use\(\s*['"]([^'"]+)['"]([\s\S]*?)\);/g)) {
        const prefix = m[1];
        const rest = m[2];
        const inline = rest.match(/require\(['"]\.\/src\/routes\/(\w+)['"]\)/);
        if (inline) { mounts.push({ prefix, file: inline[1] }); continue; }
        const vars = [...rest.matchAll(/\b(\w+)\b/g)].map(x => x[1]).filter(v => varToFile[v]);
        if (vars.length) mounts.push({ prefix, file: varToFile[vars[vars.length - 1]] });
    }

    const routes = [];
    for (const { prefix, file } of mounts) {
        const src = fs.readFileSync(path.join(BACKEND, 'src', 'routes', `${file}.js`), 'utf8');
        for (const m of src.matchAll(/router\.(get|post|put|patch|delete)\(\s*['"]([^'"]*)['"]/g)) {
            routes.push({ method: m[1].toUpperCase(), path: join(prefix, m[2]), file });
        }
        // router.route('/x').get(...).post(...)
        for (const m of src.matchAll(/router\.route\(\s*['"]([^'"]*)['"]\s*\)((?:\s*\.\s*(?:get|post|put|patch|delete)\([^;]*?\))+)/g)) {
            for (const mm of m[2].matchAll(/\.\s*(get|post|put|patch|delete)\(/g)) {
                routes.push({ method: mm[1].toUpperCase(), path: join(prefix, m[1]), file });
            }
        }
    }
    return { routes, mountedFiles: new Set(mounts.map(m => m.file)) };
}

function join(prefix, p) {
    const full = (prefix.replace(/\/$/, '') + '/' + p.replace(/^\//, '')).replace(/\/$/, '');
    return full || '/';
}

// ─── Flutter calls ──────────────────────────────────────────────────────────
function walk(dir) {
    return fs.readdirSync(dir, { withFileTypes: true }).flatMap(e => {
        const full = path.join(dir, e.name);
        return e.isDirectory() ? walk(full) : (e.name.endsWith('.dart') ? [full] : []);
    });
}

function readFlutterCalls() {
    const calls = [];
    const dynamicCalls = [];
    for (const file of walk(FLUTTER_LIB)) {
        const src = fs.readFileSync(file, 'utf8');
        const rel = path.relative(path.join(BACKEND, '..'), file);
        for (const m of src.matchAll(/_api\s*\.\s*(get|post|put|patch|delete|uploadFile)\(\s*(['"])((?:\\.|(?!\2).)*)\2/g)) {
            const method = m[1] === 'uploadFile' ? 'POST' : m[1].toUpperCase();
            const line = src.slice(0, m.index).split('\n').length;
            calls.push({ method, raw: m[3], path: normaliseDartPath(m[3]), where: `${rel}:${line}` });
        }
        for (const m of src.matchAll(/_api\s*\.\s*(get|post|put|patch|delete|uploadFile)\(\s*(?!['"])([\w.$]+)/g)) {
            const line = src.slice(0, m.index).split('\n').length;
            dynamicCalls.push({ method: m[1], expr: m[2], where: `${rel}:${line}` });
        }
    }
    return { calls, dynamicCalls };
}

function normaliseDartPath(p) {
    return '/api' + p
        .split('?')[0]                       // drop query string
        .replace(/\$\{[^}]*\}/g, ':param')    // ${expr}
        .replace(/\$[A-Za-z_]\w*/g, ':param') // $ident
        .replace(/\/$/, '');
}

// ─── Matching ───────────────────────────────────────────────────────────────
const isParam = s => s.startsWith(':');

function segmentsMatch(callPath, routePath) {
    const a = callPath.split('/');
    const b = routePath.split('/');
    if (a.length !== b.length) return false;
    return a.every((seg, i) => seg === b[i] || isParam(seg) || isParam(b[i]));
}

function check() {
    const { routes, mountedFiles } = readBackendRoutes();
    const { calls, dynamicCalls } = readFlutterCalls();
    const routeFiles = fs.readdirSync(path.join(BACKEND, 'src', 'routes'))
        .map(f => f.replace(/\.js$/, ''))
        .filter(f => f !== 'paymentWebhookRoute');
    const unmountedRouteFiles = routeFiles.filter(f => !mountedFiles.has(f));

    const missing = calls.filter(c => !routes.some(r => r.method === c.method && segmentsMatch(c.path, r.path)));
    return { routes, calls, dynamicCalls, missing, unmountedRouteFiles };
}

if (require.main === module) {
    const result = check();
    if (process.argv.includes('--json')) {
        console.log(JSON.stringify(result, null, 2));
    } else {
        console.log(`Backend routes: ${result.routes.length}   Flutter calls: ${result.calls.length}`);
        if (result.unmountedRouteFiles.length) {
            console.log(`\nRoute files not mounted in server.js: ${result.unmountedRouteFiles.join(', ')}`);
        }
        if (result.dynamicCalls.length) {
            console.log(`\nCalls with a non-literal path (not checked): ${result.dynamicCalls.length}`);
            for (const d of result.dynamicCalls) console.log(`  ${d.method.toUpperCase()} <${d.expr}>  ${d.where}`);
        }
        if (result.missing.length) {
            console.log(`\n✗ ${result.missing.length} Flutter call(s) have no matching backend route:`);
            for (const c of result.missing) console.log(`  ${c.method.padEnd(6)} ${c.path.padEnd(48)} ${c.where}`);
        } else {
            console.log('\n✓ Every Flutter API call matches a backend route.');
        }
    }
    process.exit(result.missing.length ? 1 : 0);
}

module.exports = { check };

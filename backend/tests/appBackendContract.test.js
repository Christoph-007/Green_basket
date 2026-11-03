/**
 * The app and the backend must agree. Fails the normal test run if:
 *  - the Flutter app calls a URL/method the backend does not serve, or
 *  - the app sends a body/query key that the backend handler never reads
 *    (e.g. the app posting `review` while the server reads `comment`).
 * Same checks as `npm run check:api`. Reviewed exceptions: scripts/payload-contract.allow.json
 */
const fs = require('fs');
const path = require('path');

const appPresent = fs.existsSync(path.join(__dirname, '..', '..', 'flutter_app', 'lib'));
const maybe = appPresent ? it : it.skip; // the backend can be deployed without the app next to it

maybe('every Flutter API call matches a backend route', () => {
    const { check } = require('../scripts/check-api-contract');
    const { missing } = check();
    expect(missing.map(c => `${c.method} ${c.path} (${c.where})`)).toEqual([]);
});

maybe('every body/query key the Flutter app sends is read by the backend handler', () => {
    const { check } = require('../scripts/check-payload-contract');
    const { problems, verified } = check();
    expect(verified).toBeGreaterThan(30); // the scanner is really finding payloads
    expect(problems.map(p => `${p.method} ${p.path} ${p.where}.${p.key} (sent from ${p.at})`)).toEqual([]);
});

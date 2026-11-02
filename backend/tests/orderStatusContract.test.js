/**
 * The Flutter app mirrors the order status rules in
 * flutter_app/lib/utils/order_status.dart. This test fails if the two drift.
 */
const fs = require('fs');
const path = require('path');
const rules = require('../src/utils/orderStatus');

const dart = fs.readFileSync(path.join(__dirname, '..', '..', 'flutter_app', 'lib', 'utils', 'order_status.dart'), 'utf8');

const parseList = (src) => [...src.matchAll(/'([a-z_-]+)'/g)].map(m => m[1]);

function dartTransitions() {
    const block = dart.match(/_merchantTransitions = <String, List<String>>\{([\s\S]*?)\};/)[1];
    const out = {};
    for (const m of block.matchAll(/'([a-z_-]+)':\s*\[([^\]]*)\]/g)) out[m[1]] = parseList(m[2]);
    return out;
}

const dartList = (name) => parseList(dart.match(new RegExp(`${name} = \\[([^\\]]*)\\]`))[1]);

it('merchant transitions match', () => {
    expect(dartTransitions()).toEqual(rules.MERCHANT_TRANSITIONS);
});

it('customer and admin cancellable statuses match', () => {
    expect(dartList('customerCancellable')).toEqual(rules.CUSTOMER_CANCELLABLE);
    expect(dartList('adminCancellable')).toEqual(rules.ADMIN_CANCELLABLE);
});

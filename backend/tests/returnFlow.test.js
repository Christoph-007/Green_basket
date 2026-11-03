/**
 * Returns exactly as the Flutter app uses them:
 *   order detail -> "Return items" -> POST /api/returns { orderId (database id), type, reason, items[], refundMethod }
 *   Returns screen -> GET /api/returns/my-returns, DELETE /api/returns/:id
 *   admin -> PUT /api/returns/admin/:id/process, customer sees the result in my-returns
 * Real in-memory MongoDB.
 */
jest.mock('../src/services/notify', () => ({
    email: jest.fn().mockResolvedValue({}), sms: jest.fn().mockResolvedValue({}),
    push: jest.fn().mockResolvedValue({}), all: jest.fn().mockResolvedValue({})
}));
jest.mock('../src/services/notification', () => ({
    send: jest.fn().mockResolvedValue({}), createNotification: jest.fn().mockResolvedValue({})
}));

const request = require('supertest');
const app = require('../server');
const Order = require('../src/models/Order');
const Wallet = require('../src/models/Wallet');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

let shopper, farm, prod;

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(async () => {
    await db.clear();
    shopper = await f.customer();
    farm = await f.merchant();
    prod = await f.product(farm.merchant, { stock: 100, price: 40 });
});

async function orderWithStatus(status, { quantity = 3, buyer = shopper } = {}) {
    const res = await request(app).post('/api/orders').set(f.auth(buyer.token))
        .send({ items: [{ product: prod._id, quantity }], paymentMethod: 'cod', deliveryType: 'pickup' });
    expect(res.status).toBe(201);
    const order = res.body.data.order;
    await Order.updateOne({ _id: order._id }, { status });
    return order;
}

// Same body as the app's return request (order id = OrderModel.id, i.e. the database _id)
const appReturn = (order, overrides = {}, buyer = shopper) =>
    request(app).post('/api/returns').set(f.auth(buyer.token)).send({
        orderId: order._id, type: 'return', reason: 'Arrived damaged', refundMethod: 'wallet',
        items: [{ productId: String(prod._id), quantity: 2, condition: 'damaged' }], ...overrides
    });
const myReturns = (buyer = shopper) => request(app).get('/api/returns/my-returns').set(f.auth(buyer.token));

it('accepts a return for a delivered order using the database id', async () => {
    const order = await orderWithStatus('delivered');
    const res = await appReturn(order);
    expect(res.status).toBe(201);
    expect(res.body.data.status).toBe('requested');
    expect(res.body.data.refundAmount).toBe(80); // 2 x 40
});

it('accepts a return for a completed pickup order and for the readable order number', async () => {
    const order = await orderWithStatus('completed');
    expect((await appReturn(order)).status).toBe(201);
    const other = await orderWithStatus('completed');
    expect((await appReturn(other, { orderId: other.orderId })).status).toBe(201);
});

it('my-returns gives the app everything its list card shows', async () => {
    const order = await orderWithStatus('delivered');
    await appReturn(order);
    const res = await myReturns();
    expect(res.status).toBe(200);
    const r = res.body.data.returns[0];
    expect(r._id).toBeTruthy();
    expect(r.returnId).toMatch(/^RET-/);
    expect(r.status).toBe('requested');
    expect(r.type).toBe('return');
    expect(r.reason).toBe('Arrived damaged');
    expect(r.refundAmount).toBe(80);
    expect(r.createdAt).toBeTruthy();
    expect(r.order.orderId).toBe(order.orderId);
    expect(r.items[0].quantity).toBe(2);
    expect(r.items[0].product.name).toBeTruthy();
});

it('rejects bad requests with a 400 and a readable message', async () => {
    const order = await orderWithStatus('delivered');
    const cases = [
        [{ reason: '   ' }, /required/i],
        [{ items: [] }, /required/i],
        [{ type: 'swap' }, /return or exchange/i],
        [{ refundMethod: 'cash' }, /refundMethod/],
        [{ items: [{ productId: 'nope', quantity: 1 }] }, /valid productId/],
        [{ items: [{ productId: '64b000000000000000000001', quantity: 1 }] }, /not part of this order/],
        [{ items: [{ productId: String(prod._id), quantity: 0 }] }, /between 1 and 3/],
        [{ items: [{ productId: String(prod._id), quantity: 4 }] }, /between 1 and 3/],
        [{ items: [{ productId: String(prod._id), quantity: 1.5 }] }, /between 1 and 3/],
        [{ items: [{ productId: String(prod._id), quantity: 1, condition: 'melted' }] }, /condition/],
        [{ items: [{ productId: String(prod._id), quantity: 1 }, { productId: String(prod._id), quantity: 1 }] }, /only be listed once/]
    ];
    for (const [override, message] of cases) {
        const res = await appReturn(order, override);
        expect(res.status).toBe(400);
        expect(res.body.error).toMatch(message);
    }
    expect((await myReturns()).body.data.returns).toHaveLength(0);
});

it('only allows finished orders, only the owner, and one open return per order', async () => {
    const pending = await orderWithStatus('pending');
    const res = await appReturn(pending);
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/delivered or completed/);

    const order = await orderWithStatus('delivered');
    expect((await appReturn(order, {}, await f.customer())).status).toBe(404);
    expect((await appReturn(order)).status).toBe(201);
    const again = await appReturn(order);
    expect(again.status).toBe(400);
    expect(again.body.error).toMatch(/already exists/);
});

it('lets the customer cancel a request and then raise a new one', async () => {
    const order = await orderWithStatus('delivered');
    const created = await appReturn(order);
    const id = created.body.data._id;

    const cancel = await request(app).delete(`/api/returns/${id}`).set(f.auth(shopper.token));
    expect(cancel.status).toBe(200);

    const listed = (await myReturns()).body.data.returns[0];
    expect(listed.status).toBe('rejected');
    expect(listed.rejectionReason).toBe('Cancelled by user'); // the app labels this "Cancelled"

    expect((await appReturn(order)).status).toBe(201);
});

it('admin approval refunds the wallet and the customer sees "refunded"', async () => {
    const order = await orderWithStatus('delivered');
    const created = await appReturn(order);
    const { token: adminToken } = await f.admin();

    const processed = await request(app).put(`/api/returns/admin/${created.body.data._id}/process`)
        .set(f.auth(adminToken)).send({ action: 'approve' });
    expect(processed.status).toBe(200);

    const listed = (await myReturns()).body.data.returns[0];
    expect(listed.status).toBe('refunded');
    const wallet = await Wallet.findOne({ user: shopper.user._id });
    expect(wallet.balance).toBe(80);
});

it('admin rejection tells the customer why', async () => {
    const order = await orderWithStatus('delivered');
    const created = await appReturn(order);
    const { token: adminToken } = await f.admin();
    await request(app).put(`/api/returns/admin/${created.body.data._id}/process`)
        .set(f.auth(adminToken)).send({ action: 'reject', rejectionReason: 'Outside policy' });
    const listed = (await myReturns()).body.data.returns[0];
    expect(listed.status).toBe('rejected');
    expect(listed.rejectionReason).toBe('Outside policy');
});

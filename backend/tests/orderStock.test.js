/**
 * Issue 6: stock is reserved atomically, all-or-nothing, and released when
 * the order can't be created. Real in-memory MongoDB.
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
const Product = require('../src/models/Product');
const Order = require('../src/models/Order');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

let shopper, farm;

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(async () => {
    await db.clear();
    shopper = await f.customer();
    farm = await f.merchant();
});

const placeOrder = (token, items, extra = {}) => request(app).post('/api/orders').set(f.auth(token))
    .send({ items, paymentMethod: 'cod', deliveryType: 'pickup', ...extra });

const stockOf = async (p) => (await Product.findById(p._id)).stock;

it('reduces stock for a normal COD order', async () => {
    const p = await f.product(farm.merchant, { stock: 10 });
    const res = await placeOrder(shopper.token, [{ product: p._id, quantity: 3 }]);
    expect(res.status).toBe(201);
    expect(await stockOf(p)).toBe(7);
});

it('leaves earlier items untouched when a later item is out of stock', async () => {
    const a = await f.product(farm.merchant, { stock: 10 });
    const b = await f.product(farm.merchant, { stock: 2 });
    const res = await placeOrder(shopper.token, [{ product: a._id, quantity: 1 }, { product: b._id, quantity: 5 }]);
    expect(res.status).toBe(400);
    expect(await stockOf(a)).toBe(10);
    expect(await stockOf(b)).toBe(2);
    expect(await Order.countDocuments()).toBe(0);
});

it('leaves earlier items untouched when a later product does not exist', async () => {
    const a = await f.product(farm.merchant, { stock: 10 });
    const res = await placeOrder(shopper.token, [{ product: a._id, quantity: 1 }, { product: '64b000000000000000000000', quantity: 1 }]);
    expect(res.status).toBe(404);
    expect(await stockOf(a)).toBe(10);
});

it('never oversells the last unit to concurrent shoppers', async () => {
    const p = await f.product(farm.merchant, { stock: 1 });
    const shoppers = await Promise.all([1, 2, 3, 4, 5].map(() => f.customer()));
    const results = await Promise.all(shoppers.map(s => placeOrder(s.token, [{ product: p._id, quantity: 1 }])));

    expect(results.filter(r => r.status === 201)).toHaveLength(1);
    expect(results.filter(r => r.status === 400)).toHaveLength(4);
    expect(await stockOf(p)).toBe(0);
    expect(await Order.countDocuments()).toBe(1);
});

it('rejects negative, zero and non-numeric quantities without touching stock', async () => {
    const a = await f.product(farm.merchant, { stock: 10 });
    const b = await f.product(farm.merchant, { stock: 10 });
    for (const bad of [-9, 0, 'abc', null, 1e9]) {
        const res = await placeOrder(shopper.token, [{ product: a._id, quantity: 10 }, { product: b._id, quantity: bad }]);
        expect(res.status).toBe(400);
    }
    expect(await stockOf(a)).toBe(10);
    expect(await stockOf(b)).toBe(10);
});

it('treats a numeric string quantity as a number', async () => {
    const p = await f.product(farm.merchant, { stock: 10, price: 50 });
    const res = await placeOrder(shopper.token, [{ product: p._id, quantity: '2' }]);
    expect(res.status).toBe(201);
    expect(res.body.data.order.itemsTotal).toBe(100);
    expect(await stockOf(p)).toBe(8);
});

it('gives the stock back if the order cannot be saved', async () => {
    const p = await f.product(farm.merchant, { stock: 10 });
    const spy = jest.spyOn(Order, 'create').mockRejectedValueOnce(new Error('write failed'));
    const res = await placeOrder(shopper.token, [{ product: p._id, quantity: 4 }]);
    spy.mockRestore();
    expect(res.status).toBe(500);
    expect(await stockOf(p)).toBe(10);
});

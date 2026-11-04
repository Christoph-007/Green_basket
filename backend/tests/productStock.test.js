/**
 * Merchant > Products > stock stepper -> PATCH /api/products/:id/stock { stock }
 * Real in-memory MongoDB.
 */
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const Product = require('../src/models/Product');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(db.clear);

const patch = (id, token, body) =>
    request(app).patch(`/api/products/${id}/stock`).set(f.auth(token)).send(body);

describe('PATCH /api/products/:id/stock', () => {
    it('sets the stock and moves the status to out-of-stock at zero and back to active', async () => {
        const { merchant, token } = await f.merchant();
        const product = await f.product(merchant, { stock: 10 });

        const up = await patch(product._id, token, { stock: 25 });
        expect(up.status).toBe(200);
        expect((await Product.findById(product._id)).stock).toBe(25);

        const zero = await patch(product._id, token, { stock: 0 });
        expect(zero.status).toBe(200);
        const out = await Product.findById(product._id);
        expect(out.stock).toBe(0);
        expect(out.status).toBe('out-of-stock');

        const back = await patch(product._id, token, { stock: 3 });
        expect(back.status).toBe(200);
        const again = await Product.findById(product._id);
        expect(again.stock).toBe(3);
        expect(again.status).toBe('active');
    });

    it("refuses another seller's product and leaves the stock alone", async () => {
        const owner = await f.merchant();
        const other = await f.merchant();
        const product = await f.product(owner.merchant, { stock: 10 });
        const res = await patch(product._id, other.token, { stock: 99 });
        expect(res.status).toBe(403);
        expect((await Product.findById(product._id)).stock).toBe(10);
    });

    it('answers 404 for an unknown product', async () => {
        const { token } = await f.merchant();
        const res = await patch(new mongoose.Types.ObjectId(), token, { stock: 5 });
        expect(res.status).toBe(404);
    });

    it.each([
        ['negative', { stock: -1 }],
        ['fractional', { stock: 2.5 }],
        ['text', { stock: 'abc' }],
        ['missing', {}],
        ['null', { stock: null }]
    ])('rejects a %s stock value without changing the product', async (_name, body) => {
        const { merchant, token } = await f.merchant();
        const product = await f.product(merchant, { stock: 10 });
        const res = await patch(product._id, token, body);
        expect(res.status).toBe(400);
        expect((await Product.findById(product._id)).stock).toBe(10);
    });

    it('accepts a whole number sent as text', async () => {
        const { merchant, token } = await f.merchant();
        const product = await f.product(merchant, { stock: 10 });
        const res = await patch(product._id, token, { stock: '7' });
        expect(res.status).toBe(200);
        expect((await Product.findById(product._id)).stock).toBe(7);
    });

    it('needs a signed-in merchant', async () => {
        const { merchant } = await f.merchant();
        const product = await f.product(merchant);
        expect((await request(app).patch(`/api/products/${product._id}/stock`).send({ stock: 1 })).status).toBe(401);
        const { token } = await f.customer();
        expect((await patch(product._id, token, { stock: 1 })).status).toBeGreaterThanOrEqual(401);
    });
});

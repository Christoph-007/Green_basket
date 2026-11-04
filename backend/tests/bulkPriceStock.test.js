/**
 * Merchant > Products > select several > set stock / change price
 * PUT /api/bulk/products/bulk-update-stock and bulk-update-price. Real in-memory MongoDB.
 */
const request = require('supertest');
const app = require('../server');
const Product = require('../src/models/Product');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(db.clear);

const put = (path, token, updates) =>
    request(app).put(`/api/bulk/products/${path}`).set(f.auth(token)).send({ updates });

describe('bulk-update-stock', () => {
    it('updates several products and applies the same status rules as the single endpoint', async () => {
        const { merchant, token } = await f.merchant();
        const a = await f.product(merchant, { stock: 10 });
        const b = await f.product(merchant, { stock: 10 });
        const c = await f.product(merchant, { stock: 0, status: 'out-of-stock' });

        const res = await put('bulk-update-stock', token, [
            { productId: a._id, stock: 0 },
            { productId: b._id, stock: 7 },
            { productId: c._id, stock: '4' }
        ]);
        expect(res.status).toBe(200);
        expect(res.body.data).toMatchObject({ successCount: 3, errorCount: 0 });

        const [ra, rb, rc] = await Promise.all([a, b, c].map(p => Product.findById(p._id)));
        expect(ra.stock).toBe(0);
        expect(ra.status).toBe('out-of-stock');
        expect(rb.stock).toBe(7);
        expect(rb.status).toBe('active');
        expect(rc.stock).toBe(4);
        expect(rc.status).toBe('active');
    });

    it('leaves isActive alone, so restocking never hides or resurrects a product', async () => {
        const { merchant, token } = await f.merchant();
        const p = await f.product(merchant, { stock: 5 });
        const before = (await Product.findById(p._id)).isActive;
        await put('bulk-update-stock', token, [{ productId: p._id, stock: 0 }]);
        expect((await Product.findById(p._id)).isActive).toBe(before);
    });

    it.each([[-1], [2.5], ['abc'], [''], [null], [true]])('rejects stock %p for that item only', async (bad) => {
        const { merchant, token } = await f.merchant();
        const good = await f.product(merchant, { stock: 1 });
        const other = await f.product(merchant, { stock: 1 });
        const res = await put('bulk-update-stock', token, [
            { productId: other._id, stock: bad },
            { productId: good._id, stock: 9 }
        ]);
        expect(res.status).toBe(200);
        expect(res.body.data).toMatchObject({ successCount: 1, errorCount: 1 });
        expect((await Product.findById(other._id)).stock).toBe(1);
        expect((await Product.findById(good._id)).stock).toBe(9);
    });

    it("refuses another merchant's product", async () => {
        const mine = await f.merchant();
        const theirs = await f.merchant();
        const p = await f.product(theirs.merchant, { stock: 3 });
        const res = await put('bulk-update-stock', mine.token, [{ productId: p._id, stock: 99 }]);
        expect(res.body.data).toMatchObject({ successCount: 0, errorCount: 1 });
        expect((await Product.findById(p._id)).stock).toBe(3);
    });

    it('needs a non-empty list of at most 100', async () => {
        const { token } = await f.merchant();
        expect((await put('bulk-update-stock', token, [])).status).toBe(400);
        const many = Array.from({ length: 101 }, () => ({ productId: '507f1f77bcf86cd799439011', stock: 1 }));
        expect((await put('bulk-update-stock', token, many)).status).toBe(400);
    });

    it('is for merchants only', async () => {
        const { token } = await f.customer();
        const res = await put('bulk-update-stock', token, [{ productId: '507f1f77bcf86cd799439011', stock: 1 }]);
        expect([401, 403]).toContain(res.status);
    });
});

describe('bulk-update-price', () => {
    it('sets new prices, accepting numeric text', async () => {
        const { merchant, token } = await f.merchant();
        const a = await f.product(merchant, { price: 100 });
        const b = await f.product(merchant, { price: 100 });
        const res = await put('bulk-update-price', token, [
            { productId: a._id, price: 120.5 },
            { productId: b._id, price: '80' }
        ]);
        expect(res.body.data).toMatchObject({ successCount: 2, errorCount: 0 });
        expect((await Product.findById(a._id)).price).toBe(120.5);
        expect((await Product.findById(b._id)).price).toBe(80);
    });

    it.each([[0], [-5], ['abc'], [''], [null]])('rejects price %p for that item only', async (bad) => {
        const { merchant, token } = await f.merchant();
        const x = await f.product(merchant, { price: 100 });
        const y = await f.product(merchant, { price: 100 });
        const res = await put('bulk-update-price', token, [
            { productId: x._id, price: bad },
            { productId: y._id, price: 55 }
        ]);
        expect(res.body.data).toMatchObject({ successCount: 1, errorCount: 1 });
        expect((await Product.findById(x._id)).price).toBe(100);
        expect((await Product.findById(y._id)).price).toBe(55);
    });
});

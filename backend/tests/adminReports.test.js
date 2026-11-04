/**
 * Admin reports (real in-memory MongoDB):
 *   GET /api/admin/orders/export, /api/admin/users/export,
 *   GET /api/financial/admin/payouts/export, GET /api/admin/analytics/revenue-trend
 */
const request = require('supertest');
const { parse } = require('csv-parse/sync');
const app = require('../server');
const Order = require('../src/models/Order');
const Payout = require('../src/models/Payout');
const User = require('../src/models/User');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(db.clear);

const csv = (res) => parse(res.text.replace(/^﻿/, ''), { columns: true });
const makeOrder = (customer, merchantDoc, overrides = {}) =>
    Order.create({
        customer: customer._id, merchant: merchantDoc._id, items: [],
        itemsTotal: 200, totalAmount: 200, paymentMethod: 'cod', paymentStatus: 'completed',
        status: 'delivered', deliveredAt: new Date(), ...overrides
    });

describe('access control', () => {
    it.each([
        '/api/admin/orders/export',
        '/api/admin/users/export',
        '/api/financial/admin/payouts/export',
        '/api/admin/analytics/revenue-trend'
    ])('%s needs an admin', async (url) => {
        expect((await request(app).get(url)).status).toBe(401);
        const { token } = await f.customer();
        expect((await request(app).get(url).set(f.auth(token))).status).toBeGreaterThanOrEqual(401);
    });
});

describe('GET /api/admin/orders/export', () => {
    it('returns a CSV with a header and one row per order', async () => {
        const { token } = await f.admin();
        const { user } = await f.customer();
        const { merchant } = await f.merchant();
        await makeOrder(user, merchant, { totalAmount: 200, status: 'delivered' });
        await makeOrder(user, merchant, { totalAmount: 300, status: 'pending' });

        const res = await request(app).get('/api/admin/orders/export').set(f.auth(token));
        expect(res.status).toBe(200);
        expect(res.headers['content-type']).toMatch(/text\/csv/);
        expect(res.headers['content-disposition']).toMatch(/attachment; filename="orders-\d{4}-\d{2}-\d{2}\.csv"/);
        const rows = csv(res);
        expect(rows).toHaveLength(2);
        expect(Object.keys(rows[0])).toEqual(expect.arrayContaining(['Order ID', 'Status', 'Customer', 'Merchant', 'Total']));
        expect(rows.map(r => r.Total).sort()).toEqual(['200', '300']);
    });

    it('applies the status filter and the date range', async () => {
        const { token } = await f.admin();
        const { user } = await f.customer();
        const { merchant } = await f.merchant();
        await makeOrder(user, merchant, { status: 'delivered' });
        const old = await makeOrder(user, merchant, { status: 'delivered' });
        await Order.collection.updateOne({ _id: old._id }, { $set: { createdAt: new Date('2020-01-15T00:00:00Z') } });
        await makeOrder(user, merchant, { status: 'pending' });

        const delivered = await request(app).get('/api/admin/orders/export').query({ status: 'delivered' }).set(f.auth(token));
        expect(csv(delivered)).toHaveLength(2);

        const range = await request(app).get('/api/admin/orders/export')
            .query({ from: '2020-01-01', to: '2020-12-31' }).set(f.auth(token));
        expect(csv(range)).toHaveLength(1);
    });

    it('rejects an invalid date', async () => {
        const { token } = await f.admin();
        const res = await request(app).get('/api/admin/orders/export').query({ from: 'not-a-date' }).set(f.auth(token));
        expect(res.status).toBe(400);
    });

    it('neutralises spreadsheet formulas in text cells', async () => {
        const { token } = await f.admin();
        const { user } = await f.customer({ name: '=HYPERLINK("http://evil","click")' });
        const { merchant } = await f.merchant();
        await makeOrder(user, merchant);
        const res = await request(app).get('/api/admin/orders/export').set(f.auth(token));
        expect(csv(res)[0].Customer.startsWith("'=")).toBe(true);
    });

    it('is only a header when there are no orders', async () => {
        const { token } = await f.admin();
        const res = await request(app).get('/api/admin/orders/export').set(f.auth(token));
        expect(res.status).toBe(200);
        expect(csv(res)).toHaveLength(0);
        expect(res.text).toContain('Order ID');
    });
});

describe('GET /api/admin/users/export', () => {
    it('lists users, filters by search and by blocked state', async () => {
        const { token } = await f.admin();
        await f.customer({ name: 'Asha Nair', email: 'asha@example.com' });
        const bob = await f.customer({ name: 'Bob Roy', email: 'bob@example.com' });
        await User.updateOne({ _id: bob.user._id }, { isBlocked: true });

        const all = csv(await request(app).get('/api/admin/users/export').set(f.auth(token)));
        expect(all).toHaveLength(2);
        expect(Object.keys(all[0])).toEqual(['Name', 'Email', 'Phone', 'Joined', 'Blocked']);

        const search = csv(await request(app).get('/api/admin/users/export').query({ search: 'asha' }).set(f.auth(token)));
        expect(search.map(r => r.Name)).toEqual(['Asha Nair']);

        const blocked = csv(await request(app).get('/api/admin/users/export').query({ blocked: 'true' }).set(f.auth(token)));
        expect(blocked.map(r => r.Name)).toEqual(['Bob Roy']);
        expect(blocked[0].Blocked).toBe('yes');

        const active = csv(await request(app).get('/api/admin/users/export').query({ blocked: 'false' }).set(f.auth(token)));
        expect(active.map(r => r.Name)).toEqual(['Asha Nair']);
    });

    it('treats the search text literally, not as a pattern', async () => {
        const { token } = await f.admin();
        await f.customer({ name: 'Plain Name' });
        const res = await request(app).get('/api/admin/users/export').query({ search: '.*' }).set(f.auth(token));
        expect(res.status).toBe(200);
        expect(csv(res)).toHaveLength(0);
    });
});

describe('GET /api/financial/admin/payouts/export', () => {
    it('lists payouts with the merchant name and filters by status', async () => {
        const { token } = await f.admin();
        const { merchant } = await f.merchant({ businessName: 'Green Farm' });
        const start = new Date('2026-10-01T00:00:00Z');
        const end = new Date('2026-10-31T23:59:59Z');
        await Payout.create({ merchant: merchant._id, period: { startDate: start, endDate: end }, grossRevenue: 1000, netAmount: 950, status: 'completed', totalOrders: 4 });
        await Payout.create({ merchant: merchant._id, period: { startDate: start, endDate: end }, grossRevenue: 500, netAmount: 475, status: 'pending', totalOrders: 2 });

        const all = csv(await request(app).get('/api/financial/admin/payouts/export').set(f.auth(token)));
        expect(all).toHaveLength(2);
        expect(all[0].Merchant).toBe('Green Farm');

        const pending = csv(await request(app).get('/api/financial/admin/payouts/export').query({ status: 'pending' }).set(f.auth(token)));
        expect(pending).toHaveLength(1);
        expect(pending[0]['Net amount']).toBe('475');
    });
});

describe('GET /api/admin/analytics/revenue-trend', () => {
    const today = () => new Date();
    const firstOfPreviousMonth = () => {
        const n = new Date();
        return new Date(Date.UTC(n.getUTCFullYear(), n.getUTCMonth() - 1, 1, 12));
    };

    it('returns a zero-filled series on an empty database', async () => {
        const { token } = await f.admin();
        const res = await request(app).get('/api/admin/analytics/revenue-trend').set(f.auth(token));
        expect(res.status).toBe(200);
        const d = res.body.data;
        expect(d.period).toBe('month');
        expect(d.groupBy).toBe('day');
        expect(d.current.length).toBe(new Date().getUTCDate());
        expect(d.current.every(p => p.revenue === 0 && p.orders === 0)).toBe(true);
        expect(d.totals.changePct).toBeNull();
    });

    it('counts delivered and completed orders only, in the right bucket', async () => {
        const { token } = await f.admin();
        const { user } = await f.customer();
        const { merchant } = await f.merchant();
        await makeOrder(user, merchant, { totalAmount: 500, status: 'delivered', deliveredAt: today() });
        await makeOrder(user, merchant, { totalAmount: 100, status: 'completed', deliveredAt: today() });
        await makeOrder(user, merchant, { totalAmount: 999, status: 'pending', deliveredAt: undefined });

        const res = await request(app).get('/api/admin/analytics/revenue-trend').set(f.auth(token));
        const d = res.body.data;
        const last = d.current[d.current.length - 1];
        expect(last.date).toBe(new Date().toISOString().slice(0, 10));
        expect(last.revenue).toBe(600);
        expect(last.orders).toBe(2);
        expect(d.totals.currentRevenue).toBe(600);
        expect(d.totals.currentOrders).toBe(2);
    });

    it('uses the last update when an order has no delivery time', async () => {
        const { token } = await f.admin();
        const { user } = await f.customer();
        const { merchant } = await f.merchant();
        await makeOrder(user, merchant, { totalAmount: 250, status: 'completed', deliveredAt: undefined });
        const res = await request(app).get('/api/admin/analytics/revenue-trend').set(f.auth(token));
        expect(res.body.data.totals.currentRevenue).toBe(250);
    });

    it('compares with the same number of days of the previous month', async () => {
        const { token } = await f.admin();
        const { user } = await f.customer();
        const { merchant } = await f.merchant();
        await makeOrder(user, merchant, { totalAmount: 500, deliveredAt: today() });
        await makeOrder(user, merchant, { totalAmount: 250, deliveredAt: firstOfPreviousMonth() });
        // Day 28 of the previous month only belongs to the comparison window once we are on day 28 or later.
        const n = new Date();
        await makeOrder(user, merchant, { totalAmount: 100, deliveredAt: new Date(Date.UTC(n.getUTCFullYear(), n.getUTCMonth() - 1, 28, 12)) });
        const windowIncludesDay28 = n.getUTCDate() >= 28;
        const expectedWindow = windowIncludesDay28 ? 350 : 250;

        const res = await request(app).get('/api/admin/analytics/revenue-trend').set(f.auth(token));
        const t = res.body.data.totals;
        expect(t.previousRevenue).toBe(350);
        expect(t.previousRevenueSameWindow).toBe(expectedWindow);
        expect(t.changePct).toBe(Math.round(((500 - expectedWindow) / expectedWindow) * 1000) / 10);
        expect(res.body.data.previous.length).toBeGreaterThanOrEqual(28);
    });

    it('groups a year by month and a quarter by day', async () => {
        const { token } = await f.admin();
        const { user } = await f.customer();
        const { merchant } = await f.merchant();
        await makeOrder(user, merchant, { totalAmount: 700, deliveredAt: today() });

        const year = (await request(app).get('/api/admin/analytics/revenue-trend').query({ period: 'year' }).set(f.auth(token))).body.data;
        expect(year.groupBy).toBe('month');
        expect(year.current.length).toBe(new Date().getUTCMonth() + 1);
        expect(year.totals.currentRevenue).toBe(700);

        const quarter = (await request(app).get('/api/admin/analytics/revenue-trend').query({ period: 'quarter' }).set(f.auth(token))).body.data;
        expect(quarter.groupBy).toBe('day');
        expect(quarter.totals.currentRevenue).toBe(700);
    });

    it('falls back to month for an unknown period', async () => {
        const { token } = await f.admin();
        const res = await request(app).get('/api/admin/analytics/revenue-trend').query({ period: 'decade' }).set(f.auth(token));
        expect(res.status).toBe(200);
        expect(res.body.data.period).toBe('month');
    });
});

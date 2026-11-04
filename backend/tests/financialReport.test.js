/**
 * Admin > Finance tab -> GET /api/financial/admin/reports/financial?period=...
 * Real in-memory MongoDB. Covers an empty database, delivered orders, a deleted
 * merchant, payouts, a platform-settings document without a commission rate,
 * and every period the app can send.
 */
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const Order = require('../src/models/Order');
const Payout = require('../src/models/Payout');
const PlatformSettings = require('../src/models/PlatformSettings');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(db.clear);

const URL = '/api/financial/admin/reports/financial';
const PERIODS = ['all', 'month', 'quarter', 'year'];

const makeOrder = (customer, merchantDoc, overrides = {}) =>
    Order.create({
        customer: customer._id, merchant: merchantDoc._id, items: [],
        itemsTotal: 200, totalAmount: 200, paymentMethod: 'cod', paymentStatus: 'completed',
        status: 'delivered', deliveredAt: new Date(), ...overrides
    });

describe('GET /api/financial/admin/reports/financial', () => {
    it.each(PERIODS)('returns zeros on an empty database (period=%s)', async (period) => {
        const { token } = await f.admin();
        const res = await request(app).get(URL).query({ period }).set(f.auth(token));
        expect(res.status).toBe(200);
        expect(res.body.data.summary).toMatchObject({
            totalGrossRevenue: 0, totalCommissionEarned: 0, totalRefunds: 0,
            netRevenue: 0, payoutsPaid: 0, payoutsPending: 0, totalOrders: 0
        });
        expect(res.body.data.topMerchants).toEqual([]);
    });

    it('adds up delivered and completed orders and ignores other statuses', async () => {
        const { token } = await f.admin();
        const { user } = await f.customer();
        const { merchant } = await f.merchant();
        await makeOrder(user, merchant, { totalAmount: 200, status: 'delivered' });
        await makeOrder(user, merchant, { totalAmount: 300, status: 'completed' });
        await makeOrder(user, merchant, { totalAmount: 999, status: 'pending', deliveredAt: undefined });

        const res = await request(app).get(URL).query({ period: 'all' }).set(f.auth(token));
        expect(res.status).toBe(200);
        const s = res.body.data.summary;
        expect(s.totalGrossRevenue).toBe(500);
        expect(s.totalOrders).toBe(2);
        expect(s.totalCommissionEarned).toBeCloseTo(25); // default 5%
        expect(res.body.data.topMerchants).toHaveLength(1);
        expect(res.body.data.topMerchants[0].revenue).toBe(500);
    });

    it('does not fail when an order points at a merchant that was deleted', async () => {
        const { token } = await f.admin();
        const { user } = await f.customer();
        await makeOrder(user, { _id: new mongoose.Types.ObjectId() });
        const res = await request(app).get(URL).query({ period: 'all' }).set(f.auth(token));
        expect(res.status).toBe(200);
        expect(res.body.data.summary.totalOrders).toBe(1);
        expect(res.body.data.topMerchants).toEqual([]);
    });

    it('sums paid and pending payouts that fall inside the period', async () => {
        const { token } = await f.admin();
        const { merchant } = await f.merchant();
        const start = new Date(); start.setDate(1); start.setHours(0, 0, 0, 0);
        const end = new Date(); end.setHours(23, 59, 59, 999);
        await Payout.create({ merchant: merchant._id, period: { startDate: start, endDate: end }, netAmount: 400, status: 'completed' });
        await Payout.create({ merchant: merchant._id, period: { startDate: start, endDate: end }, netAmount: 100, status: 'pending' });

        const res = await request(app).get(URL).query({ period: 'month' }).set(f.auth(token));
        expect(res.status).toBe(200);
        expect(res.body.data.summary.payoutsPaid).toBe(400);
        expect(res.body.data.summary.payoutsPending).toBe(100);
    });

    it('still answers when platform settings exist (uses the configured rate)', async () => {
        const { token } = await f.admin();
        const { user } = await f.customer();
        const { merchant } = await f.merchant();
        await PlatformSettings.create({});
        await makeOrder(user, merchant, { totalAmount: 1000 });
        const res = await request(app).get(URL).query({ period: 'all' }).set(f.auth(token));
        expect(res.status).toBe(200);
        expect(res.body.data.summary.totalCommissionEarned).toBeGreaterThanOrEqual(0);
    });

    it('rejects a non-admin and a missing token', async () => {
        const { token } = await f.customer();
        expect((await request(app).get(URL).set(f.auth(token))).status).toBeGreaterThanOrEqual(401);
        expect((await request(app).get(URL)).status).toBe(401);
    });

    it('returns the real cause in `details` when something throws', async () => {
        const { token } = await f.admin();
        const spy = jest.spyOn(Order, 'find').mockImplementationOnce(() => { throw new Error('boom'); });
        const res = await request(app).get(URL).query({ period: 'all' }).set(f.auth(token));
        spy.mockRestore();
        expect(res.status).toBe(500);
        expect(res.body.error).toBe('Failed to generate financial report');
        expect(res.body.details).toBe('boom');
    });
});

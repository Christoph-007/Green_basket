/**
 * Merchant onboarding as the Flutter admin app drives it:
 *   Admin > Merchants > Approve / Reject -> PATCH /api/admin/merchants/:id/verify { status, rejectionReason? }
 * A merchant who signed up stays "pending" and is blocked from selling until an admin approves them.
 * Real in-memory MongoDB.
 */
jest.mock('../src/services/notify', () => ({
    email: jest.fn().mockResolvedValue({ success: true }),
    sms: jest.fn().mockResolvedValue({ success: true }),
    push: jest.fn().mockResolvedValue({ success: true }),
    all: jest.fn().mockResolvedValue({ success: true })
}));

const request = require('supertest');
const app = require('../server');
const Merchant = require('../src/models/Merchant');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(db.clear);

// A merchant exactly as sign-up leaves them
const pendingMerchant = () => f.merchant({ verificationStatus: 'pending' });
const verify = (adminToken, merchantId, body) =>
    request(app).patch(`/api/admin/merchants/${merchantId}/verify`).set(f.auth(adminToken)).send(body);
const tryToSell = async (merchantToken) => {
    const category = await f.category();
    return request(app).post('/api/products').set(f.auth(merchantToken)).send({
        name: 'Tomatoes', description: 'Fresh', price: 40, stock: 10, unit: 'kg', category: String(category._id)
    });
};

it('a pending merchant is blocked from selling', async () => {
    const { token } = await pendingMerchant();
    const res = await tryToSell(token);
    expect(res.status).toBe(403);
    expect(res.body.message).toMatch(/not yet approved/i);
});

it('the admin sees the merchant in the pending list', async () => {
    const { merchant } = await pendingMerchant();
    const { token: adminToken } = await f.admin();
    const res = await request(app).get('/api/admin/merchants/pending').set(f.auth(adminToken));
    expect(res.status).toBe(200);
    expect(JSON.stringify(res.body)).toContain(String(merchant._id));
});

it('Approve (what the app sends) lets the merchant sell', async () => {
    const { merchant, token } = await pendingMerchant();
    const { token: adminToken } = await f.admin();

    const res = await verify(adminToken, merchant._id, { status: 'approved' });
    expect(res.status).toBe(200);
    expect((await Merchant.findById(merchant._id)).verificationStatus).toBe('approved');

    expect((await tryToSell(token)).status).toBe(201);
});

it('Reject stores the reason and keeps the merchant blocked', async () => {
    const { merchant, token } = await pendingMerchant();
    const { token: adminToken } = await f.admin();

    const res = await verify(adminToken, merchant._id, { status: 'rejected', rejectionReason: 'Licence photo is unreadable' });
    expect(res.status).toBe(200);
    const saved = await Merchant.findById(merchant._id);
    expect(saved.verificationStatus).toBe('rejected');
    expect(saved.rejectionReason).toBe('Licence photo is unreadable');

    expect((await tryToSell(token)).status).toBe(403);
});

it('a rejected merchant can still be approved later', async () => {
    const { merchant } = await pendingMerchant();
    const { token: adminToken } = await f.admin();
    await verify(adminToken, merchant._id, { status: 'rejected', rejectionReason: 'Missing documents' });
    const res = await verify(adminToken, merchant._id, { status: 'approved' });
    expect(res.status).toBe(200);
    expect((await Merchant.findById(merchant._id)).verificationStatus).toBe('approved');
});

it('the old payload { approved: true } is refused, so the app must send "status"', async () => {
    const { merchant } = await pendingMerchant();
    const { token: adminToken } = await f.admin();
    const res = await verify(adminToken, merchant._id, { approved: true });
    expect(res.status).toBe(400);
    expect((await Merchant.findById(merchant._id)).verificationStatus).toBe('pending');
});

it('only admins can approve', async () => {
    const { merchant } = await pendingMerchant();
    const { token: customerToken } = await f.customer();
    const res = await verify(customerToken, merchant._id, { status: 'approved' });
    expect(res.status).toBeGreaterThanOrEqual(401);
    expect((await Merchant.findById(merchant._id)).verificationStatus).toBe('pending');
});

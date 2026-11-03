/**
 * Reviews exactly as the Flutter app uses them:
 *   order list -> "Rate this order" -> POST /api/reviews { merchantId, orderId, rating, comment }
 *   order list -> GET /api/reviews/my-reviews (builds the "You reviewed this" stars from reviews[].order)
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
const Merchant = require('../src/models/Merchant');
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
    prod = await f.product(farm.merchant, { stock: 100 });
});

// Place a real order through the API, then move it to the status the test needs.
async function orderWithStatus(status, { deliveryType = 'pickup', buyer = shopper } = {}) {
    const body = { items: [{ product: prod._id, quantity: 1 }], paymentMethod: 'cod', deliveryType };
    if (deliveryType !== 'pickup') body.addressId = String((await f.address(buyer.user))._id);
    const res = await request(app).post('/api/orders').set(f.auth(buyer.token)).send(body);
    expect(res.status).toBe(201);
    const id = res.body.data.order._id;
    await Order.updateOne({ _id: id }, { status });
    return id;
}

// Same body as ReviewRepository.addMerchantReview
const appReview = (orderId, overrides = {}, buyer = shopper) =>
    request(app).post('/api/reviews').set(f.auth(buyer.token)).send({
        merchantId: String(farm.merchant._id), orderId, rating: 5, comment: 'Fresh and on time', ...overrides
    });

it('accepts a review for a delivered home-delivery order', async () => {
    const id = await orderWithStatus('delivered', { deliveryType: 'home-delivery' });
    const res = await appReview(id);
    expect(res.status).toBe(201);
    const m = await Merchant.findById(farm.merchant._id);
    expect(m.totalReviews).toBe(1);
    expect(m.averageRating).toBe(5);
});

it('accepts a review for a completed pickup order (the app offers "Rate this order" for it)', async () => {
    const id = await orderWithStatus('completed');
    const res = await appReview(id);
    expect(res.status).toBe(201);
});

it('lets the same customer review a second order from the same merchant', async () => {
    const first = await orderWithStatus('completed');
    const second = await orderWithStatus('completed');
    expect((await appReview(first, { rating: 4 })).status).toBe(201);
    expect((await appReview(second, { rating: 2 })).status).toBe(201);
    const m = await Merchant.findById(farm.merchant._id);
    expect(m.totalReviews).toBe(2);
    expect(m.averageRating).toBe(3);
});

it('refuses a second review of the same order with a clear message', async () => {
    const id = await orderWithStatus('completed');
    expect((await appReview(id)).status).toBe(201);
    const again = await appReview(id);
    expect(again.status).toBe(400);
    expect(again.body.error).toMatch(/already reviewed/i);
});

it('does not require a long comment: short and missing comments are fine', async () => {
    const a = await orderWithStatus('completed');
    const b = await orderWithStatus('completed');
    expect((await appReview(a, { comment: 'ok' })).status).toBe(201);
    expect((await appReview(b, { comment: undefined })).status).toBe(201);
});

it('rejects a comment over 500 characters and bad ratings', async () => {
    const id = await orderWithStatus('completed');
    expect((await appReview(id, { comment: 'x'.repeat(501) })).status).toBe(400);
    for (const rating of [0, 6, 4.5, 'abc', null]) {
        const res = await appReview(id, { rating });
        expect(res.status).toBe(400);
    }
});

it('rejects malformed ids with 400 instead of crashing', async () => {
    const id = await orderWithStatus('completed');
    expect((await appReview('not-an-id')).status).toBe(400);
    expect((await appReview(id, { merchantId: 'nope' })).status).toBe(400);
});

it('only lets customers review their own, finished orders', async () => {
    const pending = await orderWithStatus('pending');
    expect((await appReview(pending)).status).toBe(403);

    const mine = await orderWithStatus('completed');
    const other = await f.customer();
    expect((await appReview(mine, {}, other)).status).toBe(403);
});

it('my-reviews returns the order id the app uses to show "You reviewed this"', async () => {
    const id = await orderWithStatus('completed');
    await appReview(id, { rating: 4 });
    const res = await request(app).get('/api/reviews/my-reviews').set(f.auth(shopper.token));
    expect(res.status).toBe(200);
    const reviews = res.body.data.reviews;
    expect(reviews).toHaveLength(1);
    // order_list_screen.dart reads r['order'] as either an object with _id or a plain id string
    const order = reviews[0].order;
    expect(String(order && order._id ? order._id : order)).toBe(String(id));
    expect(reviews[0].rating).toBe(4);
});

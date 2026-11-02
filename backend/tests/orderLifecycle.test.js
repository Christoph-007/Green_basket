/**
 * Issues 8–10: cancellation rules, refunds, merchant status transitions,
 * loyalty awarded once; plus order access control. Real in-memory MongoDB;
 * only Razorpay and outbound notifications are mocked.
 */
jest.mock('../src/services/paymentService', () => ({
    createRazorpayOrder: jest.fn(),
    verifyRazorpaySignature: jest.fn(),
    getRazorpayOrder: jest.fn(),
    getRazorpayPayment: jest.fn(),
    processRazorpayRefund: jest.fn().mockResolvedValue({ id: 'rfnd_1', status: 'processed' })
}));
jest.mock('../src/services/notify', () => ({
    email: jest.fn().mockResolvedValue({}), sms: jest.fn().mockResolvedValue({}),
    push: jest.fn().mockResolvedValue({}), all: jest.fn().mockResolvedValue({})
}));
jest.mock('../src/services/notification', () => ({
    send: jest.fn().mockResolvedValue({}), createNotification: jest.fn().mockResolvedValue({})
}));

const request = require('supertest');
const app = require('../server');
const paymentService = require('../src/services/paymentService');
const Product = require('../src/models/Product');
const Order = require('../src/models/Order');
const Offer = require('../src/models/Offer');
const User = require('../src/models/User');
const Wallet = require('../src/models/Wallet');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

let shopper, farm, product;

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(async () => {
    await db.clear();
    jest.clearAllMocks();
    shopper = await f.customer();
    farm = await f.merchant();
    product = await f.product(farm.merchant, { stock: 10, price: 100 });
});

const stock = async () => (await Product.findById(product._id)).stock;

const placeOrder = async (extra = {}, token = shopper.token) => {
    const res = await request(app).post('/api/orders').set(f.auth(token))
        .send({ items: [{ product: product._id, quantity: 2 }], paymentMethod: 'cod', deliveryType: 'pickup', ...extra });
    expect(res.status).toBe(201);
    return res.body.data.order;
};

const cancel = (orderId, token = shopper.token, reason = 'changed my mind') =>
    request(app).patch(`/api/orders/${orderId}/cancel`).set(f.auth(token)).send({ reason });

const setStatus = (orderId, status, token = farm.token, note) =>
    request(app).patch(`/api/orders/merchant/${orderId}/status`).set(f.auth(token)).send({ status, note });

describe('Customer cancellation (Issue 8)', () => {
    it('cancels a pending order, restores stock and records history', async () => {
        const order = await placeOrder();
        expect(await stock()).toBe(8);

        const res = await cancel(order._id);
        expect(res.status).toBe(200);
        expect(await stock()).toBe(10);
        const saved = await Order.findById(order._id);
        expect(saved.status).toBe('cancelled');
        expect(saved.cancelledBy).toBe('customer');
        expect(saved.statusHistory[saved.statusHistory.length - 1].status).toBe('cancelled');
    });

    it.each(['preparing', 'ready', 'delivered', 'completed', 'refunded', 'cancelled'])(
        'refuses to cancel a %s order and leaves stock alone', async (status) => {
            const order = await placeOrder();
            await Order.updateOne({ _id: order._id }, { status });
            const res = await cancel(order._id);
            expect(res.status).toBe(400);
            expect(await stock()).toBe(8);
        });

    it('restores stock only once when cancelled twice at the same time', async () => {
        const order = await placeOrder();
        const results = await Promise.all([cancel(order._id), cancel(order._id), cancel(order._id)]);
        expect(results.filter(r => r.status === 200)).toHaveLength(1);
        expect(await stock()).toBe(10);
    });

    it("can't cancel someone else's order", async () => {
        const order = await placeOrder();
        const other = await f.customer();
        const res = await cancel(order._id, other.token);
        expect(res.status).toBe(404);
        expect(await stock()).toBe(8);
    });

    it('refunds a wallet-paid order back to the wallet', async () => {
        await Wallet.create({ user: shopper.user._id, balance: 500 });
        const order = await placeOrder({ paymentMethod: 'wallet' });
        expect((await Wallet.findOne({ user: shopper.user._id })).balance).toBe(300);

        const res = await cancel(order._id);
        expect(res.status).toBe(200);
        expect(res.body.data.refund).toEqual(expect.objectContaining({ refunded: true, method: 'wallet', amount: 200 }));
        const wallet = await Wallet.findOne({ user: shopper.user._id });
        expect(wallet.balance).toBe(500);
        expect(wallet.transactions.map(t => t.source)).toEqual(['payment', 'refund']);
        expect((await Order.findById(order._id)).paymentStatus).toBe('refunded');
    });

    it('refunds a Razorpay-paid order through Razorpay', async () => {
        const order = await placeOrder({ paymentMethod: 'razorpay' });
        await Order.updateOne({ _id: order._id }, {
            status: 'confirmed', paymentStatus: 'completed', razorpayPaymentId: 'pay_1',
            'paymentGateway.provider': 'razorpay'
        });
        const res = await cancel(order._id);
        expect(res.status).toBe(200);
        expect(paymentService.processRazorpayRefund).toHaveBeenCalledWith('pay_1', 200, 'changed my mind');
        const saved = await Order.findById(order._id);
        expect(saved.refund.status).toBe('processing');
        expect(saved.paymentStatus).toBe('refunded');
    });

    it('releases the coupon use when the order is cancelled', async () => {
        const offer = await Offer.create({
            title: 'Ten off', type: 'flat', discountAmount: 10, couponCode: 'TEN',
            isActive: true, status: 'active', createdBy: 'admin',
            startDate: new Date(Date.now() - 86400000), endDate: new Date(Date.now() + 86400000)
        });
        const order = await placeOrder({ couponCode: 'TEN' });
        expect((await Offer.findById(offer._id)).usedCount).toBe(1);
        await cancel(order._id);
        const after = await Offer.findById(offer._id);
        expect(after.usedCount).toBe(0);
        expect(after.usedBy).toHaveLength(0);
    });
});

describe('Admin cancellation', () => {
    it('lets an admin cancel an order that is already being prepared', async () => {
        const admin = await f.admin();
        const order = await placeOrder();
        await Order.updateOne({ _id: order._id }, { status: 'preparing' });
        const res = await cancel(order._id, admin.token, 'out of stock at farm');
        expect(res.status).toBe(200);
        expect((await Order.findById(order._id)).cancelledBy).toBe('admin');
        expect(await stock()).toBe(10);
    });
});

describe('Merchant status transitions (Issue 9)', () => {
    it('rejects skipping straight from pending to delivered/completed', async () => {
        const order = await placeOrder();
        expect((await setStatus(order._id, 'delivered')).status).toBe(400);
        expect((await setStatus(order._id, 'completed')).status).toBe(400);
        expect((await Order.findById(order._id)).status).toBe('pending');
    });

    it('rejects reviving a cancelled order or touching an unpaid online order', async () => {
        const cancelled = await placeOrder();
        await cancel(cancelled._id);
        expect((await setStatus(cancelled._id, 'confirmed')).status).toBe(400);

        const unpaid = await placeOrder({ paymentMethod: 'razorpay' });
        expect((await setStatus(unpaid._id, 'confirmed')).status).toBe(400);
    });

    it('follows the pickup flow and refuses delivery-only steps', async () => {
        const order = await placeOrder();
        for (const s of ['confirmed', 'preparing', 'ready']) {
            expect((await setStatus(order._id, s)).status).toBe(200);
        }
        expect((await setStatus(order._id, 'out-for-delivery')).status).toBe(400);
        const done = await setStatus(order._id, 'completed');
        expect(done.status).toBe(200);
        expect(done.body.allowedNextStatuses).toEqual([]);
    });

    it('follows the home-delivery flow and requires delivery before completion', async () => {
        const address = await f.address(shopper.user);
        const order = await placeOrder({ deliveryType: 'home-delivery', addressId: address._id });
        for (const s of ['confirmed', 'ready']) {
            expect((await setStatus(order._id, s)).status).toBe(200);
        }
        expect((await setStatus(order._id, 'completed')).status).toBe(400);
        expect((await setStatus(order._id, 'out-for-delivery')).status).toBe(200);
        expect((await setStatus(order._id, 'delivered')).status).toBe(200);
        const saved = await Order.findById(order._id);
        expect(saved.outForDeliveryAt).toBeInstanceOf(Date);
        expect(saved.deliveredAt).toBeInstanceOf(Date);
    });

    it('merchant cancellation restores stock and refunds a wallet order', async () => {
        await Wallet.create({ user: shopper.user._id, balance: 500 });
        const order = await placeOrder({ paymentMethod: 'wallet' });
        const res = await setStatus(order._id, 'cancelled', farm.token, 'Rain damaged the crop');
        expect(res.status).toBe(200);
        expect(await stock()).toBe(10);
        expect((await Wallet.findOne({ user: shopper.user._id })).balance).toBe(500);
        const saved = await Order.findById(order._id);
        expect(saved.cancelledBy).toBe('merchant');
        expect(saved.cancellationReason).toBe('Rain damaged the crop');
    });

    it("a merchant can't update another merchant's order", async () => {
        const order = await placeOrder();
        const otherFarm = await f.merchant();
        expect((await setStatus(order._id, 'confirmed', otherFarm.token)).status).toBe(404);
    });
});

describe('Loyalty points (Issue 10)', () => {
    it('awards points once even when the order goes delivered → completed', async () => {
        const address = await f.address(shopper.user);
        const order = await placeOrder({ deliveryType: 'home-delivery', addressId: address._id }); // 200 + 50 delivery
        for (const s of ['confirmed', 'ready', 'out-for-delivery', 'delivered', 'completed']) {
            expect((await setStatus(order._id, s)).status).toBe(200);
        }
        const user = await User.findById(shopper.user._id);
        const saved = await Order.findById(order._id);
        // bronze: 1 point per ₹10, no bonus
        expect(saved.loyaltyPointsAwarded).toBe(Math.floor(saved.totalAmount / 10));
        expect(user.loyaltyPoints).toBe(saved.loyaltyPointsAwarded);
        expect(saved.paymentStatus).toBe('completed'); // COD collected on delivery
    });

    it('applies the configured tier bonus (gold: +20%)', async () => {
        await User.updateOne({ _id: shopper.user._id }, { loyaltyTier: 'gold', loyaltyPoints: 1000 });
        const order = await placeOrder(); // pickup, 200
        for (const s of ['confirmed', 'ready', 'completed']) await setStatus(order._id, s);
        const saved = await Order.findById(order._id);
        expect(saved.loyaltyPointsAwarded).toBe(24); // floor(20 * 1.2)
        expect((await User.findById(shopper.user._id)).loyaltyPoints).toBe(1024);
    });

    it('takes the points back when an admin fully refunds the order', async () => {
        const admin = await f.admin();
        await Wallet.create({ user: shopper.user._id, balance: 500 });
        const order = await placeOrder({ paymentMethod: 'wallet' }); // confirmed & paid
        for (const s of ['ready', 'completed']) await setStatus(order._id, s);
        expect((await User.findById(shopper.user._id)).loyaltyPoints).toBe(20);

        const res = await request(app).post('/api/payment/refund').set(f.auth(admin.token))
            .send({ orderId: order._id, reason: 'quality issue' });
        expect(res.status).toBe(200);
        expect(res.body.data.method).toBe('wallet');
        expect((await User.findById(shopper.user._id)).loyaltyPoints).toBe(0);
        expect((await Wallet.findOne({ user: shopper.user._id })).balance).toBe(500);
        expect((await Order.findById(order._id)).status).toBe('refunded');
    });
});

describe('Order access control', () => {
    it('only the customer, the merchant and admins can read an order', async () => {
        const order = await placeOrder();
        const stranger = await f.customer();
        const otherFarm = await f.merchant();
        const admin = await f.admin();
        const get = (t) => request(app).get(`/api/orders/${order.orderId}`).set(f.auth(t));

        expect((await get(shopper.token)).status).toBe(200);
        expect((await get(farm.token)).status).toBe(200);
        expect((await get(admin.token)).status).toBe(200);
        expect((await get(stranger.token)).status).toBe(404);
        expect((await get(otherFarm.token)).status).toBe(404);
        expect((await request(app).get(`/api/orders/${order.orderId}/tracking`).set(f.auth(stranger.token))).status).toBe(404);
        expect((await request(app).get(`/api/orders/${order.orderId}/tracking`).set(f.auth(admin.token))).status).toBe(200);
    });

    it('only the merchant can move the tracking location', async () => {
        const order = await placeOrder();
        const move = (t) => request(app).patch(`/api/orders/${order._id}/location`).set(f.auth(t)).send({ lat: 13, lng: 80 });
        expect((await move(shopper.token)).status).toBe(404);
        expect((await move(farm.token)).status).toBe(200);
    });
});

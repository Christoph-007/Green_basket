/**
 * Wallet API (mounted at /api/wallet) against a real in-memory MongoDB.
 * Razorpay calls are mocked; everything else (auth, routes, atomic wallet
 * updates) is real.
 */
jest.mock('../src/services/paymentService', () => ({
    createRazorpayOrder: jest.fn(),
    verifyRazorpaySignature: jest.fn(),
    getRazorpayOrder: jest.fn(),
    getRazorpayPayment: jest.fn(),
    processRazorpayRefund: jest.fn()
}));
jest.mock('../src/services/notification', () => ({
    send: jest.fn().mockResolvedValue({}), createNotification: jest.fn().mockResolvedValue({})
}));
jest.mock('../src/services/notify', () => ({
    email: jest.fn().mockResolvedValue({}), sms: jest.fn().mockResolvedValue({}),
    push: jest.fn().mockResolvedValue({}), all: jest.fn().mockResolvedValue({})
}));

const request = require('supertest');
const app = require('../server');
const paymentService = require('../src/services/paymentService');
const User = require('../src/models/User');
const Wallet = require('../src/models/Wallet');
const Order = require('../src/models/Order');
const Admin = require('../src/models/Admin');
const generateToken = require('../src/utils/generateToken');
const db = require('./helpers/db');

jest.setTimeout(60000);

let user, other, token, otherToken;

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(async () => {
    await db.clear();
    jest.clearAllMocks();
    user = await User.create({ name: 'Asha', email: 'asha@example.com', phone: '9000000001', password: 'secret123' });
    other = await User.create({ name: 'Bala', email: 'bala@example.com', phone: '9000000002', password: 'secret123' });
    token = generateToken(user._id, 'user');
    otherToken = generateToken(other._id, 'user');
    paymentService.verifyRazorpaySignature.mockReturnValue(true);
});

const auth = (t) => ({ Authorization: `Bearer ${t}` });

// A captured ₹amount top-up made by `owner`
const mockTopupPayment = ({ owner = user, amount = 500, orderId = 'order_topup_1', paymentId = 'pay_topup_1', type = 'wallet_topup' } = {}) => {
    paymentService.getRazorpayOrder.mockResolvedValue({
        id: orderId, amount: amount * 100, notes: { type, userId: owner._id.toString() }
    });
    paymentService.getRazorpayPayment.mockResolvedValue({
        id: paymentId, order_id: orderId, amount: amount * 100, status: 'captured'
    });
    return { razorpayOrderId: orderId, razorpayPaymentId: paymentId, razorpaySignature: 'sig' };
};

describe('GET /api/wallet', () => {
    it('is mounted and returns (creating if needed) the wallet', async () => {
        const res = await request(app).get('/api/wallet').set(auth(token));
        expect(res.status).toBe(200);
        expect(res.body.data).toEqual(expect.objectContaining({ balance: 0, isLocked: false }));
    });

    it('transactions endpoint returns data.transactions', async () => {
        const res = await request(app).get('/api/wallet/transactions').set(auth(token));
        expect(res.status).toBe(200);
        expect(Array.isArray(res.body.data.transactions)).toBe(true);
    });
});

describe('POST /api/wallet/add-money', () => {
    it('creates a Razorpay top-up order tagged with the user', async () => {
        paymentService.createRazorpayOrder.mockResolvedValue({ id: 'order_topup_1', amount: 50000 });
        const res = await request(app).post('/api/wallet/add-money').set(auth(token)).send({ amount: 500 });
        expect(res.status).toBe(200);
        expect(res.body.data).toEqual(expect.objectContaining({ orderId: 'order_topup_1', amount: 50000 }));
        expect(paymentService.createRazorpayOrder).toHaveBeenCalledWith(
            500, expect.stringMatching(/^topup_/), user._id.toString(),
            expect.objectContaining({ type: 'wallet_topup', userId: user._id.toString() })
        );
    });
});

describe('POST /api/wallet/verify-topup', () => {
    it('credits the amount Razorpay reports, ignoring any client amount', async () => {
        const body = mockTopupPayment({ amount: 500 });
        const res = await request(app).post('/api/wallet/verify-topup').set(auth(token))
            .send({ ...body, amount: 10000 }); // attacker-supplied amount is ignored

        expect(res.status).toBe(200);
        expect(res.body.data.newBalance).toBe(500);
        const wallet = await Wallet.findOne({ user: user._id });
        expect(wallet.balance).toBe(500);
        expect(wallet.transactions).toHaveLength(1);
        expect(wallet.transactions[0]).toEqual(expect.objectContaining({
            type: 'credit', source: 'topup', amount: 500, paymentId: 'pay_topup_1',
            balanceBefore: 0, balanceAfter: 500
        }));
    });

    it('never credits the same payment twice, even when submitted concurrently', async () => {
        const body = mockTopupPayment({ amount: 300 });
        const results = await Promise.all([1, 2, 3].map(() =>
            request(app).post('/api/wallet/verify-topup').set(auth(token)).send(body)
        ));
        results.forEach(r => expect(r.status).toBe(200));
        const wallet = await Wallet.findOne({ user: user._id });
        expect(wallet.balance).toBe(300);
        expect(wallet.transactions).toHaveLength(1);
    });

    it("rejects another user's top-up payment", async () => {
        const body = mockTopupPayment({ owner: other });
        const res = await request(app).post('/api/wallet/verify-topup').set(auth(token)).send(body);
        expect(res.status).toBe(400);
        expect(await Wallet.findOne({ user: user._id, balance: { $gt: 0 } })).toBeNull();
    });

    it('rejects a Razorpay payment that was made for a normal order, not a top-up', async () => {
        const body = mockTopupPayment({ type: 'order' }); // e.g. notes of a normal checkout order
        const res = await request(app).post('/api/wallet/verify-topup').set(auth(token)).send(body);
        expect(res.status).toBe(400);
    });

    it('rejects an invalid signature', async () => {
        paymentService.verifyRazorpaySignature.mockReturnValue(false);
        const res = await request(app).post('/api/wallet/verify-topup').set(auth(token)).send(mockTopupPayment());
        expect(res.status).toBe(400);
        expect(paymentService.getRazorpayPayment).not.toHaveBeenCalled();
    });

    it('rejects a payment that is not captured/authorized', async () => {
        const body = mockTopupPayment();
        paymentService.getRazorpayPayment.mockResolvedValue({ order_id: body.razorpayOrderId, amount: 50000, status: 'failed' });
        const res = await request(app).post('/api/wallet/verify-topup').set(auth(token)).send(body);
        expect(res.status).toBe(400);
    });
});

describe('POST /api/wallet/use-for-payment', () => {
    const makeOrder = (customer, overrides = {}) => Order.create({
        customer: customer._id, merchant: other._id, items: [], itemsTotal: 200, totalAmount: 200,
        paymentMethod: 'online', paymentStatus: 'pending', status: 'payment_pending', ...overrides
    });

    it('pays an unpaid order with the wallet for exactly the order total', async () => {
        await Wallet.create({ user: user._id, balance: 1000 });
        const order = await makeOrder(user);

        const res = await request(app).post('/api/wallet/use-for-payment').set(auth(token))
            .send({ orderId: order.orderId });

        expect(res.status).toBe(200);
        expect((await Wallet.findOne({ user: user._id })).balance).toBe(800);
        const paid = await Order.findById(order._id);
        expect(paid.paymentStatus).toBe('completed');
        expect(paid.paymentMethod).toBe('wallet');
        expect(paid.status).toBe('confirmed');
    });

    it("refuses to pay someone else's order", async () => {
        await Wallet.create({ user: user._id, balance: 1000 });
        const order = await makeOrder(other);
        const res = await request(app).post('/api/wallet/use-for-payment').set(auth(token)).send({ orderId: order.orderId });
        expect(res.status).toBe(404);
        expect((await Wallet.findOne({ user: user._id })).balance).toBe(1000);
    });

    it('refuses an already paid order and a mismatched amount', async () => {
        await Wallet.create({ user: user._id, balance: 1000 });
        const paidOrder = await makeOrder(user, { paymentStatus: 'completed' });
        const r1 = await request(app).post('/api/wallet/use-for-payment').set(auth(token)).send({ orderId: paidOrder.orderId });
        expect(r1.status).toBe(400);

        const order = await makeOrder(user);
        const r2 = await request(app).post('/api/wallet/use-for-payment').set(auth(token)).send({ orderId: order.orderId, amount: 1 });
        expect(r2.status).toBe(400);
        expect((await Wallet.findOne({ user: user._id })).balance).toBe(1000);
    });

    it('rejects when the balance is insufficient', async () => {
        await Wallet.create({ user: user._id, balance: 50 });
        const order = await makeOrder(user);
        const res = await request(app).post('/api/wallet/use-for-payment').set(auth(token)).send({ orderId: order.orderId });
        expect(res.status).toBe(400);
        expect(res.body.error).toBe('Insufficient wallet balance');
    });
});

describe('POST /api/payment/refund', () => {
    const paidOrder = () => Order.create({
        customer: user._id, merchant: other._id, items: [], itemsTotal: 200, totalAmount: 200,
        paymentMethod: 'online', paymentStatus: 'completed', status: 'delivered',
        razorpayPaymentId: 'pay_1', paymentGateway: { provider: 'razorpay' }
    });

    it('is admin-only: a customer cannot refund their own order', async () => {
        const order = await paidOrder();
        const res = await request(app).post('/api/payment/refund').set(auth(token))
            .send({ orderId: order.orderId, reason: 'want money back' });
        expect(res.status).toBe(403);
        expect(paymentService.processRazorpayRefund).not.toHaveBeenCalled();
    });

    it('lets an admin refund once, and refuses a second refund', async () => {
        const admin = await Admin.create({ name: 'Admin', email: 'admin@gb.com', password: 'secret123' });
        const adminToken = generateToken(admin._id, 'admin');
        paymentService.processRazorpayRefund.mockResolvedValue({ id: 'rfnd_1', status: 'processed' });
        const order = await paidOrder();

        const first = await request(app).post('/api/payment/refund').set(auth(adminToken))
            .send({ orderId: order._id.toString(), reason: 'damaged' });
        expect(first.status).toBe(200);
        const refunded = await Order.findById(order._id);
        expect(refunded.status).toBe('refunded');
        expect(refunded.paymentStatus).toBe('refunded');

        const second = await request(app).post('/api/payment/refund').set(auth(adminToken))
            .send({ orderId: order.orderId, reason: 'again' });
        expect(second.status).toBe(400);
        expect(paymentService.processRazorpayRefund).toHaveBeenCalledTimes(1);
    });
});

describe('Wallet credits are atomic', () => {
    it('concurrent refund credits and an order debit never overwrite each other', async () => {
        const { creditWallet, debitWalletForOrder } = require('../src/utils/walletHelpers');
        await Wallet.create({ user: user._id, balance: 100 });
        const mongoose = require('mongoose');
        await Promise.all([
            ...Array.from({ length: 10 }, (_, i) => creditWallet(user._id, 10, { source: 'refund', description: `r${i}` })),
            debitWalletForOrder(user._id, 50, new mongoose.Types.ObjectId(), 'GB1')
        ]);
        const wallet = await Wallet.findOne({ user: user._id });
        expect(wallet.balance).toBe(100 + 100 - 50);
        expect(wallet.transactions).toHaveLength(11);
    });
});

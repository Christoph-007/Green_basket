/**
 * Issue 7 + 16: Razorpay confirmation via /verify and the webhook (exactly
 * once), refunds for late payments, wallet top-ups via webhook, expiry of
 * unpaid orders, and the merchant 'order_paid' event. Real in-memory MongoDB.
 */
jest.mock('../src/services/paymentService', () => ({
    createRazorpayOrder: jest.fn(),
    verifyRazorpaySignature: jest.fn().mockReturnValue(true),
    getRazorpayOrder: jest.fn(),
    getRazorpayPayment: jest.fn(),
    getRazorpayOrderPayments: jest.fn(),
    processRazorpayRefund: jest.fn().mockResolvedValue({ id: 'rfnd_1' })
}));
jest.mock('../src/services/notify', () => ({
    email: jest.fn().mockResolvedValue({}), sms: jest.fn().mockResolvedValue({}),
    push: jest.fn().mockResolvedValue({}), all: jest.fn().mockResolvedValue({})
}));
jest.mock('../src/services/notification', () => ({
    send: jest.fn().mockResolvedValue({}), createNotification: jest.fn().mockResolvedValue({})
}));

const crypto = require('crypto');
const request = require('supertest');
const app = require('../server');
const paymentService = require('../src/services/paymentService');
const OrderSocket = require('../src/sockets/orderSocket');
const lifecycle = require('../src/services/orderLifecycle');
const Order = require('../src/models/Order');
const Product = require('../src/models/Product');
const Cart = require('../src/models/Cart');
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
    paymentService.verifyRazorpaySignature.mockReturnValue(true);
    jest.spyOn(OrderSocket, 'notifyOrderPaid');
    jest.spyOn(OrderSocket, 'notifyNewOrder');
    shopper = await f.customer();
    farm = await f.merchant();
    product = await f.product(farm.merchant, { stock: 10, price: 100 });
});
afterEach(() => jest.restoreAllMocks());

// An online order (₹200, pickup) with a Razorpay order attached
async function onlineOrder() {
    const res = await request(app).post('/api/orders').set(f.auth(shopper.token))
        .send({ items: [{ product: product._id, quantity: 2 }], paymentMethod: 'razorpay', deliveryType: 'pickup' });
    expect(res.status).toBe(201);
    await Order.updateOne({ _id: res.body.data.order._id }, { razorpayOrderId: 'order_rzp_1', 'paymentGateway.provider': 'razorpay' });
    return Order.findById(res.body.data.order._id);
}

const mockCaptured = (paymentId = 'pay_1', amount = 20000) =>
    paymentService.getRazorpayPayment.mockResolvedValue({ id: paymentId, order_id: 'order_rzp_1', amount, status: 'captured' });

const verify = (order, paymentId = 'pay_1') => request(app).post('/api/payment/verify').set(f.auth(shopper.token)).send({
    orderId: order.orderId, razorpayOrderId: 'order_rzp_1', razorpayPaymentId: paymentId, razorpaySignature: 'sig'
});

const webhook = (body, secret = process.env.RAZORPAY_WEBHOOK_SECRET) => {
    const raw = JSON.stringify(body);
    const sig = crypto.createHmac('sha256', secret).update(raw).digest('hex');
    return request(app).post('/api/payment/webhook')
        .set('Content-Type', 'application/json').set('X-Razorpay-Signature', sig).send(raw);
};

const capturedEvent = (paymentId = 'pay_1', amount = 20000, orderId = 'order_rzp_1') => ({
    event: 'payment.captured',
    payload: { payment: { entity: { id: paymentId, order_id: orderId, amount, status: 'captured' } } }
});

describe('creating an online order', () => {
    it('does not announce the unpaid draft to the merchant', async () => {
        await onlineOrder();
        expect(OrderSocket.notifyNewOrder).not.toHaveBeenCalled();
    });
});

describe('POST /api/payment/verify', () => {
    it('confirms once, clears the cart and tells the merchant it was paid', async () => {
        const order = await onlineOrder();
        await Cart.create({ user: shopper.user._id, items: [{ product: product._id, quantity: 1, price: 100 }] });
        mockCaptured();

        const first = await verify(order);
        expect(first.status).toBe(200);
        const saved = await Order.findById(order._id);
        expect(saved).toEqual(expect.objectContaining({ status: 'confirmed', paymentStatus: 'completed', razorpayPaymentId: 'pay_1' }));
        expect((await Cart.findOne({ user: shopper.user._id })).items).toHaveLength(0);
        expect(OrderSocket.notifyOrderPaid).toHaveBeenCalledTimes(1);
        expect(OrderSocket.notifyOrderPaid.mock.calls[0][0].toString()).toBe(farm.merchant._id.toString());

        const second = await verify(order); // retry / double tap
        expect(second.status).toBe(200);
        expect(OrderSocket.notifyOrderPaid).toHaveBeenCalledTimes(1);
    });

    it('refunds a payment that arrives after the order was cancelled', async () => {
        const order = await onlineOrder();
        await request(app).patch(`/api/orders/${order._id}/cancel`).set(f.auth(shopper.token)).send({});
        mockCaptured();

        const res = await verify(order);
        expect(res.status).toBe(409);
        expect(paymentService.processRazorpayRefund).toHaveBeenCalledWith('pay_1', 200, expect.any(String));
        expect((await Order.findById(order._id)).status).toBe('cancelled');
    });
});

describe('POST /api/payment/webhook', () => {
    it('rejects a bad signature', async () => {
        const res = await webhook(capturedEvent(), 'wrong_secret');
        expect(res.status).toBe(400);
    });

    it('confirms the order even if the app never called /verify, and only once on replay', async () => {
        const order = await onlineOrder();
        expect((await webhook(capturedEvent())).status).toBe(200);
        expect((await webhook(capturedEvent())).status).toBe(200); // Razorpay retries
        const saved = await Order.findById(order._id);
        expect(saved.status).toBe('confirmed');
        expect(saved.paymentEvents.filter(e => e.event === 'payment_captured')).toHaveLength(1);
        expect(OrderSocket.notifyOrderPaid).toHaveBeenCalledTimes(1);
    });

    it('confirms exactly once when /verify and the webhook race', async () => {
        const order = await onlineOrder();
        mockCaptured();
        await Promise.all([verify(order), webhook(capturedEvent()), verify(order), webhook(capturedEvent())]);
        const saved = await Order.findById(order._id);
        expect(saved.statusHistory.filter(h => h.status === 'confirmed')).toHaveLength(1);
        expect(OrderSocket.notifyOrderPaid).toHaveBeenCalledTimes(1);
    });

    it('ignores a payment whose amount does not match the order', async () => {
        const order = await onlineOrder();
        await webhook(capturedEvent('pay_1', 100));
        expect((await Order.findById(order._id)).paymentStatus).toBe('pending');
    });

    it('records failed payments', async () => {
        const order = await onlineOrder();
        await webhook({ event: 'payment.failed', payload: { payment: { entity: { id: 'pay_x', order_id: 'order_rzp_1', error_description: 'Card declined' } } } });
        const saved = await Order.findById(order._id);
        expect(saved.paymentEvents.find(e => e.event === 'payment_failed').data.reason).toBe('Card declined');
        expect(saved.status).toBe('payment_pending');
    });

    it('credits a wallet top-up once when the app missed /verify-topup', async () => {
        paymentService.getRazorpayOrder.mockResolvedValue({
            id: 'order_topup', amount: 50000, notes: { type: 'wallet_topup', userId: shopper.user._id.toString() }
        });
        const event = capturedEvent('pay_topup', 50000, 'order_topup');
        await webhook(event);
        await webhook(event);
        const wallet = await Wallet.findOne({ user: shopper.user._id });
        expect(wallet.balance).toBe(500);
        expect(wallet.transactions).toHaveLength(1);
    });
});

describe('expireUnpaidOrders', () => {
    const age = (order, minutes) => Order.collection.updateOne(
        { _id: order._id }, { $set: { createdAt: new Date(Date.now() - minutes * 60000) } });

    it('cancels stale unpaid orders and gives their stock back', async () => {
        const order = await onlineOrder();
        expect((await Product.findById(product._id)).stock).toBe(8);
        await age(order, 45);
        paymentService.getRazorpayOrderPayments.mockResolvedValue([]);

        const summary = await lifecycle.expireUnpaidOrders({ olderThanMinutes: 30 });
        expect(summary).toEqual(expect.objectContaining({ checked: 1, cancelled: 1 }));
        const saved = await Order.findById(order._id);
        expect(saved.status).toBe('cancelled');
        expect(saved.cancelledBy).toBe('system');
        expect((await Product.findById(product._id)).stock).toBe(10);
    });

    it('leaves recent orders alone', async () => {
        await onlineOrder();
        const summary = await lifecycle.expireUnpaidOrders({ olderThanMinutes: 30 });
        expect(summary.checked).toBe(0);
    });

    it('confirms instead of cancelling when Razorpay says it was paid', async () => {
        const order = await onlineOrder();
        await age(order, 45);
        paymentService.getRazorpayOrderPayments.mockResolvedValue([{ id: 'pay_late', status: 'captured', amount: 20000 }]);

        const summary = await lifecycle.expireUnpaidOrders({ olderThanMinutes: 30 });
        expect(summary.confirmed).toBe(1);
        expect((await Order.findById(order._id)).status).toBe('confirmed');
        expect((await Product.findById(product._id)).stock).toBe(8);
    });

    it("doesn't cancel when Razorpay can't be reached", async () => {
        const order = await onlineOrder();
        await age(order, 45);
        paymentService.getRazorpayOrderPayments.mockRejectedValue(new Error('timeout'));
        await lifecycle.expireUnpaidOrders({ olderThanMinutes: 30 });
        expect((await Order.findById(order._id)).status).toBe('payment_pending');
    });
});

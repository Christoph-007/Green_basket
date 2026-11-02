/**
 * Wallet payments in createOrder.
 *
 * The real walletHelpers code runs against a small in-memory fake of
 * Wallet.findOneAndUpdate that applies the filter ({ balance: { $gte } },
 * { isLocked: { $ne: true } }) and evaluates the update pipeline, so these
 * tests check real balances, not just that a function was called.
 */
jest.mock('../src/models/Order', () => ({ create: jest.fn() }));
jest.mock('../src/models/Product', () => ({
    findById: jest.fn(), findByIdAndUpdate: jest.fn(),
    findOneAndUpdate: jest.fn(), updateOne: jest.fn().mockResolvedValue({ modifiedCount: 1 })
}));
jest.mock('../src/models/Cart', () => ({ findOne: jest.fn(), findOneAndUpdate: jest.fn() }));
jest.mock('../src/models/Offer', () => ({ findOne: jest.fn(), findByIdAndUpdate: jest.fn() }));
jest.mock('../src/models/User', () => ({ findById: jest.fn(), findByIdAndUpdate: jest.fn() }));
jest.mock('../src/models/Merchant', () => ({ findById: jest.fn() }));
jest.mock('../src/models/Address', () => ({ findOne: jest.fn() }));
jest.mock('../src/models/LoyaltyLog', () => ({ create: jest.fn() }));
jest.mock('../src/models/Wallet', () => ({ findOneAndUpdate: jest.fn(), findOne: jest.fn() }));
jest.mock('../src/sockets/orderSocket', () => ({ notifyNewOrder: jest.fn() }));
jest.mock('../src/services/notificationService', () => ({
    createNotification: jest.fn().mockResolvedValue({}),
    send: jest.fn().mockResolvedValue({})
}));
jest.mock('../src/services/notify', () => ({
    sms: jest.fn().mockResolvedValue({}),
    all: jest.fn().mockResolvedValue({})
}));

const orderController = require('../src/controllers/orderController');
const Order = require('../src/models/Order');
const Product = require('../src/models/Product');
const Cart = require('../src/models/Cart');
const User = require('../src/models/User');
const Merchant = require('../src/models/Merchant');
const Address = require('../src/models/Address');
const Wallet = require('../src/models/Wallet');

// ─── A tiny fake wallet store that understands the operators we use ─────────
let wallets;

const evalExpr = (expr, doc) => {
    if (expr === '$balance') return doc.balance;
    if (expr === '$transactions') return doc.transactions;
    if (Array.isArray(expr)) return expr.map(e => evalExpr(e, doc));
    if (expr && typeof expr === 'object' && !(expr instanceof Date) && expr.constructor === Object) {
        if ('$literal' in expr) return expr.$literal;
        if ('$subtract' in expr) { const [a, b] = expr.$subtract.map(e => evalExpr(e, doc)); return a - b; }
        if ('$add' in expr) { const [a, b] = expr.$add.map(e => evalExpr(e, doc)); return a + b; }
        if ('$ifNull' in expr) { const [a, b] = expr.$ifNull.map(e => evalExpr(e, doc)); return a == null ? b : a; }
        if ('$concatArrays' in expr) return [].concat(...expr.$concatArrays.map(e => evalExpr(e, doc)));
        return Object.fromEntries(Object.entries(expr).map(([k, v]) => [k, evalExpr(v, doc)]));
    }
    return expr;
};

const matches = (doc, filter) => Object.entries(filter).every(([key, cond]) => {
    const value = doc[key];
    if (cond && typeof cond === 'object' && !Array.isArray(cond)) {
        if ('$gte' in cond && !(value >= cond.$gte)) return false;
        if ('$ne' in cond && value === cond.$ne) return false;
        return true;
    }
    return String(value) === String(cond);
});

const fakeFindOneAndUpdate = async (filter, pipeline) => {
    const doc = wallets.find(w => matches(w, filter));
    if (!doc) return null;
    // All expressions in one $set stage see the document BEFORE the stage
    const updates = evalExpr(pipeline[0].$set, { ...doc, transactions: [...doc.transactions] });
    Object.assign(doc, updates);
    return doc;
};

// ─── Request helpers ────────────────────────────────────────────────────────
const mockResponse = () => {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res;
};

const orderRequest = (paymentMethod) => ({
    user: { id: 'user_1', _id: 'user_1', name: 'Asha' },
    userType: 'user',
    body: {
        items: [{ product: '64b000000000000000000001', quantity: 2 }], // 2 × ₹100
        deliveryType: 'home-delivery',               // + ₹50 delivery = ₹250
        addressId: '64b0000000000000000000a1',
        paymentMethod
    }
});

const ORDER_TOTAL = 250;

describe('createOrder — wallet payment', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        wallets = [];

        Wallet.findOneAndUpdate.mockImplementation(fakeFindOneAndUpdate);
        Wallet.findOne.mockImplementation(async (filter) => wallets.find(w => matches(w, filter)) || null);

        Product.findById.mockImplementation(async () => ({
            _id: '64b000000000000000000001', name: 'Tomato', price: 100, stock: 10, unit: 'kg',
            merchant: 'merchant_1', totalSales: 0, save: jest.fn()
        }));
        Product.findByIdAndUpdate.mockResolvedValue({});
        Product.findOneAndUpdate.mockResolvedValue({ _id: '64b000000000000000000001' }); // stock reservation succeeds
        Cart.findOne.mockResolvedValue(null);           // no coupon
        Cart.findOneAndUpdate.mockResolvedValue({});
        User.findById.mockResolvedValue(null);
        // Approved, open store without delivery zones → default ₹50 delivery
        Merchant.findById.mockResolvedValue({ _id: 'merchant_id', verificationStatus: 'approved', isStoreOpen: true, deliveryZones: [] });
        Address.findOne.mockResolvedValue({ _id: '64b0000000000000000000a1', user: 'user_1' });
        Order.create.mockImplementation(async (data) => ({ ...data, _id: data._id || 'generated_id' }));
    });

    it('rejects the order when the wallet balance is insufficient', async () => {
        wallets.push({ user: 'user_1', balance: 100, isLocked: false, transactions: [] });
        const res = mockResponse();

        await orderController.createOrder(orderRequest('wallet'), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
            success: false,
            message: 'Insufficient wallet balance',
            available: 100,
            required: ORDER_TOTAL
        }));
        expect(Order.create).not.toHaveBeenCalled();
        expect(wallets[0].balance).toBe(100);
        expect(wallets[0].transactions).toHaveLength(0);
        // The stock reserved earlier in the request is given back
        expect(Product.findByIdAndUpdate).toHaveBeenCalledWith('64b000000000000000000001', {
            $inc: { stock: 2, totalSales: -2 }
        });
        expect(Cart.findOneAndUpdate).not.toHaveBeenCalled();
    });

    it('reduces the wallet balance by the order total and creates a paid, confirmed order', async () => {
        wallets.push({ user: 'user_1', balance: 1000, isLocked: false, transactions: [] });
        const res = mockResponse();

        await orderController.createOrder(orderRequest('wallet'), res);

        expect(res.status).toHaveBeenCalledWith(201);
        expect(wallets[0].balance).toBe(1000 - ORDER_TOTAL);

        const created = Order.create.mock.calls[0][0];
        expect(created).toEqual(expect.objectContaining({
            totalAmount: ORDER_TOTAL,
            paymentMethod: 'wallet',
            paymentStatus: 'completed',
            status: 'confirmed',
            confirmedAt: expect.any(Date)
        }));
        expect(created.statusHistory[0]).toEqual(expect.objectContaining({ status: 'confirmed' }));

        // One debit transaction, in the useForPayment format, linked to this order
        expect(wallets[0].transactions).toHaveLength(1);
        expect(wallets[0].transactions[0]).toEqual(expect.objectContaining({
            type: 'debit',
            amount: ORDER_TOTAL,
            source: 'payment',
            description: `Payment for order ${created.orderId}`,
            orderId: created._id,
            balanceBefore: 1000,
            balanceAfter: 1000 - ORDER_TOTAL,
            status: 'completed'
        }));
        expect(Cart.findOneAndUpdate).toHaveBeenCalled();
    });

    it('credits the wallet back if the order cannot be created after the debit', async () => {
        wallets.push({ user: 'user_1', balance: 1000, isLocked: false, transactions: [] });
        Order.create.mockRejectedValue(new Error('db write failed'));
        const res = mockResponse();

        await orderController.createOrder(orderRequest('wallet'), res);

        expect(res.status).toHaveBeenCalledWith(500);
        expect(wallets[0].balance).toBe(1000);
        expect(wallets[0].transactions.map(t => [t.type, t.source, t.amount])).toEqual([
            ['debit', 'payment', ORDER_TOTAL],
            ['credit', 'refund', ORDER_TOTAL]
        ]);
        expect(Product.findByIdAndUpdate).toHaveBeenCalledWith('64b000000000000000000001', {
            $inc: { stock: 2, totalSales: -2 }
        });
    });

    it('does not debit a locked wallet', async () => {
        wallets.push({ user: 'user_1', balance: 1000, isLocked: true, lockedReason: 'fraud check', transactions: [] });
        const res = mockResponse();

        await orderController.createOrder(orderRequest('wallet'), res);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ message: 'Wallet is locked' }));
        expect(wallets[0].balance).toBe(1000);
        expect(Order.create).not.toHaveBeenCalled();
    });

    it('leaves COD orders unchanged (no wallet access, pending/pending)', async () => {
        const res = mockResponse();

        await orderController.createOrder(orderRequest('cod'), res);

        expect(res.status).toHaveBeenCalledWith(201);
        expect(Wallet.findOneAndUpdate).not.toHaveBeenCalled();
        const created = Order.create.mock.calls[0][0];
        expect(created).toEqual(expect.objectContaining({
            paymentMethod: 'cod', paymentStatus: 'pending', status: 'pending'
        }));
        expect(created._id).toBeUndefined();
        expect(created.confirmedAt).toBeUndefined();
        expect(created.statusHistory[0].note).toBe('Order placed successfully');
    });
});

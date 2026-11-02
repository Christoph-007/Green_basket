const paymentController = require('../src/controllers/paymentController');
const Order = require('../src/models/Order');
const paymentService = require('../src/services/paymentService');

// Mock dependencies.
// paymentService is mocked with a factory so the real Razorpay client
// (src/config/razorpay.js, which throws without KEY_ID) is never loaded.
jest.mock('../src/models/Order');
jest.mock('../src/services/paymentService', () => ({
    createRazorpayOrder: jest.fn(),
    verifyRazorpaySignature: jest.fn(),
    getRazorpayPayment: jest.fn(),
    processRazorpayRefund: jest.fn()
}));
jest.mock('../src/models/User', () => ({ findById: jest.fn() }));
jest.mock('../src/models/Cart', () => ({ findOneAndUpdate: jest.fn() }));
jest.mock('../src/services/notification', () => ({}));
jest.mock('../src/services/notify', () => ({ all: jest.fn(), sms: jest.fn() }));

const mockResponse = () => {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res;
};

const mockRequest = (user, body) => ({
    user,
    body
});

describe('Unit Tests: Payment Controller', () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    describe('createPaymentOrder', () => {
        const ORIGINAL_KEY_ID = process.env.KEY_ID;
        beforeEach(() => { process.env.KEY_ID = 'rzp_test_key'; });
        afterAll(() => { process.env.KEY_ID = ORIGINAL_KEY_ID; });

        const makeOrder = (overrides = {}) => ({
            _id: 'order_id',
            orderId: 'GB123',
            totalAmount: 500,
            paymentStatus: 'pending',
            customer: { _id: 'user_id', name: 'Test User', email: 'test@example.com', phone: '9876543210' },
            paymentGateway: {},
            paymentEvents: [],
            save: jest.fn(),
            ...overrides
        });

        it('should create a Razorpay order and save its id on the order', async () => {
            const order = makeOrder();
            Order.findOne.mockReturnValue({ populate: jest.fn().mockResolvedValue(order) });
            paymentService.createRazorpayOrder.mockResolvedValue({
                id: 'order_rzp_123',
                amount: 50000,
                currency: 'INR',
                status: 'created'
            });

            const req = mockRequest(
                { _id: 'user_id', id: 'user_id' },
                { orderId: 'GB123', amount: 500, gateway: 'razorpay' }
            );
            const res = mockResponse();

            await paymentController.createPaymentOrder(req, res);

            expect(paymentService.createRazorpayOrder).toHaveBeenCalledWith(
                500,
                'GB123',
                'user_id',
                expect.objectContaining({ customerName: 'Test User', customerEmail: 'test@example.com' })
            );
            expect(order.razorpayOrderId).toBe('order_rzp_123');
            expect(order.paymentGateway.provider).toBe('razorpay');
            expect(order.paymentEvents).toEqual([
                expect.objectContaining({ event: 'order_created' })
            ]);
            expect(order.save).toHaveBeenCalled();
            expect(res.status).not.toHaveBeenCalled();
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: true,
                data: expect.objectContaining({
                    key: 'rzp_test_key',
                    orderId: 'order_rzp_123',
                    amount: 50000,
                    currency: 'INR',
                    provider: 'razorpay'
                })
            }));
        });

        it('should return 400 if amount mismatch', async () => {
            const order = makeOrder(); // totalAmount 500
            Order.findOne.mockReturnValue({ populate: jest.fn().mockResolvedValue(order) });

            const req = mockRequest(
                { _id: 'user_id', id: 'user_id' },
                { orderId: 'GB123', amount: 100, gateway: 'razorpay' } // client sends 100
            );
            const res = mockResponse();

            await paymentController.createPaymentOrder(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: false,
                error: expect.stringContaining('Amount mismatch')
            }));
            expect(paymentService.createRazorpayOrder).not.toHaveBeenCalled();
            expect(order.save).not.toHaveBeenCalled();
        });
    });

    describe('verifyPayment', () => {
        it('should reject an invalid Razorpay signature and leave the order unpaid', async () => {
            const order = {
                orderId: 'GB123',
                razorpayOrderId: 'order_rzp_123',
                paymentStatus: 'pending',
                status: 'payment_pending',
                totalAmount: 500,
                paymentGateway: {},
                paymentEvents: [],
                updateStatus: jest.fn(),
                save: jest.fn()
            };
            Order.findOne.mockResolvedValue(order);
            paymentService.verifyRazorpaySignature.mockReturnValue(false);

            const req = mockRequest(
                { _id: 'user_id' },
                {
                    orderId: 'GB123',
                    razorpayOrderId: 'order_rzp_123',
                    razorpayPaymentId: 'pay_123',
                    razorpaySignature: 'forged_signature'
                }
            );
            const res = mockResponse();

            await paymentController.verifyPayment(req, res);

            expect(paymentService.verifyRazorpaySignature).toHaveBeenCalledWith('order_rzp_123', 'pay_123', 'forged_signature');
            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: false,
                error: 'Invalid Razorpay signature'
            }));
            expect(order.paymentStatus).toBe('pending');
            expect(order.updateStatus).not.toHaveBeenCalled();
            expect(order.save).not.toHaveBeenCalled();
            expect(paymentService.getRazorpayPayment).not.toHaveBeenCalled();
        });
    });

    // Confirmation, cancelled-order refunds and webhook races are covered
    // against a real database in tests/paymentFlow.test.js
    describe('verifyPayment (Razorpay order binding)', () => {
        const ORIGINAL_ENV = { ...process.env };

        beforeEach(() => {
            process.env.KEY_ID = 'rzp_test_key';
            process.env.KEY_SECRET = 'test_secret';
            process.env.NODE_ENV = 'test';
        });

        afterAll(() => {
            process.env = ORIGINAL_ENV;
        });

        const makeOrder = (overrides = {}) => ({
            _id: 'order_mongo_id',
            orderId: 'GB_EXPENSIVE',
            customer: 'user_id',
            merchant: 'merchant_id',
            razorpayOrderId: 'order_rzp_expensive',
            totalAmount: 1000,
            paymentStatus: 'pending',
            status: 'payment_pending',
            paymentGateway: {},
            paymentEvents: [],
            updateStatus: jest.fn(function (status) { this.status = status; }),
            save: jest.fn(),
            ...overrides
        });

        const makeReq = (body) => ({
            user: { _id: 'user_id' },
            body,
            app: { get: jest.fn().mockReturnValue(null) }
        });

        it('rejects a valid payment made for a different Razorpay order', async () => {
            const order = makeOrder();
            Order.findOne.mockResolvedValue(order);
            // The signature is valid — it is a genuine payment, just for another (cheaper) order
            paymentService.verifyRazorpaySignature.mockReturnValue(true);

            const req = makeReq({
                orderId: 'GB_EXPENSIVE',
                razorpayOrderId: 'order_rzp_cheap',
                razorpayPaymentId: 'pay_cheap',
                razorpaySignature: 'valid_sig_for_cheap_order'
            });
            const res = mockResponse();

            await paymentController.verifyPayment(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: false,
                error: 'Payment does not belong to this order'
            }));
            expect(order.paymentStatus).toBe('pending');
            expect(order.status).toBe('payment_pending');
            expect(order.save).not.toHaveBeenCalled();
            expect(paymentService.getRazorpayPayment).not.toHaveBeenCalled();
        });

        it('rejects when the order has no razorpayOrderId yet', async () => {
            const order = makeOrder({ razorpayOrderId: undefined });
            Order.findOne.mockResolvedValue(order);
            paymentService.verifyRazorpaySignature.mockReturnValue(true);

            const res = mockResponse();
            await paymentController.verifyPayment(makeReq({
                orderId: 'GB_EXPENSIVE',
                razorpayOrderId: 'order_rzp_any',
                razorpayPaymentId: 'pay_any',
                razorpaySignature: 'sig'
            }), res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(order.save).not.toHaveBeenCalled();
        });

        it('rejects when Razorpay reports a different amount than the order total', async () => {
            const order = makeOrder();
            Order.findOne.mockResolvedValue(order);
            paymentService.verifyRazorpaySignature.mockReturnValue(true);
            paymentService.getRazorpayPayment.mockResolvedValue({
                order_id: 'order_rzp_expensive', amount: 100, status: 'captured'
            });

            const res = mockResponse();
            await paymentController.verifyPayment(makeReq({
                orderId: 'GB_EXPENSIVE',
                razorpayOrderId: 'order_rzp_expensive',
                razorpayPaymentId: 'pay_1',
                razorpaySignature: 'sig'
            }), res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(order.paymentStatus).toBe('pending');
            expect(order.save).not.toHaveBeenCalled();
        });

        it('rejects in production when the Razorpay payment cannot be fetched', async () => {
            process.env.NODE_ENV = 'production';
            const order = makeOrder();
            Order.findOne.mockResolvedValue(order);
            paymentService.verifyRazorpaySignature.mockReturnValue(true);
            paymentService.getRazorpayPayment.mockRejectedValue(new Error('network down'));

            const res = mockResponse();
            await paymentController.verifyPayment(makeReq({
                orderId: 'GB_EXPENSIVE',
                razorpayOrderId: 'order_rzp_expensive',
                razorpayPaymentId: 'pay_1',
                razorpaySignature: 'sig'
            }), res);

            expect(res.status).toHaveBeenCalledWith(502);
            expect(order.save).not.toHaveBeenCalled();
        });

    });
});

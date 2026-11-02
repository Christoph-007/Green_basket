const orderController = require('../src/controllers/orderController');
const Order = require('../src/models/Order');
const Product = require('../src/models/Product');
const Cart = require('../src/models/Cart');
const OrderSocket = require('../src/sockets/orderSocket');
const notificationService = require('../src/services/notificationService');

// Mock dependencies
jest.mock('../src/models/Order');
jest.mock('../src/models/Product');
jest.mock('../src/models/Cart');
jest.mock('../src/sockets/orderSocket');
jest.mock('../src/services/notificationService');
jest.mock('../src/models/User', () => ({ findById: jest.fn().mockResolvedValue(null) }));
// Order pricing loads the merchant (approved, open) and the delivery address
jest.mock('../src/models/Merchant', () => ({ findById: jest.fn().mockResolvedValue({ _id: 'merchant_id', verificationStatus: 'approved', isStoreOpen: true, deliveryZones: [] }) }));
jest.mock('../src/models/Address', () => ({ findOne: jest.fn().mockResolvedValue({ _id: '64b0000000000000000000a1', user: 'user_id' }) }));
jest.mock('../src/services/notify', () => ({ sms: jest.fn().mockResolvedValue({}), all: jest.fn().mockResolvedValue({}) }));

const mockResponse = () => {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res;
};

const mockRequest = (user, body) => ({
    user: { _id: user.id, ...user },
    userType: 'user',
    body
});

describe('Unit Tests: Order Controller', () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    describe('createOrder', () => {
        it('should calculate totals and create order successfully', async () => {
            const req = mockRequest(
                { id: 'user_id', name: 'Test User' },
                {
                    items: [
                        { product: '64b000000000000000000001', quantity: 2 },
                        { product: '64b000000000000000000002', quantity: 1 }
                    ],
                    deliveryAddress: '64b0000000000000000000a1',
                    deliveryType: 'home-delivery',
                    paymentMethod: 'cod'
                }
            );
            const res = mockResponse();

            // Mock Products
            Product.findById.mockImplementation((id) => {
                if (id === '64b000000000000000000001') return Promise.resolve({
                    _id: '64b000000000000000000001', name: 'Apple', price: 100, stock: 10, unit: 'kg', merchant: 'merchant_id', save: jest.fn()
                });
                if (id === '64b000000000000000000002') return Promise.resolve({
                    _id: '64b000000000000000000002', name: 'Banana', price: 50, stock: 10, unit: 'kg', merchant: 'merchant_id', save: jest.fn()
                });
                return Promise.resolve(null);
            });

            // Atomic stock reservation succeeds
            Product.findOneAndUpdate.mockResolvedValue({});
            Product.updateOne.mockResolvedValue({ modifiedCount: 1 });

            // Mock Order Create
            Order.create.mockResolvedValue({
                _id: 'order_id',
                orderId: 'GB123',
                totalAmount: 300, // (100*2 + 50*1) + 50 delivery
                items: [{}, {}]
            });

            await orderController.createOrder(req, res);

            // Assertions
            expect(Order.create).toHaveBeenCalledWith(expect.objectContaining({
                itemsTotal: 250, // 100*2 + 50*1
                deliveryCharges: 50,
                totalAmount: 300,
                merchant: 'merchant_id'
            }));

            // COD orders clear the cart immediately
            expect(Cart.findOneAndUpdate).toHaveBeenCalledWith(
                { user: 'user_id' },
                expect.objectContaining({ items: [], total: 0 })
            );

            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: true
            }));
        });

        it('should return error if insufficient stock', async () => {
            const req = mockRequest(
                { id: 'user_id' },
                { items: [{ product: '64b000000000000000000001', quantity: 20 }] }
            );
            const res = mockResponse();

            Product.findById.mockResolvedValue({
                _id: '64b000000000000000000001', name: 'Apple', price: 100, stock: 5 // Less than 20
            });

            await orderController.createOrder(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: false,
                message: expect.stringContaining('Insufficient stock')
            }));
        });

        it('should return error if product not found', async () => {
            const req = mockRequest(
                { id: 'user_id' },
                { items: [{ product: 'invalid_id', quantity: 1 }] }
            );
            const res = mockResponse();

            Product.findById.mockResolvedValue(null);

            await orderController.createOrder(req, res);

            expect(res.status).toHaveBeenCalledWith(404);
        });
    });

});

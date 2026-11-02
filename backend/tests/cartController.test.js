const cartController = require('../src/controllers/cartController');
const Cart = require('../src/models/Cart');
const Product = require('../src/models/Product');
const Recipe = require('../src/models/Recipe');
const recipeCalculator = require('../src/services/recipeCalculator');

// Mock dependencies
jest.mock('../src/models/Cart');
jest.mock('../src/models/Product');
jest.mock('../src/models/Recipe');
jest.mock('../src/services/recipeCalculator');

const mockResponse = () => {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res;
};

const mockRequest = (user, body, params) => ({
    user,
    body,
    params
});

describe('Unit Tests: Cart Controller', () => {

    beforeEach(() => {
        // getCartMerchantId looks up the cart's products (one store per cart)
        Product.find.mockReturnValue({ lean: jest.fn().mockResolvedValue([]) });
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    describe('addToCart', () => {
        it('should create new cart and add item', async () => {
            const req = mockRequest({ id: 'user_1' }, { productId: 'p1', quantity: 2 });
            const res = mockResponse();

            // addToCart calls Product.findById(id).populate('merchant', ...)
            Product.findById.mockReturnValue({
                populate: jest.fn().mockResolvedValue({ _id: 'p1', price: 10, stock: 100 })
            });

            Cart.findOne.mockResolvedValue(null);
            Cart.create.mockResolvedValue({
                items: [{ product: 'p1', quantity: 2, price: 10 }],
                calculateTotal: jest.fn(),
                save: jest.fn(),
                populate: jest.fn()
            });

            await cartController.addToCart(req, res);

            expect(Cart.create).toHaveBeenCalled();
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
        });

        it('should update existing cart item quantity', async () => {
            const req = mockRequest({ id: 'user_1' }, { productId: 'p1', quantity: 2 });
            const res = mockResponse();

            Product.findById.mockReturnValue({
                populate: jest.fn().mockResolvedValue({ _id: 'p1', price: 10, stock: 50 })
            });

            // Mock existing cart with item
            const mockCart = {
                items: [{ product: 'p1', quantity: 1, toString: () => 'p1' }], // toString needed?
                // The code calls item.product.toString()
                calculateTotal: jest.fn(),
                save: jest.fn(),
                populate: jest.fn()
            };
            // Ensure product in items is treated as ObjectId-like if strictly manipulated
            // Code: item.product.toString() === productId
            // So if item.product is just string 'p1', 'p1'.toString() is 'p1'.

            Cart.findOne.mockResolvedValue(mockCart);

            await cartController.addToCart(req, res);

            // Accessing the mock object directly to verify state change is tricky if we don't return it
            // But we modified `mockCart` in place.
            expect(mockCart.items[0].quantity).toBe(3); // 1 + 2
            expect(mockCart.calculateTotal).toHaveBeenCalled();
        });
    });

    describe('addRecipeToCart', () => {
        it('should scale ingredients and add to cart', async () => {
            const req = mockRequest({ id: 'u1' }, { recipeId: 'r1', servings: 4 });
            const res = mockResponse();

            Recipe.findById.mockReturnValue({
                populate: jest.fn().mockResolvedValue({
                    _id: 'r1',
                    servings: 2,
                    ingredients: [{ product: 'p1', quantity: 100, unit: 'g' }]
                })
            });

            recipeCalculator.scaleIngredients.mockReturnValue([
                { product: { _id: 'p1' }, scaledQuantity: 200 } // Scaled up (x2)
            ]);

            Product.findById.mockResolvedValue({ _id: 'p1', price: 5, stock: 1000 });

            const mockCart = {
                items: [],
                calculateTotal: jest.fn(),
                save: jest.fn(),
                populate: jest.fn()
            };
            Cart.findOne.mockResolvedValue(mockCart);

            await cartController.addRecipeToCart(req, res);

            expect(mockCart.items).toHaveLength(1);
            expect(mockCart.items[0].quantity).toBe(200);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ success: true }));
        });
    });
});

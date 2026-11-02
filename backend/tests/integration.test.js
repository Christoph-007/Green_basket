require('dotenv').config();
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const User = require('../src/models/User');
const Product = require('../src/models/Product');
const Cart = require('../src/models/Cart');
const Order = require('../src/models/Order');
const Merchant = require('../src/models/Merchant');
const Category = require('../src/models/Category');
const Recipe = require('../src/models/Recipe');
const Review = require('../src/models/Review');
const Address = require('../src/models/Address');

const { MongoMemoryServer } = require('mongodb-memory-server');

// Increase timeout to 60s
jest.setTimeout(60000);

let mongoServer;
let userToken;
let merchantToken;
let productId;
let recipeId;

beforeAll(async () => {
    console.log('Tests starting: Setting up In-Memory Database...');

    // Create new in-memory database
    mongoServer = await MongoMemoryServer.create();
    const uri = mongoServer.getUri();

    // Connect using the in-memory URI
    await mongoose.connect(uri);
    console.log('Connected to In-Memory Database successfully.');

    // Seed Data
    // 1. Merchant
    const merchant = await Merchant.create({
        name: 'Test Merchant',
        email: 'merchant@example.com',
        phone: '1234567890',
        password: 'password123',
        businessName: 'Green Farm',
        merchantType: 'organic-farmer',
        verificationStatus: 'approved',
        isStoreOpen: true,
        location: { type: 'Point', coordinates: [77.5946, 12.9716] },
        address: { street: '123 Farm Rd', city: 'City', state: 'State', pincode: '123456' }
    });

    // 2. User
    await User.create({
        name: 'Test User',
        email: 'user@example.com',
        phone: '9876543210',
        password: 'password123',
        isEmailVerified: true
    });

    // 3. Category
    const category = await Category.create({
        name: 'Vegetables',
        description: 'Fresh Vegetables',
        image: 'http://example.com/veg.jpg'
    });

    // 4. Product
    await Product.create({
        name: 'Organic Tomato',
        description: 'Fresh organic tomatoes',
        merchant: merchant._id,
        category: category._id,
        price: 40,
        stock: 100,
        unit: 'kg',
        images: [{ url: 'http://example.com/tomato.jpg', publicId: 'tomato_123' }],
        primaryImage: 'http://example.com/tomato.jpg'
    });

    // 5. Recipe
    await Recipe.create({
        name: 'Tomato Soup',
        description: 'Simple tomato soup',
        image: 'http://example.com/soup.jpg',
        servings: 4,
        prepTime: 10,
        cookTime: 20,
        difficulty: 'easy',
        ingredients: [{
            name: 'Tomato',
            quantity: 500,
            unit: 'g',
            isOptional: false
        }],
        instructions: [{ stepNumber: 1, instruction: 'Boil tomatoes' }]
    });

    console.log('Database seeded successfully.');
}, 60000);

afterAll(async () => {
    if (mongoose.connection.readyState !== 0) {
        await mongoose.connection.dropDatabase();
        await mongoose.connection.close();
    }
    if (mongoServer) {
        await mongoServer.stop();
    }
    console.log('Database connection closed.');
});

describe('Green Basket Backend Complete Feature Test', () => {

    describe('1. Authentication', () => {
        it('should login as a User', async () => {
            const res = await request(app)
                .post('/api/auth/user/login')
                .send({
                    email: 'user@example.com',
                    password: 'password123'
                });

            if (res.statusCode !== 200) console.log('User Login Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data).toHaveProperty('token');
            userToken = res.body.data.token;
        });

        it('should login as a Merchant', async () => {
            const res = await request(app)
                .post('/api/auth/merchant/login')
                .send({
                    email: 'merchant@example.com',
                    password: 'password123'
                });

            if (res.statusCode !== 200) console.log('Merchant Login Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data).toHaveProperty('token');
            merchantToken = res.body.data.token;
        });
    });

    describe('2. Product Management', () => {
        it('should get all products', async () => {
            const res = await request(app)
                .get('/api/products');

            if (res.statusCode !== 200) console.log('Get Products Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data.products).toBeDefined();
            expect(res.body.data.products.length).toBeGreaterThan(0);

            // Save a product ID for later tests
            productId = res.body.data.products[0]._id;
        });

        it('should get a single product by ID', async () => {
            const res = await request(app)
                .get(`/api/products/${productId}`);

            if (res.statusCode !== 200) console.log('Get One Product Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data.product).toBeDefined();
            expect(res.body.data.product._id).toEqual(productId);
        });

        it('should protect merchant routes', async () => {
            // Try to create product as user (should fail)
            const res = await request(app)
                .post('/api/products')
                .set('Authorization', `Bearer ${userToken}`)
                .send({ name: 'Fail' });

            // Should be 401 or 403
            expect([401, 403]).toContain(res.statusCode);
        });
    });

    describe('3. Shopping Cart', () => {
        it('should add item to cart', async () => {
            // First clear cart to be safe
            await Cart.deleteMany({ user: (await User.findOne({ email: 'user@example.com' }))._id });

            const res = await request(app)
                .post('/api/cart/add')
                .set('Authorization', `Bearer ${userToken}`)
                .send({
                    productId: productId,
                    quantity: 1
                });

            if (res.statusCode !== 200) console.log('Add Cart Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data.cart.items).toHaveLength(1);
            expect(res.body.data.cart.items[0].product._id).toEqual(productId);
        });

        it('should get user cart', async () => {
            const res = await request(app)
                .get('/api/cart')
                .set('Authorization', `Bearer ${userToken}`);

            if (res.statusCode !== 200) console.log('Get Cart Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data.cart).toBeDefined();
            expect(res.body.data.cart.items.length).toBeGreaterThan(0);
        });
    });

    describe('4. Recipes', () => {
        it('should get all recipes', async () => {
            const res = await request(app)
                .get('/api/recipes');

            if (res.statusCode !== 200) console.log('Get Recipes Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data.recipes).toBeDefined();
            expect(res.body.data.recipes.length).toBeGreaterThan(0);
            recipeId = res.body.data.recipes[0]._id;
        });

        it('should get ingredient calculation for a recipe', async () => {
            const res = await request(app)
                .post(`/api/recipes/${recipeId}/calculate-ingredients`)
                .send({ servings: 8 });

            if (res.statusCode !== 200) console.log('Calc Ingredients Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data.ingredients).toBeDefined();
        });
    });

    describe('5. Order Processing', () => {
        let addressId;

        it('should create an address', async () => {
            const res = await request(app)
                .post('/api/users/addresses')
                .set('Authorization', `Bearer ${userToken}`)
                .send({
                    addressLine1: '123 Test St',
                    city: 'Test City',
                    state: 'Test State',
                    pincode: '123456',
                    label: 'home'
                });

            if (res.statusCode !== 200 && res.statusCode !== 201) console.log('Create Address Error:', res.body);
            expect([200, 201]).toContain(res.statusCode);
            addressId = res.body.data._id;
        });

        it('should create an order', async () => {
            const res = await request(app)
                .post('/api/orders')
                .set('Authorization', `Bearer ${userToken}`)
                .send({
                    items: [{ product: productId, quantity: 1 }],
                    deliveryAddress: addressId,
                    paymentMethod: 'cod'
                });

            if (res.statusCode !== 200 && res.statusCode !== 201) console.log('Create Order Error:', res.body);
            expect([200, 201]).toContain(res.statusCode);
        });

        it('should get user orders', async () => {
            const res = await request(app)
                .get('/api/orders/my-orders')
                .set('Authorization', `Bearer ${userToken}`);

            if (res.statusCode !== 200) console.log('Get My Orders Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data.orders).toBeDefined();
        });

        it('should get merchant orders', async () => {
            const res = await request(app)
                .get('/api/orders/merchant/orders')
                .set('Authorization', `Bearer ${merchantToken}`);

            if (res.statusCode !== 200) console.log('Get Merchant Orders Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data.orders).toBeDefined();
        });
    });

});

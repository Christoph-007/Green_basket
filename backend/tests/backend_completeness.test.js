const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const { MongoMemoryServer } = require('mongodb-memory-server');
const User = require('../src/models/User');
const Product = require('../src/models/Product');
const Category = require('../src/models/Category');

// Mock external services to prevent side effects and errors
jest.mock('../src/services/sendgridContactService', () => ({
    addContactToSendGrid: jest.fn().mockResolvedValue(true)
}));
jest.mock('../src/services/email', () => jest.fn().mockResolvedValue(true));
jest.mock('../src/services/sms', () => jest.fn().mockResolvedValue(true));

let mongoServer;

beforeAll(async () => {
    // Only start if not already connected (or force reconnect)
    if (mongoose.connection.readyState !== 0) {
        await mongoose.disconnect();
    }
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri, { family: 4 });
});

afterAll(async () => {
    await mongoose.disconnect();
    if (mongoServer) await mongoServer.stop();
});

// Setup Test Data
const testUser = {
    name: 'Test Customer',
    email: 'customer@test.com',
    password: 'Password123!',
    phone: '1234567890'
};

const testProduct = {
    name: 'Organic Apples',
    description: 'Fresh organic apples',
    price: 150,
    stock: 50,
    unit: 'kg',
    images: [{ url: 'https://example.com/apple.jpg', publicId: 'apple_001' }],
    primaryImage: 'https://example.com/apple.jpg',
    category: '', // filled later
    merchant: '' // filled later
};

let userToken;
let userId;
let categoryId;
let productId;

describe('Backend Comprehensive Audit Tests', () => {

    // 1. Authentication Check
    describe('Authentication Module', () => {
        it('should register a new user', async () => {
            const res = await request(app)
                .post('/api/auth/user/signup')
                .send(testUser);

            expect(res.statusCode).toEqual(201);
            expect(res.body.success).toBe(true);
            expect(res.body.data).toHaveProperty('token');
            // Store for later use
            userToken = res.body.data.token;
            userId = res.body.data.user.id;
        });

        it('should login the user', async () => {
            const res = await request(app)
                .post('/api/auth/user/login')
                .send({
                    email: testUser.email,
                    password: testUser.password
                });

            expect(res.statusCode).toEqual(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data).toHaveProperty('token');
            userToken = res.body.data.token;
        });

        it('should fail login with wrong password', async () => {
            const res = await request(app)
                .post('/api/auth/user/login')
                .send({
                    email: testUser.email,
                    password: 'WrongPassword'
                });

            expect(res.statusCode).toEqual(401);
        });
    });

    // 2. Product and Category Management
    describe('Inventory Module', () => {
        it('should create a category', async () => {
            const cat = await Category.create({
                name: 'Fruits',
                description: 'Fresh Fruits',
                image: 'fruit.jpg',
                isActive: true
            });
            categoryId = cat._id.toString();
            expect(cat).toHaveProperty('_id');
        });

        it('should list categories via API', async () => {
            const res = await request(app).get('/api/categories');
            if (res.statusCode !== 200) console.log('Category Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data.length).toBeGreaterThan(0);
        });

        it('should create a product directly (seed)', async () => {
            // Seed a product directly into DB
            const prod = await Product.create({
                ...testProduct,
                category: categoryId,
                merchant: new mongoose.Types.ObjectId() // Random merchant ID
            });
            productId = prod._id.toString();
            expect(prod).toHaveProperty('_id');
        });

        it('should list products via API', async () => {
            const res = await request(app).get('/api/products');
            if (res.statusCode !== 200) console.log('Products Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.products.length).toBeGreaterThan(0);
        });

        it('should get a single product by ID', async () => {
            const res = await request(app).get(`/api/products/${productId}`);
            if (res.statusCode !== 200) console.log('Get Product Error:', res.body);
            expect(res.statusCode).toEqual(200);
            expect(res.body.data.product.name).toBe(testProduct.name);
        });
    });

    // 3. Cart Functionality
    describe('Cart Module', () => {
        it('should add item to cart', async () => {
            const res = await request(app)
                .post('/api/cart/add')
                .set('Authorization', `Bearer ${userToken}`)
                .send({
                    productId: productId,
                    quantity: 2
                });

            if (res.statusCode !== 200) {
                expect(res.body).toEqual({
                    success: true,
                    message: 'Product added to cart'
                });
            }
            expect(res.statusCode).toEqual(200);
            expect(res.body.success).toBe(true);
            // Verify cart structure (product may be populated object or plain ID)
            const cartItem = res.body.data.cart.items.find(item => {
                const id = item.product?._id || item.product;
                return id?.toString() === productId;
            });
            expect(cartItem).toBeTruthy();
            expect(cartItem.quantity).toBe(2);
        });

        it('should get user cart', async () => {
            const res = await request(app)
                .get('/api/cart')
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.statusCode).toEqual(200);
            expect(res.body.data.cart.items.length).toBeGreaterThan(0);
        });

        it('should update cart item quantity', async () => {
            const res = await request(app)
                .put(`/api/cart/update/${productId}`)
                .set('Authorization', `Bearer ${userToken}`)
                .send({ quantity: 5 });

            expect(res.statusCode).toEqual(200);
            const cartItem = res.body.data.cart.items.find(item => {
                const id = item.product?._id || item.product;
                return id?.toString() === productId;
            });
            expect(cartItem).toBeTruthy();
            expect(cartItem.quantity).toBe(5);
        });
    });

    // 4. User Profile
    describe('User Profile Module', () => {
        it('should get user profile', async () => {
            const res = await request(app)
                .get('/api/users/profile')
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.statusCode).toEqual(200);
            expect(res.body.data.email).toBe(testUser.email);
        });

        it('should update user profile', async () => {
            const res = await request(app)
                .put('/api/users/profile')
                .set('Authorization', `Bearer ${userToken}`)
                .send({ name: 'Updated Name' });

            expect(res.statusCode).toEqual(200);
            expect(res.body.data.name).toBe('Updated Name');
        });
    });

    // 5. Search
    describe('Search Module', () => {
        it('should search for products', async () => {
            // Uses ?q= param per the searchProducts controller
            const res = await request(app)
                .get('/api/products/search?q=Apple');

            // Text index may not be available in memory server, but route should respond 200
            expect(res.statusCode).toEqual(200);
        });
    });

});

/**
 * Issues 11–14 against a real in-memory MongoDB: one merchant per cart/order,
 * preparation price, coupon rules, delivery-zone charges, and the checkout
 * quote matching what the order charges.
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
const Offer = require('../src/models/Offer');
const Product = require('../src/models/Product');
const Recipe = require('../src/models/Recipe');
const User = require('../src/models/User');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

let shopper, farm;

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(async () => {
    await db.clear();
    shopper = await f.customer();
    farm = await f.merchant();
});

const api = (token = shopper.token) => ({
    add: (body) => request(app).post('/api/cart/add').set(f.auth(token)).send(body),
    cart: () => request(app).get('/api/cart').set(f.auth(token)),
    coupon: (code) => request(app).post('/api/cart/coupon').set(f.auth(token)).send({ code }),
    quote: (body) => request(app).post('/api/orders/quote').set(f.auth(token)).send(body),
    order: (body) => request(app).post('/api/orders').set(f.auth(token)).send({ paymentMethod: 'cod', deliveryType: 'pickup', ...body })
});

const coupon = (overrides = {}) => Offer.create({
    title: 'Deal', type: 'flat', discountAmount: 20, couponCode: 'SAVE20', status: 'active',
    createdBy: 'admin', startDate: new Date(Date.now() - 86400000), endDate: new Date(Date.now() + 86400000),
    ...overrides
});

describe('One merchant per cart and order (Issue 11)', () => {
    it("refuses to add another store's product to the cart", async () => {
        const otherFarm = await f.merchant();
        const a = await f.product(farm.merchant);
        const b = await f.product(otherFarm.merchant);
        expect((await api().add({ productId: a._id, quantity: 1 })).status).toBe(200);
        const res = await api().add({ productId: b._id, quantity: 1 });
        expect(res.status).toBe(409);
        expect(res.body.code).toBe('DIFFERENT_MERCHANT');
    });

    it('refuses an order mixing stores', async () => {
        const otherFarm = await f.merchant();
        const a = await f.product(farm.merchant);
        const b = await f.product(otherFarm.merchant);
        const res = await api().order({ items: [{ product: a._id, quantity: 1 }, { product: b._id, quantity: 1 }] });
        expect(res.status).toBe(400);
        expect(res.body.code).toBe('MULTIPLE_MERCHANTS');
        expect((await Product.findById(a._id)).stock).toBe(10);
    });

    it('recipe-to-cart picks one store and reports the rest', async () => {
        const otherFarm = await f.merchant();
        const onion = await f.product(farm.merchant, { name: 'Onion' });
        const tomato = await f.product(farm.merchant, { name: 'Tomato' });
        const chilli = await f.product(otherFarm.merchant, { name: 'Chilli' });
        const recipe = await Recipe.create({
            name: 'Salsa', description: 'x', servings: 2, prepTime: 5, cookTime: 0,
            ingredients: [
                { name: 'Onion', quantity: 1, unit: 'kg', product: onion._id },
                { name: 'Tomato', quantity: 1, unit: 'kg', product: tomato._id },
                { name: 'Chilli', quantity: 1, unit: 'kg', product: chilli._id }
            ]
        });
        const res = await request(app).post('/api/cart/recipe-to-cart').set(f.auth(shopper.token)).send({ recipeId: recipe._id });
        expect(res.status).toBe(200);
        expect(res.body.data.stats).toEqual(expect.objectContaining({ added: 2, skipped_other_store: 1 }));
    });
});

describe('Preparation price (Issue 12)', () => {
    it('charges the preparation surcharge in the cart, the quote and the order', async () => {
        const p = await f.product(farm.merchant, { price: 100, preparationOptions: [{ type: 'chopped', additionalPrice: 20 }] });
        await api().add({ productId: p._id, quantity: 2, preparation: 'chopped' });
        expect((await api().cart()).body.data.cart.total).toBe(240);

        const quote = await api().quote({ deliveryType: 'pickup' });
        expect(quote.body.data.itemsTotal).toBe(240);

        const order = await api().order({});
        expect(order.status).toBe(201);
        expect(order.body.data.order.itemsTotal).toBe(240);
        expect(order.body.data.order.items[0]).toEqual(expect.objectContaining({ price: 120, preparation: 'chopped' }));
    });

    it('re-prices the cart when the merchant changes the price', async () => {
        const p = await f.product(farm.merchant, { price: 100 });
        await api().add({ productId: p._id, quantity: 1 });
        await Product.updateOne({ _id: p._id }, { price: 130 });
        expect((await api().cart()).body.data.cart.total).toBe(130);
    });
});

describe('Coupons (Issue 13)', () => {
    it('applies a cart coupon to the order (it never applied before)', async () => {
        const p = await f.product(farm.merchant, { price: 100 });
        await coupon();
        await api().add({ productId: p._id, quantity: 2 });
        expect((await api().coupon('SAVE20')).status).toBe(200);
        const order = await api().order({});
        expect(order.body.data.order.discount).toBe(20);
        expect(order.body.data.order.totalAmount).toBe(180);
    });

    it('enforces the per-user limit even when the code is sent with the order', async () => {
        const p = await f.product(farm.merchant, { price: 100 });
        await coupon({ usagePerUser: 1 });
        expect((await api().order({ items: [{ product: p._id, quantity: 1 }], couponCode: 'SAVE20' })).status).toBe(201);
        const again = await api().order({ items: [{ product: p._id, quantity: 1 }], couponCode: 'SAVE20' });
        expect(again.status).toBe(400);
        expect(again.body.code).toBe('COUPON_INVALID');
    });

    it('never exceeds the total usage limit under concurrency', async () => {
        const p = await f.product(farm.merchant, { price: 100, stock: 50 });
        const offer = await coupon({ totalUsageLimit: 1, usagePerUser: 5 });
        const shoppers = await Promise.all([1, 2, 3, 4].map(() => f.customer()));
        const results = await Promise.all(shoppers.map(s =>
            api(s.token).order({ items: [{ product: p._id, quantity: 1 }], couponCode: 'SAVE20' })));
        expect(results.filter(r => r.status === 201)).toHaveLength(1);
        expect((await Offer.findById(offer._id)).usedCount).toBe(1);
        expect((await Product.findById(p._id)).stock).toBe(49); // failed orders released their stock
    });

    it("rejects another merchant's coupon and expired coupons", async () => {
        const otherFarm = await f.merchant();
        const p = await f.product(farm.merchant, { price: 100 });
        await coupon({ couponCode: 'THEIRS', createdBy: 'merchant', merchant: otherFarm.merchant._id });
        await coupon({ couponCode: 'OLD', endDate: new Date(Date.now() - 1000) });
        for (const code of ['THEIRS', 'OLD']) {
            const res = await api().order({ items: [{ product: p._id, quantity: 1 }], couponCode: code });
            expect(res.status).toBe(400);
        }
    });

    it('loyalty coupons are personal, and redeeming twice at once spends points once', async () => {
        await User.updateOne({ _id: shopper.user._id }, { loyaltyPoints: 100 });
        const redeem = () => request(app).post('/api/loyalty/redeem').set(f.auth(shopper.token)).send({ points: 60 });
        const results = await Promise.all([redeem(), redeem()]);
        expect(results.filter(r => r.status === 200)).toHaveLength(1);
        expect((await User.findById(shopper.user._id)).loyaltyPoints).toBe(40);

        const code = results.find(r => r.status === 200).body.data.couponCode;
        const p = await f.product(farm.merchant, { price: 100 });
        const stranger = await f.customer();
        const stolen = await api(stranger.token).order({ items: [{ product: p._id, quantity: 1 }], couponCode: code });
        expect(stolen.status).toBe(400);
        const mine = await api().order({ items: [{ product: p._id, quantity: 1 }], couponCode: code });
        expect(mine.body.data.order.discount).toBe(60);
    });
});

describe('Delivery charges (Issue 14)', () => {
    // farm is at [80.27, 13.08]; 0.1° of latitude ≈ 11 km
    const zones = [
        { name: 'Near', radiusKm: 5, deliveryCharge: 20, freeDeliveryAbove: 1000 },
        { name: 'City', radiusKm: 15, deliveryCharge: 60 }
    ];

    it('charges the smallest zone that covers the address, and quote = order', async () => {
        const zoned = await f.merchant({ deliveryZones: zones });
        const p = await f.product(zoned.merchant, { price: 100 });
        const near = await f.address(shopper.user, { location: { type: 'Point', coordinates: [80.27, 13.10] } });  // ~2 km
        const far = await f.address(shopper.user, { location: { type: 'Point', coordinates: [80.27, 13.18] } });   // ~11 km
        const items = [{ product: p._id, quantity: 2 }];

        const q1 = await api().quote({ items, deliveryType: 'home-delivery', addressId: near._id });
        expect(q1.body.data).toEqual(expect.objectContaining({ deliveryCharges: 20, totalAmount: 220 }));
        const q2 = await api().quote({ items, deliveryType: 'home-delivery', addressId: far._id });
        expect(q2.body.data.deliveryCharges).toBe(60);

        const order = await api().order({ items, deliveryType: 'home-delivery', addressId: far._id });
        expect(order.body.data.order).toEqual(expect.objectContaining({ deliveryCharges: 60, totalAmount: 260 }));
    });

    it('refuses addresses outside every zone', async () => {
        const zoned = await f.merchant({ deliveryZones: zones });
        const p = await f.product(zoned.merchant);
        const away = await f.address(shopper.user, { location: { type: 'Point', coordinates: [80.27, 14.0] } }); // ~100 km
        const res = await api().order({ items: [{ product: p._id, quantity: 1 }], deliveryType: 'home-delivery', addressId: away._id });
        expect(res.status).toBe(400);
        expect(res.body.code).toBe('OUT_OF_DELIVERY_AREA');
        expect((await Product.findById(p._id)).stock).toBe(10);
    });

    it('is free above the zone threshold, and for platinum customers', async () => {
        const zoned = await f.merchant({ deliveryZones: zones });
        const p = await f.product(zoned.merchant, { price: 600 });
        const near = await f.address(shopper.user, { location: { type: 'Point', coordinates: [80.27, 13.10] } });
        const q = await api().quote({ items: [{ product: p._id, quantity: 2 }], deliveryType: 'home-delivery', addressId: near._id });
        expect(q.body.data.deliveryCharges).toBe(0);

        await User.updateOne({ _id: shopper.user._id }, { loyaltyTier: 'platinum' });
        const q2 = await api().quote({ items: [{ product: p._id, quantity: 1 }], deliveryType: 'home-delivery', addressId: near._id });
        expect(q2.body.data.deliveryCharges).toBe(0);
    });

    it("rejects someone else's address and missing addresses", async () => {
        const p = await f.product(farm.merchant);
        const stranger = await f.customer();
        const theirs = await f.address(stranger.user);
        const r1 = await api().order({ items: [{ product: p._id, quantity: 1 }], deliveryType: 'home-delivery', addressId: theirs._id });
        expect(r1.status).toBe(400);
        const r2 = await api().order({ items: [{ product: p._id, quantity: 1 }], deliveryType: 'home-delivery' });
        expect(r2.body.code).toBe('ADDRESS_REQUIRED');
    });

    it('uses the merchant flat charge without zones, ₹50 by default, ₹0 for pickup', async () => {
        const p = await f.product(farm.merchant, { price: 100 });
        const addr = await f.address(shopper.user);
        const items = [{ product: p._id, quantity: 1 }];
        expect((await api().quote({ items, deliveryType: 'home-delivery', addressId: addr._id })).body.data.deliveryCharges).toBe(50);
        expect((await api().quote({ items, deliveryType: 'pickup' })).body.data.deliveryCharges).toBe(0);

        const flat = await f.merchant({ deliveryCharges: 35 });
        const p2 = await f.product(flat.merchant);
        expect((await api().quote({ items: [{ product: p2._id, quantity: 1 }], deliveryType: 'home-delivery', addressId: addr._id })).body.data.deliveryCharges).toBe(35);
    });

    it('a free-delivery coupon offsets the delivery charge', async () => {
        const p = await f.product(farm.merchant, { price: 100 });
        const addr = await f.address(shopper.user);
        await coupon({ couponCode: 'FREESHIP', type: 'free_delivery', discountAmount: undefined });
        const q = await api().quote({ items: [{ product: p._id, quantity: 1 }], deliveryType: 'home-delivery', addressId: addr._id, couponCode: 'FREESHIP' });
        expect(q.body.data).toEqual(expect.objectContaining({ deliveryCharges: 50, discount: 50, totalAmount: 100 }));
    });
});

/**
 * Cart quantity validation, preparation-aware updates, and recipe unit
 * conversion (recipe "200 g" must not become 200 kg in the cart).
 */
jest.mock('../src/services/notify', () => ({
    email: jest.fn().mockResolvedValue({}), sms: jest.fn().mockResolvedValue({}),
    push: jest.fn().mockResolvedValue({}), all: jest.fn().mockResolvedValue({})
}));

const request = require('supertest');
const app = require('../server');
const Cart = require('../src/models/Cart');
const Recipe = require('../src/models/Recipe');
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

const add = (body) => request(app).post('/api/cart/add').set(f.auth(shopper.token)).send(body);

it('rejects zero, negative and non-numeric quantities', async () => {
    const p = await f.product(farm.merchant);
    for (const q of [0, -3, 'abc', 5000]) {
        const res = await add({ productId: p._id, quantity: q });
        expect(res.status).toBe(400);
    }
    expect(await Cart.countDocuments({ 'items.0': { $exists: true } })).toBe(0);
});

it('adds numeric strings as numbers (no "1" + "2" = "12")', async () => {
    const p = await f.product(farm.merchant, { stock: 50 });
    await add({ productId: p._id, quantity: '1' });
    await add({ productId: p._id, quantity: '2' });
    const cart = await Cart.findOne({ user: shopper.user._id });
    expect(cart.items[0].quantity).toBe(3);
});

it('updates the right line by preparation and refuses more than the stock', async () => {
    const p = await f.product(farm.merchant, {
        stock: 5,
        preparationOptions: [{ type: 'chopped', additionalPrice: 10 }]
    });
    await add({ productId: p._id, quantity: 1, preparation: 'chopped' });

    const ok = await request(app).put(`/api/cart/update/${p._id}`).set(f.auth(shopper.token))
        .send({ quantity: 3, preparation: 'chopped' });
    expect(ok.status).toBe(200);
    const cart = await Cart.findOne({ user: shopper.user._id });
    expect(cart.items[0]).toEqual(expect.objectContaining({ quantity: 3, preparation: 'chopped' }));

    const tooMany = await request(app).put(`/api/cart/update/${p._id}`).set(f.auth(shopper.token))
        .send({ quantity: 6, preparation: 'chopped' });
    expect(tooMany.status).toBe(400);

    const removed = await request(app).delete(`/api/cart/remove/${p._id}?preparation=chopped`).set(f.auth(shopper.token));
    expect(removed.status).toBe(200);
    expect((await Cart.findOne({ user: shopper.user._id })).items).toHaveLength(0);
});

it('converts recipe amounts into whole product units', async () => {
    const onion = await f.product(farm.merchant, { name: 'Onion', unit: 'kg', stock: 20 });
    const egg = await f.product(farm.merchant, { name: 'Egg', unit: 'dozen', stock: 20 });
    const recipe = await Recipe.create({
        name: 'Omelette', description: 'Quick', servings: 2, prepTime: 5, cookTime: 5,
        ingredients: [
            { name: 'Onion', quantity: 200, unit: 'g', product: onion._id },
            { name: 'Egg', quantity: 4, unit: 'piece', product: egg._id }
        ]
    });

    const res = await request(app).post('/api/cart/recipe-to-cart').set(f.auth(shopper.token))
        .send({ recipeId: recipe._id, servings: 2 });
    expect(res.status).toBe(200);

    const cart = await Cart.findOne({ user: shopper.user._id });
    const qty = (p) => cart.items.find(i => i.product.toString() === p._id.toString()).quantity;
    expect(qty(onion)).toBe(1); // 200 g → one 1-kg unit, not 200 kg
    expect(qty(egg)).toBe(1);   // 4 pieces → one dozen
});

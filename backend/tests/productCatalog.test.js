/**
 * Category filtering and search, as used by the app's Categories and Search
 * screens. Real in-memory MongoDB.
 */
const request = require('supertest');
const app = require('../server');
const Category = require('../src/models/Category');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

let near, dairy, fruits, milk, mango;

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(async () => {
    await db.clear();
    near = await f.merchant(); // at [80.27, 13.08]
    dairy = await Category.create({ name: 'Dairy & Eggs', slug: 'dairy-eggs' });
    fruits = await Category.create({ name: 'Fruits (Fresh)', slug: 'fruits-fresh' });
    milk = await f.product(near.merchant, { name: 'Milk', category: dairy._id });
    mango = await f.product(near.merchant, { name: 'Mango', category: fruits._id });
});

const names = (res) => res.body.data.products.map(p => p.name).sort();
const nearby = (q) => request(app).get('/api/products/nearby').query({ lat: 13.09, lng: 80.27, radius: 10, ...q });

describe('GET /api/products?category=', () => {
    it('filters by category id and by exact name (incl. special characters)', async () => {
        expect(names(await request(app).get('/api/products').query({ category: dairy._id.toString() }))).toEqual(['Milk']);
        expect(names(await request(app).get('/api/products').query({ category: 'dairy & eggs' }))).toEqual(['Milk']);
        expect(names(await request(app).get('/api/products').query({ category: 'Fruits (Fresh)' }))).toEqual(['Mango']);
        expect(names(await request(app).get('/api/products').query({ category: 'Nope' }))).toEqual([]);
        expect(names(await request(app).get('/api/products'))).toEqual(['Mango', 'Milk']);
    });
});

describe('GET /api/products/nearby?category=', () => {
    it('returns only the selected category nearby', async () => {
        expect(names(await nearby({ category: dairy._id.toString() }))).toEqual(['Milk']);
        expect(names(await nearby({ category: fruits._id.toString() }))).toEqual(['Mango']);
        expect(names(await nearby({}))).toEqual(['Mango', 'Milk']);
    });

    it('honours a category given by name (it used to return every category)', async () => {
        expect(names(await nearby({ category: 'Dairy & Eggs' }))).toEqual(['Milk']);
        expect(names(await nearby({ category: 'Unknown' }))).toEqual([]);
    });

    it('"show all" mode also filters by category', async () => {
        const res = await request(app).get('/api/products/nearby').query({ all: 'true', category: fruits._id.toString() });
        expect(names(res)).toEqual(['Mango']);
        const byName = await request(app).get('/api/products/nearby').query({ all: 'true', category: 'Dairy & Eggs' });
        expect(names(byName)).toEqual(['Milk']);
    });

    it('excludes merchants outside the radius', async () => {
        const res = await request(app).get('/api/products/nearby').query({ lat: 20, lng: 80.27, radius: 10 });
        expect(res.body.data.products).toHaveLength(0);
    });
});

describe('search input with regex characters', () => {
    it('does not crash product listing, nearby or search', async () => {
        for (const term of ['(', 'milk)', '[a', '*']) {
            expect((await request(app).get('/api/products').query({ search: term })).status).toBe(200);
            expect((await nearby({ search: term })).status).toBe(200);
            expect((await request(app).get('/api/search/products').query({ q: term })).status).toBe(200);
            expect((await request(app).get('/api/search/suggestions').query({ q: term + 'xx' })).status).toBe(200);
        }
        const res = await request(app).get('/api/products').query({ search: 'Milk' });
        expect(names(res)).toEqual(['Milk']);
    });
});

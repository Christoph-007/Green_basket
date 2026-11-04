/**
 * The two search endpoints the app's search screen calls (real in-memory MongoDB):
 *   GET /api/search/suggestions?q=  -> data.suggestions[{ type, text, id }]
 *   GET /api/search/trending        -> data.trendingProducts[{ product: { name, ... } }]
 * The Flutter parser (ProductRepository.getSearchSuggestions / getTrendingSearches)
 * reads exactly these fields.
 */
const request = require('supertest');
const app = require('../server');
const Category = require('../src/models/Category');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(db.clear);

describe('GET /api/search/suggestions', () => {
    it('returns product and category suggestions as { type, text, id }', async () => {
        const { merchant } = await f.merchant();
        await f.product(merchant, { name: 'Tomato Cherry' });
        await f.product(merchant, { name: 'Onion Red' });
        await Category.create({ name: 'Tomatoes', slug: 'tomatoes' });

        const res = await request(app).get('/api/search/suggestions').query({ q: 'tom' });
        expect(res.status).toBe(200);
        const list = res.body.data.suggestions;
        expect(list.map(s => s.text).sort()).toEqual(['Tomato Cherry', 'Tomatoes']);
        expect(list.find(s => s.text === 'Tomato Cherry').type).toBe('product');
        expect(list.find(s => s.text === 'Tomatoes').type).toBe('category');
        expect(list.every(s => s.id)).toBe(true);
    });

    it('returns an empty list for fewer than two characters', async () => {
        const res = await request(app).get('/api/search/suggestions').query({ q: 't' });
        expect(res.status).toBe(200);
        expect(res.body.data.suggestions).toEqual([]);
    });

    it('treats the text literally (no regular-expression injection)', async () => {
        const { merchant } = await f.merchant();
        await f.product(merchant, { name: 'Plain' });
        const res = await request(app).get('/api/search/suggestions').query({ q: '.*' });
        expect(res.status).toBe(200);
        expect(res.body.data.suggestions).toEqual([]);
    });
});

describe('GET /api/search/trending', () => {
    it('falls back to popular products when nothing was sold yet', async () => {
        const { merchant } = await f.merchant();
        await f.product(merchant, { name: 'Mango' });
        const res = await request(app).get('/api/search/trending');
        expect(res.status).toBe(200);
        const list = res.body.data.trendingProducts;
        expect(list).toHaveLength(1);
        expect(list[0].product.name).toBe('Mango');
    });

    it('returns an empty list on an empty database', async () => {
        const res = await request(app).get('/api/search/trending');
        expect(res.status).toBe(200);
        expect(res.body.data.trendingProducts).toEqual([]);
    });
});

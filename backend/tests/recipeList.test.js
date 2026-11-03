/**
 * Recipes as the Flutter app uses them:
 *   Recipes screen chips -> GET /api/recipes?mealType=breakfast|lunch|dinner|snack|dessert (omitted for "All")
 *   with the user's location -> lat, lng, radius -> distance / isNearby on each recipe
 *   admin screen          -> POST/PUT /api/recipes with { category: 'snacks' | 'breakfast' | ... }
 * Real in-memory MongoDB.
 */
const request = require('supertest');
const app = require('../server');
const Recipe = require('../src/models/Recipe');
const Merchant = require('../src/models/Merchant');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(db.clear);

const base = { description: 'Tasty', servings: 2, prepTime: 5, cookTime: 10 };
const make = (name, extra = {}) => Recipe.create({ name, ...base, ...extra });
const names = (res) => res.body.data.recipes.map(r => r.name).sort();
const list = (query = '') => request(app).get(`/api/recipes${query}`);

describe('meal filter (what the app chips send)', () => {
    beforeEach(async () => {
        await make('Idli', { category: 'breakfast' });
        await make('Sambar rice', { category: 'lunch' });
        await make('Chapati', { category: 'dinner' });
        await make('Banana chips', { category: 'snacks' });
        await make('Vada', { category: 'snack' });
        await make('Payasam', { category: 'dessert' });
    });

    it('returns everything when no filter, or "all", is sent', async () => {
        expect(names(await list())).toHaveLength(6);
        expect(names(await list('?mealType=all'))).toHaveLength(6);
    });

    it.each([
        ['breakfast', ['Idli']],
        ['lunch', ['Sambar rice']],
        ['dinner', ['Chapati']],
        ['dessert', ['Payasam']]
    ])('mealType=%s returns only that meal', async (meal, expected) => {
        expect(names(await list(`?mealType=${meal}`))).toEqual(expected);
    });

    it('treats "snack" and "snacks" as the same meal (the chip says Snack, the admin form saves snacks)', async () => {
        expect(names(await list('?mealType=snack'))).toEqual(['Banana chips', 'Vada']);
        expect(names(await list('?mealType=snacks'))).toEqual(['Banana chips', 'Vada']);
    });

    it('is case-insensitive and still honours the older category parameter', async () => {
        expect(names(await list('?mealType=Breakfast'))).toEqual(['Idli']);
        expect(names(await list('?category=lunch'))).toEqual(['Sambar rice']);
    });

    it('combines the meal filter with a text search', async () => {
        await Recipe.init();
        const res = await list('?mealType=snack&search=banana');
        expect(res.status).toBe(200);
        expect(names(res)).toEqual(['Banana chips']);
    });
});

describe('category and mealType stay in step', () => {
    it('saving a recipe fills in the missing one', async () => {
        const a = await make('A', { category: 'snacks' });
        const b = await make('B', { mealType: 'dinner' });
        expect(a.mealType).toBe('snacks');
        expect(b.category).toBe('dinner');
    });

    it('editing a recipe through the admin API moves it to the new meal only', async () => {
        const { token } = await f.admin();
        const created = await request(app).post('/api/recipes').set(f.auth(token))
            .send({ ...base, name: 'Upma', category: 'breakfast',
                ingredients: [{ name: 'rava', quantity: 1, unit: 'cup' }] });
        expect(created.status).toBe(201);
        const id = created.body.data.recipe._id;

        const updated = await request(app).put(`/api/recipes/${id}`).set(f.auth(token)).send({ category: 'dinner' });
        expect(updated.status).toBe(200);

        expect(names(await list('?mealType=dinner'))).toEqual(['Upma']);
        expect(names(await list('?mealType=breakfast'))).toEqual([]); // not left behind under the old meal
    });

    it('rejects an invalid meal on update with 400 instead of saving it', async () => {
        const { token } = await f.admin();
        const r = await make('Soup', { category: 'lunch' });
        const res = await request(app).put(`/api/recipes/${r._id}`).set(f.auth(token)).send({ category: 'brunch' });
        expect(res.status).toBe(400);
        expect((await Recipe.findById(r._id)).category).toBe('lunch');
    });
});

describe('distance from the user (lat / lng / radius)', () => {
    async function recipeWithFarm(name, coordinates) {
        const farm = await f.merchant(coordinates ? { location: { type: 'Point', coordinates } } : {});
        const prod = await f.product(farm.merchant);
        return make(name, { category: 'lunch', ingredients: [{ name: 'x', quantity: 1, unit: 'kg', product: prod._id }] });
    }
    const near = '&lat=13.08&lng=80.27';

    it('reports distance and flags only recipes outside the radius', async () => {
        await recipeWithFarm('Close', [80.27, 13.08]);   // same spot
        await recipeWithFarm('Far', [77.59, 12.97]);     // Bengaluru, ~290 km away
        const res = await list(`?radius=10${near}`);
        const byName = Object.fromEntries(res.body.data.recipes.map(r => [r.name, r]));
        expect(byName.Close.distance).toBe(0);           // 0 km is a real distance, not "unknown"
        expect(byName.Close.isNearby).toBe(true);
        expect(byName.Far.distance).toBeGreaterThan(200);
        expect(byName.Far.isNearby).toBe(false);
    });

    it('does not crash on a recipe with no ingredients or a farm with no location', async () => {
        await make('Plain', { category: 'lunch' });
        const noLocation = await recipeWithFarm('NoLocation', [80.27, 13.08]);
        const farmId = (await Recipe.findById(noLocation._id).populate('ingredients.product')).ingredients[0].product.merchant;
        await Merchant.collection.updateOne({ _id: farmId }, { $unset: { location: '' } });

        const res = await list(`?radius=10${near}`);
        expect(res.status).toBe(200);
        for (const name of ['Plain', 'NoLocation']) {
            const recipe = res.body.data.recipes.find(r => r.name === name);
            expect(recipe.distance).toBeNull();
            expect(recipe.isNearby).toBe(true); // unknown location is not flagged as far away
        }
    });
});

describe('paging', () => {
    it('ignores nonsense page and limit instead of failing', async () => {
        await make('One', { category: 'lunch' });
        const res = await list('?page=abc&limit=-5');
        expect(res.status).toBe(200);
        expect(res.body.data.pagination.page).toBe(1);
        expect(res.body.data.pagination.limit).toBeGreaterThanOrEqual(1);
    });

    it('pages through results', async () => {
        for (const n of ['a', 'b', 'c']) await make(n, { category: 'lunch' });
        const second = await list('?limit=2&page=2');
        expect(second.body.data.recipes).toHaveLength(1);
        expect(second.body.data.pagination.pages).toBe(2);
    });
});

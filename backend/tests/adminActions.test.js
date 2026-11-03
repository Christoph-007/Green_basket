/**
 * Admin buttons that used to show a success message without calling the server.
 * Each test sends exactly what the Flutter app now sends:
 *   Admin > Recipes > Publish / Unpublish -> PUT    /api/recipes/:id { status }
 *   Admin > Recipes > Delete              -> DELETE /api/recipes/:id
 *   Admin > User > Send Notification      -> POST   /api/notifications/admin/bulk-send { userIds, title, message, channels }
 *   Admin > User > Reset Password         -> POST   /api/auth/forgot-password { email }
 * Real in-memory MongoDB.
 */
jest.mock('../src/services/notify', () => ({
    email: jest.fn().mockResolvedValue({ success: true }),
    sms: jest.fn().mockResolvedValue({ success: true }),
    push: jest.fn().mockResolvedValue({ success: true }),
    all: jest.fn().mockResolvedValue({ success: true })
}));

const request = require('supertest');
const app = require('../server');
const notify = require('../src/services/notify');
const Recipe = require('../src/models/Recipe');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(async () => {
    await db.clear();
    jest.clearAllMocks();
});

const newRecipe = (name = 'Upma') => Recipe.create({
    name, description: 'Tasty', servings: 2, prepTime: 5, cookTime: 10, category: 'breakfast'
});
const visibleToCustomers = async () =>
    (await request(app).get('/api/recipes')).body.data.recipes.map(r => r.name);

describe('Admin > Recipes', () => {
    it('Unpublish hides the recipe from customers and Publish brings it back', async () => {
        const { token } = await f.admin();
        const recipe = await newRecipe();
        expect(await visibleToCustomers()).toEqual(['Upma']);

        const hide = await request(app).put(`/api/recipes/${recipe._id}`).set(f.auth(token)).send({ status: 'draft' });
        expect(hide.status).toBe(200);
        expect(hide.body.data.recipe.status).toBe('draft');
        expect(await visibleToCustomers()).toEqual([]);

        // the admin list still shows it (that is where the Publish button lives)
        const adminList = await request(app).get('/api/recipes/admin/all').set(f.auth(token));
        expect(adminList.body.data.recipes.map(r => r.name)).toEqual(['Upma']);

        const show = await request(app).put(`/api/recipes/${recipe._id}`).set(f.auth(token)).send({ status: 'published' });
        expect(show.status).toBe(200);
        expect(await visibleToCustomers()).toEqual(['Upma']);
    });

    it('Delete really removes the recipe', async () => {
        const { token } = await f.admin();
        const recipe = await newRecipe();
        const res = await request(app).delete(`/api/recipes/${recipe._id}`).set(f.auth(token));
        expect(res.status).toBe(200);
        expect(await Recipe.countDocuments()).toBe(0);
        expect(await visibleToCustomers()).toEqual([]);
    });

    it('customers cannot publish, unpublish or delete', async () => {
        const { token } = await f.customer();
        const recipe = await newRecipe();
        expect((await request(app).put(`/api/recipes/${recipe._id}`).set(f.auth(token)).send({ status: 'draft' })).status).toBeGreaterThanOrEqual(401);
        expect((await request(app).delete(`/api/recipes/${recipe._id}`).set(f.auth(token))).status).toBeGreaterThanOrEqual(401);
        expect(await Recipe.countDocuments()).toBe(1);
        expect((await Recipe.findById(recipe._id)).status).toBe('published');
    });
});

describe('Admin > User detail', () => {
    it('Send Notification reaches that one user and shows in their notifications', async () => {
        const { token: adminToken } = await f.admin();
        const target = await f.customer();
        const bystander = await f.customer();

        const res = await request(app).post('/api/notifications/admin/bulk-send').set(f.auth(adminToken)).send({
            userIds: [String(target.user._id)], title: 'Hello', message: 'Your order is special', channels: ['inApp', 'push']
        });
        expect(res.status).toBe(200);
        expect(res.body.data).toEqual({ sent: 1, failed: 0 });

        const mine = await request(app).get('/api/notifications').set(f.auth(target.token));
        expect(JSON.stringify(mine.body)).toContain('Your order is special');
        const theirs = await request(app).get('/api/notifications').set(f.auth(bystander.token));
        expect(JSON.stringify(theirs.body)).not.toContain('Your order is special');
    });

    it('Reset Password emails the user a reset code', async () => {
        const { user } = await f.customer();
        const res = await request(app).post('/api/auth/forgot-password').send({ email: user.email });
        expect(res.status).toBe(200);
        const sent = notify.email.mock.calls.filter(([opts]) => opts.to === user.email);
        expect(sent.length).toBeGreaterThan(0);
        expect(sent[sent.length - 1][0].data.otp).toMatch(/^\d{6}$/);
    });

    it('Reset Password reports an unknown email instead of pretending it worked', async () => {
        const res = await request(app).post('/api/auth/forgot-password').send({ email: 'nobody@example.com' });
        expect(res.status).toBe(404);
        expect(res.body.message).toMatch(/no account/i);
    });
});

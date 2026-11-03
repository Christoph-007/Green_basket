/**
 * Two things the Flutter app relies on that used to fail quietly:
 *  1. Logout calls DELETE /api/notifications/fcm-token { token }. It used to be swallowed by
 *     DELETE /api/notifications/:id (treating "fcm-token" as a notification id).
 *  2. The product repository can send ?isOrganic=true; the backend now filters on it.
 * Real in-memory MongoDB.
 */
const request = require('supertest');
const app = require('../server');
const User = require('../src/models/User');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(db.clear);

describe('push token registration', () => {
    it('registers and then removes a device token, as the app does on login and logout', async () => {
        const { user, token } = await f.customer();

        const add = await request(app).post('/api/notifications/fcm-token').set(f.auth(token))
            .send({ token: 'device-token-1', deviceType: 'android' });
        expect(add.status).toBe(200);
        expect((await User.findById(user._id)).fcmTokens).toContain('device-token-1');

        const remove = await request(app).delete('/api/notifications/fcm-token').set(f.auth(token))
            .send({ token: 'device-token-1' });
        expect(remove.status).toBe(200);
        expect((await User.findById(user._id)).fcmTokens).not.toContain('device-token-1');
    });

    it('still deletes a single notification by id', async () => {
        const { user, token } = await f.customer();
        const Notification = require('../src/models/Notification');
        const note = await Notification.create({
            user: user._id, userModel: 'User', type: 'info', title: 'Hi', message: 'Hello'
        });
        const res = await request(app).delete(`/api/notifications/${note._id}`).set(f.auth(token));
        expect(res.status).toBe(200);
        expect(await Notification.countDocuments()).toBe(0);
    });
});

describe('product filters', () => {
    it('isOrganic=true returns only organic products', async () => {
        const farm = await f.merchant();
        await f.product(farm.merchant, { name: 'Organic spinach', tags: ['organic', 'leafy'] });
        await f.product(farm.merchant, { name: 'Regular onions', tags: ['root'] });

        const organic = await request(app).get('/api/products?isOrganic=true');
        expect(organic.body.data.products.map(p => p.name)).toEqual(['Organic spinach']);

        const all = await request(app).get('/api/products');
        expect(all.body.data.products).toHaveLength(2);
    });
});

/**
 * The token refresh contract the Flutter ApiProvider relies on:
 *   POST /api/auth/login          -> { token, refreshToken }
 *   POST /api/auth/refresh-token  { refreshToken } -> 200 { success, token, refreshToken }
 *   a refused refresh token       -> 401 (the app signs the user out)
 * Several requests can refresh at once, so the same refresh token must work more than once.
 */
const request = require('supertest');
const app = require('../server');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

let tokens;

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(async () => {
    await db.clear();
    const { user } = await f.customer({ isVerified: true });
    const login = await request(app).post('/api/auth/login').send({ email: user.email, password: 'secret123' });
    expect(login.status).toBe(200);
    tokens = { access: login.body.token, refresh: login.body.refreshToken };
});

const refresh = (refreshToken) => request(app).post('/api/auth/refresh-token').send({ refreshToken });

it('login hands the app a separate access token and refresh token', () => {
    expect(tokens.access).toBeTruthy();
    expect(tokens.refresh).toBeTruthy();
    expect(tokens.refresh).not.toBe(tokens.access);
});

it('refresh returns new tokens at the top level of the response, where the app reads them', async () => {
    const res = await refresh(tokens.refresh);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(typeof res.body.token).toBe('string');
    expect(typeof res.body.refreshToken).toBe('string');

    // and the new access token really works
    const me = await request(app).get('/api/users/profile').set(f.auth(res.body.token));
    expect(me.status).toBe(200);
});

it('the same refresh token can be used by several requests at once', async () => {
    const results = await Promise.all([1, 2, 3, 4, 5].map(() => refresh(tokens.refresh)));
    expect(results.map(r => r.status)).toEqual([200, 200, 200, 200, 200]);
});

it('an invalid refresh token, or an access token, is refused with 401 so the app signs out', async () => {
    expect((await refresh('garbage')).status).toBe(401);
    expect((await refresh(tokens.access)).status).toBe(401);
});

it('a request without a token gets 401 (what triggers the refresh in the app)', async () => {
    const res = await request(app).get('/api/orders/my-orders');
    expect(res.status).toBe(401);
});

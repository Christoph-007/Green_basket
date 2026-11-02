/**
 * Issue 19: token types (refresh ≠ access), refresh checks the account, and
 * the CORS allow-list. Real in-memory MongoDB.
 */
jest.mock('../src/services/notify', () => ({
    email: jest.fn().mockResolvedValue({}), sms: jest.fn().mockResolvedValue({}),
    push: jest.fn().mockResolvedValue({}), all: jest.fn().mockResolvedValue({})
}));

const request = require('supertest');
const jwt = require('jsonwebtoken');
const app = require('../server');
const User = require('../src/models/User');
const db = require('./helpers/db');
const f = require('./helpers/fixtures');

jest.setTimeout(60000);

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(db.clear);

const login = async () => {
    const { user } = await f.customer({ email: 'sec@example.com' });
    const res = await request(app).post('/api/auth/login').send({ email: 'sec@example.com', password: 'secret123' });
    expect(res.status).toBe(200);
    return { user, token: res.body.token, refreshToken: res.body.refreshToken };
};

describe('Token types', () => {
    it('a refresh token is not accepted as an access token', async () => {
        const { token, refreshToken } = await login();
        expect((await request(app).get('/api/users/profile').set('Authorization', `Bearer ${token}`)).status).toBe(200);
        expect((await request(app).get('/api/users/profile').set('Authorization', `Bearer ${refreshToken}`)).status).toBe(401);
    });

    it('an access token cannot be used to refresh', async () => {
        const { token, refreshToken } = await login();
        expect((await request(app).post('/api/auth/refresh-token').send({ refreshToken: token })).status).toBe(401);
        const ok = await request(app).post('/api/auth/refresh-token').send({ refreshToken });
        expect(ok.status).toBe(200);
        expect(jwt.decode(ok.body.token).tokenType).toBe('access');
        expect(jwt.decode(ok.body.refreshToken).tokenType).toBe('refresh');
    });

    it('a blocked or deleted account cannot refresh', async () => {
        const { user, refreshToken } = await login();
        await User.updateOne({ _id: user._id }, { isBlocked: true });
        expect((await request(app).post('/api/auth/refresh-token').send({ refreshToken })).status).toBe(401);
        await User.deleteOne({ _id: user._id });
        expect((await request(app).post('/api/auth/refresh-token').send({ refreshToken })).status).toBe(401);
    });
});

describe('CORS', () => {
    const env = { ...process.env };
    afterEach(() => { process.env = { ...env }; });

    it('allows the mobile app (no Origin header)', async () => {
        process.env.NODE_ENV = 'production';
        delete process.env.CORS_ORIGINS; delete process.env.FRONTEND_URL;
        expect((await request(app).get('/api/health')).status).toBe(200);
    });

    it('blocks unknown websites in production and allows listed ones', async () => {
        process.env.NODE_ENV = 'production';
        process.env.CORS_ORIGINS = 'https://admin.greenbasket.example';
        const evil = await request(app).get('/api/health').set('Origin', 'https://evil.example');
        expect(evil.headers['access-control-allow-origin']).toBeUndefined();
        const good = await request(app).get('/api/health').set('Origin', 'https://admin.greenbasket.example');
        expect(good.headers['access-control-allow-origin']).toBe('https://admin.greenbasket.example');
    });

    it('blocks all websites in production when no list is configured', async () => {
        process.env.NODE_ENV = 'production';
        delete process.env.CORS_ORIGINS; delete process.env.FRONTEND_URL;
        const res = await request(app).get('/api/health').set('Origin', 'https://evil.example');
        expect(res.headers['access-control-allow-origin']).toBeUndefined();
    });
});

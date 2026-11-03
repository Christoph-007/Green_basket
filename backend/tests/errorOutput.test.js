/**
 * Error responses must not leak stack traces unless NODE_ENV is "development".
 * (An unset NODE_ENV used to expose them, which is the usual state of a hosted server.)
 */
const request = require('supertest');
const app = require('../server');

const original = process.env.NODE_ENV;
afterEach(() => {
    if (original === undefined) delete process.env.NODE_ENV; else process.env.NODE_ENV = original;
});

const notFoundBody = async () => (await request(app).get('/api/this-route-does-not-exist')).body;

it.each(['test', 'production', 'staging'])('hides the stack when NODE_ENV is %s', async (env) => {
    process.env.NODE_ENV = env;
    const body = await notFoundBody();
    expect(body.success).toBe(false);
    expect(body.message).toMatch(/Not Found/);
    expect(body.stack).toBeUndefined();
});

it('hides the stack when NODE_ENV is not set at all', async () => {
    delete process.env.NODE_ENV;
    expect((await notFoundBody()).stack).toBeUndefined();
});

it('shows the stack only in development', async () => {
    process.env.NODE_ENV = 'development';
    expect((await notFoundBody()).stack).toContain('Not Found');
});

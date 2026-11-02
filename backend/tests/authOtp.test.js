/**
 * Email OTP verification and role-agnostic password reset, end to end
 * against a real (in-memory) MongoDB. The notify service is mocked so the
 * test can read the OTP that would have been emailed.
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
const User = require('../src/models/User');
const Merchant = require('../src/models/Merchant');
const db = require('./helpers/db');

jest.setTimeout(60000);

// The most recent OTP emailed to an address
const lastOtpFor = (email) => {
    const calls = notify.email.mock.calls.filter(([opts]) => opts.to === email && opts.template === 'otpCode');
    if (!calls.length) throw new Error(`No OTP email sent to ${email}`);
    return calls[calls.length - 1][0].data.otp;
};

beforeAll(db.connect);
afterAll(db.disconnect);
beforeEach(async () => {
    await db.clear();
    jest.clearAllMocks();
});

const signupUser = (overrides = {}) => request(app).post('/api/auth/user/signup').send({
    name: 'Asha', email: 'asha@example.com', phone: '9000000001', password: 'secret123', ...overrides
});

describe('Email verification by OTP', () => {
    it('signup emails a verification OTP; verify-otp logs the customer in and marks the email verified', async () => {
        const signup = await signupUser();
        expect(signup.status).toBe(201);

        const otpEmail = notify.email.mock.calls.find(([o]) => o.template === 'otpCode')[0];
        expect(otpEmail.data.isVerification).toBe(true);

        const res = await request(app).post('/api/auth/verify-otp')
            .send({ email: 'asha@example.com', otp: lastOtpFor('asha@example.com') });

        expect(res.status).toBe(200);
        expect(res.body).toEqual(expect.objectContaining({
            success: true,
            role: 'customer',
            token: expect.any(String),
            refreshToken: expect.any(String),
            user: expect.objectContaining({ email: 'asha@example.com', name: 'Asha' })
        }));
        const user = await User.findOne({ email: 'asha@example.com' });
        expect(user.isEmailVerified).toBe(true);

        // The token works on a protected route
        const profile = await request(app).get('/api/users/profile').set('Authorization', `Bearer ${res.body.token}`);
        expect(profile.status).toBe(200);
    });

    it('a wrong OTP is rejected, and the OTP is burned after 5 wrong attempts', async () => {
        await signupUser();
        const realOtp = lastOtpFor('asha@example.com');
        const wrong = realOtp === '000000' ? '111111' : '000000';

        for (let i = 1; i <= 4; i++) {
            const r = await request(app).post('/api/auth/verify-otp').send({ email: 'asha@example.com', otp: wrong });
            expect(r.status).toBe(400);
            expect(r.body.message).toBe('Invalid OTP');
        }
        const fifth = await request(app).post('/api/auth/verify-otp').send({ email: 'asha@example.com', otp: wrong });
        expect(fifth.body.message).toMatch(/Too many incorrect attempts/);

        // Even the correct code no longer works
        const late = await request(app).post('/api/auth/verify-otp').send({ email: 'asha@example.com', otp: realOtp });
        expect(late.status).toBe(400);

        // A resent OTP works
        const resend = await request(app).post('/api/auth/resend-otp').send({ email: 'asha@example.com' });
        expect(resend.status).toBe(200);
        const ok = await request(app).post('/api/auth/verify-otp')
            .send({ email: 'asha@example.com', otp: lastOtpFor('asha@example.com') });
        expect(ok.status).toBe(200);

        // Resend is refused once verified
        const again = await request(app).post('/api/auth/resend-otp').send({ email: 'asha@example.com' });
        expect(again.status).toBe(400);
    });

    it('merchant signup also sends an OTP and verify-otp returns the merchant role', async () => {
        const signup = await request(app).post('/api/auth/merchant/signup').send({
            name: 'Ravi', email: 'ravi@farm.com', phone: '9000000002', password: 'secret123', businessName: 'Ravi Farm'
        });
        expect(signup.status).toBe(201);

        const res = await request(app).post('/api/auth/verify-otp')
            .send({ email: 'ravi@farm.com', otp: lastOtpFor('ravi@farm.com') });
        expect(res.status).toBe(200);
        expect(res.body.role).toBe('merchant');
        expect(res.body.user.verificationStatus).toBe('pending');
        expect((await Merchant.findOne({ email: 'ravi@farm.com' })).isEmailVerified).toBe(true);
    });

    it('a customer cannot sign up with an email that already belongs to a merchant', async () => {
        await request(app).post('/api/auth/merchant/signup').send({
            name: 'Ravi', email: 'ravi@farm.com', phone: '9000000002', password: 'secret123'
        });
        const res = await signupUser({ email: 'ravi@farm.com', phone: '9000000003' });
        expect(res.status).toBe(400);
    });
});

describe('Password reset for any role (POST /api/auth/forgot-password, /reset-password)', () => {
    it('resets a merchant password via the shared endpoints', async () => {
        await Merchant.create({
            name: 'Ravi', email: 'ravi@farm.com', phone: '9000000002', password: 'oldpass123',
            businessName: 'Ravi Farm', verificationStatus: 'approved',
            address: { street: 'x', city: 'x', state: 'x', pincode: '000000' }
        });

        const forgot = await request(app).post('/api/auth/forgot-password').send({ email: 'ravi@farm.com' });
        expect(forgot.status).toBe(200);
        const otp = lastOtpFor('ravi@farm.com');

        const reset = await request(app).post('/api/auth/reset-password')
            .send({ email: 'ravi@farm.com', otp, newPassword: 'newpass456' });
        expect(reset.status).toBe(200);

        const login = await request(app).post('/api/auth/login').send({ email: 'ravi@farm.com', password: 'newpass456' });
        expect(login.status).toBe(200);
        expect(login.body.role).toBe('merchant');
    });

    it('resets a customer password and rejects a wrong OTP', async () => {
        await User.create({ name: 'Asha', email: 'asha@example.com', phone: '9000000001', password: 'oldpass123' });

        await request(app).post('/api/auth/forgot-password').send({ email: 'asha@example.com' });
        const otp = lastOtpFor('asha@example.com');

        const bad = await request(app).post('/api/auth/reset-password')
            .send({ email: 'asha@example.com', otp: otp === '000000' ? '111111' : '000000', newPassword: 'x' });
        expect(bad.status).toBe(400);

        const reset = await request(app).post('/api/auth/reset-password')
            .send({ email: 'asha@example.com', otp, newPassword: 'newpass456' });
        expect(reset.status).toBe(200);

        const login = await request(app).post('/api/auth/login').send({ email: 'asha@example.com', password: 'newpass456' });
        expect(login.status).toBe(200);
        expect(login.body.role).toBe('customer');
    });
});

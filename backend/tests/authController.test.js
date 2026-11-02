const authController = require('../src/controllers/authController');
const User = require('../src/models/User');
const Merchant = require('../src/models/Merchant');
const generateToken = require('../src/utils/generateToken');
const { sendEmail } = require('../src/services/emailService');

// Mock dependencies
jest.mock('../src/models/User');
jest.mock('../src/models/Merchant');
jest.mock('../src/utils/generateToken');
jest.mock('../src/services/emailService');
jest.mock('../src/models/OTP', () => ({ generateOTP: jest.fn().mockResolvedValue('123456'), verifyOTP: jest.fn() }));
jest.mock('../src/services/notify', () => ({
    email: jest.fn().mockResolvedValue({ success: true }),
    sms: jest.fn().mockResolvedValue({ success: true }),
    all: jest.fn().mockResolvedValue({ success: true })
}));
jest.mock('../src/services/sendgridContactService', () => ({ addContactToSendGrid: jest.fn().mockResolvedValue({}) }));
const notify = require('../src/services/notify');
const OTP = require('../src/models/OTP');
jest.mock('jsonwebtoken', () => ({
    sign: jest.fn(() => 'mocked.jwt.token'),
    verify: jest.fn()
}));

const mockResponse = () => {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    return res;
};

const mockRequest = (body) => ({
    body
});

describe('Unit Tests: Auth Controller', () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    describe('userSignup', () => {
        it('should create a new user and email a verification OTP', async () => {
            const req = mockRequest({
                name: 'Test User',
                email: 'test@example.com',
                password: 'password123',
                phone: '1234567890'
            });
            const res = mockResponse();

            // Mock User.findOne to return null (no existing user)
            User.findOne.mockResolvedValue(null);

            // Mock User.create to return created user
            User.create.mockResolvedValue({
                _id: 'user_id',
                name: 'Test User',
                email: 'test@example.com',
                phone: '1234567890'
            });

            // Mock generateToken
            generateToken.mockReturnValue('mocked_auth_token');

            await authController.userSignup(req, res);

            // Email/phone must be unique across customers and merchants
            expect(User.findOne).toHaveBeenCalledWith({ $or: [{ email: 'test@example.com' }, { phone: '1234567890' }] });
            expect(Merchant.findOne).toHaveBeenCalledWith({ $or: [{ email: 'test@example.com' }, { phone: '1234567890' }] });
            expect(User.create).toHaveBeenCalled();
            // The app's OTP screen needs an email-verification OTP
            expect(OTP.generateOTP).toHaveBeenCalledWith('test@example.com', 'user', 'email_verification');
            expect(notify.email).toHaveBeenCalledWith(expect.objectContaining({
                to: 'test@example.com',
                template: 'otpCode',
                data: expect.objectContaining({ otp: '123456', isVerification: true })
            }));
            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: true,
                data: expect.objectContaining({ token: 'mocked_auth_token' })
            }));
        });

        it('should return error if user already exists', async () => {
            const req = mockRequest({
                name: 'Test User',
                email: 'existing@example.com'
            });
            const res = mockResponse();

            User.findOne.mockResolvedValue({ _id: 'existing_id' });

            await authController.userSignup(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: false,
                message: 'User already exists with this email or phone'
            }));
        });
    });

    describe('userLogin', () => {
        it('should return token for valid credentials', async () => {
            const req = mockRequest({
                email: 'test@example.com',
                password: 'password123'
            });
            const res = mockResponse();

            const mockUser = {
                _id: 'user_id',
                name: 'Test User',
                email: 'test@example.com',
                isBlocked: false,
                comparePassword: jest.fn().mockResolvedValue(true),
                save: jest.fn().mockResolvedValue(true)
            };

            // Mock chaining: User.findOne().select()
            const mockSelect = jest.fn().mockResolvedValue(mockUser);
            User.findOne.mockReturnValue({ select: mockSelect });

            generateToken.mockReturnValue('mocked_auth_token');

            await authController.userLogin(req, res);

            expect(mockUser.comparePassword).toHaveBeenCalledWith('password123');
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: true,
                data: expect.objectContaining({ token: 'mocked_auth_token' })
            }));
        });

        it('should return 401 for invalid password', async () => {
            const req = mockRequest({
                email: 'test@example.com',
                password: 'wrongpassword'
            });
            const res = mockResponse();

            const mockUser = {
                comparePassword: jest.fn().mockResolvedValue(false)
            };

            const mockSelect = jest.fn().mockResolvedValue(mockUser);
            User.findOne.mockReturnValue({ select: mockSelect });

            await authController.userLogin(req, res);

            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
                success: false,
                message: 'Invalid email or password'
            }));
        });
    });

});

require('dotenv').config();
const mongoose = require('mongoose');

// Need to mock these BEFORE requiring the service
jest.mock('../src/models/Notification');
jest.mock('../src/models/User');
// Mocking the downstream services so they don't actually send anything
jest.mock('../src/services/email', () => jest.fn().mockResolvedValue(true));
jest.mock('../src/services/sms', () => jest.fn().mockResolvedValue(true));
jest.mock('../src/services/pushNotification', () => jest.fn().mockResolvedValue(true));

const notificationService = require('../src/services/notification'); // Correct path
const Notification = require('../src/models/Notification');
const User = require('../src/models/User');
const sendEmail = require('../src/services/email');

describe('Unit Tests: Notification Service', () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    it('should create a notification record and attempt to send email', async () => {
        const userId = new mongoose.Types.ObjectId().toString();
        const data = {
            recipient: userId,
            recipientModel: 'User',
            type: 'order_placed',
            title: 'Test Order',
            message: 'Your order has been placed',
            channels: ['email'] // Simplify to just email for this test
        };

        // Mock User found
        User.findById.mockResolvedValue({
            _id: userId,
            email: 'test@example.com',
            notificationPreferences: { email: { orderUpdates: true } }
        });

        // Mock Notification creation
        const mockSave = jest.fn().mockResolvedValue(true);
        Notification.create.mockResolvedValue({
            ...data,
            _id: 'notif_123',
            user: userId,
            channels: { push: {}, email: {}, sms: {}, inApp: {} },
            save: mockSave
        });

        // Suppress console warnings from missing keys in test env
        const consoleSpy = jest.spyOn(console, 'warn').mockImplementation(() => { });

        // Call the service (using the adapter adapter method for compatibility if needed, or direct)
        // The service exports an instance, so we use it directly
        await notificationService.createNotification(data);

        expect(User.findById).toHaveBeenCalledWith(userId);
        expect(Notification.create).toHaveBeenCalledWith(expect.objectContaining({
            user: userId,
            title: 'Test Order'
        }));

        // Verify email was sent
        expect(sendEmail).toHaveBeenCalled();

        consoleSpy.mockRestore();
    });

    it('should get user notifications with pagination', async () => {
        const userId = new mongoose.Types.ObjectId().toString();

        // Mongoose query chain mock
        const mockChain = {
            sort: jest.fn().mockReturnThis(),
            skip: jest.fn().mockReturnThis(),
            limit: jest.fn().mockResolvedValue(['notif1', 'notif2'])
        };
        Notification.find.mockReturnValue(mockChain);

        Notification.countDocuments.mockImplementation((query) => {
            if (query['channels.inApp.read'] === false) return Promise.resolve(5); // unread
            return Promise.resolve(20); // total
        });

        const result = await notificationService.getUserNotifications(userId, { page: 1, limit: 10 });

        expect(result.notifications).toHaveLength(2);
        expect(result.unreadCount).toBe(5);
        expect(result.pagination.total).toBe(20);
        expect(Notification.find).toHaveBeenCalledWith({ user: userId });
    });

});

const Notification = require('../models/Notification');
const sendEmail = require('./email');
const sendSMS = require('./sms');
const sendPushNotification = require('./pushNotification');

class NotificationService {
    async send(userId, userModel, notificationData) {
        const {
            type,
            title,
            message,
            data = {},
            channels = ['push', 'email', 'sms', 'inApp'],
            priority = 'medium',
            actionUrl,
            imageUrl,
            isBroadcast = false,
            broadcastId,
            isBroadcastPrimary = false,
            recipientCount = 1,
            audience
        } = notificationData;

        // Get user preferences
        const User = require('../models/User');
        const Merchant = require('../models/Merchant');
        const Admin = require('../models/Admin');

        const Model = userModel === 'User' ? User :
            userModel === 'Merchant' ? Merchant : Admin;

        const user = await Model.findById(userId);

        if (!user) {
            throw new Error('User not found');
        }

        const prefs = user.notificationSettings || user.notificationPreferences || {};

        // Create notification record
        const notification = await Notification.create({
            user: userId,
            userModel,
            type,
            title,
            message,
            data,
            priority,
            actionUrl,
            imageUrl,
            isBroadcast,
            broadcastId,
            isBroadcastPrimary,
            recipientCount,
            audience,
            channels: {
                push: { sent: false },
                email: { sent: false },
                sms: { sent: false },
                inApp: { sent: true }
            }
        });

        // Send via enabled channels
        const promises = [];

        // Push notification
        if (channels.includes('push') && this.shouldSendPush(type, prefs)) {
            promises.push(
                sendPushNotification(userId, notification, userModel)
                    .then((result) => {
                        if (result && result.success) {
                            notification.channels.push.sent = true;
                            notification.channels.push.sentAt = new Date();
                        } else {
                            notification.channels.push.error = result ? result.reason : 'Failed to send';
                        }
                    })
                    .catch(err => {
                        console.error(`[Notification] Push error: ${err.message}`);
                        notification.channels.push.error = err.message;
                    })
            );
        } else {
            console.log(`[Notification] Skipping Push: channel not requested or disabled by prefs. User: ${userId}`);
        }

        // Email
        if (channels.includes('email') && this.shouldSendEmail(type, prefs)) {
            promises.push(
                sendEmail({
                    to: user.email,
                    subject: title,
                    template: this.getEmailTemplate(type),
                    data: { ...data, message, title }
                })
                    .then(() => {
                        notification.channels.email.sent = true;
                        notification.channels.email.sentAt = new Date();
                    })
                    .catch(err => {
                        console.error(`[Notification] Email error: ${err.message}`);
                        notification.channels.email.error = err.message;
                    })
            );
        } else {
            console.log(`[Notification] Skipping Email: channel not requested or disabled by prefs. User: ${userId}`);
        }

        // SMS
        if (channels.includes('sms') && this.shouldSendSMS(type, prefs) && user.phone) {
            promises.push(
                sendSMS({
                    to: user.phone,
                    message: `${title}: ${message}`
                })
                    .then(() => {
                        notification.channels.sms.sent = true;
                        notification.channels.sms.sentAt = new Date();
                    })
                    .catch(err => {
                        console.error(`[Notification] SMS error: ${err.message}`);
                        notification.channels.sms.error = err.message;
                    })
            );
        } else {
            console.log(`[Notification] Skipping SMS: channel not requested or disabled by prefs/phone. User: ${userId}`);
        }

        await Promise.allSettled(promises);
        await notification.save();

        // Emit via Socket.IO for real-time (if available)
        try {
            const io = require('../../server').io;
            if (io) {
                io.to(`user_${userId}`).emit('notification', notification);
            }
        } catch (error) {
            // Socket.IO not available, skip
        }

        return notification;
    }

    shouldSendPush(type, prefs) {
        const typeCategory = this.getTypeCategory(type);
        return prefs.push?.[typeCategory] !== false;
    }

    shouldSendEmail(type, prefs) {
        const typeCategory = this.getTypeCategory(type);
        return prefs.email?.[typeCategory] !== false;
    }

    shouldSendSMS(type, prefs) {
        const typeCategory = this.getTypeCategory(type);
        return prefs.sms?.[typeCategory] !== false;
    }

    getTypeCategory(type) {
        const orderTypes = ['order', 'order_placed', 'order_confirmed',
            'order_out_for_delivery', 'order_delivered', 'order_cancelled'];
        const promotionTypes = ['offer_available', 'flash_sale', 'promotion'];
        const systemTypes = ['account_update', 'profile_update', 'merchant_approved', 
            'merchant_rejected', 'merchant_blocked', 'merchant_unblocked', 'system', 'info'];
        const paymentTypes = ['payment_received', 'payment_success', 'payment_failed', 'refund_processed', 'wallet_credit', 'payment'];

        if (orderTypes.includes(type)) return 'order';
        if (promotionTypes.includes(type)) return 'promotion';
        if (paymentTypes.includes(type)) return 'payment';
        if (systemTypes.includes(type)) return 'system';

        return 'system'; // Default to system for unknown types
    }

    getEmailTemplate(type) {
        const templates = {
            'order_placed': 'orderConfirmation',
            'order_confirmed': 'orderConfirmed',
            'order_delivered': 'orderDelivered',
            'order_cancelled': 'orderCancelled',
            'merchant_approved': 'merchantApproved',
            'offer_available': 'offerNotification',
            'price_drop': 'priceDrop',
            'back_in_stock': 'backInStock',
            'refund_processed': 'refundProcessed',
            'wallet_credit': 'walletCredit'
        };

        return templates[type] || 'generic';
    }

    // Adapter for compatibility
    async createNotification({ recipient, recipientModel, type, title, message, data }) {
        return this.send(recipient, recipientModel, { type, title, message, data });
    }

    async markAsRead(notificationId, userId) {
        return Notification.findOneAndUpdate(
            { _id: notificationId, user: userId },
            { 'channels.inApp.read': true, 'channels.inApp.readAt': new Date() },
            { new: true }
        );
    }

    async markAllAsRead(userId) {
        await Notification.updateMany(
            { user: userId, 'channels.inApp.read': false },
            { 'channels.inApp.read': true, 'channels.inApp.readAt': new Date() }
        );
    }

    async getUserNotifications(userId, { page = 1, limit = 20 }) {
        const skip = (page - 1) * limit;

        const notifications = await Notification.find({ user: userId })
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(parseInt(limit));

        const total = await Notification.countDocuments({ user: userId });
        const unreadCount = await Notification.countDocuments({
            user: userId,
            'channels.inApp.read': false
        });

        return {
            notifications,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total,
                pages: Math.ceil(total / limit)
            },
            unreadCount
        };
    }
}

module.exports = new NotificationService();

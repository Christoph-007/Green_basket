const Notification = require('../models/Notification');
const notificationService = require('../services/notification');
const crypto = require('crypto');

exports.getNotifications = async (req, res) => {
    try {
        const { page = 1, limit = 20, unread, type } = req.query;

        const query = { user: req.user._id };

        if (unread === 'true') {
            query['channels.inApp.read'] = false;
        }

        if (type) {
            query.type = type;
        }

        const skip = (page - 1) * limit;

        const [notifications, total, unreadCount] = await Promise.all([
            Notification.find(query)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Notification.countDocuments(query),
            Notification.countDocuments({
                user: req.user._id,
                'channels.inApp.read': false
            })
        ]);

        res.json({
            success: true,
            data: {
                notifications,
                unreadCount,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to fetch notifications',
            details: error.message
        });
    }
};

exports.markAsRead = async (req, res) => {
    try {
        const { id } = req.params;

        const notification = await Notification.findOne({
            _id: id,
            user: req.user._id
        });

        if (!notification) {
            return res.status(404).json({
                success: false,
                error: 'Notification not found'
            });
        }

        notification.channels.inApp.read = true;
        notification.channels.inApp.readAt = new Date();
        await notification.save();

        res.json({
            success: true,
            message: 'Notification marked as read'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to mark notification as read',
            details: error.message
        });
    }
};

exports.markAllAsRead = async (req, res) => {
    try {
        const result = await Notification.updateMany(
            {
                user: req.user._id,
                'channels.inApp.read': false
            },
            {
                $set: {
                    'channels.inApp.read': true,
                    'channels.inApp.readAt': new Date()
                }
            }
        );

        res.json({
            success: true,
            message: 'All notifications marked as read',
            data: {
                modifiedCount: result.modifiedCount
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to mark all notifications as read',
            details: error.message
        });
    }
};

exports.deleteNotification = async (req, res) => {
    try {
        const { id } = req.params;

        const notification = await Notification.findOneAndDelete({
            _id: id,
            user: req.user._id
        });

        if (!notification) {
            return res.status(404).json({
                success: false,
                error: 'Notification not found'
            });
        }

        res.json({
            success: true,
            message: 'Notification deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to delete notification',
            details: error.message
        });
    }
};

exports.getUnreadCount = async (req, res) => {
    try {
        const count = await Notification.countDocuments({
            user: req.user._id,
            'channels.inApp.read': false
        });

        res.json({
            success: true,
            data: {
                count
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to get unread count',
            details: error.message
        });
    }
};

exports.clearAllNotifications = async (req, res) => {
    try {
        const result = await Notification.deleteMany({
            user: req.user._id
        });

        res.json({
            success: true,
            message: 'All notifications cleared',
            data: {
                deletedCount: result.deletedCount
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to clear notifications',
            details: error.message
        });
    }
};

exports.updateNotificationPreferences = async (req, res) => {
    try {
        const { email, push, sms } = req.body;

        const user = await req.user.constructor.findById(req.user._id);

        if (!user.notificationPreferences) {
            user.notificationPreferences = {};
        }

        if (email) {
            user.notificationPreferences.email = {
                ...user.notificationPreferences.email,
                ...email
            };
        }

        if (push) {
            user.notificationPreferences.push = {
                ...user.notificationPreferences.push,
                ...push
            };
        }

        if (sms) {
            user.notificationPreferences.sms = {
                ...user.notificationPreferences.sms,
                ...sms
            };
        }

        await user.save();

        res.json({
            success: true,
            message: 'Notification preferences updated successfully',
            data: {
                notificationPreferences: user.notificationPreferences
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to update notification preferences',
            details: error.message
        });
    }
};

exports.getNotificationPreferences = async (req, res) => {
    try {
        const user = await req.user.constructor.findById(req.user._id);

        res.json({
            success: true,
            data: user.notificationPreferences || {
                email: {
                    orderUpdates: true,
                    offers: true,
                    newsletter: false,
                    productUpdates: true
                },
                push: {
                    orderUpdates: true,
                    offers: true,
                    priceDrops: true,
                    backInStock: true
                },
                sms: {
                    orderUpdates: true,
                    offers: false,
                    otp: true
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to get notification preferences',
            details: error.message
        });
    }
};

exports.registerFCMToken = async (req, res) => {
    try {
        const { token, deviceType } = req.body;

        if (!token) {
            return res.status(400).json({
                success: false,
                error: 'Token is required'
            });
        }

        const user = await req.user.constructor.findById(req.user._id);

        if (!user.fcmTokens) {
            user.fcmTokens = [];
        }
        if (!user.deviceTokens) {
            user.deviceTokens = [];
        }

        // Remove token if already exists
        user.fcmTokens = user.fcmTokens.filter(t => t !== token);

        // Add new token
        user.fcmTokens.push(token);

        // Update device tokens
        const existingDevice = user.deviceTokens.find(d => d.token === token);
        if (existingDevice) {
            existingDevice.lastUsed = new Date();
        } else {
            user.deviceTokens.push({
                token,
                deviceType: deviceType || 'web',
                lastUsed: new Date()
            });
        }

        await user.save();

        res.json({
            success: true,
            message: 'FCM token registered successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to register FCM token',
            details: error.message
        });
    }
};

exports.removeFCMToken = async (req, res) => {
    try {
        const { token } = req.body;

        if (!token) {
            return res.status(400).json({
                success: false,
                error: 'Token is required'
            });
        }

        const user = await req.user.constructor.findById(req.user._id);

        user.fcmTokens = user.fcmTokens.filter(t => t !== token);
        user.deviceTokens = user.deviceTokens.filter(d => d.token !== token);

        await user.save();

        res.json({
            success: true,
            message: 'FCM token removed successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to remove FCM token',
            details: error.message
        });
    }
};

exports.sendTestNotification = async (req, res) => {
    try {
        const { userId, title, message, channels } = req.body;

        if (!userId || !title || !message) {
            return res.status(400).json({
                success: false,
                error: 'userId, title, and message are required'
            });
        }

        const notification = await notificationService.send(
            userId,
            'User',
            {
                type: 'flash_sale',
                title,
                message,
                channels: channels || ['push', 'email', 'inApp'],
                priority: 'medium'
            }
        );

        res.json({
            success: true,
            message: 'Test notification sent successfully',
            data: {
                notificationId: notification._id
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to send test notification',
            details: error.message
        });
    }
};

exports.getAllSentNotifications = async (req, res) => {
    try {
        const { page = 1, limit = 20, type, audience } = req.query;
        const query = {};

        if (type) query.type = type;
        if (audience) {
            if (audience === 'Customers Only') query.userModel = 'User';
            if (audience === 'Merchants Only') query.userModel = 'Merchant';
        }

        const skip = (page - 1) * limit;
        
        // Deduplicate broadcasts in admin view by only showing primary records
        if (req.query.showAll !== 'true') {
            query.isBroadcastPrimary = { $ne: false };
        }

        const [notifications, total] = await Promise.all([
            Notification.find(query)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Notification.countDocuments(query)
        ]);

        res.json({
            success: true,
            data: {
                notifications,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to fetch all notifications',
            details: error.message
        });
    }
};

exports.bulkSendNotifications = async (req, res) => {
    try {
        let { userIds, title, message, body, type, channels, types, audience, actionUrl, imageUrl } = req.body;

        // Map frontend fields for compatibility
        if (!message && body) message = body;
        if (!channels && types) {
            channels = Array.isArray(types) ? types.map(t => t.toLowerCase()) : [types.toLowerCase()];
        }
        if (!type) type = 'info';

        // Resolve userIds from audience if not provided
        if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
            if (!audience) {
                return res.status(400).json({
                    success: false,
                    error: 'Either userIds or audience is required'
                });
            }

            const User = require('../models/User');
            const Merchant = require('../models/Merchant');

            userIds = [];
            const targetUsers = [];

            if (audience === 'Customers Only') {
                const customers = await User.find({ isActive: true }, '_id');
                customers.forEach(u => targetUsers.push({ id: u._id, model: 'User' }));
            }
            if (audience === 'Merchants Only') {
                const merchants = await Merchant.find({ isActive: true }, '_id');
                merchants.forEach(m => targetUsers.push({ id: m._id, model: 'Merchant' }));
            }

            if (targetUsers.length === 0) {
                return res.json({
                    success: true,
                    message: `No active users found for audience: ${audience}`,
                    data: { sent: 0, failed: 0 }
                });
            }

            const results = { sent: 0, failed: 0 };
            const broadcastId = crypto.randomUUID?.() || `br_${Date.now()}`;

            for (let i = 0; i < targetUsers.length; i++) {
                const target = targetUsers[i];
                try {
                    await notificationService.send(target.id, target.model, {
                        type: type || 'info',
                        title,
                        message,
                        channels: channels || ['push', 'email', 'sms', 'inApp'],
                        actionUrl,
                        imageUrl,
                        priority: 'medium',
                        isBroadcast: true,
                        broadcastId,
                        isBroadcastPrimary: i === 0,
                        recipientCount: targetUsers.length,
                        audience: audience
                    });
                    results.sent++;
                } catch (error) {
                    console.error(`Failed to send notification to ${target.id} (${target.model}):`, error);
                    results.failed++;
                }
            }

            return res.json({
                success: true,
                message: `Notifications sent to ${audience}`,
                data: results
            });
        }

        // Original logic for specific userIds (default to 'User' model for simplicity or based on a flag)
        const results = {
            sent: 0,
            failed: 0
        };
        const broadcastId = crypto.randomUUID?.() || `br_${Date.now()}`;

        for (let i = 0; i < userIds.length; i++) {
            const userId = userIds[i];
            try {
                await notificationService.send(userId, req.body.userModel || 'User', {
                    type,
                    title,
                    message,
                    channels: channels || ['push', 'email', 'sms', 'inApp'],
                    actionUrl,
                    imageUrl,
                    priority: 'medium',
                    isBroadcast: true,
                    broadcastId,
                    isBroadcastPrimary: i === 0,
                    recipientCount: userIds.length,
                    audience: audience || 'Custom'
                });
                results.sent++;
            } catch (error) {
                console.error(`Failed to send notification to ${userId}:`, error);
                results.failed++;
            }
        }

        res.json({
            success: true,
            message: 'Bulk notifications sent successfully',
            data: results
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to send bulk notifications',
            details: error.message
        });
    }
};

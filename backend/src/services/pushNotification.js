const { messaging } = require('../config/firebase');

/**
 * Send push notifications to a user or merchant's devices
 * @param {string} userId - Target ID
 * @param {object} notification - Notification content {title, message, data, imageUrl}
 * @param {string} userModel - 'User' or 'Merchant'
 */
const sendPushNotification = async (userId, notification, userModel = 'User') => {
    try {
        // Get user's or merchant's FCM tokens
        const User = require('../models/User');
        const Merchant = require('../models/Merchant');
        const Model = userModel === 'Merchant' ? Merchant : User;
        
        const user = await Model.findById(userId);

        if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
            console.log(`[Push] No FCM tokens for ${userModel} ${userId}`);
            return { success: false, reason: 'No FCM tokens' };
        }

        console.log(`[Push] Sending to ${user.fcmTokens.length} tokens for ${userModel} ${userId}`);

        // FCM v1 requirements: All data values must be strings
        const dataPayload = {};
        if (notification.data) {
            Object.keys(notification.data).forEach(key => {
                const val = notification.data[key];
                dataPayload[key] = typeof val === 'object' ? JSON.stringify(val) : String(val);
            });
        }

        const message = {
            notification: {
                title: notification.title,
                body: notification.message
            },
            data: dataPayload,
            tokens: user.fcmTokens
        };

        // Add image if provided
        if (notification.imageUrl) {
            message.notification.imageUrl = notification.imageUrl;
        }

        // use sendEachForMulticast as sendMulticast is deprecated/removed in recent firebase-admin versions
        const response = await messaging.sendEachForMulticast(message);

        // Remove invalid tokens
        if (response.failureCount > 0) {
            const tokensToRemove = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    const error = resp.error;
                    // Only remove if it's a "not registered" or "invalid" token error
                    if (error && (error.code === 'messaging/registration-token-not-registered' || 
                                 error.code === 'messaging/invalid-registration-token')) {
                        tokensToRemove.push(user.fcmTokens[idx]);
                    }
                }
            });

            if (tokensToRemove.length > 0) {
                console.log(`[Push] Removing ${tokensToRemove.length} invalid tokens for ${userModel} ${userId}`);
                await Model.findByIdAndUpdate(userId, {
                    $pull: { fcmTokens: { $in: tokensToRemove } }
                });
            }
        }

        console.log(`[Push] Success! Count: ${response.successCount}, Failure: ${response.failureCount}`);

        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount
        };
    } catch (error) {
        console.error('Push notification error:', error);
        // Don't throw to prevent crashing the whole notification pipeline
        return { success: false, error: error.message };
    }
};

module.exports = sendPushNotification;

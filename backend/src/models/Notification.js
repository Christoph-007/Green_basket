const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        refPath: 'userModel',
        required: true
    },
    userModel: {
        type: String,
        enum: ['User', 'Merchant', 'Admin'],
        required: true
    },
    type: {
        type: String,
        enum: [
            'order', 'order_placed', 'order_confirmed',
            'order_out_for_delivery', 'order_delivered', 'order_cancelled',
            'new_order', 'low_stock', 'merchant_approved', 'merchant_rejected',
            'merchant_blocked', 'merchant_unblocked',
            'offer_available', 'price_drop', 'back_in_stock',
            'prebooking_available',
            'review_reminder', 'wallet_credit', 'referral_reward',
            'flash_sale', 'payment_received', 'payment_success', 'payment_failed',
            'refund_processed',
            'loyalty', 'account_update', 'otp', 'profile_update', 'info'
        ],
        required: true
    },
    title: {
        type: String,
        required: true
    },
    message: {
        type: String,
        required: true
    },
    data: mongoose.Schema.Types.Mixed,

    // Multi-channel delivery
    channels: {
        push: {
            sent: { type: Boolean, default: false },
            sentAt: Date,
            error: String
        },
        email: {
            sent: { type: Boolean, default: false },
            sentAt: Date,
            error: String
        },
        sms: {
            sent: { type: Boolean, default: false },
            sentAt: Date,
            error: String
        },
        inApp: {
            sent: { type: Boolean, default: true },
            read: { type: Boolean, default: false },
            readAt: Date
        }
    },

    priority: {
        type: String,
        enum: ['low', 'medium', 'high', 'urgent'],
        default: 'medium'
    },

    actionUrl: String,
    imageUrl: String,

    // Broadcast Support
    isBroadcast: { type: Boolean, default: false },
    broadcastId: String,
    isBroadcastPrimary: { type: Boolean, default: false },
    recipientCount: { type: Number, default: 1 },
    audience: String
}, { timestamps: true });

// Indexes
notificationSchema.index({ user: 1, 'channels.inApp.read': 1 });
notificationSchema.index({ user: 1, createdAt: -1 });
notificationSchema.index({ type: 1 });

module.exports = mongoose.model('Notification', notificationSchema);

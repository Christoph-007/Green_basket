const mongoose = require('mongoose');

const platformSettingsSchema = new mongoose.Schema({
    general: {
        appName: { type: String, default: 'GreenBasket' },
        supportEmail: { type: String, default: 'support@greenbasket.in' },
        supportPhone: { type: String, default: '+91 1800 123 4567' }
    },
    payment: {
        codEnabled: { type: Boolean, default: true },
        walletEnabled: { type: Boolean, default: true },
        upiEnabled: { type: Boolean, default: true },
        minOrderAmount: { type: Number, default: 100 }
    },
    notifications: {
        fcmEnabled: { type: Boolean, default: true },
        emailNotifEnabled: { type: Boolean, default: true }
    },
    security: {
        sessionTimeout: { type: Number, default: 30 },
        twoFaEnabled: { type: Boolean, default: false }
    },
    commission: {
        defaultRate: {
            type: Number,
            default: 5
        },
        premiumMerchantRate: {
            type: Number,
            default: 3
        },
        byCategory: [{
            category: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Category'
            },
            rate: Number
        }]
    },
    payoutSchedule: {
        type: String,
        enum: ['daily', 'weekly', 'biweekly', 'monthly'],
        default: 'weekly'
    },
    minimumPayoutAmount: {
        type: Number,
        default: 1000
    },
    maximumPayoutAmount: {
        type: Number,
        default: 50000
    },

    taxSettings: {
        gstRate: {
            type: Number,
            default: 18
        },
        gstNumber: String,
        companyName: String
    }
}, { timestamps: true });

module.exports = mongoose.model('PlatformSettings', platformSettingsSchema);

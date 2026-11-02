const mongoose = require('mongoose');

const couponSchema = new mongoose.Schema({
    code: {
        type: String,
        required: true,
        unique: true,
        uppercase: true,
        trim: true
    },
    description: String,
    discountType: {
        type: String,
        enum: ['percentage', 'fixed'],
        required: true
    },
    discountValue: {
        type: Number,
        required: true
    },
    maxDiscountAmount: Number, // For percentage based
    minOrderAmount: {
        type: Number,
        default: 0
    },
    validFrom: Date,
    validUntil: Date,
    isActive: {
        type: Boolean,
        default: true
    },
    usageLimitPerUser: {
        type: Number,
        default: 1
    },
    totalUsageLimit: Number,
    usedCount: {
        type: Number,
        default: 0
    },
    applicableCategories: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category'
    }],
    applicableProducts: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product'
    }],
    merchant: { // If specific to a merchant
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Merchant'
    }
}, { timestamps: true });

module.exports = mongoose.model('Coupon', couponSchema);

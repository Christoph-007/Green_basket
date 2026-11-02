const mongoose = require('mongoose');

const offerSchema = new mongoose.Schema({
    // Ownership
    merchant: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Merchant'
        // null means platform-wide offer (admin)
    },
    createdBy: {
        type: String,
        enum: ['merchant', 'admin'],
        required: true
    },

    // Basic Information
    title: {
        type: String,
        required: [true, 'Offer title is required'],
        trim: true,
        maxlength: 100
    },
    description: {
        type: String,
        maxlength: 500
    },

    // Offer Type
    type: {
        type: String,
        enum: ['percentage', 'flat', 'bogo', 'free_delivery', 'bundle'],
        required: true
    },

    // Discount Details
    discountPercentage: {
        type: Number,
        min: 0,
        max: 100
    },
    discountAmount: {
        type: Number,
        min: 0
    },
    maxDiscountCap: {
        type: Number,
        min: 0
    },
    // BOGO Details
    buyQuantity: {
        type: Number,
        min: 1
    },
    getQuantity: {
        type: Number,
        min: 1
    },

    // Applicable Scope
    applicableOn: {
        type: String,
        enum: ['all', 'categories', 'products'],
        default: 'all'
    },
    categories: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category'
    }],
    products: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product'
    }],

    // Conditions
    minOrderValue: {
        type: Number,
        default: 0,
        min: 0
    },

    // Timing
    startDate: {
        type: Date,
        required: [true, 'Start date is required']
    },
    endDate: {
        type: Date,
        required: [true, 'End date is required']
    },
    isFlashSale: {
        type: Boolean,
        default: false
    },

    // Usage Limits
    totalUsageLimit: {
        type: Number,
        min: 0
    },
    usagePerUser: {
        type: Number,
        default: 1,
        min: 1
    },
    usedCount: {
        type: Number,
        default: 0,
        min: 0
    },

    // Coupon Code
    couponCode: {
        type: String,
        uppercase: true,
        trim: true,
        sparse: true
    },
    // Personal coupons (e.g. loyalty rewards) can only be used by this user
    restrictedTo: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    isPublic: {
        type: Boolean,
        default: true
    },

    // Users who used this offer
    usedBy: [{
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        },
        usedAt: {
            type: Date,
            default: Date.now
        },
        orderId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Order'
        },
        discountAmount: {
            type: Number,
            default: 0
        }
    }],

    // Status
    status: {
        type: String,
        enum: ['active', 'inactive', 'expired', 'exhausted', 'scheduled'],
        default: 'active'
    }

}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// Indexes for performance

offerSchema.index({ merchant: 1, status: 1 });
offerSchema.index({ startDate: 1, endDate: 1 });
offerSchema.index({ isFlashSale: 1, status: 1 });
offerSchema.index({ 'usedBy.user': 1 });

// Virtual for remaining uses
offerSchema.virtual('remainingUses').get(function () {
    if (!this.totalUsageLimit) return 'Unlimited';
    return Math.max(0, this.totalUsageLimit - this.usedCount);
});

// Virtual for time remaining (for flash sales)
offerSchema.virtual('timeRemaining').get(function () {
    if (!this.endDate) return null;
    const now = new Date();
    const remaining = this.endDate - now;
    return Math.max(0, Math.floor(remaining / 1000)); // in seconds
});

// Validation: Ensure discount values are provided based on type
offerSchema.pre('save', function (next) {
    if (this.type === 'percentage' && !this.discountPercentage) {
        return next(new Error('discountPercentage is required for percentage type offers'));
    }
    if (this.type === 'flat' && !this.discountAmount) {
        return next(new Error('discountAmount is required for flat type offers'));
    }
    if (this.startDate >= this.endDate) {
        return next(new Error('endDate must be after startDate'));
    }
    next();
});

// Auto-update status based on usage and dates
offerSchema.methods.updateStatus = function () {
    const now = new Date();

    if (now > this.endDate) {
        this.status = 'expired';
    } else if (this.totalUsageLimit && this.usedCount >= this.totalUsageLimit) {
        this.status = 'exhausted';
    } else if (now >= this.startDate && now <= this.endDate && this.status !== 'inactive') {
        this.status = 'active';
    }

    return this.status;
};

module.exports = mongoose.model('Offer', offerSchema);

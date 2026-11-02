const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
    // Basic Information
    name: {
        type: String,
        required: [true, 'Name is required'],
        trim: true,
        minlength: 2,
        maxlength: 50
    },
    email: {
        type: String,
        required: [true, 'Email is required'],
        unique: true,
        lowercase: true,
        trim: true,
        match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email']
    },
    phone: {
        type: String,
        required: [true, 'Phone number is required'],
        unique: true,
        match: [/^[0-9]{10}$/, 'Please enter a valid 10-digit phone number']
    },
    password: {
        type: String,
        required: [true, 'Password is required'],
        minlength: 6,
        select: false
    },

    // Profile Information
    profileImage: {
        type: String,
        default: null
    },

    // Authentication
    authProvider: {
        type: String,
        enum: ['local', 'google', 'facebook'],
        default: 'local'
    },
    googleId: String,
    facebookId: String,
    isEmailVerified: {
        type: Boolean,
        default: false
    },
    isPhoneVerified: {
        type: Boolean,
        default: false
    },

    // Preferences
    dietaryPreferences: [{
        type: String,
        enum: ['vegetarian', 'vegan', 'non-vegetarian', 'gluten-free', 'organic-only', 'dairy-free']
    }],
    allergies: [{
        type: String
    }],
    dateOfBirth: Date,

    // Home location (used for nearby merchant discovery when device GPS is unavailable)
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: {
            type: [Number], // [longitude, latitude]
            default: undefined
        }
    },

    // Loyalty & Rewards
    loyaltyPoints: {
        type: Number,
        default: 0,
        min: 0
    },
    loyaltyTier: {
        type: String,
        enum: ['bronze', 'silver', 'gold', 'platinum'],
        default: 'bronze'
    },
    pointsHistory: [{
        type: {
            type: String,
            enum: ['earned', 'redeemed', 'expired', 'bonus'],
            required: true
        },
        points: {
            type: Number,
            required: true
        },
        source: {
            type: String,
            enum: ['order', 'review', 'referral', 'birthday', 'redemption', 'expiry'],
            required: true
        },
        description: String,
        orderId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Order'
        },
        expiryDate: Date,
        createdAt: {
            type: Date,
            default: Date.now
        }
    }],
    nextTierPoints: Number,
    tierBenefits: {
        extraPointsPercentage: {
            type: Number,
            default: 0
        },
        freeDeliveryThreshold: Number,
        prioritySupport: {
            type: Boolean,
            default: false
        }
    },

    // Referral System
    referral: {
        code: {
            type: String,
            unique: true,
            sparse: true,
            uppercase: true
        },
        referredBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        },
        referrals: [{
            user: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'User'
            },
            status: {
                type: String,
                enum: ['pending', 'completed'],
                default: 'pending'
            },
            rewardEarned: {
                type: Number,
                default: 0
            },
            firstOrderId: {
                type: mongoose.Schema.Types.ObjectId,
                ref: 'Order'
            },
            createdAt: {
                type: Date,
                default: Date.now
            },
            completedAt: Date
        }],
        totalEarned: {
            type: Number,
            default: 0
        }
    },

    // Wallet
    walletBalance: {
        type: Number,
        default: 0
    },

    // Notification Settings
    notificationSettings: {
        push: {
            order: { type: Boolean, default: true },
            payment: { type: Boolean, default: true },
            promotion: { type: Boolean, default: true },
            system: { type: Boolean, default: true }
        },
        email: {
            order: { type: Boolean, default: true },
            payment: { type: Boolean, default: true },
            otp: { type: Boolean, default: true },
            system: { type: Boolean, default: true }
        }
    },

    // FCM Tokens for Push Notifications
    fcmTokens: [String],
    deviceTokens: [{
        token: String,
        deviceType: { type: String, enum: ['ios', 'android', 'web'] },
        lastUsed: Date
    }],

    // Status
    isActive: {
        type: Boolean,
        default: true
    },
    isBlocked: {
        type: Boolean,
        default: false
    },
    blockedReason: String,

    // Timestamps
    lastLoginAt: Date,
    passwordChangedAt: Date
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// Virtual for addresses
userSchema.virtual('addresses', {
    ref: 'Address',
    localField: '_id',
    foreignField: 'user'
});

// Hash password before saving
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();
    this.password = await bcrypt.hash(this.password, 12);
    next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);

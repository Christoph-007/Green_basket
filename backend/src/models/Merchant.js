const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const merchantSchema = new mongoose.Schema({
    // Basic Information
    name: {
        type: String,
        required: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true
    },
    phone: {
        type: String,
        required: true,
        unique: true
    },
    password: {
        type: String,
        required: true,
        select: false
    },

    // Business Information
    isEmailVerified: {
        type: Boolean,
        default: false
    },
    businessName: {
        type: String,
        trim: true
    },
    merchantType: {
        type: String,
        enum: ['home-grower', 'organic-farmer', 'local-farmer']
    },
    businessDescription: {
        type: String,
        maxlength: 500
    },
    sellingModel: {
        type: String,
        enum: ['retail', 'wholesale', 'both'],
        default: 'retail'
    },
    // Location (now filled during profile completion)
    address: {
        street: { type: String },
        city: { type: String, index: true },
        state: { type: String },
        pincode: { type: String, index: true },
        landmark: String
    },
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: {
            type: [Number],  // [longitude, latitude]
            index: '2dsphere'
        }
    },

    // Business Details
    fssaiLicense: {
        number: String,
        expiryDate: Date,
        document: String
    },
    gstNumber: String,
    panNumber: String,

    // Certifications
    certifications: [{
        name: String,
        issuedBy: String,
        issuedDate: Date,
        expiryDate: Date,
        document: String
    }],

    // Images
    profileImage: String,
    farmImages: [String],

    // Verification Status
    verificationStatus: {
        type: String,
        enum: ['pending', 'under-review', 'approved', 'rejected'],
        default: 'pending'
    },
    verifiedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Admin'
    },
    verifiedAt: Date,
    rejectionReason: String,

    // Badges & Ratings
    badges: [{
        type: String,
        enum: ['verified', 'organic-certified', 'premium-seller', 'top-rated', 'fast-delivery']
    }],
    averageRating: {
        type: Number,
        default: 0,
        min: 0,
        max: 5
    },
    totalReviews: {
        type: Number,
        default: 0
    },

    // Business Metrics
    totalOrders: {
        type: Number,
        default: 0
    },
    totalRevenue: {
        type: Number,
        default: 0
    },

    // Operating Hours
    operatingHours: {
        monday: { open: String, close: String, isOpen: Boolean },
        tuesday: { open: String, close: String, isOpen: Boolean },
        wednesday: { open: String, close: String, isOpen: Boolean },
        thursday: { open: String, close: String, isOpen: Boolean },
        friday: { open: String, close: String, isOpen: Boolean },
        saturday: { open: String, close: String, isOpen: Boolean },
        sunday: { open: String, close: String, isOpen: Boolean }
    },

    // Store Status
    isStoreOpen: {
        type: Boolean,
        default: true
    },
    vacationMode: {
        isActive: Boolean,
        startDate: Date,
        endDate: Date,
        message: String
    },

    // Delivery Settings
    deliveryRadius: {
        type: Number,
        default: 10  // in kilometers
    },
    minimumOrderValue: {
        type: Number,
        default: 0
    },
    deliveryCharges: {
        type: Number,
        default: 0
    },
    freeDeliveryAbove: Number,

    // Delivery Zones (Advanced)
    deliveryZones: [{
        name: {
            type: String,
            trim: true
        },
        radiusKm: {
            type: Number,
            required: true,
            min: 0.1,
            max: 100
        },
        deliveryCharge: {
            type: Number,
            required: true,
            min: 0
        },
        minimumOrder: {
            type: Number,
            default: 0,
            min: 0
        },
        freeDeliveryAbove: {
            type: Number,
            min: 0
        },
        estimatedDeliveryTime: {
            type: String,
            default: '30-45 mins'
        },
        isActive: {
            type: Boolean,
            default: true
        }
    }],

    // Bank Details
    bankDetails: {
        accountHolderName: String,
        accountNumber: String,
        ifscCode: String,
        bankName: String,
        branch: String
    },

    // Settings
    notificationSettings: {
        push: {
            order: { type: Boolean, default: true },
            payment: { type: Boolean, default: true },
            promotion: { type: Boolean, default: true },
            system: { type: Boolean, default: true },
            lowStock: { type: Boolean, default: true },
            reviews: { type: Boolean, default: true }
        },
        email: {
            order: { type: Boolean, default: true },
            payment: { type: Boolean, default: true },
            lowStock: { type: Boolean, default: true },
            system: { type: Boolean, default: true }
        },
        sms: {
            order: { type: Boolean, default: false },
            urgent: { type: Boolean, default: true }
        }
    },

    // Order Settings
    autoAcceptOrders: {
        type: Boolean,
        default: false
    },
    defaultPrepTime: {
        type: Number,
        default: 30 // in minutes
    },

    // Status
    isActive: {
        type: Boolean,
        default: true
    },
    isBlocked: {
        type: Boolean,
        default: false
    },

    lastLoginAt: Date,
    fcmTokens: [String],
    deviceTokens: [{
        token: String,
        deviceType: { type: String, enum: ['ios', 'android', 'web'] },
        lastUsed: Date
    }]
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// Virtual for dynamic store status
merchantSchema.virtual('isCurrentlyOpen').get(function () {
    // 1. Check if the store is manually closed
    if (!this.isStoreOpen) return false;

    // 2. Check Vacation Mode
    if (this.vacationMode && this.vacationMode.isActive) {
        const now = new Date();
        if (now >= this.vacationMode.startDate && now <= this.vacationMode.endDate) {
            return false;
        }
    }

    // 3. Check Operating Hours
    if (!this.operatingHours) return true;

    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    const now = new Date();
    const dayName = days[now.getDay()];
    const todayHours = this.operatingHours[dayName];

    if (!todayHours || todayHours.isOpen === false) return false;

    if (todayHours.open && todayHours.close) {
        const [openH, openM] = todayHours.open.split(':').map(Number);
        const [closeH, closeM] = todayHours.close.split(':').map(Number);

        const currentTime = now.getHours() * 60 + now.getMinutes();
        const openTime = openH * 60 + openM;
        const closeTime = closeH * 60 + closeM;

        if (currentTime < openTime || currentTime > closeTime) {
            return false;
        }
    }

    return true;
});

// Hash password
merchantSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();
    this.password = await bcrypt.hash(this.password, 12);
    next();
});

// Compare password
merchantSchema.methods.comparePassword = async function (candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

// Text index for search functionality
merchantSchema.index({
    name: 'text',
    businessName: 'text',
    'address.city': 'text',
    businessDescription: 'text'
}, {
    weights: {
        businessName: 10,
        name: 5,
        'address.city': 3,
        businessDescription: 1
    },
    name: 'MerchantSearchIndex'
});

module.exports = mongoose.model('Merchant', merchantSchema);

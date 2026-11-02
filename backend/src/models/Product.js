const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
    // Basic Information
    name: {
        type: String,
        required: true,
        trim: true,
        index: 'text'
    },
    description: {
        type: String,
        required: true,
        maxlength: 1000
    },

    // Merchant
    merchant: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Merchant',
        required: true,
        index: true
    },

    // Category
    category: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category',
        required: true
    },
    subCategory: String,

    // Pricing
    price: {
        type: Number,
        required: true,
        min: 0
    },
    comparePrice: {
        type: Number,  // Original price for discount display
        min: 0
    },
    unit: {
        type: String,
        default: 'kg'
    },

    // Inventory
    stock: {
        type: Number,
        required: true,
        default: 0,
        min: 0
    },
    lowStockThreshold: {
        type: Number,
        default: 10
    },

    // Featured / Promotion
    isFeatured: {
        type: Boolean,
        default: false
    },

    // Product Properties
    tags: [{
        type: String
    }],

    preparationOptions: [{
        type: {
            type: String
        },
        additionalPrice: {
            type: Number,
            default: 0
        }
    }],

    // Images
    images: [{
        url: String,
        publicId: String
    }],
    primaryImage: {
        type: String
    },

    // Nutritional Information (per 100g/ml)
    nutritionalInfo: {
        calories: Number,
        protein: Number,
        carbohydrates: Number,
        fat: Number,
        fiber: Number,
        vitamins: [String]
    },

    // Origin & Quality
    origin: {
        farm: String,
        location: String,
        harvestDate: Date
    },
    qualityCertifications: [{
        name: String,
        document: String
    }],

    // Seasonal Information
    isSeasonal: {
        type: Boolean,
        default: false
    },
    availableMonths: [{
        type: Number,
        min: 1,
        max: 12
    }],

    // Status
    status: {
        type: String,
        enum: ['active', 'out-of-stock', 'coming-soon', 'discontinued'],
        default: 'active'
    },

    // Reviews & Ratings
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

    // Sales Metrics
    totalSales: {
        type: Number,
        default: 0
    },
    views: {
        type: Number,
        default: 0
    },
    dailySales: {
        type: Number,
        default: 0
    },
    dailyViews: {
        type: Number,
        default: 0
    },
    lastDailyActivity: {
        type: String
    },

    // Pre-booking Features
    isPreBookable: {
        type: Boolean,
        default: false
    },
    expectedAvailabilityDate: {
        type: Date
    },

    // Active Status
    isActive: {
        type: Boolean,
        default: true
    },

    // SEO
    slug: {
        type: String,
        unique: true
    },

    // Geographical Location (for proximity discovery)
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: {
            type: [Number], // [longitude, latitude]
            index: '2dsphere'
        }
    }
}, {
    timestamps: true
});

// Create slug before saving
productSchema.pre('save', function (next) {
    if (this.isModified('name') && !this.slug) {
        this.slug = this.name.toLowerCase().replace(/[^a-z0-9]+/g, '-') + '-' + Date.now();
    }
    next();
});

// Indexes
productSchema.index({ name: 'text', description: 'text' });
productSchema.index({ merchant: 1, status: 1 });
productSchema.index({ category: 1, status: 1 });

module.exports = mongoose.model('Product', productSchema);

const mongoose = require('mongoose');

const preBookingSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    product: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: true
    },
    merchant: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Merchant',
        required: true
    },
    quantity: {
        type: Number,
        required: true,
        min: 1
    },
    expectedAvailability: {
        type: Date,
        required: true
    },
    notifyWhenAvailable: {
        type: Boolean,
        default: true
    },
    status: {
        type: String,
        enum: ['pending', 'available', 'ordered', 'cancelled', 'expired'],
        default: 'pending'
    },
    expiryDate: {
        type: Date
    },
    convertedToOrder: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Order'
    },
    notes: {
        type: String,
        maxlength: 500
    }
}, {
    timestamps: true
});

// Indexes for faster queries
preBookingSchema.index({ user: 1, status: 1 });
preBookingSchema.index({ product: 1, status: 1 });
preBookingSchema.index({ merchant: 1, status: 1 });
preBookingSchema.index({ expectedAvailability: 1 });
preBookingSchema.index({ expiryDate: 1 });

// Compound index for checking duplicates
preBookingSchema.index({ user: 1, product: 1, status: 1 });

// Virtual for checking if expired
preBookingSchema.virtual('isExpired').get(function () {
    if (this.status === 'available' && this.expiryDate) {
        return new Date() > this.expiryDate;
    }
    return false;
});

// Method to check and update expiry
preBookingSchema.methods.checkExpiry = function () {
    if (this.status === 'available' && this.expiryDate && new Date() > this.expiryDate) {
        this.status = 'expired';
        return true;
    }
    return false;
};

// Pre-save hook
preBookingSchema.pre('save', function (next) {
    // Ensure expectedAvailability is in the future for new bookings
    if (this.isNew && this.expectedAvailability < new Date()) {
        return next(new Error('Expected availability must be in the future'));
    }
    next();
});

module.exports = mongoose.model('PreBooking', preBookingSchema);

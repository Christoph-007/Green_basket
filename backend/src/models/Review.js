const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
    order: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Order',
        required: true
    },
    customer: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    merchant: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Merchant',
        required: true
    },
    product: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product',
        required: false
    },
    rating: {
        type: Number,
        required: true,
        min: 1,
        max: 5
    },
    comment: {
        type: String,
        maxlength: 500
    },
    images: [String],
    isVerified: {
        type: Boolean,
        default: true  // Auto-verified if from completed order
    },
    helpfulCount: {
        type: Number,
        default: 0
    },
    merchantReply: {
        comment: String,
        repliedAt: Date
    }
}, { timestamps: true });

module.exports = mongoose.model('Review', reviewSchema);

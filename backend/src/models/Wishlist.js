const mongoose = require('mongoose');

const wishlistSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true
    },
    items: [{
        product: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Product',
            required: true
        },
        addedAt: {
            type: Date,
            default: Date.now
        },
        priceWhenAdded: Number,
        notifyOnStock: {
            type: Boolean,
            default: true
        },
        notifyOnPriceDrop: {
            type: Boolean,
            default: true
        },
        notes: String
    }]
}, { timestamps: true });

// Indexes
wishlistSchema.index({ 'items.product': 1 });

module.exports = mongoose.model('Wishlist', wishlistSchema);

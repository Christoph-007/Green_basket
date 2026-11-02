const mongoose = require('mongoose');

const returnSchema = new mongoose.Schema({
    returnId: {
        type: String,
        unique: true
    },
    order: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Order',
        required: true
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    items: [{
        product: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Product'
        },
        quantity: Number,
        reason: String,
        condition: {
            type: String,
            enum: ['unopened', 'opened', 'damaged', 'wrong_item']
        }
    }],
    type: {
        type: String,
        enum: ['return', 'exchange'],
        required: true
    },
    reason: {
        type: String,
        required: true
    },
    images: [String],
    exchangeItems: [{
        product: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Product'
        },
        quantity: Number
    }],
    status: {
        type: String,
        enum: ['requested', 'approved', 'pickup_scheduled', 'picked_up', 'processed', 'refunded', 'rejected'],
        default: 'requested'
    },
    refundAmount: Number,
    refundMethod: {
        type: String,
        enum: ['wallet', 'original_payment']
    },
    adminNotes: String,
    rejectionReason: String,
    processedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Admin'
    },
    processedAt: Date
}, { timestamps: true });

returnSchema.pre('save', function (next) {
    if (!this.returnId) {
        this.returnId = `RET-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    }
    next();
});

returnSchema.index({ order: 1 });
returnSchema.index({ user: 1, status: 1 });


module.exports = mongoose.model('Return', returnSchema);

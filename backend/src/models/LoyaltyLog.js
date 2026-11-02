const mongoose = require('mongoose');

const loyaltyLogSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    type: {
        type: String,
        enum: ['earned', 'redeemed', 'expired', 'bonus', 'reversed'],
        required: true
    },
    points: {
        type: Number,
        required: true
    },
    description: String,
    order: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Order'
    },
    metadata: {
        type: Object // Flexible field for future expansion (e.g. source of bonus)
    }
}, { timestamps: true });

module.exports = mongoose.model('LoyaltyLog', loyaltyLogSchema);

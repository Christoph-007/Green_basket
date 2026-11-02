const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        unique: true
    },
    balance: {
        type: Number,
        default: 0,
        min: 0
    },
    transactions: [{
        type: {
            type: String,
            enum: ['credit', 'debit'],
            required: true
        },
        amount: {
            type: Number,
            required: true
        },
        source: {
            type: String,
            enum: ['refund', 'cashback', 'referral', 'payment', 'admin_credit', 'topup'],
            required: true
        },
        description: String,
        orderId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Order'
        },
        paymentId: String,
        referenceId: String,
        balanceBefore: Number,
        balanceAfter: Number,
        status: {
            type: String,
            enum: ['pending', 'completed', 'failed'],
            default: 'completed'
        },
        createdAt: {
            type: Date,
            default: Date.now
        }
    }],
    isLocked: {
        type: Boolean,
        default: false
    },
    lockedReason: String
}, { timestamps: true });

// Indexes
walletSchema.index({ 'transactions.createdAt': -1 });
walletSchema.index({ 'transactions.orderId': 1 });

module.exports = mongoose.model('Wallet', walletSchema);

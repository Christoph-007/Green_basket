const mongoose = require('mongoose');

const payoutSchema = new mongoose.Schema({
    payoutId: {
        type: String,
        unique: true
    },
    merchant: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Merchant',
        required: true
    },
    period: {
        startDate: {
            type: Date,
            required: true
        },
        endDate: {
            type: Date,
            required: true
        }
    },
    totalOrders: {
        type: Number,
        default: 0
    },
    grossRevenue: {
        type: Number,
        default: 0
    },
    platformCommission: {
        rate: Number,
        amount: Number
    },
    deliveryCharges: {
        type: Number,
        default: 0
    },
    refunds: {
        type: Number,
        default: 0
    },
    adjustments: {
        type: Number,
        default: 0
    },
    netAmount: {
        type: Number,
        default: 0
    },
    status: {
        type: String,
        enum: ['pending', 'processing', 'completed', 'failed', 'on_hold'],
        default: 'pending'
    },
    paymentDetails: {
        method: String,
        transactionId: String,
        processedAt: Date,
        failureReason: String,
        bankAccount: {
            accountNumber: String,
            ifscCode: String,
            accountHolderName: String
        }
    },
    breakdown: [{
        orderId: String,
        orderAmount: Number,
        commissionAmount: Number,
        netAmount: Number
    }],
    notes: String
}, { timestamps: true });

payoutSchema.pre('save', async function (next) {
    if (!this.payoutId) {
        this.payoutId = `PAY-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    }
    next();
});

payoutSchema.index({ merchant: 1, status: 1 });
payoutSchema.index({ 'period.startDate': 1, 'period.endDate': 1 });


module.exports = mongoose.model('Payout', payoutSchema);

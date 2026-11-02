const mongoose = require('mongoose');

const disputeSchema = new mongoose.Schema({
    disputeId: {
        type: String,
        unique: true
    },
    order: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Order',
        required: true
    },
    raisedBy: {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            refPath: 'raisedBy.userModel'
        },
        userModel: {
            type: String,
            enum: ['User', 'Merchant']
        }
    },
    category: {
        type: String,
        required: true
    },
    productId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Product'
    },
    description: {
        type: String,
        required: true
    },
    images: [String],
    status: {
        type: String,
        enum: ['open', 'investigating', 'resolved', 'closed', 'escalated'],
        default: 'open'
    },
    resolution: {
        type: {
            type: String,
            enum: ['refund', 'replacement', 'partial_refund', 'compensation', 'no_action']
        },
        amount: Number,
        description: String,
        resolvedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Admin'
        },
        resolvedAt: Date
    },
    conversation: [{
        from: {
            type: mongoose.Schema.Types.ObjectId,
            refPath: 'conversation.fromModel'
        },
        fromModel: {
            type: String,
            enum: ['User', 'Merchant', 'Admin']
        },
        message: String,
        attachments: [String],
        timestamp: {
            type: Date,
            default: Date.now
        }
    }],
    priority: {
        type: String,
        enum: ['low', 'medium', 'high', 'urgent'],
        default: 'medium'
    }
}, { timestamps: true });

// Auto-generate disputeId before save
disputeSchema.pre('save', async function (next) {
    if (!this.disputeId) {
        this.disputeId = `DISP-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    }
    next();
});

// Indexes

disputeSchema.index({ 'raisedBy.user': 1, status: 1 });
disputeSchema.index({ order: 1 });
disputeSchema.index({ status: 1, priority: 1 });

module.exports = mongoose.model('Dispute', disputeSchema);

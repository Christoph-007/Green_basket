const mongoose = require('mongoose');

const ticketSchema = new mongoose.Schema({
    ticketId: {
        type: String,
        unique: true,
        required: true
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    subject: {
        type: String,
        required: true
    },
    category: {
        type: String,
        enum: ['order', 'payment', 'product', 'account', 'other'],
        required: true
    },
    status: {
        type: String,
        enum: ['open', 'pending', 'resolved', 'closed'],
        default: 'open'
    },
    priority: {
        type: String,
        enum: ['low', 'medium', 'high', 'critical'],
        default: 'low'
    },
    relatedOrder: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Order'
    },
    messages: [{
        sender: {
            type: String,
            enum: ['user', 'admin', 'system']
        },
        senderId: mongoose.Schema.Types.ObjectId, // User ID or Admin ID
        message: String,
        timestamp: {
            type: Date,
            default: Date.now
        },
        attachments: [String] // URLs
    }]
}, { timestamps: true });

// Auto-generate ticket ID
ticketSchema.pre('save', function (next) {
    if (!this.ticketId) {
        this.ticketId = 'TKT' + Date.now().toString().slice(-6) + Math.floor(Math.random() * 1000);
    }
    next();
});

module.exports = mongoose.model('Ticket', ticketSchema);

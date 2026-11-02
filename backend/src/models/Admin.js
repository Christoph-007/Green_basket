const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const adminSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true
    },
    password: {
        type: String,
        required: true,
        select: false
    },
    role: {
        type: String,
        enum: ['super-admin', 'admin', 'moderator'],
        default: 'admin'
    },
    permissions: [{
        type: String,
        enum: ['manage-users', 'manage-merchants', 'manage-products', 'manage-orders', 'manage-content', 'view-analytics']
    }],
    isActive: {
        type: Boolean,
        default: true
    },
    lastLoginAt: Date
}, {
    timestamps: true
});

// Hash password
adminSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();
    this.password = await bcrypt.hash(this.password, 12);
    next();
});

// Compare password
adminSchema.methods.comparePassword = async function (candidatePassword) {
    return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('Admin', adminSchema);

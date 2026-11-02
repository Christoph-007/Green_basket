const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const MAX_OTP_ATTEMPTS = 5;

const otpSchema = new mongoose.Schema({
    identifier: {
        type: String,
        required: true,
        index: true
    },
    otp: {
        type: String,
        required: true
    },
    purpose: {
        type: String,
        enum: ['password_reset', 'email_verification', 'phone_verification'],
        default: 'password_reset'
    },
    userType: {
        type: String,
        enum: ['user', 'merchant'],
        required: true
    },
    used: {
        type: Boolean,
        default: false
    },
    // Wrong guesses against this OTP; it is invalidated after MAX_OTP_ATTEMPTS
    attempts: {
        type: Number,
        default: 0
    },
    expiresAt: {
        type: Date,
        required: true,
        index: { expires: 0 } // TTL index — auto-delete when expired
    }
}, { timestamps: true });

// Hash OTP before saving
otpSchema.pre('save', async function (next) {
    if (!this.isModified('otp')) return next();
    this.otp = await bcrypt.hash(this.otp, 10);
    next();
});

// Compare plain OTP with hashed
otpSchema.methods.compareOTP = async function (candidateOTP) {
    return bcrypt.compare(candidateOTP, this.otp);
};

// Static: generate a 6-digit OTP, store it, return the plain OTP
otpSchema.statics.generateOTP = async function (identifier, userType, purpose = 'password_reset') {
    // Invalidate any previous unused OTPs for this identifier+purpose
    await this.updateMany(
        { identifier, purpose, used: false },
        { used: true }
    );

    const plainOTP = Math.floor(100000 + Math.random() * 900000).toString();

    await this.create({
        identifier,
        otp: plainOTP,
        purpose,
        userType,
        expiresAt: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    });

    return plainOTP;
};

// Static: verify an OTP
otpSchema.statics.verifyOTP = async function (identifier, candidateOTP, purpose = 'password_reset') {
    const record = await this.findOne({
        identifier,
        purpose,
        used: false,
        expiresAt: { $gt: new Date() }
    }).sort({ createdAt: -1 });

    if (!record) return { valid: false, reason: 'OTP expired or not found' };

    const isMatch = await record.compareOTP(String(candidateOTP));
    if (!isMatch) {
        // Count the wrong guess; burn the OTP after too many so it can't be brute-forced
        record.attempts = (record.attempts || 0) + 1;
        if (record.attempts >= MAX_OTP_ATTEMPTS) record.used = true;
        await record.save();
        return {
            valid: false,
            reason: record.used
                ? 'Too many incorrect attempts. Please request a new OTP.'
                : 'Invalid OTP'
        };
    }

    // Mark as used
    record.used = true;
    await record.save();

    return { valid: true, userType: record.userType };
};

module.exports = mongoose.model('OTP', otpSchema);

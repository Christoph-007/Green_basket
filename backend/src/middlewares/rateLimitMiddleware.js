const rateLimit = require('express-rate-limit');

// General API rate limiter
exports.apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5000, // Increased from 1000 for better experience during dev/high usage
    message: {
        success: false,
        message: 'Too many requests, please try again later.'
    }
});

// Strict limiter for authentication routes
exports.authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 20, // Increased from 5 attempts per hour to 20 per 15 mins
    message: {
        success: false,
        message: 'Too many login attempts, please try again later.'
    }
});

// Order creation limiter
exports.orderLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 3, // 3 orders per minute
    message: {
        success: false,
        message: 'Too many orders, please wait a moment.'
    }
});

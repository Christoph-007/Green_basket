const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Merchant = require('../models/Merchant');
const Admin = require('../models/Admin');

// Verify JWT token
exports.authenticate = async (req, res, next) => {
    try {
        let token;

        // Get token from header
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'Not authorized. Please login.'
            });
        }

        // Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // A refresh token must not work as an access token
        if (decoded.tokenType === 'refresh') {
            return res.status(401).json({ success: false, message: 'Invalid or expired token' });
        }

        // Get user based on userType
        let user;
        if (decoded.userType === 'user') {
            user = await User.findById(decoded.id);
        } else if (decoded.userType === 'merchant') {
            user = await Merchant.findById(decoded.id);
        } else if (decoded.userType === 'admin') {
            user = await Admin.findById(decoded.id);
        }

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'User not found'
            });
        }

        if (user.isBlocked) {
            return res.status(403).json({
                success: false,
                message: 'Account has been blocked'
            });
        }

        // Attach user to request
        req.user = user;
        req.userType = decoded.userType;

        next();
    } catch (error) {
        return res.status(401).json({
            success: false,
            message: 'Invalid or expired token',
            error: error.message
        });
    }
};

// Check if user is merchant
exports.isMerchant = (req, res, next) => {
    if (req.userType !== 'merchant') {
        return res.status(403).json({
            success: false,
            message: 'Access denied. Merchants only.'
        });
    }

    if (req.user.verificationStatus !== 'approved') {
        return res.status(403).json({
            success: false,
            message: 'Merchant account not yet approved'
        });
    }

    next();
};

// Check if user is admin
exports.isAdmin = (req, res, next) => {
    if (req.userType !== 'admin') {
        return res.status(403).json({
            success: false,
            message: 'Access denied. Admins only.'
        });
    }
    next();
};

// Check if user is customer
exports.isUser = (req, res, next) => {
    if (req.userType !== 'user') {
        return res.status(403).json({
            success: false,
            message: 'Access denied. Customers only.'
        });
    }
    next();
};

// Restrict to specific user types
exports.restrictTo = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.userType)) {
            return res.status(403).json({
                success: false,
                message: `Access denied. Only ${roles.join(', ')} can access this resource.`
            });
        }

        // Additional check for merchants
        if (req.userType === 'merchant' && req.user.verificationStatus !== 'approved') {
            return res.status(403).json({
                success: false,
                message: 'Merchant account not yet approved'
            });
        }

        next();
    };
};

// Optional authentication - doesn't fail if no token
exports.optionalAuthenticate = async (req, res, next) => {
    try {
        let token;
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) {
            return next();
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        let user;
        if (decoded.userType === 'user') {
            user = await User.findById(decoded.id);
        } else if (decoded.userType === 'merchant') {
            user = await Merchant.findById(decoded.id);
        } else if (decoded.userType === 'admin') {
            user = await Admin.findById(decoded.id);
        }

        if (user && !user.isBlocked) {
            req.user = user;
            req.userType = decoded.userType;
        }

        next();
    } catch (error) {
        // If token is invalid, just proceed as unauthenticated
        next();
    }
};

// Alias for authenticate (commonly used as 'protect')
exports.protect = exports.authenticate;

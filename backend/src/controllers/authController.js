const User = require('../models/User');
const Merchant = require('../models/Merchant');
const Admin = require('../models/Admin');
const OTP = require('../models/OTP');
const generateToken = require('../utils/generateToken');
const { addContactToSendGrid } = require('../services/sendgridContactService');
const notify = require('../services/notify');
const jwt = require('jsonwebtoken');

// Helper: generate a long-lived refresh token
const refreshSecret = () => process.env.REFRESH_TOKEN_SECRET || process.env.JWT_SECRET;

const generateRefreshToken = (id, userType) => {
    return jwt.sign(
        { id, userType, tokenType: 'refresh' },
        refreshSecret(),
        { expiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN || '30d' }
    );
};

// Response payloads shared by login and OTP verification
const userPayload = (u) => ({
    id: u._id,
    name: u.name,
    email: u.email,
    phone: u.phone,
    profileImage: u.profileImage,
    loyaltyPoints: u.loyaltyPoints,
    location: u.location && u.location.coordinates && u.location.coordinates.length === 2
        ? { lat: u.location.coordinates[1], lng: u.location.coordinates[0] }
        : null
});

const merchantPayload = (m) => ({
    id: m._id,
    name: m.name,
    email: m.email,
    businessName: m.businessName,
    verificationStatus: m.verificationStatus,
    isStoreOpen: m.isStoreOpen
});

// Find a customer or merchant account by email (emails are unique across both)
const findAccountByEmail = async (email) => {
    const normalized = (email || '').toLowerCase().trim();
    if (!normalized) return null;
    const user = await User.findOne({ email: normalized });
    if (user) return { account: user, userType: 'user' };
    const merchant = await Merchant.findOne({ email: normalized });
    if (merchant) return { account: merchant, userType: 'merchant' };
    return null;
};

// Generate and send an email-verification OTP (email + SMS). Never throws.
const sendVerificationOtp = async (account, userType) => {
    try {
        const plainOTP = await OTP.generateOTP(account.email.toLowerCase(), userType, 'email_verification');
        await Promise.allSettled([
            notify.email({
                to: account.email,
                subject: 'Verify your email — Green Basket',
                template: 'otpCode',
                data: { name: account.name, otp: plainOTP, isVerification: true, year: new Date().getFullYear() }
            }),
            notify.sms(account.phone, `Your Green Basket verification code is: ${plainOTP}. It expires in 10 minutes.`)
        ]);
        return true;
    } catch (error) {
        console.error('Verification OTP error:', error.message);
        return false;
    }
};

// ─────────────────────────────────────────────────────────────
// UNIFIED LOGIN  –  POST /api/auth/login
// Accepts email + password, auto-detects role from DB,
// returns { token, refreshToken, role, user }
// ─────────────────────────────────────────────────────────────
exports.unifiedLogin = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Email and password are required'
            });
        }

        // ── 1. Try Customer (User) ──────────────────────────────
        const userRecord = await User.findOne({ email: email.toLowerCase() }).select('+password');
        if (userRecord) {
            const isMatch = await userRecord.comparePassword(password);
            if (!isMatch) {
                return res.status(401).json({ success: false, message: 'Invalid email or password' });
            }
            if (userRecord.isBlocked) {
                return res.status(403).json({ success: false, message: 'Your account has been blocked. Please contact support.' });
            }
            userRecord.lastLoginAt = new Date();
            await userRecord.save({ validateBeforeSave: false });
            const token = generateToken(userRecord._id, 'user');
            const refreshToken = generateRefreshToken(userRecord._id, 'user');
            return res.json({
                success: true,
                message: 'Login successful',
                token,
                refreshToken,
                role: 'customer',
                user: userPayload(userRecord)
            });
        }

        // ── 2. Try Merchant ─────────────────────────────────────
        const merchantRecord = await Merchant.findOne({ email: email.toLowerCase() }).select('+password');
        if (merchantRecord) {
            const isMatch = await merchantRecord.comparePassword(password);
            if (!isMatch) {
                return res.status(401).json({ success: false, message: 'Invalid email or password' });
            }
            if (merchantRecord.isBlocked) {
                return res.status(403).json({ success: false, message: 'Your account has been blocked.' });
            }
            merchantRecord.lastLoginAt = new Date();
            await merchantRecord.save({ validateBeforeSave: false });
            const token = generateToken(merchantRecord._id, 'merchant');
            const refreshToken = generateRefreshToken(merchantRecord._id, 'merchant');
            return res.json({
                success: true,
                message: 'Login successful',
                token,
                refreshToken,
                role: 'merchant',
                user: merchantPayload(merchantRecord)
            });
        }

        // ── 3. Try Admin ────────────────────────────────────────
        const adminRecord = await Admin.findOne({ email: email.toLowerCase() }).select('+password');
        if (adminRecord) {
            const isMatch = await adminRecord.comparePassword(password);
            if (!isMatch) {
                return res.status(401).json({ success: false, message: 'Invalid email or password' });
            }
            adminRecord.lastLoginAt = new Date();
            await adminRecord.save({ validateBeforeSave: false });
            const token = generateToken(adminRecord._id, 'admin');
            const refreshToken = generateRefreshToken(adminRecord._id, 'admin');
            return res.json({
                success: true,
                message: 'Login successful',
                token,
                refreshToken,
                role: 'admin',
                user: {
                    id: adminRecord._id,
                    name: adminRecord.name,
                    email: adminRecord.email,
                    role: adminRecord.role,
                    permissions: adminRecord.permissions
                }
            });
        }

        // ── 4. Email not found in any collection ────────────────
        return res.status(404).json({
            success: false,
            message: 'No account found with this email address'
        });

    } catch (error) {
        console.error('Unified login error:', error);
        res.status(500).json({
            success: false,
            message: 'Login failed. Please try again.',
            error: error.message
        });
    }
};

// User Signup
exports.userSignup = async (req, res) => {
    try {
        const { name, email, phone, password } = req.body;

        // Email/phone must be unique across customers AND merchants, otherwise
        // email-based login/OTP/password reset can't tell the accounts apart
        const normalizedEmail = (email || '').toLowerCase();
        const [existingUser, existingMerchant] = await Promise.all([
            User.findOne({ $or: [{ email: normalizedEmail }, { phone }] }),
            Merchant.findOne({ $or: [{ email: normalizedEmail }, { phone }] })
        ]);
        if (existingUser || existingMerchant) {
            return res.status(400).json({
                success: false,
                message: 'User already exists with this email or phone'
            });
        }

        // Create user
        const user = await User.create({
            name,
            email,
            phone,
            password
        });

        // Send the email-verification OTP the app's OTP screen asks for
        await sendVerificationOtp(user, 'user');

        // Add to SendGrid Contacts (non-blocking)
        addContactToSendGrid({
            name: user.name,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName
        }).catch(console.error);

        // Welcome SMS (non-blocking)
        notify.sms(user.phone, `Welcome to Green Basket, ${user.name}! 🌿 Enter the code we emailed you to verify your account.`).catch(() => {});

        // Welcome email via SendGrid template (non-blocking)
        notify.email({
            to: user.email,
            subject: 'Welcome to Green Basket! 🌿',
            template: 'welcome',
            data: { name: user.name, year: new Date().getFullYear() }
        }).catch(() => {});

        // Generate auth token
        const token = generateToken(user._id, 'user');

        res.status(201).json({
            success: true,
            message: 'User registered successfully. Enter the OTP sent to your email to verify it.',
            data: {
                user: {
                    id: user._id,
                    name: user.name,
                    email: user.email,
                    phone: user.phone
                },
                token
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error in user signup',
            error: error.message
        });
    }
};

// User Login
exports.userLogin = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Find user with password field
        const user = await User.findOne({ email }).select('+password');

        if (!user || !(await user.comparePassword(password))) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }

        if (user.isBlocked) {
            return res.status(403).json({
                success: false,
                message: 'Your account has been blocked. Please contact support.'
            });
        }

        // Update last login
        user.lastLoginAt = new Date();
        await user.save({ validateBeforeSave: false });

        // Generate token
        const token = generateToken(user._id, 'user');

        res.json({
            success: true,
            message: 'Login successful',
            data: {
                user: {
                    id: user._id,
                    name: user.name,
                    email: user.email,
                    phone: user.phone,
                    profileImage: user.profileImage,
                    loyaltyPoints: user.loyaltyPoints,
                    location: user.location && user.location.coordinates && user.location.coordinates.length === 2
                        ? { lat: user.location.coordinates[1], lng: user.location.coordinates[0] }
                        : null
                },
                token
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error in user login',
            error: error.message
        });
    }
};

// Merchant Signup
exports.merchantSignup = async (req, res) => {
    try {
        const { name, email, phone, password, businessName, merchantType } = req.body;

        // Check existing merchant AND user (cross-collection unique check for email/phone)
        const User = require('../models/User');
        const [existingMerchant, existingUser] = await Promise.all([
            Merchant.findOne({ $or: [{ email: email.toLowerCase() }, { phone }] }),
            User.findOne({ $or: [{ email: email.toLowerCase() }, { phone }] })
        ]);

        if (existingMerchant || existingUser) {
            return res.status(400).json({
                success: false,
                message: 'An account with this email or phone already exists'
            });
        }

        // Create merchant with sensible defaults if fields are missing from frontend
        const merchant = await Merchant.create({
            name,
            email: email.toLowerCase(),
            phone,
            password,
            businessName: businessName || `${name}'s Store`,
            merchantType: merchantType || 'local-farmer',
            verificationStatus: 'pending',
            // Provide a partial empty address if not sent
            address: {
                street: 'Pending',
                city: 'Pending',
                state: 'Pending',
                pincode: '000000'
            }
        });

        const token = generateToken(merchant._id, 'merchant');

        // Welcome email + SMS (non-blocking)
        notify.email({
            to: merchant.email,
            subject: 'Welcome to Green Basket — Merchant Registration',
            template: 'merchantWelcome',
            data: { merchantName: merchant.name, businessName: merchant.businessName, year: new Date().getFullYear() }
        }).catch(() => {});

        notify.sms(merchant.phone, `Welcome to Green Basket, ${merchant.name}! Your merchant application for "${merchant.businessName}" is pending review. We'll notify you once approved.`).catch(() => {});

        await sendVerificationOtp(merchant, 'merchant');

        res.status(201).json({
            success: true,
            message: 'Merchant registered. Waiting for admin approval.',
            data: {
                merchant: {
                    id: merchant._id,
                    name: merchant.name,
                    businessName: merchant.businessName,
                    verificationStatus: merchant.verificationStatus
                },
                token
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error in merchant signup',
            error: error.message
        });
    }
};

// Merchant Login
exports.merchantLogin = async (req, res) => {
    try {
        const { email, password } = req.body;

        const merchant = await Merchant.findOne({ email }).select('+password');

        if (!merchant || !(await merchant.comparePassword(password))) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }

        if (merchant.isBlocked) {
            return res.status(403).json({
                success: false,
                message: 'Your account has been blocked.'
            });
        }

        merchant.lastLoginAt = new Date();
        await merchant.save({ validateBeforeSave: false });

        const token = generateToken(merchant._id, 'merchant');

        res.json({
            success: true,
            message: 'Login successful',
            data: {
                merchant: {
                    id: merchant._id,
                    name: merchant.name,
                    businessName: merchant.businessName,
                    verificationStatus: merchant.verificationStatus,
                    isStoreOpen: merchant.isStoreOpen
                },
                token
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error in merchant login',
            error: error.message
        });
    }
};

// Admin Login
exports.adminLogin = async (req, res) => {
    try {
        const { email, password } = req.body;

        const admin = await Admin.findOne({ email }).select('+password');

        if (!admin || !(await admin.comparePassword(password))) {
            return res.status(401).json({
                success: false,
                message: 'Invalid credentials'
            });
        }

        admin.lastLoginAt = new Date();
        await admin.save({ validateBeforeSave: false });

        const token = generateToken(admin._id, 'admin');

        res.json({
            success: true,
            message: 'Admin login successful',
            data: {
                admin: {
                    id: admin._id,
                    name: admin.name,
                    role: admin.role,
                    permissions: admin.permissions
                },
                token
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error in admin login',
            error: error.message
        });
    }
};

// Verify Email
exports.verifyEmail = async (req, res) => {
    try {
        const { token } = req.body;

        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        const user = await User.findById(decoded.id);
        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        user.isEmailVerified = true;
        await user.save();

        res.json({
            success: true,
            message: 'Email verified successfully'
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: 'Invalid or expired verification token'
        });
    }
};

// Forgot Password (OTP-based — works for Users)
exports.forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ success: false, message: 'Email is required' });
        }

        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user) {
            return res.status(404).json({ success: false, message: 'No account found with this email' });
        }

        // Generate 6-digit OTP, hash & store
        const plainOTP = await OTP.generateOTP(email.toLowerCase(), 'user', 'password_reset');

        // Send OTP via email AND SMS in parallel
        await Promise.allSettled([
            notify.email({
                to: user.email,
                subject: 'Your Password Reset OTP — Green Basket',
                template: 'otpCode',
                data: { name: user.name, otp: plainOTP, year: new Date().getFullYear() }
            }),
            notify.sms(user.phone, `Your Green Basket password reset OTP is: ${plainOTP}. It expires in 10 minutes. Do not share this code.`)
        ]);

        res.json({
            success: true,
            message: 'OTP sent to your registered email and phone number'
        });
    } catch (error) {
        console.error('Forgot password error:', error);
        res.status(500).json({ success: false, message: 'Error sending OTP', error: error.message });
    }
};

// Reset Password (OTP verification — Users)
exports.resetPassword = async (req, res) => {
    try {
        const { email, otp, newPassword } = req.body;

        if (!email || !otp || !newPassword) {
            return res.status(400).json({ success: false, message: 'Email, OTP, and new password are required' });
        }

        // Verify OTP
        const result = await OTP.verifyOTP(email.toLowerCase(), otp, 'password_reset');
        if (!result.valid) {
            return res.status(400).json({ success: false, message: result.reason });
        }

        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        user.password = newPassword;
        user.passwordChangedAt = new Date();
        await user.save();

        // Confirmation notifications (non-blocking)
        notify.email({
            to: user.email,
            subject: 'Password Changed Successfully — Green Basket',
            template: 'generic',
            data: { title: 'Password Changed', message: 'Your password has been successfully reset. If you did not make this change, contact support immediately.' }
        }).catch(() => {});

        notify.sms(user.phone, 'Your Green Basket password has been changed successfully. If this wasn\'t you, contact support immediately.').catch(() => {});

        res.json({ success: true, message: 'Password reset successful' });
    } catch (error) {
        console.error('Reset password error:', error);
        res.status(400).json({ success: false, message: 'Password reset failed', error: error.message });
    }
};

// Forgot Password (OTP-based — Merchants)
exports.merchantForgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ success: false, message: 'Email is required' });
        }

        const merchant = await Merchant.findOne({ email: email.toLowerCase() });
        if (!merchant) {
            return res.status(404).json({ success: false, message: 'No merchant account found with this email' });
        }

        const plainOTP = await OTP.generateOTP(email.toLowerCase(), 'merchant', 'password_reset');

        await Promise.allSettled([
            notify.email({
                to: merchant.email,
                subject: 'Your Password Reset OTP — Green Basket Merchant',
                template: 'otpCode',
                data: { name: merchant.name, otp: plainOTP, year: new Date().getFullYear() }
            }),
            notify.sms(merchant.phone, `Your Green Basket merchant password reset OTP is: ${plainOTP}. It expires in 10 minutes.`)
        ]);

        res.json({ success: true, message: 'OTP sent to your registered email and phone number' });
    } catch (error) {
        console.error('Merchant forgot password error:', error);
        res.status(500).json({ success: false, message: 'Error sending OTP', error: error.message });
    }
};

// Reset Password (OTP verification — Merchants)
exports.merchantResetPassword = async (req, res) => {
    try {
        const { email, otp, newPassword } = req.body;

        if (!email || !otp || !newPassword) {
            return res.status(400).json({ success: false, message: 'Email, OTP, and new password are required' });
        }

        const result = await OTP.verifyOTP(email.toLowerCase(), otp, 'password_reset');
        if (!result.valid) {
            return res.status(400).json({ success: false, message: result.reason });
        }

        const merchant = await Merchant.findOne({ email: email.toLowerCase() });
        if (!merchant) {
            return res.status(404).json({ success: false, message: 'Merchant not found' });
        }

        merchant.password = newPassword;
        merchant.passwordChangedAt = new Date();
        await merchant.save();

        notify.email({
            to: merchant.email,
            subject: 'Password Changed Successfully — Green Basket',
            template: 'generic',
            data: { title: 'Password Changed', message: 'Your merchant account password has been successfully reset. If you did not make this change, contact support immediately.' }
        }).catch(() => {});

        notify.sms(merchant.phone, 'Your Green Basket merchant password has been changed successfully. If this wasn\'t you, contact support immediately.').catch(() => {});

        res.json({ success: true, message: 'Password reset successful' });
    } catch (error) {
        console.error('Merchant reset password error:', error);
        res.status(400).json({ success: false, message: 'Password reset failed', error: error.message });
    }
};

// Refresh Token
// ─────────────────────────────────────────────────────────────
// EMAIL OTP VERIFICATION  –  used by the app's OTP screen after signup
// POST /api/auth/verify-otp  { email, otp }  →  { token, refreshToken, role, user }
// ─────────────────────────────────────────────────────────────
exports.verifyOtp = async (req, res) => {
    try {
        const { email, otp } = req.body;
        if (!email || !otp) {
            return res.status(400).json({ success: false, message: 'Email and OTP are required' });
        }

        const found = await findAccountByEmail(email);
        if (!found) {
            return res.status(404).json({ success: false, message: 'No account found with this email' });
        }

        const result = await OTP.verifyOTP(email.toLowerCase().trim(), otp, 'email_verification');
        if (!result.valid) {
            return res.status(400).json({ success: false, message: result.reason });
        }

        const { account, userType } = found;
        if (account.isBlocked) {
            return res.status(403).json({ success: false, message: 'Your account has been blocked. Please contact support.' });
        }

        account.isEmailVerified = true;
        account.lastLoginAt = new Date();
        await account.save({ validateBeforeSave: false });

        return res.json({
            success: true,
            message: 'Email verified successfully',
            token: generateToken(account._id, userType),
            refreshToken: generateRefreshToken(account._id, userType),
            role: userType === 'merchant' ? 'merchant' : 'customer',
            user: userType === 'merchant' ? merchantPayload(account) : userPayload(account)
        });
    } catch (error) {
        console.error('Verify OTP error:', error);
        res.status(500).json({ success: false, message: 'OTP verification failed', error: error.message });
    }
};

// POST /api/auth/resend-otp  { email }
exports.resendOtp = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ success: false, message: 'Email is required' });
        }
        const found = await findAccountByEmail(email);
        if (!found) {
            return res.status(404).json({ success: false, message: 'No account found with this email' });
        }
        if (found.account.isEmailVerified) {
            return res.status(400).json({ success: false, message: 'Email is already verified. Please log in.' });
        }
        await sendVerificationOtp(found.account, found.userType);
        res.json({ success: true, message: 'A new OTP has been sent to your email' });
    } catch (error) {
        console.error('Resend OTP error:', error);
        res.status(500).json({ success: false, message: 'Failed to resend OTP', error: error.message });
    }
};

// ─────────────────────────────────────────────────────────────
// ROLE-AGNOSTIC PASSWORD RESET  –  the app has one forgot-password screen
// for customers and merchants; route to the right handler by email.
// POST /api/auth/forgot-password  { email }
// POST /api/auth/reset-password   { email, otp, newPassword }
// ─────────────────────────────────────────────────────────────
exports.forgotPasswordAnyRole = async (req, res) => {
    const found = await findAccountByEmail(req.body && req.body.email).catch(() => null);
    if (found && found.userType === 'merchant') return exports.merchantForgotPassword(req, res);
    return exports.forgotPassword(req, res);
};

exports.resetPasswordAnyRole = async (req, res) => {
    const found = await findAccountByEmail(req.body && req.body.email).catch(() => null);
    if (found && found.userType === 'merchant') return exports.merchantResetPassword(req, res);
    return exports.resetPassword(req, res);
};

exports.refreshToken = async (req, res) => {
    try {
        const refreshToken = req.body.refreshToken || req.body.token;
        if (!refreshToken) {
            return res.status(400).json({ success: false, message: 'Refresh token is required' });
        }

        const decoded = jwt.verify(refreshToken, refreshSecret());
        // Only refresh tokens may refresh. Older refresh tokens had no
        // tokenType; accept those only when a separate refresh secret proves
        // they weren't access tokens.
        const separateSecret = process.env.REFRESH_TOKEN_SECRET && process.env.REFRESH_TOKEN_SECRET !== process.env.JWT_SECRET;
        if (decoded.tokenType !== 'refresh' && !(decoded.tokenType === undefined && separateSecret)) {
            return res.status(401).json({ success: false, message: 'Invalid or expired refresh token' });
        }

        // The account must still exist and not be blocked
        const Model = decoded.userType === 'merchant' ? Merchant : decoded.userType === 'admin' ? Admin : User;
        const account = await Model.findById(decoded.id);
        if (!account || account.isBlocked) {
            return res.status(401).json({ success: false, message: 'Invalid or expired refresh token' });
        }

        const newToken = generateToken(decoded.id, decoded.userType);
        const newRefreshToken = generateRefreshToken(decoded.id, decoded.userType);

        res.json({
            success: true,
            token: newToken,
            refreshToken: newRefreshToken
        });
    } catch (error) {
        res.status(401).json({
            success: false,
            message: 'Invalid or expired refresh token'
        });
    }
};

// Logout
exports.logout = async (req, res) => {
    res.json({
        success: true,
        message: 'Logged out successfully'
    });
};

const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { validateSignup, validateLogin } = require('../utils/validators');
const { validate } = require('../middlewares/validationMiddleware');
const { authLimiter } = require('../middlewares/rateLimitMiddleware');

// ─────────────────────────────────────────────────────────────
// UNIFIED LOGIN  –  single endpoint for all user types
// POST /api/auth/login  →  { token, role, user }
// ─────────────────────────────────────────────────────────────
router.post('/login', authController.unifiedLogin);

// User Authentication
router.post('/user/signup', validateSignup, validate, authController.userSignup);
router.post('/user/login', validateLogin, validate, authController.userLogin);
router.post('/user/verify-email', authController.verifyEmail);
router.post('/user/forgot-password', authController.forgotPassword);
router.post('/user/reset-password', authController.resetPassword);

// Merchant Authentication

router.post('/merchant/signup', validateSignup, validate, authController.merchantSignup);
router.post('/merchant/login', validateLogin, validate, authController.merchantLogin);
router.post('/merchant/forgot-password', authController.merchantForgotPassword);
router.post('/merchant/reset-password', authController.merchantResetPassword);

// Email verification by OTP (used by the app's OTP screen after signup)
router.post('/verify-otp', authLimiter, authController.verifyOtp);
router.post('/resend-otp', authLimiter, authController.resendOtp);

// Password reset for any role (the app has a single forgot-password screen)
router.post('/forgot-password', authLimiter, authController.forgotPasswordAnyRole);
router.post('/reset-password', authLimiter, authController.resetPasswordAnyRole);

// Admin Authentication
router.post('/admin/login', validateLogin, validate, authController.adminLogin);

// Token Management
router.post('/refresh-token', authController.refreshToken);
router.post('/logout', authController.logout);

module.exports = router;

const User = require('../models/User');
const Order = require('../models/Order');
const crypto = require('crypto');
const REFERRAL_CONFIG = require('../config/referral');
const { addReferralBonus } = require('../utils/walletHelpers');
const notificationService = require('../services/notification');

/**
 * Generate a unique referral code based on user name
 * @param {String} userName - User's name
 * @returns {String} - Unique referral code
 */
const generateUniqueCode = async (userName) => {
    const prefix = REFERRAL_CONFIG.codePrefix;

    // Extract alphanumeric characters from name (first 4 chars)
    const namePart = userName
        .replace(/[^a-zA-Z0-9]/g, '')
        .toUpperCase()
        .slice(0, 4)
        .padEnd(4, 'X'); // Pad with X if name is too short

    // Generate random part (4 characters)
    const randomPart = crypto
        .randomBytes(3)
        .toString('hex')
        .toUpperCase()
        .slice(0, 4);

    const code = `${prefix}${namePart}${randomPart}`;

    // Check if code already exists
    const existingUser = await User.findOne({ 'referral.code': code });
    if (existingUser) {
        // Recurse if collision (very rare)
        return generateUniqueCode(userName);
    }

    return code;
};

/**
 * @desc    Generate referral code for user
 * @route   POST /api/referral/generate
 * @access  Private (User)
 */
exports.generateReferralCode = async (req, res) => {
    try {
        const user = await User.findById(req.user._id);

        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        // Return existing code if already generated
        if (user.referral && user.referral.code) {
            return res.json({
                success: true,
                data: {
                    referralCode: user.referral.code,
                    referralLink: `${process.env.FRONTEND_URL}/signup?ref=${user.referral.code}`,
                    shareText: `Join Green Basket and get ₹${REFERRAL_CONFIG.referredBonus} off your first order! Use my referral code ${user.referral.code}`
                }
            });
        }

        // Generate new code
        const code = await generateUniqueCode(user.name);

        if (!user.referral) {
            user.referral = {};
        }

        user.referral.code = code;
        await user.save();

        res.json({
            success: true,
            data: {
                referralCode: code,
                referralLink: `${process.env.FRONTEND_URL}/signup?ref=${code}`,
                shareText: `Join Green Basket and get ₹${REFERRAL_CONFIG.referredBonus} off your first order! Use my referral code ${code}`
            }
        });
    } catch (error) {
        console.error('Generate referral code error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to generate referral code',
            details: error.message
        });
    }
};

/**
 * @desc    Get referral stats for user
 * @route   GET /api/referral/stats
 * @access  Private (User)
 */
exports.getReferralStats = async (req, res) => {
    try {
        const user = await User.findById(req.user._id)
            .populate({
                path: 'referral.referrals.user',
                select: 'name createdAt'
            });

        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        if (!user.referral || !user.referral.code) {
            return res.json({
                success: true,
                data: {
                    referralCode: null,
                    referralLink: null,
                    stats: {
                        totalReferrals: 0,
                        completedReferrals: 0,
                        pendingReferrals: 0,
                        totalEarned: 0
                    },
                    referrals: []
                }
            });
        }

        const referrals = user.referral.referrals || [];

        const stats = {
            totalReferrals: referrals.length,
            completedReferrals: referrals.filter(r => r.status === 'completed').length,
            pendingReferrals: referrals.filter(r => r.status === 'pending').length,
            totalEarned: user.referral.totalEarned || 0
        };

        const referralDetails = referrals.map(r => ({
            user: r.user ? {
                name: r.user.name,
                joinedAt: r.user.createdAt
            } : { name: 'Unknown', joinedAt: null },
            status: r.status,
            rewardEarned: r.rewardEarned,
            completedAt: r.completedAt,
            createdAt: r.createdAt
        }));

        res.json({
            success: true,
            data: {
                referralCode: user.referral.code,
                referralLink: `${process.env.FRONTEND_URL}/signup?ref=${user.referral.code}`,
                stats,
                referrals: referralDetails
            }
        });
    } catch (error) {
        console.error('Get referral stats error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch referral stats',
            details: error.message
        });
    }
};

/**
 * @desc    Apply referral code during signup
 * @route   POST /api/referral/apply
 * @access  Private (User - called right after signup)
 */
exports.applyReferralCode = async (req, res) => {
    try {
        const { referralCode } = req.body;

        if (!referralCode) {
            return res.status(400).json({
                success: false,
                error: 'Referral code is required'
            });
        }

        const user = await User.findById(req.user._id);

        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        // Check if already referred
        if (user.referral && user.referral.referredBy) {
            return res.status(400).json({
                success: false,
                error: 'Referral code already applied'
            });
        }

        // Find referrer
        const referrer = await User.findOne({
            'referral.code': referralCode.toUpperCase()
        });

        if (!referrer) {
            return res.status(404).json({
                success: false,
                error: 'Invalid referral code'
            });
        }

        // Cannot refer yourself
        if (referrer._id.toString() === req.user._id.toString()) {
            return res.status(400).json({
                success: false,
                error: 'Cannot use your own referral code'
            });
        }

        // Set referral
        if (!user.referral) user.referral = {};
        user.referral.referredBy = referrer._id;
        await user.save();

        // Add to referrer's list
        if (!referrer.referral.referrals) referrer.referral.referrals = [];
        referrer.referral.referrals.push({
            user: user._id,
            status: 'pending',
            rewardEarned: 0
        });
        await referrer.save();

        // Give signup bonus to new user
        await addReferralBonus(
            user._id,
            REFERRAL_CONFIG.referredBonus,
            referrer._id
        );

        // Send notification to new user
        await notificationService.send(
            user._id,
            'User',
            {
                type: 'wallet_credit',
                title: 'Referral Bonus!',
                message: `₹${REFERRAL_CONFIG.referredBonus} has been added to your wallet as referral bonus`,
                channels: ['push', 'email']
            }
        );

        res.json({
            success: true,
            message: 'Referral code applied successfully',
            data: {
                bonus: REFERRAL_CONFIG.referredBonus,
                referrerName: referrer.name
            }
        });
    } catch (error) {
        console.error('Apply referral code error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to apply referral code',
            details: error.message
        });
    }
};

/**
 * @desc    Process referral reward after first order completion
 * @route   POST /api/referral/process-reward
 * @access  Private (System/Admin)
 */
exports.processReferralReward = async (req, res) => {
    try {
        const { userId, orderId, orderAmount } = req.body;

        if (!userId || !orderId || !orderAmount) {
            return res.status(400).json({
                success: false,
                error: 'userId, orderId, and orderAmount are required'
            });
        }

        // Check if order meets minimum requirement
        if (orderAmount < REFERRAL_CONFIG.minOrderForReward) {
            return res.json({
                success: true,
                message: 'Order does not meet minimum amount for referral reward'
            });
        }

        const user = await User.findById(userId);

        if (!user || !user.referral || !user.referral.referredBy) {
            return res.json({
                success: true,
                message: 'User has no referral'
            });
        }

        const referrer = await User.findById(user.referral.referredBy);

        if (!referrer) {
            return res.json({
                success: true,
                message: 'Referrer not found'
            });
        }

        // Find the referral entry
        const referralEntry = referrer.referral.referrals.find(
            r => r.user.toString() === userId
        );

        if (!referralEntry || referralEntry.status === 'completed') {
            return res.json({
                success: true,
                message: 'Referral already processed or not found'
            });
        }

        // Update referral status
        referralEntry.status = 'completed';
        referralEntry.rewardEarned = REFERRAL_CONFIG.referrerBonus;
        referralEntry.firstOrderId = orderId;
        referralEntry.completedAt = new Date();

        referrer.referral.totalEarned =
            (referrer.referral.totalEarned || 0) + REFERRAL_CONFIG.referrerBonus;

        await referrer.save();

        // Credit wallet bonus to referrer
        await addReferralBonus(
            referrer._id,
            REFERRAL_CONFIG.referrerBonus,
            userId
        );

        // Send notification to referrer
        await notificationService.send(
            referrer._id,
            'User',
            {
                type: 'referral_reward',
                title: 'Referral Reward!',
                message: `Your friend placed their first order! ₹${REFERRAL_CONFIG.referrerBonus} has been credited to your wallet`,
                channels: ['push', 'email']
            }
        );

        res.json({
            success: true,
            message: 'Referral reward processed',
            data: {
                referrerBonus: REFERRAL_CONFIG.referrerBonus
            }
        });
    } catch (error) {
        console.error('Process referral reward error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to process referral reward',
            details: error.message
        });
    }
};

/**
 * @desc    Validate referral code
 * @route   GET /api/referral/validate/:code
 * @access  Public
 */
exports.validateReferralCode = async (req, res) => {
    try {
        const { code } = req.params;

        if (!code) {
            return res.status(400).json({
                success: false,
                error: 'Referral code is required'
            });
        }

        const referrer = await User.findOne({
            'referral.code': code.toUpperCase()
        }).select('name');

        if (!referrer) {
            return res.json({
                success: true,
                data: {
                    valid: false,
                    message: 'Invalid referral code'
                }
            });
        }

        // Mask name for privacy: "John D."
        const nameParts = referrer.name.split(' ');
        const maskedName = nameParts[0] + (nameParts[1] ? ` ${nameParts[1][0]}.` : '');

        res.json({
            success: true,
            data: {
                valid: true,
                referrerName: maskedName,
                bonus: REFERRAL_CONFIG.referredBonus
            }
        });
    } catch (error) {
        console.error('Validate referral code error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to validate referral code',
            details: error.message
        });
    }
};

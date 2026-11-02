const crypto = require('crypto');
const User = require('../models/User');
const Offer = require('../models/Offer');
const { LOYALTY_TIERS, getTierFromPoints, getNextTier, getPointsToNextTier } = require('../config/loyaltyTiers');

exports.redeemPoints = async (req, res) => {
    try {
        const points = Number(req.body.points);

        if (!Number.isInteger(points) || points <= 0) {
            return res.status(400).json({
                success: false,
                error: 'Valid points amount is required'
            });
        }

        if (points < 50) {
            return res.status(400).json({
                success: false,
                error: 'Minimum 50 points required for redemption'
            });
        }

        // Deduct atomically, only if the user still has enough points (a double
        // tap used to be able to spend the same points twice)
        const user = await User.findOneAndUpdate(
            { _id: req.user._id, loyaltyPoints: { $gte: points } },
            {
                $inc: { loyaltyPoints: -points },
                $push: {
                    pointsHistory: {
                        type: 'redeemed',
                        points: -points,
                        source: 'redemption',
                        description: 'Points redeemed for a discount coupon'
                    }
                }
            },
            { new: true }
        );

        if (!user) {
            const current = await User.findById(req.user._id);
            return res.status(400).json({
                success: false,
                error: 'Insufficient loyalty points',
                available: current ? current.loyaltyPoints : 0,
                requested: points
            });
        }

        // Update tier if necessary
        const newTier = getTierFromPoints(user.loyaltyPoints);
        if (newTier !== user.loyaltyTier) {
            await User.updateOne({ _id: user._id }, { $set: { loyaltyTier: newTier, tierBenefits: LOYALTY_TIERS[newTier].benefits } });
            user.loyaltyTier = newTier;
        }

        // 1 point = ₹1, as a personal one-time coupon (applied at checkout).
        // Random code + restrictedTo: it can't be guessed or used by others.
        const discountAmount = points;
        const couponCode = `LOYALTY-${crypto.randomBytes(5).toString('hex').toUpperCase()}`;
        await Offer.create({
            title: 'Loyalty Reward',
            description: `Reward for redeeming ${points} loyalty points`,
            couponCode,
            type: 'flat',
            discountAmount,
            minOrderValue: 0,
            startDate: new Date(),
            endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // Valid for 30 days
            usagePerUser: 1,
            totalUsageLimit: 1,
            status: 'active',
            createdBy: 'admin',
            isPublic: false,
            restrictedTo: user._id
        });

        res.json({
            success: true,
            message: 'Points redeemed successfully',
            data: {
                pointsRedeemed: points,
                discountAmount,
                remainingPoints: user.loyaltyPoints,
                currentTier: user.loyaltyTier,
                couponCode
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to redeem points',
            details: error.message
        });
    }
};

exports.getPointsHistory = async (req, res) => {
    try {
        const { page = 1, limit = 20, type } = req.query;

        const user = await User.findById(req.user._id);

        // Filter history
        let history = [...user.pointsHistory];

        if (type) {
            history = history.filter(h => h.type === type);
        }

        // Sort by date (newest first)
        history.sort((a, b) => b.createdAt - a.createdAt);

        // Calculate summary
        const summary = {
            totalEarned: user.pointsHistory
                .filter(h => h.type === 'earned' || h.type === 'bonus')
                .reduce((sum, h) => sum + h.points, 0),
            totalRedeemed: Math.abs(user.pointsHistory
                .filter(h => h.type === 'redeemed')
                .reduce((sum, h) => sum + h.points, 0)),
            totalExpired: Math.abs(user.pointsHistory
                .filter(h => h.type === 'expired')
                .reduce((sum, h) => sum + h.points, 0))
        };

        // Pagination
        const total = history.length;
        const pages = Math.ceil(total / limit);
        const skip = (page - 1) * limit;
        const paginatedHistory = history.slice(skip, skip + parseInt(limit));

        res.json({
            success: true,
            data: {
                currentPoints: user.loyaltyPoints,
                currentTier: user.loyaltyTier,
                nextTier: getNextTier(user.loyaltyTier),
                pointsToNextTier: getPointsToNextTier(user.loyaltyPoints, user.loyaltyTier),
                tierBenefits: user.tierBenefits,
                history: paginatedHistory,
                summary,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to fetch points history',
            details: error.message
        });
    }
};

exports.getTierBenefits = async (req, res) => {
    try {
        const user = await User.findById(req.user._id);

        const currentTierData = LOYALTY_TIERS[user.loyaltyTier];
        const nextTier = getNextTier(user.loyaltyTier);
        const pointsToNext = getPointsToNextTier(user.loyaltyPoints, user.loyaltyTier);

        // Calculate progress percentage
        let progressPercentage = 0;
        if (nextTier) {
            const nextTierData = LOYALTY_TIERS[nextTier];
            const pointsInCurrentTier = user.loyaltyPoints - currentTierData.minPoints;
            const pointsNeededForNextTier = nextTierData.minPoints - currentTierData.minPoints;
            progressPercentage = Math.round((pointsInCurrentTier / pointsNeededForNextTier) * 100);
        } else {
            progressPercentage = 100;
        }

        const allTiers = Object.keys(LOYALTY_TIERS).map(tier => ({
            name: LOYALTY_TIERS[tier].name,
            tier,
            minPoints: LOYALTY_TIERS[tier].minPoints,
            benefits: LOYALTY_TIERS[tier].benefits,
            color: LOYALTY_TIERS[tier].color
        }));

        res.json({
            success: true,
            data: {
                currentTier: {
                    name: currentTierData.name,
                    tier: user.loyaltyTier,
                    minPoints: currentTierData.minPoints,
                    benefits: currentTierData.benefits,
                    color: currentTierData.color
                },
                allTiers,
                progress: {
                    currentPoints: user.loyaltyPoints,
                    nextTier,
                    pointsToNextTier: pointsToNext,
                    progressPercentage
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to fetch tier benefits',
            details: error.message
        });
    }
};

exports.awardPoints = async (req, res) => {
    try {
        const { userId, points, source, description, orderId } = req.body;

        if (!userId || !points || !source) {
            return res.status(400).json({
                success: false,
                error: 'userId, points, and source are required'
            });
        }

        if (points <= 0) {
            return res.status(400).json({
                success: false,
                error: 'Points must be greater than 0'
            });
        }

        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'User not found'
            });
        }

        const previousTier = user.loyaltyTier;

        // Add points
        user.loyaltyPoints += points;

        // Add to history
        user.pointsHistory.push({
            type: 'earned',
            points,
            source,
            description: description || `Points earned from ${source}`,
            orderId
        });

        // Update tier if necessary
        const newTier = getTierFromPoints(user.loyaltyPoints);
        const tierUpgraded = newTier !== previousTier;

        if (tierUpgraded) {
            user.loyaltyTier = newTier;
            user.tierBenefits = LOYALTY_TIERS[newTier].benefits;

            // Send tier upgrade notification
            try {
                const notificationService = require('../services/notification');
                await notificationService.send(
                    userId,
                    'User',
                    {
                        type: 'wallet_credit',
                        title: 'Tier Upgraded!',
                        message: `Congratulations! You've been upgraded to ${LOYALTY_TIERS[newTier].name} tier`,
                        data: {
                            newTier,
                            benefits: LOYALTY_TIERS[newTier].benefits
                        },
                        channels: ['push', 'email']
                    }
                );
            } catch (notifError) {
                console.error('Notification error:', notifError);
            }
        }

        await user.save();

        res.json({
            success: true,
            message: 'Points awarded successfully',
            data: {
                pointsAwarded: points,
                totalPoints: user.loyaltyPoints,
                tier: user.loyaltyTier,
                tierUpgraded
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to award points',
            details: error.message
        });
    }
};

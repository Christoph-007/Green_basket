const Offer = require('../models/Offer');
const Cart = require('../models/Cart');
const Order = require('../models/Order');
const User = require('../models/User');

/**
 * @desc    Create new offer
 * @route   POST /api/offers
 * @access  Private (Merchant/Admin)
 */
exports.createOffer = async (req, res) => {
    try {
        const {
            title, description, type, discountPercentage,
            discountAmount, maxDiscountCap, applicableOn,
            categories, products, minOrderValue,
            startDate, endDate, isFlashSale,
            totalUsageLimit, usagePerUser,
            couponCode, isPublic
        } = req.body;

        // Validation
        if (!title || !type || !startDate || !endDate) {
            return res.status(400).json({
                success: false,
                error: 'title, type, startDate, and endDate are required'
            });
        }

        if (type === 'percentage' && !discountPercentage) {
            return res.status(400).json({
                success: false,
                error: 'discountPercentage is required for percentage type'
            });
        }

        if (type === 'flat' && !discountAmount) {
            return res.status(400).json({
                success: false,
                error: 'discountAmount is required for flat type'
            });
        }

        if (new Date(startDate) >= new Date(endDate)) {
            return res.status(400).json({
                success: false,
                error: 'endDate must be after startDate'
            });
        }

        // Check coupon code uniqueness
        if (couponCode) {
            const existingOffer = await Offer.findOne({
                couponCode: couponCode.toUpperCase()
            });

            if (existingOffer) {
                return res.status(400).json({
                    success: false,
                    error: 'Coupon code already exists'
                });
            }
        }

        // Determine if merchant or admin
        const isAdmin = req.user.userType === 'admin';
        const merchantId = isAdmin ? null : req.user._id;

        const offer = await Offer.create({
            merchant: merchantId,
            createdBy: isAdmin ? 'admin' : 'merchant',
            title,
            description,
            type,
            discountPercentage,
            discountAmount,
            maxDiscountCap,
            applicableOn: applicableOn || 'all',
            categories: categories || [],
            products: products || [],
            minOrderValue: minOrderValue || 0,
            startDate: new Date(startDate),
            endDate: new Date(endDate),
            isFlashSale: isFlashSale || false,
            totalUsageLimit,
            usagePerUser: usagePerUser || 1,
            couponCode: couponCode ? couponCode.toUpperCase() : undefined,
            isPublic: isPublic !== undefined ? isPublic : true,
            status: 'active'
        });

        res.status(201).json({
            success: true,
            message: 'Offer created successfully',
            data: {
                offer: {
                    _id: offer._id,
                    title: offer.title,
                    couponCode: offer.couponCode,
                    status: offer.status,
                    startDate: offer.startDate,
                    endDate: offer.endDate,
                    type: offer.type,
                    isFlashSale: offer.isFlashSale
                }
            }
        });
    } catch (error) {
        console.error('Create offer error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create offer',
            details: error.message
        });
    }
};

/**
 * @desc    Get all offers for merchant
 * @route   GET /api/offers/merchant
 * @access  Private (Merchant)
 */
exports.getMerchantOffers = async (req, res) => {
    try {
        const { status, page = 1, limit = 20 } = req.query;

        const query = { merchant: req.user._id };

        if (status) {
            query.status = status;
        }

        // Auto-expire offers
        await Offer.updateMany(
            {
                merchant: req.user._id,
                endDate: { $lt: new Date() },
                status: 'active'
            },
            { $set: { status: 'expired' } }
        );

        const skip = (page - 1) * limit;

        const [offers, total] = await Promise.all([
            Offer.find(query)
                .populate('categories', 'name')
                .populate('products', 'name')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Offer.countDocuments(query)
        ]);

        console.log(`[OfferController] Found ${offers.length} offers for merchant ${req.user._id}`);


        const offersWithActive = offers.map(o => {
            const obj = o.toObject ? o.toObject({ virtuals: true }) : o;
            return {
                ...obj,
                active: o.status === 'active'
            };
        });

        res.json({
            success: true,
            data: {
                offers: offersWithActive,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });

    } catch (error) {
        console.error('Get merchant offers error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch merchant offers',
            details: error.message
        });
    }
};

/**
 * @desc    Get available offers for user
 * @route   GET /api/offers/available
 * @access  Private (User)
 */
exports.getAvailableOffers = async (req, res) => {
    try {
        const { merchantId, cartTotal } = req.query;

        const query = {
            status: 'active',
            startDate: { $lte: new Date() },
            endDate: { $gte: new Date() },
            isPublic: true
        };

        if (merchantId) {
            query.$or = [
                { merchant: merchantId },
                { merchant: null } // Platform-wide offers
            ];
        }

        const offers = await Offer.find(query)
            .populate('categories', 'name')
            .sort({ createdAt: -1 });

        // Check eligibility for each offer
        const offersWithEligibility = await Promise.all(
            offers.map(async (offer) => {
                let isEligible = true;
                let ineligibleReason = null;

                // Check min order value
                if (cartTotal && offer.minOrderValue > 0) {
                    if (parseFloat(cartTotal) < offer.minOrderValue) {
                        isEligible = false;
                        ineligibleReason = `Minimum order value ₹${offer.minOrderValue} required`;
                    }
                }

                // Check usage per user
                if (offer.usagePerUser && req.user) {
                    const userUsageCount = offer.usedBy.filter(
                        u => u.user.toString() === req.user._id.toString()
                    ).length;

                    if (userUsageCount >= offer.usagePerUser) {
                        isEligible = false;
                        ineligibleReason = 'You have already used this offer';
                    }
                }

                // Check total usage limit
                if (offer.totalUsageLimit && offer.usedCount >= offer.totalUsageLimit) {
                    isEligible = false;
                    ineligibleReason = 'Offer limit reached';
                }

                return {
                    _id: offer._id,
                    title: offer.title,
                    description: offer.description,
                    type: offer.type,
                    discountPercentage: offer.discountPercentage,
                    discountAmount: offer.discountAmount,
                    maxDiscountCap: offer.maxDiscountCap,
                    couponCode: offer.couponCode,
                    minOrderValue: offer.minOrderValue,
                    endDate: offer.endDate,
                    isFlashSale: offer.isFlashSale,
                    isEligible,
                    ineligibleReason
                };
            })
        );

        res.json({
            success: true,
            data: {
                offers: offersWithEligibility
            }
        });
    } catch (error) {
        console.error('Get available offers error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch available offers',
            details: error.message
        });
    }
};

/**
 * @desc    Apply coupon code to cart
 * @route   POST /api/offers/apply-coupon
 * @access  Private (User)
 */
// POST /api/offers/cart/apply-coupon — same as POST /api/cart/coupon. One
// implementation, so both paths apply identical coupon rules.
exports.applyCoupon = async (req, res) => {
    req.body = { ...req.body, code: req.body.code || req.body.couponCode };
    return require('./cartController').applyCoupon(req, res);
};

/**
 * @desc    Remove coupon from cart
 * @route   DELETE /api/offers/remove-coupon
 * @access  Private (User)
 */
// DELETE /api/offers/cart/remove-coupon — same as DELETE /api/cart/coupon
exports.removeCoupon = async (req, res) => require('./cartController').removeCoupon(req, res);

/**
 * @desc    Update offer
 * @route   PUT /api/offers/:id
 * @access  Private (Merchant/Admin - Owner)
 */
exports.updateOffer = async (req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body;

        const offer = await Offer.findById(id);

        if (!offer) {
            return res.status(404).json({
                success: false,
                error: 'Offer not found'
            });
        }

        // Check ownership
        const isAdmin = req.user.userType === 'admin';
        if (!isAdmin && offer.merchant && offer.merchant.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                error: 'You can only update your own offers'
            });
        }

        // Cannot update coupon code if already used
        if (updates.couponCode && offer.usedCount > 0) {
            return res.status(400).json({
                success: false,
                error: 'Cannot update coupon code of an offer that has been used'
            });
        }

        // Check if coupon code unique (if changing)
        if (updates.couponCode && updates.couponCode !== offer.couponCode) {
            const existingOffer = await Offer.findOne({
                couponCode: updates.couponCode.toUpperCase(),
                _id: { $ne: id }
            });

            if (existingOffer) {
                return res.status(400).json({
                    success: false,
                    error: 'Coupon code already exists'
                });
            }
        }

        const allowedUpdates = [
            'title', 'description', 'discountPercentage', 'discountAmount',
            'maxDiscountCap', 'applicableOn', 'categories', 'products',
            'minOrderValue', 'startDate', 'endDate', 'totalUsageLimit',
            'usagePerUser', 'couponCode', 'isPublic', 'status'
        ];

        allowedUpdates.forEach(field => {
            if (updates[field] !== undefined) {
                offer[field] = updates[field];
            }
        });

        await offer.save();

        res.json({
            success: true,
            message: 'Offer updated successfully',
            data: { offer }
        });
    } catch (error) {
        console.error('Update offer error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update offer',
            details: error.message
        });
    }
};

/**
 * @desc    Delete/Deactivate offer
 * @route   DELETE /api/offers/:id
 * @access  Private (Merchant/Admin)
 */
exports.deleteOffer = async (req, res) => {
    try {
        const { id } = req.params;

        const offer = await Offer.findById(id);

        if (!offer) {
            return res.status(404).json({
                success: false,
                error: 'Offer not found'
            });
        }

        const isAdmin = req.user.userType === 'admin';
        if (!isAdmin && offer.merchant && offer.merchant.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                error: 'You can only delete your own offers'
            });
        }

        await offer.deleteOne();

        res.json({
            success: true,
            message: 'Offer deactivated successfully'
        });
    } catch (error) {
        console.error('Delete offer error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete offer',
            details: error.message
        });
    }
};

/**
 * @desc    Get offer analytics
 * @route   GET /api/offers/:id/analytics
 * @access  Private (Merchant/Admin)
 */
exports.getOfferAnalytics = async (req, res) => {
    try {
        const { id } = req.params;

        const offer = await Offer.findById(id)
            .populate('usedBy.orderId', 'totalAmount createdAt')
            .populate('usedBy.user', 'name');

        if (!offer) {
            return res.status(404).json({
                success: false,
                error: 'Offer not found'
            });
        }

        const isAdmin = req.user.userType === 'admin';
        if (!isAdmin && offer.merchant && offer.merchant.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                error: 'Access denied'
            });
        }

        const usedBy = offer.usedBy;
        const totalDiscountGiven = usedBy.reduce((sum, u) => sum + (u.discountAmount || 0), 0);
        const totalRevenueGenerated = usedBy.reduce((sum, u) => {
            return sum + (u.orderId ? u.orderId.totalAmount : 0);
        }, 0);

        // Recent redemptions
        const redemptions = usedBy.map(u => ({
            customer: u.user ? u.user.name : 'Guest',
            date: u.usedAt.toLocaleDateString(),
            orderValue: u.orderId ? u.orderId.totalAmount : 0,
            discount: u.discountAmount || 0
        })).reverse().slice(0, 10);

        // Usage by day
        const usageByDay = {};
        usedBy.forEach(u => {
            const date = u.usedAt.toLocaleDateString('en-US', { weekday: 'short' });
            if (!usageByDay[date]) {
                usageByDay[date] = { count: 0, revenue: 0 };
            }
            usageByDay[date].count++;
            usageByDay[date].revenue += u.orderId ? u.orderId.totalAmount : 0;
        });

        // Current week days
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const chartData = days.map(day => ({
            day,
            count: usageByDay[day] ? usageByDay[day].count : 0
        }));

        res.json({
            success: true,
            data: {
                stats: {
                    totalUses: offer.usedCount,
                    totalRevenue: Math.round(totalRevenueGenerated),
                    averageOrderValue: usedBy.length > 0
                        ? Math.round(totalRevenueGenerated / usedBy.length)
                        : 0,
                    discountGiven: Math.round(totalDiscountGiven),
                },
                chartData,
                redemptions
            }
        });
    } catch (error) {
        console.error('Get offer analytics error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch offer analytics',
            details: error.message
        });
    }
};

/**
 * @desc    Get flash sales
 * @route   GET /api/offers/flash-sales
 * @access  Public
 */
exports.getFlashSales = async (req, res) => {
    try {
        const now = new Date();

        const flashSales = await Offer.find({
            isFlashSale: true,
            status: 'active',
            startDate: { $lte: now },
            endDate: { $gte: now }
        })
            .populate('merchant', 'businessName logo')
            .sort({ endDate: 1 }); // Sort by ending soonest

        const flashSalesWithTime = flashSales.map(sale => ({
            _id: sale._id,
            title: sale.title,
            description: sale.description,
            type: sale.type,
            discountPercentage: sale.discountPercentage,
            discountAmount: sale.discountAmount,
            couponCode: sale.couponCode,
            endDate: sale.endDate,
            timeRemainingSeconds: Math.max(
                0,
                Math.floor((sale.endDate - now) / 1000)
            ),
            merchant: sale.merchant,
            usedCount: sale.usedCount,
            totalUsageLimit: sale.totalUsageLimit
        }));

        res.json({
            success: true,
            data: {
                flashSales: flashSalesWithTime
            }
        });
    } catch (error) {
        console.error('Get flash sales error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch flash sales',
            details: error.message
        });
    }
};

/**
 * @desc    Get all platform offers (Admin)
 * @route   GET /api/offers/admin/all
 * @access  Private (Admin)
 */
exports.getAllOffers = async (req, res) => {
    try {
        const { status, type, page = 1, limit = 20 } = req.query;

        const query = {};
        if (status) query.status = status;
        if (type) query.type = type;

        const skip = (page - 1) * limit;

        const [offers, total] = await Promise.all([
            Offer.find(query)
                .populate('merchant', 'businessName')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Offer.countDocuments(query)
        ]);

        res.json({
            success: true,
            data: {
                offers,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('Get all offers error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch offers',
            details: error.message
        });
    }
};

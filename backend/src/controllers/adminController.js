const Merchant = require('../models/Merchant');
const User = require('../models/User');
const Order = require('../models/Order');
const Product = require('../models/Product');
const Review = require('../models/Review');
const PlatformSettings = require('../models/PlatformSettings');
const notify = require('../services/notify');
const notificationService = require('../services/notificationService');

exports.getSettings = async (req, res) => {
    try {
        let settings = await PlatformSettings.findOne();
        if (!settings) {
            settings = await PlatformSettings.create({});
        }
        res.json({ success: true, data: settings });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.updateSettings = async (req, res) => {
    try {
        const { section, ...data } = req.body;
        let settings = await PlatformSettings.findOne();
        if (!settings) {
            settings = new PlatformSettings({});
        }

        if (section && settings[section]) {
            // Update specific section
            settings[section] = { ...settings[section], ...data };
        } else {
            // Bulk update
            Object.keys(data).forEach(key => {
                if (settings[key] !== undefined) {
                    settings[key] = data[key];
                }
            });
        }

        await settings.save();
        res.json({ success: true, message: 'Settings updated successfully', data: settings });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getPendingMerchants = async (req, res) => {
    try {
        const merchants = await Merchant.find({ verificationStatus: 'pending' });
        res.json({
            success: true,
            data: merchants
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching pending merchants',
            error: error.message
        });
    }
};

exports.verifyMerchant = async (req, res) => {
    try {
        const { id } = req.params;
        const { status, rejectionReason } = req.body; // status: 'approved' or 'rejected'

        if (!status || !['approved', 'rejected'].includes(status)) {
            return res.status(400).json({
                success: false,
                message: 'Please provide a valid status (approved or rejected)'
            });
        }

        const merchant = await Merchant.findById(id);
        if (!merchant) {
            return res.status(404).json({
                success: false,
                message: 'Merchant not found'
            });
        }

        merchant.verificationStatus = status;
        merchant.verifiedBy = req.user._id;
        merchant.verifiedAt = new Date();

        if (status === 'rejected') {
            merchant.rejectionReason = rejectionReason;
        }

        await merchant.save();

        // ── Send approval / rejection notifications ──────────────────
        if (status === 'approved') {
            notify.all({
                user: { _id: merchant._id, email: merchant.email, phone: merchant.phone },
                subject: 'Your Merchant Account is Approved! 🎉',
                template: 'merchantApproved',
                templateData: {
                    merchantName: merchant.name,
                    businessName: merchant.businessName,
                    year: new Date().getFullYear()
                },
                smsBody: `Congrats ${merchant.name}! Your Green Basket merchant account "${merchant.businessName}" has been approved. Log in and start selling!`,
                pushTitle: '🎉 Account Approved!',
                pushBody: `Your merchant account "${merchant.businessName}" is now live on Green Basket!`,
                pushData: { type: 'merchant_approved' }
            }).catch(() => {});

            await notificationService.createNotification({
                recipient: merchant._id,
                recipientModel: 'Merchant',
                type: 'merchant_approved',
                title: 'Account Approved',
                message: `Your merchant account "${merchant.businessName}" has been approved!`,
                data: { status: 'approved' }
            });
        } else {
            notify.all({
                user: { _id: merchant._id, email: merchant.email, phone: merchant.phone },
                subject: 'Merchant Application Update — Green Basket',
                template: 'merchantRejected',
                templateData: {
                    merchantName: merchant.name,
                    businessName: merchant.businessName,
                    rejectionReason,
                    year: new Date().getFullYear()
                },
                smsBody: `Hi ${merchant.name}, your Green Basket merchant application for "${merchant.businessName}" was not approved.${rejectionReason ? ' Reason: ' + rejectionReason : ''} You may re-apply.`,
                pushTitle: 'Application Update',
                pushBody: `Your merchant application was not approved.${rejectionReason ? ' Reason: ' + rejectionReason : ''}`,
                pushData: { type: 'merchant_rejected' }
            }).catch(() => {});
        }
        // ─────────────────────────────────────────────────────────────

        res.json({
            success: true,
            message: `Merchant ${status}`,
            data: merchant
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating merchant status',
            error: error.message
        });
    }
};

exports.getUsers = async (req, res) => {
    try {
        const { page = 1, limit = 20, search } = req.query;
        let query = {};

        if (search) {
            query = {
                $or: [
                    { name: { $regex: search, $options: 'i' } },
                    { email: { $regex: search, $options: 'i' } }
                ]
            };
        }

        const skip = (page - 1) * limit;

        const [users, total] = await Promise.all([
            User.find(query)
                .select('-password')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            User.countDocuments(query)
        ]);

        res.json({
            success: true,
            data: {
                users,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching users',
            error: error.message
        });
    }
};

exports.toggleUserBlock = async (req, res) => {
    try {
        const { id } = req.params;
        const { isBlocked, blockedReason } = req.body;

        let user = await User.findById(id);

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        // If isBlocked is not provided in body, toggle the current status
        const newStatus = isBlocked !== undefined ? isBlocked : !user.isBlocked;

        user.isBlocked = newStatus;
        if (blockedReason) user.blockedReason = blockedReason;
        
        await user.save();
        
        // ── Block/unblock notifications ───────────────────────────────
        notify.all({
            user: { _id: user._id, email: user.email, phone: user.phone },
            subject: newStatus ? 'Account Suspended — Green Basket' : 'Account Reactivated — Green Basket',
            template: 'accountBlocked',
            templateData: {
                name: user.name,
                isBlocked: newStatus,
                action: newStatus ? 'Suspended' : 'Reactivated',
                reason: blockedReason || '',
                year: new Date().getFullYear()
            },
            smsBody: newStatus
                ? `Green Basket: Your account has been suspended.${blockedReason ? ' Reason: ' + blockedReason : ''} Contact support for assistance.`
                : `Green Basket: Your account has been reactivated. You can now access all features.`,
            pushTitle: newStatus ? '⚠️ Account Suspended' : '✅ Account Reactivated',
            pushBody: newStatus ? 'Your account has been suspended.' : 'Your account has been reactivated!',
            pushData: { type: newStatus ? 'user_blocked' : 'user_unblocked' }
        }).catch(() => {});
        // ─────────────────────────────────────────────────────────────

        res.json({
            success: true,
            message: `User ${newStatus ? 'blocked' : 'unblocked'}`,
            data: user
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating user status',
            error: error.message
        });
    }
};

exports.getPlatformStats = async (req, res) => {
    try {
        const [
            userCount,
            merchantCount,
            orderCount,
            pendingMerchantCount,
            revenueAgg,
            todayOrderCount,
            recentOrders
        ] = await Promise.all([
            User.countDocuments(),
            Merchant.countDocuments(),
            Order.countDocuments(),
            Merchant.countDocuments({ verificationStatus: 'pending' }),
            Order.aggregate([
                { $match: { paymentStatus: { $in: ['completed', 'paid'] } } },
                { $group: { _id: null, total: { $sum: '$totalAmount' } } }
            ]),
            Order.countDocuments({
                createdAt: { $gte: new Date(new Date().setHours(0, 0, 0, 0)) }
            }),
            Order.find()
                .sort({ createdAt: -1 })
                .limit(10)
                .populate('customer', 'name email phone')
                .populate('merchant', 'businessName')
                .select('orderId status totalAmount itemsTotal deliveryCharges paymentMethod paymentStatus items createdAt customer merchant deliveryType')
                .lean()
        ]);

        const totalRevenue = revenueAgg.length > 0 ? revenueAgg[0].total : 0;

        // Format recent orders for frontend
        const formattedRecentOrders = recentOrders.map(order => ({
            _id: order._id,
            orderId: order.orderId,
            orderNumber: order.orderId,
            status: order.status,
            totalAmount: order.totalAmount,
            itemsTotal: order.itemsTotal,
            deliveryCharges: order.deliveryCharges,
            paymentMethod: order.paymentMethod,
            paymentStatus: order.paymentStatus,
            itemCount: order.items ? order.items.length : 0,
            deliveryType: order.deliveryType,
            createdAt: order.createdAt,
            customerName: order.customer ? order.customer.name : 'Unknown',
            customerEmail: order.customer ? order.customer.email : '',
            customerPhone: order.customer ? order.customer.phone : '',
            merchantName: order.merchant ? order.merchant.businessName : 'Unknown',
        }));

        res.json({
            success: true,
            data: {
                totalUsers: userCount,
                totalMerchants: merchantCount,
                totalOrders: orderCount,
                ordersToday: todayOrderCount,
                allTimeOrders: orderCount,
                revenue: totalRevenue,
                totalRevenue: totalRevenue,
                pendingMerchants: pendingMerchantCount,
                pendingActions: pendingMerchantCount,
                recentOrders: formattedRecentOrders
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching platform stats',
            error: error.message
        });
    }
};

exports.getAllMerchants = async (req, res) => {
    try {
        const { page = 1, limit = 20, status, search } = req.query;
        let query = {};

        if (status) query.verificationStatus = status;
        if (search) {
            query.$or = [
                { businessName: { $regex: search, $options: 'i' } },
                { email: { $regex: search, $options: 'i' } }
            ];
        }

        const skip = (page - 1) * limit;

        const [merchants, total] = await Promise.all([
            Merchant.find(query)
                .select('-password -bankDetails')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Merchant.countDocuments(query)
        ]);

        res.json({
            success: true,
            data: {
                merchants,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getAllOrders = async (req, res) => {
    try {
        const { page = 1, limit = 50, status, search } = req.query;
        let query = {};

        if (status && status !== 'all') {
            query.status = status;
        }

        if (search) {
            query.$or = [
                { orderId: { $regex: search, $options: 'i' } },
            ];
        }

        const skip = (page - 1) * limit;

        const [orders, total] = await Promise.all([
            Order.find(query)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit))
                .populate('customer', 'name email phone')
                .populate('merchant', 'businessName phone')
                .select('orderId status totalAmount itemsTotal deliveryCharges paymentMethod paymentStatus items createdAt customer merchant deliveryType')
                .lean(),
            Order.countDocuments(query)
        ]);

        const formattedOrders = orders.map(order => ({
            _id: order._id,
            orderId: order.orderId,
            orderNumber: order.orderId,
            status: order.status,
            totalAmount: order.totalAmount,
            itemsTotal: order.itemsTotal,
            deliveryCharges: order.deliveryCharges,
            paymentMethod: order.paymentMethod,
            paymentStatus: order.paymentStatus,
            itemCount: order.items ? order.items.length : 0,
            items: order.items,
            deliveryType: order.deliveryType,
            createdAt: order.createdAt,
            customer: order.customer ? { name: order.customer.name, email: order.customer.email, phone: order.customer.phone } : { name: 'Unknown' },
            customerName: order.customer ? order.customer.name : 'Unknown',
            merchantName: order.merchant ? order.merchant.businessName : 'Unknown',
            merchant: order.merchant ? { businessName: order.merchant.businessName, phone: order.merchant.phone } : { businessName: 'Unknown' },
        }));

        res.json({
            success: true,
            data: {
                orders: formattedOrders,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching orders',
            error: error.message
        });
    }
};

exports.getMerchantAnalytics = async (req, res) => {
    try {
        const { id } = req.params;
        const merchantId = id;
        
        const mongoose = require('mongoose');
        const merchantIdObj = new mongoose.Types.ObjectId(merchantId);
        const { period = 'week' } = req.query;

        let startDate = new Date();
        let groupBy = { $dayOfWeek: "$createdAt" };
        let labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        let dayMap = { 2: 0, 3: 1, 4: 2, 5: 3, 6: 4, 7: 5, 1: 6 };

        if (period === 'month') {
            startDate.setDate(startDate.getDate() - 30);
            groupBy = { $dayOfMonth: "$createdAt" };
            // For month, we'll still show 7 buckets or simplify it to weeks
            // Let's keep it simple for now: group by day of week but over last 30 days
        } else if (period === 'year') {
            startDate.setFullYear(startDate.getFullYear() - 1);
            groupBy = { $month: "$createdAt" };
            labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            dayMap = { 1: 0, 2: 1, 3: 2, 4: 3, 5: 4, 6: 5, 7: 6, 8: 7, 9: 8, 10: 9, 11: 10, 12: 11 };
        } else {
            startDate.setDate(startDate.getDate() - 7);
        }

        const [orders, products, reviews, salesAgg, topProductsAgg] = await Promise.all([
            Order.find({ merchant: merchantId, status: 'delivered' }),
            Product.find({ merchant: merchantId }),
            Review.find({ merchant: merchantId }).sort({ createdAt: -1 }).limit(10).populate('customer', 'name'),

            Order.aggregate([
                { $match: { 
                    merchant: merchantIdObj, 
                    status: 'delivered', 
                    createdAt: { $gte: startDate }
                } },
                { $group: {
                    _id: groupBy,
                    total: { $sum: "$totalAmount" }
                } }
            ]),
            Order.aggregate([
                { $match: { merchant: merchantIdObj, status: 'delivered' } },
                { $unwind: "$items" },
                { $group: {
                    _id: "$items.product",
                    productName: { $first: "$items.name" },
                    soldCount: { $sum: "$items.quantity" },
                    revenue: { $sum: { $multiply: ["$items.price", "$items.quantity"] } }
                }},
                { $sort: { soldCount: -1 } },
                { $limit: 5 }
            ])
        ]);

        const totalRevenue = orders.reduce((sum, o) => sum + (o.total || o.totalAmount || 0), 0);
        const totalOrders = orders.length;
        const totalProducts = products.length;
        
        const totalReviews = await Review.countDocuments({ merchant: merchantId });
        const allRatings = await Review.find({ merchant: merchantId }, 'rating');
        const averageRating = totalReviews > 0 
            ? allRatings.reduce((sum, r) => sum + r.rating, 0) / totalReviews 
            : 0;
        const recentReviews = reviews.slice(0, 5);


        const salesData = labels.map(l => ({ label: l, amount: 0 }));

        salesAgg.forEach(item => {
            const index = dayMap[item._id];
            if (index !== undefined && index < salesData.length) {
                salesData[index].amount += item.total;
            }
        });

        const topProducts = topProductsAgg.map(p => ({
            name: p.productName || 'Unknown',
            soldCount: p.soldCount,
            revenue: p.revenue
        }));

        res.json({
            success: true,
            data: {
                totalRevenue,
                totalOrders,
                totalProducts,
                totalReviews,
                averageRating,
                recentReviews,
                salesData,
                topProducts
            }
        });


    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching merchant analytics',
            error: error.message
        });
    }
};
exports.toggleMerchantBlock = async (req, res) => {
    try {
        const { id } = req.params;
        const { isBlocked, blockedReason } = req.body;

        const merchant = await Merchant.findById(id);
        if (!merchant) {
            return res.status(404).json({
                success: false,
                message: 'Merchant not found'
            });
        }

        // Toggle if not provided
        const newStatus = isBlocked !== undefined ? isBlocked : !merchant.isBlocked;
        
        merchant.isBlocked = newStatus;
        if (blockedReason) merchant.blockedReason = blockedReason;

        await merchant.save();

        // ── Block/unblock notifications ───────────────────────────────
        notify.all({
            user: { _id: merchant._id, email: merchant.email, phone: merchant.phone },
            subject: newStatus ? 'Account Suspended — Green Basket' : 'Account Reactivated — Green Basket',
            template: 'accountBlocked',
            templateData: {
                name: merchant.name,
                isBlocked: newStatus,
                action: newStatus ? 'Suspended' : 'Reactivated',
                reason: blockedReason || '',
                year: new Date().getFullYear()
            },
            smsBody: newStatus
                ? `Green Basket: Your merchant account has been suspended.${blockedReason ? ' Reason: ' + blockedReason : ''} Contact support for assistance.`
                : `Green Basket: Your merchant account has been reactivated. You can now access all features.`,
            pushTitle: newStatus ? '⚠️ Account Suspended' : '✅ Account Reactivated',
            pushBody: newStatus ? 'Your account has been suspended.' : 'Your account has been reactivated!',
            pushData: { type: newStatus ? 'merchant_blocked' : 'merchant_unblocked' }
        }).catch(() => {});
        // ─────────────────────────────────────────────────────────────

        res.json({
            success: true,
            message: `Merchant ${newStatus ? 'blocked' : 'unblocked'}`,
            data: merchant
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating merchant status',
            error: error.message
        });
    }
};

const Merchant = require('../models/Merchant');
const Order = require('../models/Order');
const Product = require('../models/Product');
const mongoose = require('mongoose');
const notify = require('../services/notify');

exports.uploadImage = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'No image uploaded' });
        }

        const { imageType } = req.body; // 'logo' or 'cover'
        const imageUrl = req.file.path;

        const updateData = {};
        if (imageType === 'logo') {
            updateData.profileImage = imageUrl;
        } else if (imageType === 'cover') {
            updateData.farmImages = [imageUrl];
        }

        const merchant = await Merchant.findByIdAndUpdate(
            req.user.id,
            updateData,
            { new: true }
        );

        res.json({
            success: true,
            message: 'Image uploaded successfully',
            imageUrl: imageUrl,
            data: merchant
        });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error uploading image', error: error.message });
    }
};

exports.getProfile = async (req, res) => {
    try {
        const merchant = await Merchant.findById(req.user.id);
        res.json({
            success: true,
            data: merchant
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching profile',
            error: error.message
        });
    }
};

exports.updateProfile = async (req, res) => {
    try {
        let {
            businessName, businessDescription, address,
            phone, email, gstNumber,
            operatingHours, deliveryRadius, minimumOrderValue,
            deliveryCharges, bankDetails, sellingModel,
            autoAcceptOrders, defaultPrepTime, notificationSettings, isStoreOpen
        } = req.body;

        // If address is a string (from frontend text field), convert to object format
        if (typeof address === 'string') {
            address = {
                street: address,
                city: '',
                state: '',
                pincode: ''
            };
        }

        const merchant = await Merchant.findByIdAndUpdate(
            req.user.id,
            {
                businessName, businessDescription, address,
                operatingHours, deliveryRadius, minimumOrderValue,
                deliveryCharges, bankDetails, phone, email, gstNumber,
                sellingModel,
                autoAcceptOrders, defaultPrepTime, notificationSettings, isStoreOpen
            },
            { new: true, runValidators: true }
        );

        // ── Merchant profile update notification (non-blocking) ────────
        if (merchant) {
            const changedFields = Object.keys(req.body).filter(k => !['notificationSettings'].includes(k));
            if (changedFields.length > 0) {
                notify.email({
                    to: merchant.email,
                    subject: 'Profile Updated — Green Basket Merchant',
                    template: 'profileUpdated',
                    data: { name: merchant.name, changes: changedFields.join(', '), year: new Date().getFullYear() }
                }).catch(() => {});
            }
        }
        // ─────────────────────────────────────────────────────────────

        res.json({
            success: true,
            message: 'Merchant profile updated',
            data: merchant
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating profile',
            error: error.message
        });
    }
};

exports.toggleStoreStatus = async (req, res) => {
    try {
        const merchant = await Merchant.findById(req.user.id);
        merchant.isStoreOpen = !merchant.isStoreOpen;
        await merchant.save();

        res.json({
            success: true,
            message: `Store is now ${merchant.isStoreOpen ? 'Open' : 'Closed'}`,
            isStoreOpen: merchant.isStoreOpen,
            data: merchant
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error toggling store status',
            error: error.message
        });
    }
};

exports.getDashboardStats = async (req, res) => {
    try {
        const merchantId = req.user.id;
        const objectId = new mongoose.Types.ObjectId(merchantId);

        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);

        const [
            totalOrders,
            totalProducts,
            activeProducts,
            lowStockProducts,
            orderStatsRaw,
            todayStatsRaw,
            openDisputes
        ] = await Promise.all([
            Order.countDocuments({ merchant: merchantId, status: { $ne: 'payment_pending' } }),
            Product.countDocuments({ merchant: merchantId }),
            Product.countDocuments({ merchant: merchantId, isActive: true }),
            Product.countDocuments({ merchant: merchantId, stock: { $lte: 10 } }),
            Order.aggregate([
                { $match: { merchant: objectId, status: { $ne: 'payment_pending' } } },
                {
                    $group: {
                        _id: '$status',
                        count: { $sum: 1 },
                        revenue: {
                            $sum: { $cond: [{ $in: ['$status', ['delivered', 'completed']] }, '$totalAmount', 0] }
                        }
                    }
                }
            ]),
            Order.aggregate([
                { $match: { merchant: objectId, status: { $ne: 'payment_pending' }, createdAt: { $gte: todayStart } } },
                {
                    $group: {
                        _id: null,
                        todayOrders: { $sum: 1 },
                        todayRevenue: {
                            $sum: { $cond: [{ $in: ['$status', ['delivered', 'completed']] }, '$totalAmount', 0] }
                        }
                    }
                }
            ]),
            require('../models/Dispute').aggregate([
                {
                    $lookup: {
                        from: 'orders',
                        localField: 'order',
                        foreignField: '_id',
                        as: 'orderObj'
                    }
                },
                { $match: { 'orderObj.merchant': objectId, status: { $in: ['open', 'investigating', 'escalated'] } } },
                { $count: 'total' }
            ])
        ]);

        const disputeCount = openDisputes[0]?.total || 0;

        const orderStats = orderStatsRaw.reduce((acc, curr) => {
            if (curr._id === 'pending') acc.pending += curr.count;
            else if (curr._id === 'confirmed') acc.confirmed += curr.count;
            else if (curr._id === 'ready') acc.processing += curr.count;
            else if (curr._id === 'out-for-delivery') acc.shipped += curr.count;
            else if (curr._id === 'delivered' || curr._id === 'completed') { acc.delivered += curr.count; acc.totalRevenue += curr.revenue; }
            else if (curr._id === 'cancelled' || curr._id === 'refunded') acc.cancelled += curr.count;
            return acc;
        }, {
            pending: 0, confirmed: 0, processing: 0, shipped: 0, delivered: 0, cancelled: 0, totalRevenue: 0
        });

        const todayStats = todayStatsRaw[0] || { todayOrders: 0, todayRevenue: 0 };
        const averageOrderValue = totalOrders > 0 ? (orderStats.totalRevenue / totalOrders) : 0;

        res.json({
            success: true,
            data: {
                totalOrders,
                totalProducts,
                activeProducts,
                lowStockProducts,
                totalRevenue: orderStats.totalRevenue,
                todayOrders: todayStats.todayOrders,
                todayRevenue: todayStats.todayRevenue,
                averageOrderValue,
                pendingOrders: orderStats.pending || 0,
                confirmedOrders: orderStats.confirmed || 0,
                processingOrders: orderStats.processing || 0,
                shippedOrders: orderStats.shipped || 0,
                deliveredOrders: orderStats.delivered || 0,
                cancelledOrders: orderStats.cancelled || 0,
                openDisputes: disputeCount
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching stats',
            error: error.message
        });
    }
};

exports.getAllMerchants = async (req, res) => {
    try {
        console.log('--- GET ALL MERCHANTS QUERY ---', req.query);
        const { page = 1, limit = 20, status, search, sellingModel, merchantType } = req.query;
        let query = {};

        if (status) query.verificationStatus = status;
        if (sellingModel) {
            query.sellingModel = { $in: [sellingModel, 'both'] };
        }
        if (merchantType) {
            query.merchantType = merchantType;
        }
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

/**
 * @desc    Update password
 * @route   PATCH /api/merchants/update-password
 * @access  Private
 */
exports.updatePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;

        const merchant = await Merchant.findById(req.user.id).select('+password');

        if (!merchant || !(await merchant.comparePassword(currentPassword))) {
            return res.status(401).json({
                success: false,
                message: 'Incorrect current password'
            });
        }

        merchant.password = newPassword;
        await merchant.save();

        res.json({
            success: true,
            message: 'Password updated successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating password',
            error: error.message
        });
    }
};

/**
 * @desc    Update notification settings
 * @route   PATCH /api/merchants/notification-settings
 * @access  Private
 */
exports.updateNotificationSettings = async (req, res) => {
    try {
        const { email, sms, newOrders, lowStock } = req.body;

        const merchant = await Merchant.findByIdAndUpdate(
            req.user.id,
            {
                $set: {
                    notificationSettings: { email, sms, newOrders, lowStock }
                }
            },
            { new: true }
        );

        res.json({
            success: true,
            message: 'Notification settings updated',
            data: merchant.notificationSettings
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating notification settings',
            error: error.message
        });
    }
};

exports.getMerchantById = async (req, res) => {
    try {
        const merchant = await Merchant.findById(req.params.id).select('-password -bankDetails');
        if (!merchant) {
            return res.status(404).json({ success: false, message: 'Merchant not found' });
        }
        res.json({
            success: true,
            data: merchant
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

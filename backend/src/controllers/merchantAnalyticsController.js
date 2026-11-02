const Order = require('../models/Order');
const Product = require('../models/Product');
const Review = require('../models/Review');
const User = require('../models/User');

/**
 * @desc    Get sales analytics for merchant
 * @route   GET /api/merchants/analytics/sales
 * @access  Private (Merchant)
 */
exports.getSalesAnalytics = async (req, res) => {
    try {
        const { period = 'month', startDate, endDate } = req.query;
        const merchantId = req.user._id;

        // Determine date range
        let dateRange = {};
        const now = new Date();

        if (startDate && endDate) {
            dateRange = {
                $gte: new Date(startDate),
                $lte: new Date(endDate)
            };
        } else {
            switch (period) {
                case 'today':
                    const todayStart = new Date(now.setHours(0, 0, 0, 0));
                    dateRange = { $gte: todayStart };
                    break;
                case 'week':
                    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
                    dateRange = { $gte: weekAgo };
                    break;
                case 'month':
                    const monthAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
                    dateRange = { $gte: monthAgo };
                    break;
                case 'year':
                    const yearAgo = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000);
                    dateRange = { $gte: yearAgo };
                    break;
            }
        }

        // Get current period orders - use deliveredAt if available, fall back to createdAt
        const orders = await Order.find({
            merchant: merchantId,
            status: 'delivered',
            $or: [
                { deliveredAt: dateRange },
                { deliveredAt: { $exists: false }, createdAt: dateRange },
                { deliveredAt: null, createdAt: dateRange }
            ]
        });

        // Get previous period orders for comparison
        const periodLength = dateRange.$gte
            ? Date.now() - dateRange.$gte.getTime()
            : 30 * 24 * 60 * 60 * 1000;

        const previousPeriodOrders = await Order.find({
            merchant: merchantId,
            status: 'delivered',
            $or: [
                { deliveredAt: {
                    $gte: new Date(dateRange.$gte - periodLength),
                    $lt: dateRange.$gte
                }},
                { deliveredAt: { $exists: false }, createdAt: {
                    $gte: new Date(dateRange.$gte - periodLength),
                    $lt: dateRange.$gte
                }},
                { deliveredAt: null, createdAt: {
                    $gte: new Date(dateRange.$gte - periodLength),
                    $lt: dateRange.$gte
                }}
            ]
        });

        // Calculate summary
        const totalRevenue = orders.reduce((sum, o) => sum + o.totalAmount, 0);
        const totalOrders = orders.length;
        const averageOrderValue = totalOrders > 0
            ? Math.round(totalRevenue / totalOrders)
            : 0;

        const prevRevenue = previousPeriodOrders.reduce((sum, o) => sum + o.totalAmount, 0);
        const prevOrders = previousPeriodOrders.length;

        const revenueGrowth = prevRevenue > 0
            ? Math.round(((totalRevenue - prevRevenue) / prevRevenue) * 100 * 10) / 10
            : 0;
        const ordersGrowth = prevOrders > 0
            ? Math.round(((totalOrders - prevOrders) / prevOrders) * 100 * 10) / 10
            : 0;

        // Daily breakdown
        const dailyBreakdownMap = {};
        orders.forEach(order => {
            const dateObj = order.deliveredAt || order.createdAt;
            const date = dateObj.toISOString().split('T')[0];
            if (!dailyBreakdownMap[date]) {
                dailyBreakdownMap[date] = { revenue: 0, orders: 0 };
            }
            dailyBreakdownMap[date].revenue += order.totalAmount;
            dailyBreakdownMap[date].orders++;
        });

        const dailyBreakdown = Object.keys(dailyBreakdownMap)
            .sort()
            .map(date => ({
                date,
                revenue: dailyBreakdownMap[date].revenue,
                orders: dailyBreakdownMap[date].orders,
                averageOrderValue: Math.round(
                    dailyBreakdownMap[date].revenue / dailyBreakdownMap[date].orders
                )
            }));

        // Peak hours
        const hourlyBreakdownMap = {};
        orders.forEach(order => {
            const hour = new Date(order.deliveredAt || order.createdAt).getHours();
            if (!hourlyBreakdownMap[hour]) {
                hourlyBreakdownMap[hour] = 0;
            }
            hourlyBreakdownMap[hour]++;
        });

        const peakHours = Object.keys(hourlyBreakdownMap)
            .map(hour => ({
                hour: parseInt(hour),
                orders: hourlyBreakdownMap[hour]
            }))
            .sort((a, b) => b.orders - a.orders)
            .slice(0, 5);

        // Top selling day
        const dayBreakdownMap = {};
        const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        orders.forEach(order => {
            const day = dayNames[new Date(order.deliveredAt || order.createdAt).getDay()];
            if (!dayBreakdownMap[day]) {
                dayBreakdownMap[day] = 0;
            }
            dayBreakdownMap[day]++;
        });

        const topSellingDay = Object.keys(dayBreakdownMap)
            .sort((a, b) => dayBreakdownMap[b] - dayBreakdownMap[a])[0] || 'N/A';

        // Payment method breakdown
        const paymentMethodBreakdown = {};
        orders.forEach(order => {
            const method = order.paymentDetails?.method || 'cod';
            paymentMethodBreakdown[method] = (paymentMethodBreakdown[method] || 0) + 1;
        });

        res.json({
            success: true,
            data: {
                summary: {
                    totalRevenue,
                    totalOrders,
                    averageOrderValue,
                    revenueGrowth,
                    ordersGrowth
                },
                dailyBreakdown,
                peakHours,
                topSellingDay,
                paymentMethodBreakdown
            }
        });
    } catch (error) {
        console.error('Get sales analytics error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch sales analytics',
            details: error.message
        });
    }
};

/**
 * @desc    Get product performance analytics
 * @route   GET /api/merchants/analytics/products
 * @access  Private (Merchant)
 */
exports.getProductAnalytics = async (req, res) => {
    try {
        const merchantId = req.user._id;
        const { limit = 10 } = req.query;

        // Best sellers
        const bestSellers = await Order.aggregate([
            {
                $match: {
                    merchant: merchantId,
                    status: 'delivered'
                }
            },
            { $unwind: '$items' },
            {
                $group: {
                    _id: '$items.product',
                    totalSold: { $sum: '$items.quantity' },
                    revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } },
                    orderCount: { $sum: 1 }
                }
            },
            { $sort: { totalSold: -1 } },
            { $limit: parseInt(limit) },
            {
                $lookup: {
                    from: 'products',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'product'
                }
            },
            { $unwind: '$product' },
            {
                $project: {
                    product: {
                        _id: '$product._id',
                        name: '$product.name',
                        primaryImage: '$product.primaryImage',
                        price: '$product.price',
                        stock: '$product.stock',
                        averageRating: '$product.averageRating'
                    },
                    totalSold: 1,
                    revenue: 1,
                    orderCount: 1
                }
            }
        ]);

        // Low performers (least sold in last 30 days)
        const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        const lowPerformers = await Order.aggregate([
            {
                $match: {
                    merchant: merchantId,
                    status: 'delivered',
                    deliveredAt: { $gte: thirtyDaysAgo }
                }
            },
            { $unwind: '$items' },
            {
                $group: {
                    _id: '$items.product',
                    totalSold: { $sum: '$items.quantity' }
                }
            },
            { $sort: { totalSold: 1 } },
            { $limit: parseInt(limit) },
            {
                $lookup: {
                    from: 'products',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'product'
                }
            },
            { $unwind: '$product' },
            {
                $project: {
                    product: {
                        _id: '$product._id',
                        name: '$product.name',
                        primaryImage: '$product.primaryImage',
                        stock: '$product.stock'
                    },
                    totalSold: 1
                }
            }
        ]);

        res.json({
            success: true,
            data: {
                bestSellers,
                lowPerformers
            }
        });
    } catch (error) {
        console.error('Get product analytics error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch product analytics',
            details: error.message
        });
    }
};

/**
 * @desc    Get customer analytics
 * @route   GET /api/merchants/analytics/customers
 * @access  Private (Merchant)
 */
exports.getCustomerAnalytics = async (req, res) => {
    try {
        const merchantId = req.user._id;
        const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

        // All customers
        const allCustomerAgg = await Order.aggregate([
            { $match: { merchant: merchantId, status: 'delivered' } },
            {
                $group: {
                    _id: '$customer',
                    totalOrders: { $sum: 1 },
                    totalSpent: { $sum: '$totalAmount' },
                    firstOrder: { $min: '$createdAt' }
                }
            }
        ]);

        // New customers (last 30 days)
        const newCustomers = allCustomerAgg.filter(
            c => c.firstOrder >= thirtyDaysAgo
        ).length;

        // Top customers
        const topCustomers = await Order.aggregate([
            { $match: { merchant: merchantId, status: 'delivered' } },
            {
                $group: {
                    _id: '$customer',
                    totalOrders: { $sum: 1 },
                    totalSpent: { $sum: '$totalAmount' }
                }
            },
            { $sort: { totalSpent: -1 } },
            { $limit: 10 },
            {
                $lookup: {
                    from: 'users',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'customer'
                }
            },
            { $unwind: '$customer' },
            {
                $project: {
                    customer: { _id: '$customer._id', name: '$customer.name' },
                    totalOrders: 1,
                    totalSpent: 1
                }
            }
        ]);

        const totalCustomers = allCustomerAgg.length;
        const returningCustomers = allCustomerAgg.filter(c => c.totalOrders > 1).length;
        const retentionRate = totalCustomers > 0
            ? Math.round((returningCustomers / totalCustomers) * 100)
            : 0;

        const avgOrderFrequency = totalCustomers > 0
            ? Math.round(
                (allCustomerAgg.reduce((sum, c) => sum + c.totalOrders, 0) / totalCustomers) * 10
            ) / 10
            : 0;

        res.json({
            success: true,
            data: {
                totalCustomers,
                newCustomers,
                returningCustomers,
                retentionRate,
                averageOrderFrequency: avgOrderFrequency,
                topCustomers
            }
        });
    } catch (error) {
        console.error('Get customer analytics error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch customer analytics',
            details: error.message
        });
    }
};

/**
 * @desc    Get inventory analytics
 * @route   GET /api/merchants/analytics/inventory
 * @access  Private (Merchant)
 */
exports.getInventoryAnalytics = async (req, res) => {
    try {
        const merchantId = req.user._id;

        const products = await Product.find({ merchant: merchantId });

        const totalProducts = products.length;
        const lowStockProducts = products.filter(p => p.stock > 0 && p.stock <= 10);
        const outOfStockProducts = products.filter(p => p.stock === 0);

        const inventoryValue = products.reduce((sum, p) => sum + (p.price * p.stock), 0);

        // Generate recommendations
        const recommendations = [];

        lowStockProducts.forEach(p => {
            recommendations.push({
                product: { _id: p._id, name: p.name },
                action: 'restock',
                reason: `Low stock: ${p.stock} units remaining`,
                urgency: p.stock <= 3 ? 'high' : 'medium'
            });
        });

        outOfStockProducts.forEach(p => {
            recommendations.push({
                product: { _id: p._id, name: p.name },
                action: 'restock',
                reason: 'Out of stock - losing sales',
                urgency: 'high'
            });
        });

        res.json({
            success: true,
            data: {
                totalProducts,
                activeProducts: products.filter(p => p.isActive).length,
                lowStockProducts: lowStockProducts.length,
                outOfStockProducts: outOfStockProducts.length,
                inventoryValue: Math.round(inventoryValue),
                recommendations,
                products: {
                    lowStock: lowStockProducts.map(p => ({
                        _id: p._id,
                        name: p.name,
                        stock: p.stock,
                        price: p.price
                    })),
                    outOfStock: outOfStockProducts.map(p => ({
                        _id: p._id,
                        name: p.name,
                        price: p.price
                    }))
                }
            }
        });
    } catch (error) {
        console.error('Get inventory analytics error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch inventory analytics',
            details: error.message
        });
    }
};

/**
 * @desc    Get revenue forecast
 * @route   GET /api/merchants/analytics/forecast
 * @access  Private (Merchant)
 */
exports.getRevenueForecast = async (req, res) => {
    try {
        const merchantId = req.user._id;

        // Get last 90 days of data
        const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
        const orders = await Order.find({
            merchant: merchantId,
            status: 'delivered',
            deliveredAt: { $gte: ninetyDaysAgo }
        }).sort({ deliveredAt: 1 });

        // Simple moving average forecast
        const dailyRevenue = {};
        orders.forEach(order => {
            const date = order.deliveredAt.toISOString().split('T')[0];
            dailyRevenue[date] = (dailyRevenue[date] || 0) + order.totalAmount;
        });

        const revenueArray = Object.values(dailyRevenue);
        const avgDailyRevenue = revenueArray.length > 0
            ? revenueArray.reduce((sum, r) => sum + r, 0) / revenueArray.length
            : 0;

        // Simple trend calculation
        const firstHalf = revenueArray.slice(0, Math.floor(revenueArray.length / 2));
        const secondHalf = revenueArray.slice(Math.floor(revenueArray.length / 2));

        const firstHalfAvg = firstHalf.length > 0
            ? firstHalf.reduce((s, r) => s + r, 0) / firstHalf.length
            : 0;
        const secondHalfAvg = secondHalf.length > 0
            ? secondHalf.reduce((s, r) => s + r, 0) / secondHalf.length
            : 0;

        const growthRate = firstHalfAvg > 0
            ? (secondHalfAvg - firstHalfAvg) / firstHalfAvg
            : 0;

        const nextMonthRevenue = Math.round(avgDailyRevenue * 30 * (1 + growthRate));
        const nextMonthOrders = Math.round((orders.length / 90) * 30 * (1 + growthRate));
        const confidence = Math.min(0.95, 0.5 + (revenueArray.length / 90) * 0.45);

        res.json({
            success: true,
            data: {
                nextMonth: {
                    predictedRevenue: nextMonthRevenue,
                    predictedOrders: nextMonthOrders,
                    confidence: Math.round(confidence * 100) / 100,
                    growthRate: Math.round(growthRate * 100 * 10) / 10
                },
                historicalAverage: {
                    dailyRevenue: Math.round(avgDailyRevenue),
                    monthlyRevenue: Math.round(avgDailyRevenue * 30),
                    dailyOrders: Math.round(orders.length / 90)
                }
            }
        });
    } catch (error) {
        console.error('Get revenue forecast error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch revenue forecast',
            details: error.message
        });
    }
};

/**
 * @desc    Get review analytics
 * @route   GET /api/merchants/analytics/reviews
 * @access  Private (Merchant)
 */
exports.getReviewAnalytics = async (req, res) => {
    try {
        const merchantId = req.user._id;

        const reviews = await Review.find({ merchant: merchantId });

        const totalReviews = reviews.length;
        const averageRating = totalReviews > 0
            ? Math.round((reviews.reduce((sum, r) => sum + r.rating, 0) / totalReviews) * 10) / 10
            : 0;

        // Rating distribution
        const ratingDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
        reviews.forEach(r => {
            ratingDistribution[r.rating]++;
        });

        // Reviews this month
        const thisMonthStart = new Date();
        thisMonthStart.setDate(1);
        thisMonthStart.setHours(0, 0, 0, 0);

        const reviewsThisMonth = reviews.filter(
            r => r.createdAt >= thisMonthStart
        ).length;

        res.json({
            success: true,
            data: {
                totalReviews,
                averageRating,
                reviewsThisMonth,
                ratingDistribution,
                responseRate: 0 // Implement when reply feature added
            }
        });
    } catch (error) {
        console.error('Get review analytics error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch review analytics',
            details: error.message
        });
    }
};

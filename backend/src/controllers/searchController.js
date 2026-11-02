const Product = require('../models/Product');
const Category = require('../models/Category');
const Order = require('../models/Order');

/**
 * @desc    Advanced product search
 * @route   GET /api/search/products
 * @access  Public
 */
exports.advancedSearch = async (req, res) => {
    try {
        const {
            q, category, minPrice, maxPrice, tags,
            isOrganic, merchantId, sortBy,
            page = 1, limit = 20,
            latitude, longitude, maxDistanceKm = 10
        } = req.query;

        const query = { isActive: true };
        const appliedFilters = {};

        // Text search
        if (q && q.trim()) {
            query.$or = [
                { name: { $regex: q.trim(), $options: 'i' } },
                { description: { $regex: q.trim(), $options: 'i' } },
                { tags: { $in: [new RegExp(q.trim(), 'i')] } }
            ];
            appliedFilters.query = q.trim();
        }

        // Category filter
        if (category) {
            query.category = category;
            appliedFilters.category = category;
        }

        // Price range filter
        if (minPrice || maxPrice) {
            query.price = {};
            if (minPrice) query.price.$gte = parseFloat(minPrice);
            if (maxPrice) query.price.$lte = parseFloat(maxPrice);
            appliedFilters.priceRange = {
                min: minPrice ? parseFloat(minPrice) : 0,
                max: maxPrice ? parseFloat(maxPrice) : null
            };
        }

        // Tags filter
        if (tags) {
            const tagsArray = tags.split(',').map(t => t.trim()).filter(Boolean);
            if (tagsArray.length > 0) {
                query.tags = { $in: tagsArray };
                appliedFilters.tags = tagsArray;
            }
        }

        // Organic filter
        if (isOrganic === 'true') {
            query.tags = query.tags ? { $all: ['organic'], ...query.tags } : { $in: ['organic'] };
            appliedFilters.isOrganic = true;
        }

        // Merchant filter
        if (merchantId) {
            query.merchant = merchantId;
            appliedFilters.merchantId = merchantId;
        }

        // Sorting
        let sortOption = { createdAt: -1 };
        if (sortBy === 'price_asc') sortOption = { price: 1 };
        else if (sortBy === 'price_desc') sortOption = { price: -1 };
        else if (sortBy === 'rating') sortOption = { averageRating: -1 };
        else if (sortBy === 'newest') sortOption = { createdAt: -1 };

        const skip = (page - 1) * limit;

        const [products, total] = await Promise.all([
            Product.find(query)
                .populate('category', 'name')
                .populate('merchant', 'businessName isOpen averageRating')
                .sort(sortOption)
                .skip(skip)
                .limit(parseInt(limit)),
            Product.countDocuments(query)
        ]);

        res.json({
            success: true,
            data: {
                products,
                totalResults: total,
                appliedFilters,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('Advanced search error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to perform search',
            details: error.message
        });
    }
};

/**
 * @desc    Get search suggestions/autocomplete
 * @route   GET /api/search/suggestions
 * @access  Public
 */
exports.getSearchSuggestions = async (req, res) => {
    try {
        const { q } = req.query;

        if (!q || q.trim().length < 2) {
            return res.json({
                success: true,
                data: { suggestions: [] }
            });
        }

        const searchRegex = new RegExp(q.trim(), 'i');

        const [products, categories] = await Promise.all([
            Product.find({
                isActive: true,
                name: searchRegex
            })
                .select('name')
                .limit(5),
            Category.find({
                isActive: true,
                name: searchRegex
            })
                .select('name')
                .limit(3)
        ]);

        const suggestions = [
            ...products.map(p => ({
                type: 'product',
                text: p.name,
                id: p._id
            })),
            ...categories.map(c => ({
                type: 'category',
                text: c.name,
                id: c._id
            }))
        ];

        res.json({
            success: true,
            data: { suggestions }
        });
    } catch (error) {
        console.error('Get suggestions error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch suggestions',
            details: error.message
        });
    }
};

/**
 * @desc    Get trending products
 * @route   GET /api/search/trending
 * @access  Public
 */
exports.getTrendingProducts = async (req, res) => {
    try {
        const { limit = 10, category } = req.query;

        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

        const matchStage = {
            status: 'delivered',
            deliveredAt: { $gte: sevenDaysAgo }
        };

        const pipeline = [
            { $match: matchStage },
            { $unwind: '$items' },
            {
                $group: {
                    _id: '$items.product',
                    totalSold: { $sum: '$items.quantity' },
                    orderCount: { $sum: 1 }
                }
            },
            { $sort: { totalSold: -1 } },
            { $limit: parseInt(limit) * 2 },
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
                $match: {
                    'product.isActive': true
                }
            },
            { $limit: parseInt(limit) },
            {
                $project: {
                    product: {
                        _id: '$product._id',
                        name: '$product.name',
                        price: '$product.price',
                        primaryImage: '$product.primaryImage',
                        averageRating: '$product.averageRating',
                        stock: '$product.stock'
                    },
                    totalSold: 1,
                    orderCount: 1
                }
            }
        ];

        let trendingProducts = await Order.aggregate(pipeline);

        if (trendingProducts.length === 0) {
            // Fallback to top-rated products if no orders exist yet
            const popularProducts = await Product.find({ isActive: true })
                .sort({ averageRating: -1, stock: -1 })
                .limit(parseInt(limit));

            trendingProducts = popularProducts.map(p => ({
                product: {
                    _id: p._id,
                    name: p.name,
                    price: p.price,
                    primaryImage: p.primaryImage,
                    averageRating: p.averageRating,
                    stock: p.stock
                },
                totalSold: 0,
                orderCount: 0
            }));
        }

        res.json({
            success: true,
            data: {
                trendingProducts,
                period: trendingProducts[0]?.totalSold === 0 ? 'All Time (Fallback)' : 'Last 7 days'
            }
        });
    } catch (error) {
        console.error('Get trending products error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch trending products',
            details: error.message
        });
    }
};

module.exports = exports;

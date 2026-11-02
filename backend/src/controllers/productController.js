const Product = require('../models/Product');
const Category = require('../models/Category');
const Merchant = require('../models/Merchant');
const mongoose = require('mongoose');
const uploadService = require('../services/uploadService');
const { haversineKm, computeScore } = require('../utils/haversine');

// Get All Products
exports.getAllProducts = async (req, res) => {
    try {
        const { page = 1, limit = 12, category, merchant, search, sort = '-createdAt', isFeatured } = req.query;
        const isAdmin = req.user && req.userType === 'admin';
        const query = {};

        if (category) {
            if (mongoose.Types.ObjectId.isValid(category)) {
                query.category = new mongoose.Types.ObjectId(category);
            } else {
                const cat = await Category.findOne({ name: new RegExp(`^${category}$`, 'i') });
                if (cat) {
                    query.category = cat._id;
                } else {
                    return res.json({ success: true, data: { products: [], pagination: { page: 1, limit, total: 0, pages: 0 } } });
                }
            }
        }

        if (!isAdmin) {
            query.status = 'active';
            query.isActive = { $ne: false };
        }

        if (merchant) query.merchant = merchant;
        if (isFeatured === 'true') query.isFeatured = true;
        if (search) {
            const searchRegex = new RegExp(search, 'i');
            query.$or = [
                { name: searchRegex },
                { description: searchRegex },
                { tags: searchRegex },
                { subCategory: searchRegex }
            ];
        }

        let sortOption = sort || '-createdAt';
        if (sort === 'popular-today') {
            sortOption = { dailySales: -1, dailyViews: -1, totalSales: -1 };
        } else if (sort === '-totalSales') {
            sortOption = { totalSales: -1 };
        }


        const products = await Product.find(query)
            .populate('merchant', 'businessName profileImage averageRating isStoreOpen')
            .populate('category', 'name')
            .sort(sortOption)
            .limit(limit * 1)
            .skip((page - 1) * limit);

        const total = await Product.countDocuments(query);

        res.json({
            success: true,
            data: {
                products,
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
            message: 'Error fetching products',
            error: error.message
        });
    }
};

// Get Product By ID
exports.getProductById = async (req, res) => {
    try {
        const { id } = req.params;

        let product;
        if (mongoose.Types.ObjectId.isValid(id)) {
            product = await Product.findById(id)
                .populate('merchant', 'businessName profileImage averageRating address isStoreOpen')
                .populate('category', 'name');
        } else {
            product = await Product.findOne({ slug: id })
                .populate('merchant', 'businessName profileImage averageRating address isStoreOpen')
                .populate('category', 'name');
        }

        if (!product) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        // Restrictions removed for debugging

        // Increment views
        const todayStr = new Date().toISOString().split('T')[0];
        if (product.lastDailyActivity !== todayStr) {
            product.dailyViews = 1;
            product.dailySales = 0;
            product.lastDailyActivity = todayStr;
        } else {
            product.dailyViews = (product.dailyViews || 0) + 1;
        }
        product.views = (product.views || 0) + 1;
        await product.save();

        res.json({
            success: true,
            data: { product }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching product',
            error: error.message
        });
    }
};

// Create Product (Merchant)
exports.createProduct = async (req, res) => {
    try {
        const merchantId = req.user._id;
        const productData = { ...req.body };

        // Check if product with same name already exists for this merchant (Upsert logic)
        const existingProduct = await Product.findOne({
            name: productData.name,
            merchant: merchantId
        });

        if (existingProduct) {
            existingProduct.stock += (parseInt(productData.stock) || 0);

            // Re-activate if it was out of stock
            if (existingProduct.stock > 0 && existingProduct.status === 'out-of-stock') {
                existingProduct.status = 'active';
            }

            await existingProduct.save();

            return res.status(200).json({
                success: true,
                message: 'Product already exists. Stock updated successfully.',
                data: { product: existingProduct }
            });
        }

        // Handle image uploads
        let images = [];
        if (req.files && req.files.length > 0) {
            images = await uploadService.uploadMultipleImages(req.files, 'products');
        }

        // Handle category name to ID resolution if needed
        if (productData.category && !mongoose.Types.ObjectId.isValid(productData.category)) {
            const cat = await Category.findOne({ name: new RegExp(`^${productData.category}$`, 'i') });
            if (cat) {
                productData.category = cat._id;
            } else {
                return res.status(400).json({
                    success: false,
                    message: `Category "${productData.category}" not found.`
                });
            }
        }

        // Map MRP to comparePrice
        if (productData.mrp) {
            productData.comparePrice = productData.mrp;
        }

        // Handle isOrganic tag
        if (productData.isOrganic === true || productData.isOrganic === 'true') {
            if (!productData.tags) productData.tags = [];
            if (!productData.tags.includes('organic')) {
                productData.tags.push('organic');
            }
        }

        const product = await Product.create({
            ...productData,
            merchant: merchantId,
            images: images,
            primaryImage: images[0]?.url || req.body.primaryImage || 'https://res.cloudinary.com/demo/image/upload/sample.jpg'
        });

        res.status(201).json({
            success: true,
            message: 'Product created successfully',
            data: { product }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error creating product',
            error: error.message
        });
    }
};

// Update Product (Merchant)
exports.updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const merchantId = req.user._id;
        const updates = { ...req.body };
        delete updates._id;
        delete updates.id;
        delete updates.merchant;
        delete updates.createdAt;
        delete updates.updatedAt;

        // 1. Check if product exists at all
        const product = await Product.findById(id);

        if (!product) {
            return res.status(404).json({
                success: false,
                message: `Product with ID ${id} not found in database.`
            });
        }

        // 2. Check ownership (skip for Admin)
        if (req.userType !== 'admin' && product.merchant.toString() !== merchantId.toString()) {
            return res.status(403).json({
                success: false,
                message: `Access denied. You do not own this product.`
            });
        }

        // Handle new image uploads
        if (req.files && req.files.length > 0) {
            const newImages = await uploadService.uploadMultipleImages(req.files, 'products');
            updates.images = [...product.images, ...newImages];
            if (!updates.primaryImage) {
                updates.primaryImage = newImages[0]?.url;
            }
        }

        // Handle category name to ID resolution if needed
        if (updates.category && !mongoose.Types.ObjectId.isValid(updates.category)) {
            const cat = await Category.findOne({ name: new RegExp(`^${updates.category}$`, 'i') });
            if (cat) {
                updates.category = cat._id;
            } else {
                return res.status(400).json({
                    success: false,
                    message: `Category "${updates.category}" not found.`
                });
            }
        }

        // Map MRP to comparePrice
        if (updates.mrp) {
            updates.comparePrice = updates.mrp;
        }

        // Handle isOrganic tag
        if (updates.isOrganic === true || updates.isOrganic === 'true') {
            if (!updates.tags) updates.tags = product.tags || [];
            if (!updates.tags.includes('organic')) {
                updates.tags.push('organic');
            }
        } else if (updates.isOrganic === false || updates.isOrganic === 'false') {
            if (updates.tags && updates.tags.includes('organic')) {
                updates.tags = updates.tags.filter(t => t !== 'organic');
            } else if (!updates.tags && product.tags && product.tags.includes('organic')) {
                updates.tags = product.tags.filter(t => t !== 'organic');
            }
        }

        Object.assign(product, updates);
        await product.save();

        res.json({
            success: true,
            message: 'Product updated successfully',
            data: { product }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating product',
            error: error.message
        });
    }
};

// Delete Product (Merchant)
exports.deleteProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const merchantId = req.user._id;

        // 1. Check if product exists at all
        const productCheck = await Product.findById(id);

        if (!productCheck) {
            return res.status(404).json({
                success: false,
                message: `Product with ID ${id} not found in database.`
            });
        }

        // 2. Check ownership (skip for Admin)
        if (req.userType !== 'admin' && productCheck.merchant.toString() !== merchantId.toString()) {
            return res.status(403).json({
                success: false,
                message: `Access denied. You do not own this product.`
            });
        }

        const product = await Product.findByIdAndDelete(id);

        // Delete images from Cloudinary
        if (product.images && product.images.length > 0) {
            const publicIds = product.images.map(img => img.publicId).filter(Boolean);
            await uploadService.deleteMultipleImages(publicIds);
        }

        res.json({
            success: true,
            message: 'Product deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error deleting product',
            error: error.message
        });
    }
};

// Update Stock (Merchant)
exports.updateStock = async (req, res) => {
    try {
        const { id } = req.params;
        const { stock } = req.body;
        const merchantId = req.user._id;

        // 1. Check if product exists at all
        const product = await Product.findById(id);

        if (!product) {
            return res.status(404).json({
                success: false,
                message: `Product with ID ${id} not found in database.`
            });
        }

        // 2. Check ownership
        if (product.merchant.toString() !== merchantId.toString()) {
            return res.status(403).json({
                success: false,
                message: `Access denied. You do not own this product. (Your ID: ${merchantId}, Product Owner: ${product.merchant})`
            });
        }

        product.stock = stock;

        // Update status based on stock
        if (stock === 0) {
            product.status = 'out-of-stock';
        } else if (product.status === 'out-of-stock') {
            product.status = 'active';
        }

        await product.save();

        res.json({
            success: true,
            message: 'Stock updated successfully',
            data: { product }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating stock',
            error: error.message
        });
    }
};

// Get My Products (Merchant)
exports.getMyProducts = async (req, res) => {
    try {
        const merchantId = req.user._id;
        const { page = 1, limit = 12, status } = req.query;

        const query = { merchant: merchantId };
        if (status) query.status = status;

        const products = await Product.find(query)
            .populate('category', 'name')
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit);

        const total = await Product.countDocuments(query);

        res.json({
            success: true,
            data: {
                products,
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
            message: 'Error fetching products',
            error: error.message
        });
    }
};

// Search Products
exports.searchProducts = async (req, res) => {
    try {
        const { q } = req.query;

        if (!q) {
            return res.json({
                success: true,
                data: { products: [] }
            });
        }

        const searchRegex = new RegExp(q, 'i');
        const products = await Product.find({
            $or: [
                { name: searchRegex },
                { description: searchRegex },
                { tags: searchRegex },
                { subCategory: searchRegex }
            ],
            status: 'active'
        })
            .populate('merchant', 'businessName isStoreOpen')
            .limit(20);

        res.json({
            success: true,
            data: { products }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error searching products',
            error: error.message
        });
    }
};

// ─── Nearby Products (Document-driven implementation) ───────────────────────
// GET /api/products/nearby?lat=...&lng=...&radius=5&category=...&search=...&sort=score&page=1&limit=20
// GET /api/products/nearby?all=true  → bypasses location filter, returns all products
// ─── Nearby Products (Internal Helper for Aggregation) ───────────────────────
exports.getNearbyProductsInternal = async ({ lat, lng, radius, category, search, sort, page = 1, limit = 20, all = false }) => {
    const pageNum = parseInt(page);
    const limitNum = Math.min(parseInt(limit), 50);
    const skipNum = (pageNum - 1) * limitNum;
    const radiusKm = parseFloat(radius || 5);

    if (all === true || all === 'true') {
        const productQuery = { status: 'active', isActive: { $ne: false }, stock: { $gt: 0 } };
        if (category) {
            if (mongoose.Types.ObjectId.isValid(category)) {
                productQuery.category = new mongoose.Types.ObjectId(category);
            }
        }
        if (search) {
            const searchRegex = new RegExp(search, 'i');
            productQuery.$or = [{ name: searchRegex }, { description: searchRegex }, { tags: searchRegex }];
        }
        const total = await Product.countDocuments(productQuery);
        const products = await Product.find(productQuery)
            .populate('merchant', 'businessName profileImage averageRating isStoreOpen')
            .populate('category', 'name')
            .sort({ createdAt: -1 })
            .skip(skipNum)
            .limit(limitNum)
            .lean();
        return { products, total, search_radius_km: null, actual_radius_km: null };
    }

    const buyerLat = parseFloat(lat);
    const buyerLng = parseFloat(lng);

    const merchantMatch = { isActive: true, isBlocked: { $ne: true } };

    let categoryId = null;
    if (category && mongoose.Types.ObjectId.isValid(category)) {
        categoryId = new mongoose.Types.ObjectId(category);
    }

    const pipeline = [
        {
            $geoNear: {
                near: { type: 'Point', coordinates: [buyerLng, buyerLat] },
                distanceField: 'distanceMetres',
                maxDistance: radiusKm * 1000,
                spherical: true,
                query: merchantMatch
            }
        },
        {
            $lookup: {
                from: 'products',
                localField: '_id',
                foreignField: 'merchant',
                as: 'products'
            }
        },
        { $unwind: '$products' },
        {
            $match: {
                'products.status': 'active',
                'products.isActive': { $ne: false },
                'products.stock': { $gt: 0 },
                ...(categoryId ? { 'products.category': categoryId } : {}),
                ...(search ? {
                    $or: [
                        { 'products.name': { $regex: search, $options: 'i' } },
                        { 'products.description': { $regex: search, $options: 'i' } },
                        { 'products.tags': { $regex: search, $options: 'i' } }
                    ]
                } : {})
            }
        },
        {
            $addFields: {
                distKm: { $divide: ['$distanceMetres', 1000] },
                rating: { $ifNull: ['$products.averageRating', { $ifNull: ['$averageRating', 0] }] },
                stock: { $ifNull: ['$products.stock', 0] },
                prepTime: { $ifNull: ['$defaultPrepTime', 15] },
                harvestDate: '$products.origin.harvestDate'
            }
        },
        {
            $addFields: {
                proximityScore: { $max: [0, { $subtract: [1, { $divide: ['$distKm', radiusKm] }] }] },
                ratingScore: { $divide: ['$rating', 5] },
                transitTime: { $multiply: [{ $divide: ['$distKm', 20] }, 60] },
                availabilityScore: { $min: [1.0, { $divide: ['$stock', 50] }] },
                daysDiff: {
                    $cond: {
                        if: { $gt: ['$harvestDate', null] },
                        then: { $divide: [{ $subtract: [new Date(), '$harvestDate'] }, 1000 * 60 * 60 * 24] },
                        else: 99
                    }
                }
            }
        },
        {
            $addFields: {
                etaMins: { $round: [{ $add: ['$prepTime', '$transitTime', 10] }, 0] },
                freshnessScore: {
                    $switch: {
                        branches: [
                            { case: { $lte: ['$daysDiff', 1] }, then: 1.0 },
                            { case: { $lte: ['$daysDiff', 2] }, then: 0.7 },
                            { case: { $lte: ['$daysDiff', 3] }, then: 0.3 }
                        ],
                        default: 0.1
                    }
                }
            }
        },
        {
            $addFields: {
                etaScore: { $max: [0, { $subtract: [1, { $divide: ['$etaMins', 120] }] }] },
                reliabilityScore: 0.85 
            }
        },
        {
            $addFields: {
                compositeScore: {
                    $add: [
                        { $multiply: ['$proximityScore', 0.30] },
                        { $multiply: ['$ratingScore', 0.20] },
                        { $multiply: ['$freshnessScore', 0.20] },
                        { $multiply: ['$etaScore', 0.15] },
                        { $multiply: ['$availabilityScore', 0.10] },
                        { $multiply: ['$reliabilityScore', 0.05] }
                    ]
                }
            }
        },
        {
            $project: {
                _id: '$products._id',
                name: '$products.name',
                description: '$products.description',
                category: '$products.category',
                price: '$products.price',
                comparePrice: '$products.comparePrice',
                unit: '$products.unit',
                stock: '$products.stock',
                images: '$products.images',
                primaryImage: '$products.primaryImage',
                averageRating: '$products.averageRating',
                isOrganic: { $in: ['organic', { $ifNull: ['$products.tags', []] }] },
                distance_km: { $round: ['$distKm', 1] },
                distance_label: { $concat: [{ $toString: { $round: ['$distKm', 1] } }, ' km away'] },
                eta_mins: '$etaMins',
                score: { $round: ['$compositeScore', 2] },
                merchant: {
                    _id: '$_id',
                    businessName: '$businessName',
                    profileImage: '$profileImage',
                    averageRating: '$averageRating',
                    isStoreOpen: '$isStoreOpen'
                },
                merchantCity: { $ifNull: ['$address.city', ''] }
            }
        }
    ];

    const sortStage = {};
    if (sort === 'score') sortStage.score = -1;
    else if (sort === 'distance') sortStage.distance_km = 1;
    else if (sort === 'price') sortStage.price = 1;
    else if (sort === 'rating') sortStage.averageRating = -1;
    else sortStage.score = -1;

    pipeline.push({ $sort: sortStage });

    const finalPipeline = [
        ...pipeline,
        {
            $facet: {
                metadata: [{ $count: 'total' }],
                data: [{ $skip: skipNum }, { $limit: limitNum }]
            }
        }
    ];

    const aggregated = await Merchant.aggregate(finalPipeline);
    const products = aggregated[0].data;
    const total = aggregated[0].metadata[0]?.total || 0;

    const populatedProducts = await Product.populate(products, { path: 'category', select: 'name' });
    return { products: populatedProducts, total, search_radius_km: radiusKm, actual_radius_km: radiusKm };
};

// GET /api/products/nearby
exports.getNearbyProducts = async (req, res) => {
    try {
        const { lat, lng } = req.query;
        if (!lat || !lng) {
            // If lat/lng missing, but 'all' is not request, we can't do nearby.
            if (req.query.all !== 'true') {
                 return res.status(400).json({ success: false, message: 'lat and lng query parameters are required' });
            }
        }

        const result = await exports.getNearbyProductsInternal(req.query);

        res.json({
            success: true,
            data: {
                ...result,
                pagination: {
                    page: parseInt(req.query.page || 1),
                    limit: Math.min(parseInt(req.query.limit || 20), 50),
                    total: result.total,
                    pages: Math.ceil(result.total / Math.min(parseInt(req.query.limit || 20), 50))
                }
            }
        });
    } catch (error) {
        console.error('[getNearbyProducts] Error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching nearby products',
            error: error.message
        });
    }
};

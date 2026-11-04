const BulkUploadLog = require('../models/BulkUploadLog');
const { parse } = require('csv-parse/sync');
const { stringify } = require('csv-stringify/sync');
const Product = require('../models/Product');
const Category = require('../models/Category');

/**
 * @desc    Bulk upload products via CSV
 * @route   POST /api/bulk/products/bulk-upload
 * @access  Private (Merchant)
 */
exports.bulkUploadProducts = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                error: 'CSV file is required'
            });
        }

        const results = {
            totalRows: 0,
            successCount: 0,
            errorCount: 0,
            errors: []
        };

        // Parse CSV
        const records = parse(req.file.buffer.toString(), {
            columns: true,
            skip_empty_lines: true,
            trim: true
        });

        results.totalRows = records.length;

        // Process each row
        for (let i = 0; i < records.length; i++) {
            const row = records[i];
            const rowNumber = i + 2; // +2 because row 1 is header

            try {
                // Validate required fields
                if (!row.name || !row.price || !row.stock) {
                    throw new Error('name, price, and stock are required');
                }

                const price = parseFloat(row.price);
                const stock = parseInt(row.stock);

                if (isNaN(price) || price <= 0) {
                    throw new Error('Price must be a positive number');
                }

                if (isNaN(stock) || stock < 0) {
                    throw new Error('Stock must be a non-negative number');
                }

                // Find category
                let categoryId = null;
                if (row.category) {
                    // Escape regex characters so a CSV value can't match other categories
                    const escaped = row.category.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
                    const category = await Category.findOne({
                        name: { $regex: new RegExp(`^${escaped}$`, 'i') }
                    });

                    if (!category) {
                        throw new Error(`Category '${row.category}' not found`);
                    }
                    categoryId = category._id;
                }

                // Parse tags
                const tags = row.tags
                    ? row.tags.split(',').map(t => t.trim()).filter(Boolean)
                    : [];

                // Create product
                const slug = row.name
                    .toLowerCase()
                    .replace(/[^a-z0-9]+/g, '-')
                    .replace(/(^-|-$)/g, '') + `-${Date.now()}`;

                await Product.create({
                    name: row.name,
                    description: row.description || '',
                    category: categoryId,
                    merchant: req.user._id,
                    price,
                    stock,
                    unit: row.unit || 'kg',
                    tags,
                    primaryImage: row.primaryImage || 'https://via.placeholder.com/300',
                    slug,
                    isActive: true
                });

                results.successCount++;
            } catch (error) {
                results.errorCount++;
                results.errors.push({
                    row: rowNumber,
                    data: row,
                    error: error.message
                });
            }
        }

        // Keep a history entry for the merchant's "recent uploads" list
        await BulkUploadLog.create({
            merchant: req.user._id,
            fileName: req.file.originalname,
            totalRows: results.totalRows,
            successCount: results.successCount,
            errorCount: results.errorCount,
            errors: results.errors.slice(0, 20).map(e => ({ row: e.row, error: e.error })),
            status: results.errorCount === 0 ? 'completed' : (results.successCount > 0 ? 'partial' : 'failed')
        }).catch(err => console.error('Bulk upload log error:', err.message));

        res.json({
            success: true,
            message: 'Bulk upload completed',
            data: results
        });
    } catch (error) {
        console.error('Bulk upload error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to process bulk upload',
            details: error.message
        });
    }
};

/**
 * @desc    Bulk update prices
 * @route   PUT /api/bulk/products/bulk-update-price
 * @access  Private (Merchant)
 */
exports.bulkUpdatePrice = async (req, res) => {
    try {
        const { updates } = req.body;

        if (!updates || !Array.isArray(updates) || updates.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'updates array is required'
            });
        }

        if (updates.length > 100) {
            return res.status(400).json({
                success: false,
                error: 'Maximum 100 products can be updated at once'
            });
        }

        const results = {
            successCount: 0,
            errorCount: 0,
            errors: []
        };

        for (const update of updates) {
            try {
                if (!update.productId || update.price === undefined) {
                    throw new Error('productId and price are required');
                }

                const price = (typeof update.price === 'number' || (typeof update.price === 'string' && update.price.trim() !== ''))
                    ? Number(update.price)
                    : NaN;
                if (!Number.isFinite(price) || price <= 0) {
                    throw new Error('Price must be a positive number');
                }

                const product = await Product.findOne({
                    _id: update.productId,
                    merchant: req.user._id
                });

                if (!product) {
                    throw new Error('Product not found or access denied');
                }

                product.price = price;
                await product.save();

                results.successCount++;
            } catch (error) {
                results.errorCount++;
                results.errors.push({
                    productId: update.productId,
                    error: error.message
                });
            }
        }

        res.json({
            success: true,
            message: 'Bulk price update completed',
            data: results
        });
    } catch (error) {
        console.error('Bulk update price error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to bulk update prices',
            details: error.message
        });
    }
};

/**
 * @desc    Bulk update stock
 * @route   PUT /api/bulk/products/bulk-update-stock
 * @access  Private (Merchant)
 */
exports.bulkUpdateStock = async (req, res) => {
    try {
        const { updates } = req.body;

        if (!updates || !Array.isArray(updates) || updates.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'updates array is required'
            });
        }

        if (updates.length > 100) {
            return res.status(400).json({
                success: false,
                error: 'Maximum 100 products can be updated at once'
            });
        }

        const results = {
            successCount: 0,
            errorCount: 0,
            errors: []
        };

        for (const update of updates) {
            try {
                if (!update.productId || update.stock === undefined) {
                    throw new Error('productId and stock are required');
                }

                const stock = (typeof update.stock === 'number' || (typeof update.stock === 'string' && update.stock.trim() !== ''))
                    ? Number(update.stock)
                    : NaN;
                if (!Number.isInteger(stock) || stock < 0) {
                    throw new Error('Stock must be a whole number, zero or more');
                }

                const product = await Product.findOne({
                    _id: update.productId,
                    merchant: req.user._id
                });

                if (!product) {
                    throw new Error('Product not found or access denied');
                }

                // Same rules as PATCH /products/:id/stock
                product.stock = stock;
                if (stock === 0) {
                    product.status = 'out-of-stock';
                } else if (product.status === 'out-of-stock') {
                    product.status = 'active';
                }
                await product.save();

                results.successCount++;
            } catch (error) {
                results.errorCount++;
                results.errors.push({
                    productId: update.productId,
                    error: error.message
                });
            }
        }

        res.json({
            success: true,
            message: 'Bulk stock update completed',
            data: results
        });
    } catch (error) {
        console.error('Bulk update stock error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to bulk update stock',
            details: error.message
        });
    }
};

/**
 * @desc    Export products to CSV
 * @route   GET /api/bulk/products/export
 * @access  Private (Merchant)
 */
exports.exportProducts = async (req, res) => {
    try {
        const products = await Product.find({ merchant: req.user._id })
            .populate('category', 'name')
            .sort({ createdAt: -1 });

        const csvData = products.map(product => ({
            ID: product._id.toString(),
            Name: product.name,
            Description: product.description || '',
            Category: product.category?.name || '',
            Price: product.price,
            Stock: product.stock,
            Unit: product.unit || 'kg',
            Tags: (product.tags || []).join(','),
            IsActive: product.isActive,
            AverageRating: product.averageRating || 0,
            CreatedAt: product.createdAt.toISOString()
        }));

        const csvContent = stringify(csvData, {
            header: true,
            columns: ['ID', 'Name', 'Description', 'Category', 'Price', 'Stock', 'Unit', 'Tags', 'IsActive', 'AverageRating', 'CreatedAt']
        });

        // Set response headers
        const Merchant = require('../models/Merchant');
        const merchant = await Merchant.findById(req.user._id).select('businessName');
        const filename = `${merchant.businessName.replace(/\s+/g, '_')}_products_${Date.now()}.csv`;

        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

        res.send(csvContent);
    } catch (error) {
        console.error('Export products error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to export products',
            details: error.message
        });
    }
};

module.exports = exports;

// GET /api/bulk/products/upload-history — the merchant's recent CSV uploads
exports.getUploadHistory = async (req, res) => {
    try {
        const uploads = await BulkUploadLog.find({ merchant: req.user._id })
            .sort({ createdAt: -1 })
            .limit(20)
            .lean();
        res.json({ success: true, data: uploads });
    } catch (error) {
        res.status(500).json({ success: false, error: 'Failed to fetch upload history', details: error.message });
    }
};

// GET /api/bulk/products/template — CSV template with the columns bulk-upload reads
exports.getUploadTemplate = (req, res) => {
    const csv = [
        'name,description,category,price,stock,unit,tags,primaryImage',
        'Organic Tomatoes,Fresh farm tomatoes,Vegetables,40,100,kg,"organic,fresh",',
        'Spinach Bunch,Leafy greens,Vegetables,25,50,bunch,leafy,'
    ].join('\n') + '\n';
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="greenbasket_products_template.csv"');
    res.send(csv);
};

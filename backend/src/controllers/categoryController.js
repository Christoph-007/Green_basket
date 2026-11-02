const Category = require('../models/Category');
const Product = require('../models/Product');

// @desc    Get all active categories (public)
// @route   GET /api/categories
// @access  Public
exports.getAllCategories = async (req, res) => {
    try {
        const categories = await Category.find({ isActive: { $ne: false } }).sort({ name: 1 });
        res.json({ success: true, data: categories });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error fetching categories', error: error.message });
    }
};

// @desc    Get ALL categories with product counts (admin)
// @route   GET /api/admin/categories
// @access  Admin
exports.getAllCategoriesAdmin = async (req, res) => {
    try {
        const categories = await Category.aggregate([
            { $sort: { name: 1 } },
            {
                $lookup: {
                    from: 'products',
                    let: { catId: '$_id' },
                    pipeline: [
                        { $match: { $expr: { $eq: ['$category', '$$catId'] } } }
                    ],
                    as: '_products'
                }
            },
            { $addFields: { productsCount: { $size: '$_products' } } },
            { $project: { _products: 0 } }
        ]);

        res.json({ success: true, data: categories });
    } catch (error) {
        res.status(500).json({ success: false, message: 'Error fetching categories', error: error.message });
    }
};

// @desc    Get category by ID
// @route   GET /api/categories/:id
// @access  Public
exports.getCategoryById = async (req, res) => {
    try {
        const category = await Category.findById(req.params.id);

        if (!category) {
            return res.status(404).json({
                success: false,
                message: 'Category not found'
            });
        }

        res.json({
            success: true,
            data: category
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching category',
            error: error.message
        });
    }
};

// @desc    Create category
// @route   POST /api/categories
// @access  Admin
exports.createCategory = async (req, res) => {
    try {
        const category = await Category.create(req.body);

        res.status(201).json({
            success: true,
            message: 'Category created successfully',
            data: category
        });
    } catch (error) {
        if (error.code === 11000) {
            return res.status(409).json({
                success: false,
                message: `A category with the name "${req.body.name}" already exists`
            });
        }
        res.status(500).json({
            success: false,
            message: 'Error creating category',
            error: error.message
        });
    }
};

// @desc    Update category
// @route   PUT /api/categories/:id
// @access  Admin
exports.updateCategory = async (req, res) => {
    try {
        const category = await Category.findByIdAndUpdate(
            req.params.id,
            req.body,
            { new: true, runValidators: true }
        );

        if (!category) {
            return res.status(404).json({
                success: false,
                message: 'Category not found'
            });
        }

        if (req.body.isActive === false) {
            await Product.updateMany({ category: req.params.id }, { isActive: false });
        }

        res.json({
            success: true,
            message: 'Category updated successfully',
            data: category
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error updating category',
            error: error.message
        });
    }
};

// @desc    Delete category
// @route   DELETE /api/categories/:id
// @access  Admin
exports.deleteCategory = async (req, res) => {
    try {
        const category = await Category.findByIdAndDelete(req.params.id);

        if (!category) {
            return res.status(404).json({
                success: false,
                message: 'Category not found'
            });
        }

        // Deactivate all products in this category when it's deleted
        await Product.updateMany({ category: req.params.id }, { isActive: false });

        res.json({
            success: true,
            message: 'Category deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error deleting category',
            error: error.message
        });
    }
};

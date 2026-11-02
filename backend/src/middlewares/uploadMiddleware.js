const multer = require('multer');

// Memory storage for Cloudinary
const storage = multer.memoryStorage();

// File filter
const fileFilter = (req, file, cb) => {
    // Accept images only
    if (file.mimetype.startsWith('image/')) {
        cb(null, true);
    } else {
        cb(new Error('Only image files are allowed!'), false);
    }
};

// Multer config
const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    }
});

// Single image upload
exports.uploadSingleImage = upload.single('image');

// Multiple images (products)
exports.uploadProductImages = upload.array('images', 5);

// Recipe image
exports.uploadRecipeImage = upload.single('recipeImage');

// Profile image
exports.uploadProfileImage = upload.single('profileImage');

// Error handling middleware for multer
exports.handleMulterError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({
                success: false,
                message: 'File size too large. Maximum 5MB allowed.'
            });
        }
        return res.status(400).json({
            success: false,
            message: err.message
        });
    }
    next(err);
};

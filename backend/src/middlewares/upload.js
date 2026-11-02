const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('../config/cloudinary');

// Image upload configuration
const imageStorage = new CloudinaryStorage({
    cloudinary: cloudinary,
    params: async (req, file) => {
        return {
            folder: `greenbasket/images/${req.user._id}`,
            allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
            transformation: [
                { width: 2000, height: 2000, crop: 'limit' },
                { quality: 'auto:good' },
                { fetch_format: 'auto' }
            ],
            public_id: `${Date.now()}-${file.originalname.split('.')[0]}`
        };
    }
});

const uploadImage = multer({
    storage: imageStorage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter: (req, file, cb) => {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Only image files are allowed'), false);
        }
    }
});

module.exports = {
    uploadImage: uploadImage.single('file'),
    uploadMultipleImages: uploadImage.array('files', 5)
};

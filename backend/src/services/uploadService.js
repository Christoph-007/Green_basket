const cloudinary = require('../config/cloudinary');
const sharp = require('sharp');

class UploadService {
    /**
     * Upload image to Cloudinary
     */
    async uploadImage(file, folder = 'products') {
        try {
            // Optimize image with sharp
            const optimizedBuffer = await sharp(file.buffer)
                .resize(800, 800, {
                    fit: 'inside',
                    withoutEnlargement: true
                })
                .jpeg({ quality: 85 })
                .toBuffer();

            // Upload to Cloudinary
            const result = await new Promise((resolve, reject) => {
                const uploadStream = cloudinary.uploader.upload_stream(
                    {
                        folder: `green-basket/${folder}`,
                        resource_type: 'image',
                        transformation: [
                            { width: 800, height: 800, crop: 'limit' },
                            { quality: 'auto' },
                            { fetch_format: 'auto' }
                        ]
                    },
                    (error, result) => {
                        if (error) reject(error);
                        else resolve(result);
                    }
                );

                uploadStream.end(optimizedBuffer);
            });

            return {
                url: result.secure_url,
                publicId: result.public_id
            };
        } catch (error) {
            console.error('Upload error:', error);
            throw new Error('Image upload failed');
        }
    }

    /**
     * Upload multiple images
     */
    async uploadMultipleImages(files, folder = 'products') {
        const uploadPromises = files.map(file => this.uploadImage(file, folder));
        return await Promise.all(uploadPromises);
    }

    /**
     * Delete image from Cloudinary
     */
    async deleteImage(publicId) {
        try {
            await cloudinary.uploader.destroy(publicId);
            return { success: true };
        } catch (error) {
            console.error('Delete error:', error);
            throw new Error('Image deletion failed');
        }
    }

    /**
     * Delete multiple images
     */
    async deleteMultipleImages(publicIds) {
        const deletePromises = publicIds.map(id => this.deleteImage(id));
        return await Promise.all(deletePromises);
    }
}

module.exports = new UploadService();

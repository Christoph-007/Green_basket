const Review = require('../models/Review');

exports.getProductReviews = async (req, res) => {
    try {
        const { productId } = req.params;
        const { page = 1, limit = 10 } = req.query;

        const reviews = await Review.find({ product: productId, isVerified: true })
            .populate('customer', 'name profileImage')
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit);

        const total = await Review.countDocuments({ product: productId, isVerified: true });

        res.json({
            success: true,
            data: {
                reviews,
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
            message: 'Error fetching reviews',
            error: error.message
        });
    }
};

exports.getMerchantReviews = async (req, res) => {
    try {
        const { merchantId } = req.params;
        const { page = 1, limit = 10 } = req.query;

        // Assuming reviews are linked to merchant via `merchant` field
        const reviews = await Review.find({ merchant: merchantId, isVerified: true })
            .populate('customer', 'name profileImage')
            .populate('product', 'name images')
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit);

        const total = await Review.countDocuments({ merchant: merchantId, isVerified: true });

        res.json({
            success: true,
            data: {
                reviews,
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
            message: 'Error fetching reviews',
            error: error.message
        });
    }
};

exports.deleteReview = async (req, res) => {
    try {
        const { id } = req.params;
        const review = await Review.findById(id);

        if (!review) {
            return res.status(404).json({
                success: false,
                message: 'Review not found'
            });
        }

        // Check permissions (Admin or the customer who wrote it)
        if (req.userType !== 'admin' && review.customer.toString() !== req.user.id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorized to delete this review'
            });
        }

        await review.deleteOne();

        res.json({
            success: true,
            message: 'Review deleted successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error deleting review',
            error: error.message
        });
    }
};

exports.addReview = async (req, res) => {
    try {
        const { productId, merchantId, orderId, rating, comment, images } = req.body;

        // Validation
        if (!rating || rating < 1 || rating > 5) {
            return res.status(400).json({
                success: false,
                error: 'Rating must be between 1 and 5'
            });
        }

        if (!comment || comment.trim().length < 5) {
            return res.status(400).json({
                success: false,
                error: 'Comment must be at least 5 characters long'
            });
        }


        if (!productId && !merchantId) {
            return res.status(400).json({
                success: false,
                error: 'Either productId or merchantId is required'
            });
        }

        // Verify user has a delivered order for this product/merchant
        const Order = require('../models/Order');
        const orderQuery = {
            customer: req.user._id,
            status: 'delivered'
        };

        if (productId) orderQuery['items.product'] = productId;
        if (merchantId) orderQuery.merchant = merchantId;
        if (orderId) orderQuery._id = orderId;

        const eligibleOrder = await Order.findOne(orderQuery);

        if (!eligibleOrder) {
            return res.status(403).json({
                success: false,
                error: 'You can only review products or merchants from your delivered orders'
            });
        }

        // Check for existing review to prevent duplicates
        const Review = require('../models/Review');
        const existingQuery = { customer: req.user._id };

        if (productId) existingQuery.product = productId;
        if (merchantId) existingQuery.merchant = merchantId;

        const existingReview = await Review.findOne(existingQuery);

        if (existingReview) {
            return res.status(400).json({
                success: false,
                error: 'You have already submitted a review for this item. You can edit your existing review.'
            });
        }

        // Create review
        const review = await Review.create({
            customer: req.user._id,
            product: productId || undefined,
            merchant: merchantId || eligibleOrder.merchant,
            order: eligibleOrder._id,
            rating: parseInt(rating),
            comment: comment.trim(),
            images: images || []
        });

        // Recalculate and update average rating
        if (productId) {
            const Product = require('../models/Product');
            const allProductReviews = await Review.find({ product: productId });
            const avgRating = allProductReviews.reduce((sum, r) => sum + r.rating, 0) / allProductReviews.length;

            await Product.findByIdAndUpdate(productId, {
                averageRating: parseFloat(avgRating.toFixed(1)),
                totalReviews: allProductReviews.length
            });
        }

        if (merchantId || eligibleOrder.merchant) {
            const targetMerchantId = merchantId || eligibleOrder.merchant;
            const Merchant = require('../models/Merchant');
            const allMerchantReviews = await Review.find({ merchant: targetMerchantId });
            const avgRating = allMerchantReviews.reduce((sum, r) => sum + r.rating, 0) / allMerchantReviews.length;

            await Merchant.findByIdAndUpdate(targetMerchantId, {
                averageRating: parseFloat(avgRating.toFixed(1)),
                totalReviews: allMerchantReviews.length
            });

            // Ensure all products in this order reflect this rating too 
            if (!productId && eligibleOrder.items && eligibleOrder.items.length > 0) {
                const Product = require('../models/Product');
                // Use a Set to avoid updating same product multiple times if they bought multiple of it
                const uniqueProductIds = [...new Set(eligibleOrder.items.map(i => i.product.toString()))];
                for (const pId of uniqueProductIds) {
                    const prod = await Product.findById(pId);
                    if (prod) {
                        const newTotal = (prod.totalReviews || 0) + 1;
                        const newAvg = ((prod.averageRating || 0) * (prod.totalReviews || 0) + parseInt(rating)) / newTotal;
                        await Product.findByIdAndUpdate(pId, {
                            averageRating: parseFloat(newAvg.toFixed(1)),
                            totalReviews: newTotal
                        });
                    }
                }
            }
        }





        await review.populate('customer', 'name');

        res.status(201).json({
            success: true,
            message: 'Review submitted successfully',
            data: { review }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to submit review',
            details: error.message
        });
    }
};

exports.getMyReviews = async (req, res) => {
    try {
        const { page = 1, limit = 10 } = req.query;
        const skip = (page - 1) * limit;

        const Review = require('../models/Review'); // Ensure imported

        const [reviews, total] = await Promise.all([
            Review.find({ customer: req.user._id })
                .populate('product', 'name primaryImage price')
                .populate('merchant', 'businessName logo')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Review.countDocuments({ customer: req.user._id })
        ]);

        res.json({
            success: true,
            data: {
                reviews,
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
            error: 'Failed to fetch your reviews',
            details: error.message
        });
    }
};

// ─── Merchant: reply to a review ─────────────────────────────────────────────
exports.replyToReview = async (req, res) => {
    try {
        const { id } = req.params;
        const { comment } = req.body;

        if (!comment || comment.trim().length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Reply comment is required'
            });
        }

        const review = await Review.findById(id);
        if (!review) {
            return res.status(404).json({ success: false, message: 'Review not found' });
        }

        // Only the merchant who owns this review may reply
        if (review.merchant.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: 'Not authorised to reply to this review'
            });
        }

        review.merchantReply = {
            comment: comment.trim(),
            repliedAt: new Date()
        };
        await review.save();

        res.json({
            success: true,
            message: 'Reply posted successfully',
            data: { review }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error posting reply',
            error: error.message
        });
    }
};

exports.updateReview = async (req, res) => {
    try {
        const { id } = req.params;
        const { rating, comment } = req.body;

        const Review = require('../models/Review');
        const review = await Review.findOne({ _id: id, customer: req.user._id });

        if (!review) {
            return res.status(404).json({
                success: false,
                error: 'Review not found or access denied'
            });
        }

        // 7-day edit window
        const daysSinceReview = (Date.now() - review.createdAt) / (24 * 60 * 60 * 1000);
        if (daysSinceReview > 7) {
            return res.status(400).json({
                success: false,
                error: 'Reviews can only be edited within 7 days of submission'
            });
        }

        if (rating !== undefined) {
            if (rating < 1 || rating > 5) {
                return res.status(400).json({ success: false, error: 'Rating must be between 1 and 5' });
            }
            review.rating = parseInt(rating);
        }

        if (comment !== undefined) {
            if (comment.trim().length < 5) {
                return res.status(400).json({ success: false, error: 'Comment must be at least 5 characters' });
            }
            review.comment = comment.trim();
        }

        await review.save();

        // Recalculate average rating
        if (review.product) {
            const Product = require('../models/Product');
            const allReviews = await Review.find({ product: review.product });
            const avgRating = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;
            await Product.findByIdAndUpdate(review.product, { averageRating: parseFloat(avgRating.toFixed(1)) });
        }

        res.json({
            success: true,
            message: 'Review updated successfully',
            data: { review }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to update review',
            details: error.message
        });
    }
};

// ─── Merchant: get reviews for their own store ────────────────────────────────
exports.getMyStoreReviews = async (req, res) => {
    try {
        const merchantId = req.user._id;
        const { page = 1, limit = 20 } = req.query;
        const skip = (page - 1) * limit;

        const [reviews, total] = await Promise.all([
            Review.find({ merchant: merchantId })
                .populate('customer', 'name profileImage')
                .populate('order', 'orderId orderNumber')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Review.countDocuments({ merchant: merchantId })
        ]);

        const allRatings = await Review.find({ merchant: merchantId }, 'rating');
        const avgRating = allRatings.length > 0
            ? (allRatings.reduce((s, r) => s + r.rating, 0) / allRatings.length).toFixed(1)
            : 0;

        res.json({
            success: true,
            data: {
                reviews,
                averageRating: parseFloat(avgRating),
                totalReviews: total,
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
            error: 'Failed to fetch store reviews',
            details: error.message
        });
    }
};


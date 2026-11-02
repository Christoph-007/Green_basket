const PreBooking = require('../models/PreBooking');
const Product = require('../models/Product');
const Cart = require('../models/Cart');

/**
 * @desc    Create a pre-booking
 * @route   POST /api/prebooking
 * @access  Private (User)
 */
exports.createPreBooking = async (req, res) => {
    try {
        const { productId, quantity, expectedAvailability, notes } = req.body;

        // Validation
        if (!productId || !quantity || !expectedAvailability) {
            return res.status(400).json({
                success: false,
                error: 'productId, quantity, and expectedAvailability are required'
            });
        }

        // Check if product exists
        const product = await Product.findById(productId);
        if (!product) {
            return res.status(404).json({
                success: false,
                error: 'Product not found'
            });
        }

        // Check if product supports pre-booking
        if (!product.isPreBookable) {
            return res.status(400).json({
                success: false,
                error: 'This product does not support pre-booking'
            });
        }

        // Check for existing pending pre-booking
        const existingPreBooking = await PreBooking.findOne({
            user: req.user._id,
            product: productId,
            status: 'pending'
        });

        if (existingPreBooking) {
            return res.status(400).json({
                success: false,
                error: 'You already have a pending pre-booking for this product'
            });
        }

        // Validate expected availability date
        const expectedDate = new Date(expectedAvailability);
        if (expectedDate < new Date()) {
            return res.status(400).json({
                success: false,
                error: 'Expected availability date must be in the future'
            });
        }

        // Create pre-booking
        const preBooking = await PreBooking.create({
            user: req.user._id,
            product: productId,
            merchant: product.merchant,
            quantity,
            expectedAvailability: expectedDate,
            notes
        });

        // Populate product details
        await preBooking.populate('product', 'name primaryImage price');
        await preBooking.populate('merchant', 'businessName');

        res.status(201).json({
            success: true,
            message: 'Pre-booking created successfully. You will be notified when the product becomes available.',
            data: {
                preBooking
            }
        });
    } catch (error) {
        console.error('Create pre-booking error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create pre-booking',
            details: error.message
        });
    }
};

/**
 * @desc    Get user's pre-bookings
 * @route   GET /api/prebooking/my-prebookings
 * @access  Private (User)
 */
exports.getMyPreBookings = async (req, res) => {
    try {
        const { status, page = 1, limit = 20 } = req.query;
        const skip = (page - 1) * limit;

        const query = { user: req.user._id };
        if (status) {
            query.status = status;
        }

        const [preBookings, total] = await Promise.all([
            PreBooking.find(query)
                .populate('product', 'name primaryImage price isActive')
                .populate('merchant', 'businessName')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            PreBooking.countDocuments(query)
        ]);

        // Check and update expired bookings
        for (const pb of preBookings) {
            if (pb.checkExpiry()) {
                await pb.save();
            }
        }

        res.json({
            success: true,
            data: {
                preBookings,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('Get my pre-bookings error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch pre-bookings',
            details: error.message
        });
    }
};

/**
 * @desc    Cancel a pre-booking
 * @route   DELETE /api/prebooking/:id
 * @access  Private (User)
 */
exports.cancelPreBooking = async (req, res) => {
    try {
        const preBooking = await PreBooking.findOne({
            _id: req.params.id,
            user: req.user._id,
            status: 'pending'
        });

        if (!preBooking) {
            return res.status(404).json({
                success: false,
                error: 'Pre-booking not found or already processed'
            });
        }

        preBooking.status = 'cancelled';
        await preBooking.save();

        res.json({
            success: true,
            message: 'Pre-booking cancelled successfully'
        });
    } catch (error) {
        console.error('Cancel pre-booking error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to cancel pre-booking',
            details: error.message
        });
    }
};

/**
 * @desc    Mark product as available (Merchant)
 * @route   PATCH /api/prebooking/products/:id/mark-available
 * @access  Private (Merchant)
 */
exports.markProductAvailable = async (req, res) => {
    try {
        const { stock } = req.body;

        // Find product owned by merchant
        const product = await Product.findOne({
            _id: req.params.id,
            merchant: req.user._id
        });

        if (!product) {
            return res.status(404).json({
                success: false,
                error: 'Product not found'
            });
        }

        // Update product
        product.stock = stock || 100;
        product.isActive = true;
        await product.save();

        // Find all pending pre-bookings for this product
        const preBookings = await PreBooking.find({
            product: req.params.id,
            status: 'pending'
        }).populate('user', 'name email');

        // Set expiry date (7 days from now)
        const expiryDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

        // Update pre-bookings and send notifications
        const notificationService = require('../services/notification');
        let notifiedCount = 0;

        for (const pb of preBookings) {
            pb.status = 'available';
            pb.expiryDate = expiryDate;
            await pb.save();

            // Send notification
            if (pb.notifyWhenAvailable) {
                try {
                    await notificationService.send(pb.user._id, 'User', {
                        type: 'prebooking_available',
                        title: 'Pre-booked Item Available!',
                        message: `${product.name} is now available. Order within 7 days to secure your booking.`,
                        data: {
                            preBookingId: pb._id,
                            productId: product._id
                        },
                        channels: ['push', 'email']
                    });
                    notifiedCount++;
                } catch (notifError) {
                    console.error('Notification error:', notifError);
                }
            }
        }

        res.json({
            success: true,
            message: `Product marked as available. ${notifiedCount} user(s) notified.`,
            data: {
                product: {
                    _id: product._id,
                    name: product.name,
                    stock: product.stock
                },
                preBookingsUpdated: preBookings.length,
                usersNotified: notifiedCount
            }
        });
    } catch (error) {
        console.error('Mark product available error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to mark product as available',
            details: error.message
        });
    }
};

/**
 * @desc    Convert pre-booking to order
 * @route   POST /api/prebooking/:id/convert-to-order
 * @access  Private (User)
 */
exports.convertToOrder = async (req, res) => {
    try {
        const preBooking = await PreBooking.findOne({
            _id: req.params.id,
            user: req.user._id,
            status: 'available'
        }).populate('product');

        if (!preBooking) {
            return res.status(404).json({
                success: false,
                error: 'Pre-booking not found or not available'
            });
        }

        // Check if expired
        if (preBooking.expiryDate && new Date() > preBooking.expiryDate) {
            preBooking.status = 'expired';
            await preBooking.save();
            return res.status(400).json({
                success: false,
                error: 'Pre-booking has expired'
            });
        }

        // Check product availability
        if (!preBooking.product.isActive || preBooking.product.stock < preBooking.quantity) {
            return res.status(400).json({
                success: false,
                error: 'Product is no longer available in the requested quantity'
            });
        }

        // Add to cart
        let cart = await Cart.findOne({ user: req.user._id });

        if (!cart) {
            cart = await Cart.create({
                user: req.user._id,
                items: []
            });
        }

        // Check if product already in cart
        const existingItem = cart.items.find(
            item => item.product.toString() === preBooking.product._id.toString()
        );

        if (existingItem) {
            existingItem.quantity += preBooking.quantity;
        } else {
            cart.items.push({
                product: preBooking.product._id,
                quantity: preBooking.quantity,
                price: preBooking.product.price
            });
        }

        await cart.save();

        // Update pre-booking status
        preBooking.status = 'ordered';
        await preBooking.save();

        res.json({
            success: true,
            message: 'Pre-booking converted successfully. Product added to your cart.',
            data: {
                preBooking,
                cart
            }
        });
    } catch (error) {
        console.error('Convert to order error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to convert pre-booking',
            details: error.message
        });
    }
};

/**
 * @desc    Get all pre-bookings (Admin)
 * @route   GET /api/prebooking/admin/all
 * @access  Private (Admin)
 */
exports.getAllPreBookings = async (req, res) => {
    try {
        const { status, page = 1, limit = 20 } = req.query;
        const skip = (page - 1) * limit;

        const query = status ? { status } : {};

        const [preBookings, total] = await Promise.all([
            PreBooking.find(query)
                .populate('user', 'name email')
                .populate('product', 'name primaryImage price')
                .populate('merchant', 'businessName')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            PreBooking.countDocuments(query)
        ]);

        // Get statistics
        const stats = await PreBooking.aggregate([
            {
                $group: {
                    _id: '$status',
                    count: { $sum: 1 }
                }
            }
        ]);

        res.json({
            success: true,
            data: {
                preBookings,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                },
                statistics: stats
            }
        });
    } catch (error) {
        console.error('Get all pre-bookings error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch pre-bookings',
            details: error.message
        });
    }
};

exports.updatePreBookingStatus = async (req, res) => {
    try {
        const { status, notify } = req.body;
        const preBooking = await PreBooking.findOne({
            _id: req.params.id,
            merchant: req.user._id
        }).populate('user', 'name email').populate('product', 'name');

        if (!preBooking) {
            return res.status(404).json({ success: false, error: 'Pre-booking not found' });
        }

        preBooking.status = status;
        if (status === 'available') {
            preBooking.expiryDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days expiry
        }
        await preBooking.save();

        if (notify && status === 'available') {
            const notificationService = require('../services/notification');
            await notificationService.send(
                preBooking.user._id,
                'User',
                {
                    type: 'prebooking_available',
                    title: 'Your Pre-booked Item is Ready!', // Customized title
                    message: `Good news! ${preBooking.product.name} is now available. Please initiate your order within 7 days.`,
                    channels: ['push', 'email'],
                    data: { preBookingId: preBooking._id, productId: preBooking.product._id }
                }
            );
        }

        res.json({
            success: true,
            message: 'Pre-booking status updated',
            data: { preBooking }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

/**
 * @desc    Update pre-booking settings for a product (Merchant)
 * @route   PATCH /api/prebooking/merchant/products/:productId/prebooking
 * @access  Private (Merchant)
 */
exports.updatePreBookingSettings = async (req, res) => {
    try {
        const { productId } = req.params;
        const {
            isPreBookable,
            expectedAvailability,
            preBookingOpenDate,
            maxPreBookingsAllowed,
            preBookingMessage
        } = req.body;

        const product = await Product.findOne({
            _id: productId,
            merchant: req.user._id
        });

        if (!product) {
            return res.status(404).json({
                success: false,
                error: 'Product not found or you do not have permission to edit it'
            });
        }

        // Validate dates
        if (expectedAvailability && new Date(expectedAvailability) <= new Date()) {
            return res.status(400).json({
                success: false,
                error: 'expectedAvailability must be a future date'
            });
        }

        if (isPreBookable !== undefined) {
            product.isPreBookable = Boolean(isPreBookable);
        }

        if (!product.preBookingDetails) {
            product.preBookingDetails = {};
        }

        if (expectedAvailability) {
            product.preBookingDetails.expectedAvailability = new Date(expectedAvailability);
        }

        if (preBookingOpenDate) {
            product.preBookingDetails.preBookingOpenDate = new Date(preBookingOpenDate);
        }

        if (maxPreBookingsAllowed !== undefined) {
            if (maxPreBookingsAllowed < 1) {
                return res.status(400).json({ success: false, error: 'maxPreBookingsAllowed must be at least 1' });
            }
            product.preBookingDetails.maxPreBookingsAllowed = maxPreBookingsAllowed;
        }

        if (preBookingMessage) {
            product.preBookingDetails.preBookingMessage = preBookingMessage;
        }

        await product.save();

        res.json({
            success: true,
            message: 'Pre-booking settings updated successfully',
            data: {
                productId: product._id,
                productName: product.name,
                isPreBookable: product.isPreBookable,
                preBookingDetails: product.preBookingDetails
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to update pre-booking settings',
            details: error.message
        });
    }
};

/**
 * @desc    Get merchant's pre-bookings
 * @route   GET /api/prebooking/merchant/all
 * @access  Private (Merchant)
 */
exports.getMerchantPreBookings = async (req, res) => {
    try {
        const { status, productId, page = 1, limit = 20 } = req.query;

        const query = { merchant: req.user._id };
        if (status) query.status = status;
        if (productId) query.product = productId;

        const skip = (page - 1) * limit;

        const [preBookings, total] = await Promise.all([
            PreBooking.find(query)
                .populate('user', 'name email phone')
                .populate('product', 'name primaryImage price stock')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            PreBooking.countDocuments(query)
        ]);

        const [pendingCount, availableCount, orderedCount] = await Promise.all([
            PreBooking.countDocuments({ merchant: req.user._id, status: 'pending' }),
            PreBooking.countDocuments({ merchant: req.user._id, status: 'available' }),
            PreBooking.countDocuments({ merchant: req.user._id, status: 'ordered' })
        ]);

        res.json({
            success: true,
            data: {
                preBookings,
                stats: {
                    totalPending: pendingCount,
                    totalAvailable: availableCount,
                    totalOrdered: orderedCount
                },
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
            error: 'Failed to fetch merchant pre-bookings',
            details: error.message
        });
    }
};

module.exports = exports;

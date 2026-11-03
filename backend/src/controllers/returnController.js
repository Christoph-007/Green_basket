const mongoose = require('mongoose');
const Return = require('../models/Return');
const Order = require('../models/Order');
const Wallet = require('../models/Wallet');
const { creditWallet } = require('../utils/walletHelpers');

// A return can be requested once the customer has the goods: delivery orders end at
// "delivered" (then "completed"), pickup orders end at "completed".
const RETURNABLE_STATUSES = ['delivered', 'completed'];
const RETURN_WINDOW_DAYS = 7;
const ITEM_CONDITIONS = ['unopened', 'opened', 'damaged', 'wrong_item'];
const REFUND_METHODS = ['wallet', 'original_payment'];
const bad = (res, error) => res.status(400).json({ success: false, error });

/**
 * @desc    Request return/exchange
 * @route   POST /api/returns
 * @access  Private (User)
 */
exports.requestReturn = async (req, res) => {
    try {
        const { orderId, type, reason, items, images, refundMethod, exchangeItems } = req.body;
        const cleanReason = typeof reason === 'string' ? reason.trim() : '';

        if (!orderId || !type || !cleanReason || !Array.isArray(items) || items.length === 0) {
            return res.status(400).json({
                success: false,
                error: 'orderId, type, reason, and items are required'
            });
        }

        if (!['return', 'exchange'].includes(type)) {
            return res.status(400).json({
                success: false,
                error: 'type must be return or exchange'
            });
        }

        if (refundMethod !== undefined && !REFUND_METHODS.includes(refundMethod)) {
            return bad(res, `refundMethod must be one of: ${REFUND_METHODS.join(', ')}`);
        }

        // The app sends the order's database id; API clients may send the readable order number.
        const orderMatch = mongoose.Types.ObjectId.isValid(orderId)
            ? { $or: [{ _id: orderId }, { orderId }] }
            : { orderId };
        const order = await Order.findOne({ ...orderMatch, customer: req.user._id });

        if (!order) {
            return res.status(404).json({
                success: false,
                error: 'Order not found'
            });
        }

        if (!RETURNABLE_STATUSES.includes(order.status)) {
            return bad(res, 'Returns can only be requested for delivered or completed orders');
        }

        // Check 7-day return window
        const deliveredAt = order.deliveredAt || order.updatedAt;
        const daysSinceDelivery = (Date.now() - deliveredAt) / (24 * 60 * 60 * 1000);

        if (daysSinceDelivery > RETURN_WINDOW_DAYS) {
            return bad(res, `Return window (${RETURN_WINDOW_DAYS} days) has expired`);
        }

        // Check for existing active return
        const existingReturn = await Return.findOne({
            order: order._id,
            status: { $nin: ['refunded', 'rejected'] }
        });

        if (existingReturn) {
            return res.status(400).json({
                success: false,
                error: 'A return/exchange request already exists for this order',
                returnId: existingReturn.returnId
            });
        }

        // Validate every item against what was actually ordered, and price the refund from it.
        const returnItems = [];
        const seenProducts = new Set();
        let refundAmount = 0;
        for (const item of items) {
            const productId = item && item.productId;
            if (!productId || !mongoose.Types.ObjectId.isValid(productId)) {
                return bad(res, 'Each item needs a valid productId');
            }
            const orderItem = order.items.find(oi => oi.product.toString() === String(productId));
            if (!orderItem) {
                return bad(res, 'One of the items is not part of this order');
            }
            if (seenProducts.has(String(productId))) {
                return bad(res, 'Each product can only be listed once');
            }
            seenProducts.add(String(productId));

            const quantity = Number(item.quantity);
            const maxQuantity = Math.max(1, Math.ceil(orderItem.quantity));
            if (!Number.isInteger(quantity) || quantity < 1 || quantity > maxQuantity) {
                return bad(res, `Return quantity must be between 1 and ${maxQuantity}`);
            }
            if (item.condition !== undefined && !ITEM_CONDITIONS.includes(item.condition)) {
                return bad(res, `condition must be one of: ${ITEM_CONDITIONS.join(', ')}`);
            }

            returnItems.push({ product: productId, quantity, reason: item.reason, condition: item.condition });
            refundAmount += orderItem.price * quantity;
        }
        refundAmount = Math.round(refundAmount * 100) / 100;

        const returnRequest = await Return.create({
            order: order._id,
            user: req.user._id,
            type,
            reason: cleanReason,
            items: returnItems,
            images: images || [],
            exchangeItems: exchangeItems || [],
            refundAmount,
            refundMethod: refundMethod || 'wallet',
            status: 'requested'
        });

        // Notify user
        try {
            const notificationService = require('../services/notification');
            await notificationService.send(
                req.user._id,
                'User',
                {
                    type: 'order_placed',
                    title: `${type === 'return' ? 'Return' : 'Exchange'} Request Submitted`,
                    message: `Your ${type} request ${returnRequest.returnId} has been submitted and will be reviewed within 24 hours`,
                    channels: ['push', 'email']
                }
            );
        } catch (notifError) {
            console.error('Notification error:', notifError);
        }

        res.status(201).json({
            success: true,
            message: `${type === 'return' ? 'Return' : 'Exchange'} request submitted successfully`,
            data: {
                returnId: returnRequest.returnId,
                _id: returnRequest._id,
                status: returnRequest.status,
                type: returnRequest.type,
                refundAmount
            }
        });
    } catch (error) {
        console.error('Request return error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to submit return request',
            details: error.message
        });
    }
};

/**
 * @desc    Get my returns
 * @route   GET /api/returns/my-returns
 * @access  Private (User)
 */
exports.getMyReturns = async (req, res) => {
    try {
        const { page = 1, limit = 10 } = req.query;
        const skip = (page - 1) * limit;

        const [returns, total] = await Promise.all([
            Return.find({ user: req.user._id })
                .populate('order', 'orderId totalAmount createdAt')
                .populate('items.product', 'name primaryImage price')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Return.countDocuments({ user: req.user._id })
        ]);

        res.json({
            success: true,
            data: {
                returns,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('Get my returns error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch returns',
            details: error.message
        });
    }
};

/**
 * @desc    Get return by ID
 * @route   GET /api/returns/:id
 * @access  Private (User/Admin)
 */
exports.getReturnById = async (req, res) => {
    try {
        const returnRequest = await Return.findById(req.params.id)
            .populate('order', 'orderId totalAmount items')
            .populate('user', 'name email')
            .populate('items.product', 'name primaryImage price')
            .populate('processedBy', 'name');

        if (!returnRequest) {
            return res.status(404).json({ success: false, error: 'Return request not found' });
        }

        const isOwner = returnRequest.user._id.toString() === req.user._id.toString();
        const isAdmin = req.user.userType === 'admin';

        if (!isOwner && !isAdmin) {
            return res.status(403).json({ success: false, error: 'Access denied' });
        }

        res.json({ success: true, data: { return: returnRequest } });
    } catch (error) {
        console.error('Get return by ID error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

/**
 * @desc    Process return (Admin)
 * @route   PUT /api/returns/admin/:id/process
 * @access  Private (Admin)
 */
exports.processReturn = async (req, res) => {
    try {
        const { action, refundAmount, refundMethod, adminNotes, rejectionReason } = req.body;

        if (!action || !['approve', 'reject'].includes(action)) {
            return res.status(400).json({ success: false, error: 'action must be approve or reject' });
        }

        const returnRequest = await Return.findById(req.params.id)
            .populate('order')
            .populate('user', 'name email');

        if (!returnRequest) {
            return res.status(404).json({ success: false, error: 'Return request not found' });
        }

        if (returnRequest.status !== 'requested') {
            return res.status(400).json({ success: false, error: 'Return request has already been processed' });
        }

        if (action === 'approve') {
            returnRequest.status = 'approved';
            returnRequest.refundAmount = refundAmount || returnRequest.refundAmount;
            returnRequest.refundMethod = refundMethod || returnRequest.refundMethod;
            returnRequest.adminNotes = adminNotes;
            returnRequest.processedBy = req.user._id;
            returnRequest.processedAt = new Date();

            // Never refund more than the order was worth
            const orderTotal = returnRequest.order && returnRequest.order.totalAmount;
            if (orderTotal !== undefined && returnRequest.refundAmount > orderTotal) {
                return res.status(400).json({ success: false, error: `Refund amount cannot exceed the order total (${orderTotal})` });
            }

            // Claim the request atomically so two admins can't both refund it
            const claimed = await Return.findOneAndUpdate(
                { _id: returnRequest._id, status: 'requested' },
                { $set: { status: 'approved', processedAt: new Date() } }
            );
            if (!claimed) {
                return res.status(400).json({ success: false, error: 'Return request has already been processed' });
            }

            // Process refund (atomic wallet credit)
            if (returnRequest.refundMethod === 'wallet') {
                await creditWallet(returnRequest.user._id, returnRequest.refundAmount, {
                    source: 'refund',
                    description: `Refund for return ${returnRequest.returnId}`,
                    orderId: returnRequest.order._id
                });
                returnRequest.status = 'refunded';
            }
        } else {
            returnRequest.status = 'rejected';
            returnRequest.rejectionReason = rejectionReason || 'Return request rejected';
            returnRequest.processedBy = req.user._id;
            returnRequest.processedAt = new Date();
        }

        await returnRequest.save();

        // Notify user
        try {
            const notificationService = require('../services/notification');
            await notificationService.send(
                returnRequest.user._id,
                'User',
                {
                    type: 'refund_processed',
                    title: action === 'approve' ? 'Return Approved' : 'Return Rejected',
                    message: action === 'approve'
                        ? `Your return ${returnRequest.returnId} has been approved. ₹${returnRequest.refundAmount} refunded to your wallet.`
                        : `Your return ${returnRequest.returnId} has been rejected. Reason: ${returnRequest.rejectionReason}`,
                    channels: ['push', 'email']
                }
            );
        } catch (notifError) {
            console.error('Notification error:', notifError);
        }

        res.json({ success: true, message: `Return ${action}d successfully`, data: { return: returnRequest } });
    } catch (error) {
        console.error('Process return error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

/**
 * @desc    Get all returns (Admin)
 * @route   GET /api/returns/admin/all
 * @access  Private (Admin)
 */
exports.getAllReturns = async (req, res) => {
    try {
        const { status, type, page = 1, limit = 20 } = req.query;
        const query = {};
        if (status) query.status = status;
        if (type) query.type = type;
        const skip = (page - 1) * limit;
        const [returns, total] = await Promise.all([
            Return.find(query)
                .populate('user', 'name email')
                .populate('order', 'orderId totalAmount')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Return.countDocuments(query)
        ]);
        res.json({
            success: true,
            data: {
                returns,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('Get all returns error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

/**
 * @desc    Cancel return request
 * @route   DELETE /api/returns/:id
 * @access  Private (User)
 */
exports.cancelReturn = async (req, res) => {
    try {
        const returnRequest = await Return.findOneAndUpdate(
            { _id: req.params.id, user: req.user._id, status: 'requested' },
            { status: 'rejected', rejectionReason: 'Cancelled by user' },
            { new: true }
        );
        if (!returnRequest) {
            return res.status(404).json({ success: false, error: 'Return request not found or cannot be cancelled' });
        }
        res.json({ success: true, message: 'Return request cancelled' });
    } catch (error) {
        console.error('Cancel return error:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = exports;

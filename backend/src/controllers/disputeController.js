const mongoose = require('mongoose');
const Dispute = require('../models/Dispute');
const Order = require('../models/Order');
const Wallet = require('../models/Wallet');
const { creditWallet } = require('../utils/walletHelpers');

/**
 * @desc    Raise a dispute
 * @route   POST /api/disputes
 * @access  Private (User)
 */
exports.raiseDispute = async (req, res) => {
    try {
        const { orderId, category, reason, description, images, productId } = req.body;
        const selectedCategory = category || reason;

        // Validation
        if (!orderId || !selectedCategory || !description) {
            return res.status(400).json({
                success: false,
                error: 'orderId, category/reason, and description are required'
            });
        }

        // Find order - try both MongoDB ID and human-readable orderId
        let order;
        if (mongoose.Types.ObjectId.isValid(orderId)) {
            order = await Order.findById(orderId);
        }
        
        if (!order) {
            order = await Order.findOne({ orderId: orderId });
        }

        if (!order) {
            return res.status(404).json({
                success: false,
                error: 'Order not found'
            });
        }

        // Check ownership
        if (order.customer.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                error: 'You can only raise disputes for your own orders'
            });
        }

        // Check if dispute already exists for this order/product
        const query = {
            order: order._id,
            status: { $nin: ['resolved', 'closed'] }
        };
        if (productId) query.product = productId;

        const existingDispute = await Dispute.findOne(query);

        if (existingDispute) {
            return res.status(400).json({
                success: false,
                error: 'An active dispute already exists for this order/item',
                data: {
                    existingDisputeId: existingDispute.disputeId,
                    status: existingDispute.status
                }
            });
        }

        // Determine priority based on category
        const highPriorityCategories = ['missing_item', 'payment_issue', 'damaged_item', 'Wrong Item', 'Quality Issue'];
        const urgentPriorityCategories = ['refund_issue', 'Return Item'];
        let priority = 'medium';

        if (urgentPriorityCategories.includes(selectedCategory)) {
            priority = 'urgent';
        } else if (highPriorityCategories.includes(selectedCategory)) {
            priority = 'high';
        }

        // Create dispute
        const dispute = await Dispute.create({
            order: order._id,
            raisedBy: {
                user: req.user._id,
                userModel: 'User'
            },
            category: selectedCategory,
            description,
            images: images || [],
            priority,
            productId: productId || undefined
        });

        // Notify merchant
        try {
            const notificationService = require('../services/notificationService');
            await notificationService.createNotification({
                recipient: order.merchant,
                recipientModel: 'Merchant',
                type: 'order',
                title: 'New Dispute Raised',
                message: `A dispute has been raised for order ${order.orderId}`,
                data: { disputeId: dispute._id, orderId: order._id }
            });
        } catch (notifError) {
            console.error('Notification error:', notifError);
        }

        res.status(201).json({
            success: true,
            message: 'Dispute raised successfully',
            data: {
                disputeId: dispute.disputeId,
                _id: dispute._id,
                status: dispute.status,
                category: dispute.category,
                priority: dispute.priority
            }
        });
    } catch (error) {
        console.error('Raise dispute error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to raise dispute',
            details: error.message
        });
    }
};

/**
 * @desc    Get merchant disputes
 * @route   GET /api/disputes/merchant/all
 * @access  Private (Merchant)
 */
exports.getMerchantDisputes = async (req, res) => {
    try {
        const merchantId = req.user._id;
        const { status } = req.query;

        // Find orders belonging to this merchant
        const merchantOrders = await Order.find({ merchant: merchantId }).select('_id');
        const orderIds = merchantOrders.map(o => o._id);

        const query = { order: { $in: orderIds } };
        if (status) query.status = status;

        const disputes = await Dispute.find(query)
            .populate('order', 'orderId totalAmount createdAt items')
            .populate('raisedBy.user', 'name email')
            .sort({ createdAt: -1 });

        res.json({
            success: true,
            data: { disputes }
        });
    } catch (error) {
        console.error('Get merchant disputes error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch disputes'
        });
    }
};

/**
 * @desc    Get my disputes
 * @route   GET /api/disputes/my-disputes
 * @access  Private (User)
 */
exports.getMyDisputes = async (req, res) => {
    try {
        const { status, page = 1, limit = 10 } = req.query;

        const query = { 'raisedBy.user': req.user._id };

        if (status) {
            query.status = status;
        }

        const skip = (page - 1) * limit;

        const [disputes, total] = await Promise.all([
            Dispute.find(query)
                .populate('order', 'orderId totalAmount createdAt items')
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Dispute.countDocuments(query)
        ]);

        res.json({
            success: true,
            data: {
                disputes,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('Get my disputes error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch disputes',
            details: error.message
        });
    }
};

/**
 * @desc    Get dispute by ID
 * @route   GET /api/disputes/:id
 * @access  Private (User/Admin)
 */
exports.getDisputeById = async (req, res) => {
    try {
        const { id } = req.params;

        const dispute = await Dispute.findById(id)
            .populate('order', 'orderId totalAmount items createdAt')
            .populate('raisedBy.user', 'name email phone')
            .populate('resolution.resolvedBy', 'name')
            .populate('conversation.from', 'name');

        if (!dispute) {
            return res.status(404).json({
                success: false,
                error: 'Dispute not found'
            });
        }

        // Check access
        const isOwner = dispute.raisedBy.user._id.toString() === req.user._id.toString();
        const isAdmin = req.user.userType === 'admin';

        if (!isOwner && !isAdmin) {
            return res.status(403).json({
                success: false,
                error: 'Access denied'
            });
        }

        res.json({
            success: true,
            data: {
                dispute
            }
        });
    } catch (error) {
        console.error('Get dispute by ID error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch dispute',
            details: error.message
        });
    }
};

/**
 * @desc    Add message to dispute
 * @route   POST /api/disputes/:id/message
 * @access  Private (User/Admin)
 */
exports.addMessage = async (req, res) => {
    try {
        const { id } = req.params;
        const { message, attachments } = req.body;

        if (!message || message.trim().length === 0) {
            return res.status(400).json({
                success: false,
                error: 'Message is required'
            });
        }

        const dispute = await Dispute.findById(id);

        if (!dispute) {
            return res.status(404).json({
                success: false,
                error: 'Dispute not found'
            });
        }

        // Check access
        const isOwner = dispute.raisedBy.user.toString() === req.user._id.toString();
        const isAdmin = req.user.userType === 'admin';

        if (!isOwner && !isAdmin) {
            return res.status(403).json({
                success: false,
                error: 'Access denied'
            });
        }

        // Cannot add message to resolved/closed dispute
        if (['resolved', 'closed'].includes(dispute.status)) {
            return res.status(400).json({
                success: false,
                error: 'Cannot add message to a resolved or closed dispute'
            });
        }

        // Add message
        dispute.conversation.push({
            from: req.user._id,
            fromModel: req.user.userType === 'admin' ? 'Admin' : 'User',
            message: message.trim(),
            attachments: attachments || [],
            timestamp: new Date()
        });

        // If admin responds, update status to investigating
        if (isAdmin && dispute.status === 'open') {
            dispute.status = 'investigating';
        }

        await dispute.save();

        // Populate the conversation before returning
        await dispute.populate('conversation.from', 'name');

        // Notify the other party
        try {
            const notificationService = require('../services/notification');

            if (isAdmin) {
                // Notify user
                await notificationService.send(
                    dispute.raisedBy.user,
                    'User',
                    {
                        type: 'order_placed',
                        title: 'Dispute Update',
                        message: `Admin has responded to your dispute ${dispute.disputeId}`,
                        channels: ['push', 'email'],
                        data: { disputeId: dispute.disputeId }
                    }
                );
            }
        } catch (notifError) {
            console.error('Notification error:', notifError);
        }

        res.json({
            success: true,
            message: 'Message added to dispute',
            data: {
                conversation: dispute.conversation,
                status: dispute.status
            }
        });
    } catch (error) {
        console.error('Add message error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to add message',
            details: error.message
        });
    }
};

/**
 * @desc    Get all disputes (Admin)
 * @route   GET /api/disputes/admin/all
 * @access  Private (Admin)
 */
exports.getAllDisputes = async (req, res) => {
    try {
        const { status, priority, category, page = 1, limit = 20 } = req.query;

        const query = {};

        if (status) query.status = status;
        if (priority) query.priority = priority;
        if (category) query.category = category;

        const skip = (page - 1) * limit;

        const [disputes, total, openCount, investigatingCount, urgentCount] = await Promise.all([
            Dispute.find(query)
                .populate('raisedBy.user', 'name email phone')
                .populate('order', 'orderId totalAmount merchant')
                .sort({ priority: -1, createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            Dispute.countDocuments(query),
            Dispute.countDocuments({ status: 'open' }),
            Dispute.countDocuments({ status: 'investigating' }),
            Dispute.countDocuments({ priority: 'urgent', status: { $nin: ['resolved', 'closed'] } })
        ]);

        res.json({
            success: true,
            data: {
                disputes,
                stats: {
                    totalOpen: openCount,
                    totalInvestigating: investigatingCount,
                    totalUrgent: urgentCount
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
        console.error('Get all disputes error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch disputes',
            details: error.message
        });
    }
};

/**
 * @desc    Resolve dispute (Admin)
 * @route   PUT /api/disputes/admin/:id/resolve
 * @access  Private (Admin)
 */
exports.resolveDispute = async (req, res) => {
    try {
        const { id } = req.params;
        const { resolutionType, amount, description } = req.body;

        if (!resolutionType || !description) {
            return res.status(400).json({
                success: false,
                error: 'resolutionType and description are required'
            });
        }

        const validResolutionTypes = ['refund', 'replacement', 'partial_refund', 'compensation', 'no_action'];
        if (!validResolutionTypes.includes(resolutionType)) {
            return res.status(400).json({
                success: false,
                error: `resolutionType must be one of: ${validResolutionTypes.join(', ')}`
            });
        }

        if (['refund', 'partial_refund', 'compensation'].includes(resolutionType) && !amount) {
            return res.status(400).json({
                success: false,
                error: 'Amount is required for refund/compensation resolutions'
            });
        }

        const dispute = await Dispute.findById(id)
            .populate('order')
            .populate('raisedBy.user', 'name email');

        if (!dispute) {
            return res.status(404).json({
                success: false,
                error: 'Dispute not found'
            });
        }

        if (['resolved', 'closed'].includes(dispute.status)) {
            return res.status(400).json({
                success: false,
                error: 'Dispute is already resolved'
            });
        }

        // Update dispute
        dispute.status = 'resolved';
        dispute.resolution = {
            type: resolutionType,
            amount: amount || 0,
            description,
            resolvedBy: req.user._id,
            resolvedAt: new Date()
        };

        await dispute.save();

        // Process refund/compensation to wallet if applicable
        if (['refund', 'partial_refund', 'compensation'].includes(resolutionType) && amount > 0) {
            // Atomic credit (a save() here would overwrite concurrent wallet changes)
            await creditWallet(dispute.raisedBy.user._id, amount, {
                source: 'refund',
                description: `Dispute resolution - ${dispute.disputeId}: ${description}`,
                orderId: dispute.order._id
            });
        }

        // Notify user
        try {
            const notificationService = require('../services/notification');
            await notificationService.send(
                dispute.raisedBy.user._id,
                'User',
                {
                    type: 'order_delivered',
                    title: 'Dispute Resolved',
                    message: `Your dispute ${dispute.disputeId} has been resolved. ${amount > 0 ? `₹${amount} has been credited to your wallet.` : ''
                        }`,
                    channels: ['push', 'email'],
                    data: {
                        disputeId: dispute.disputeId,
                        resolution: resolutionType,
                        amount
                    }
                }
            );
        } catch (notifError) {
            console.error('Notification error:', notifError);
        }

        res.json({
            success: true,
            message: 'Dispute resolved successfully',
            data: {
                dispute: {
                    disputeId: dispute.disputeId,
                    status: dispute.status,
                    resolution: dispute.resolution
                }
            }
        });
    } catch (error) {
        console.error('Resolve dispute error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to resolve dispute',
            details: error.message
        });
    }
};

/**
 * @desc    Escalate dispute
 * @route   PATCH /api/disputes/:id/escalate
 * @access  Private (User)
 */
exports.escalateDispute = async (req, res) => {
    try {
        const { id } = req.params;

        const dispute = await Dispute.findById(id);

        if (!dispute) {
            return res.status(404).json({
                success: false,
                error: 'Dispute not found'
            });
        }

        // Check ownership
        if (dispute.raisedBy.user.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                error: 'You can only escalate your own disputes'
            });
        }

        if (['resolved', 'closed'].includes(dispute.status)) {
            return res.status(400).json({
                success: false,
                error: 'Cannot escalate a resolved or closed dispute'
            });
        }

        if (dispute.status === 'escalated') {
            return res.status(400).json({
                success: false,
                error: 'Dispute is already escalated'
            });
        }

        dispute.status = 'escalated';
        dispute.priority = 'urgent';

        await dispute.save();

        res.json({
            success: true,
            message: 'Dispute escalated to urgent priority',
            data: {
                disputeId: dispute.disputeId,
                status: dispute.status,
                priority: dispute.priority
            }
        });
    } catch (error) {
        console.error('Escalate dispute error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to escalate dispute',
            details: error.message
        });
    }
};

/**
 * @desc    Update dispute status (Admin)
 * @route   PATCH /api/disputes/admin/:id/status
 * @access  Private (Admin)
 */
exports.updateDisputeStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const validStatuses = ['open', 'investigating', 'resolved', 'closed', 'escalated'];

        if (!status || !validStatuses.includes(status)) {
            return res.status(400).json({
                success: false,
                error: `status must be one of: ${validStatuses.join(', ')}`
            });
        }

        const dispute = await Dispute.findById(id);

        if (!dispute) {
            return res.status(404).json({
                success: false,
                error: 'Dispute not found'
            });
        }

        const previousStatus = dispute.status;
        dispute.status = status;

        await dispute.save();

        // Notify user of status change
        try {
            const notificationService = require('../services/notification');
            await notificationService.send(
                dispute.raisedBy.user,
                'User',
                {
                    type: 'order_placed',
                    title: 'Dispute Status Updated',
                    message: `Your dispute ${dispute.disputeId} status has been updated to ${status}`,
                    channels: ['push'],
                    data: {
                        disputeId: dispute.disputeId,
                        previousStatus,
                        newStatus: status
                    }
                }
            );
        } catch (notifError) {
            console.error('Notification error:', notifError);
        }

        res.json({
            success: true,
            message: `Dispute status updated to ${status}`,
            data: {
                disputeId: dispute.disputeId,
                status: dispute.status,
                previousStatus
            }
        });
    } catch (error) {
        console.error('Update dispute status error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update dispute status',
            details: error.message
        });
    }
};

module.exports = exports;

/**
 * @desc    Resolve dispute (Merchant)
 * @route   PUT /api/disputes/merchant/:id/resolve
 * @access  Private (Merchant)
 */
exports.resolveMerchantDispute = async (req, res) => {
    try {
        const { id } = req.params;
        const { resolutionType, amount, description } = req.body;
        const merchantId = req.user._id;

        if (!resolutionType || !description) {
            return res.status(400).json({
                success: false,
                error: 'resolutionType and description are required'
            });
        }

        const validResolutionTypes = ['refund', 'replacement', 'partial_refund', 'compensation', 'no_action'];
        if (!validResolutionTypes.includes(resolutionType)) {
            return res.status(400).json({
                success: false,
                error: `resolutionType must be one of: ${validResolutionTypes.join(', ')}`
            });
        }

        if (['refund', 'partial_refund', 'compensation'].includes(resolutionType) && !amount) {
            return res.status(400).json({
                success: false,
                error: 'Amount is required for refund/compensation resolutions'
            });
        }

        const dispute = await Dispute.findById(id)
            .populate('order')
            .populate('raisedBy.user', 'name email');

        if (!dispute) {
            return res.status(404).json({
                success: false,
                error: 'Dispute not found'
            });
        }

        // Check Merchant Ownership
        if (dispute.order.merchant.toString() !== merchantId.toString()) {
            return res.status(403).json({
                success: false,
                error: 'Unauthorized: You can only resolve disputes for your own orders'
            });
        }

        if (['resolved', 'closed'].includes(dispute.status)) {
            return res.status(400).json({
                success: false,
                error: 'Dispute is already resolved'
            });
        }

        // Update dispute
        dispute.status = 'resolved';
        dispute.resolution = {
            type: resolutionType,
            amount: amount || 0,
            description,
            resolvedBy: merchantId,
            resolvedAt: new Date()
        };

        await dispute.save();

        // Process refund/compensation to wallet if applicable
        if (['refund', 'partial_refund', 'compensation'].includes(resolutionType) && amount > 0) {
            // Atomic credit (a save() here would overwrite concurrent wallet changes)
            await creditWallet(dispute.raisedBy.user._id, amount, {
                source: 'refund',
                description: `Dispute resolution (by merchant) - ${dispute.disputeId}: ${description}`,
                orderId: dispute.order._id
            });
        }

        // Notify user
        try {
            const notificationService = require('../services/notification');
            await notificationService.send(
                dispute.raisedBy.user._id,
                'User',
                {
                    type: 'order_delivered',
                    title: 'Dispute Resolved',
                    message: `Your dispute ${dispute.disputeId} has been resolved by the merchant. ${amount > 0 ? `₹${amount} has been credited to your wallet.` : ''
                        }`,
                    channels: ['push', 'email'],
                    data: {
                        disputeId: dispute.disputeId,
                        resolution: resolutionType,
                        amount
                    }
                }
            );
        } catch (notifError) {
            console.error('Notification error:', notifError);
        }

        res.json({
            success: true,
            message: 'Dispute resolved successfully',
            data: {
                dispute: {
                    disputeId: dispute.disputeId,
                    status: dispute.status,
                    resolution: dispute.resolution
                }
            }
        });
    } catch (error) {
        console.error('Resolve dispute error:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to resolve dispute',
            details: error.message
        });
    }
};


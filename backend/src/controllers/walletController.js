const Wallet = require('../models/Wallet');
const Order = require('../models/Order');
const paymentService = require('../services/paymentService');
const { ensureWallet, creditWallet, debitWalletForOrder, creditWalletTopup } = require('../utils/walletHelpers');

exports.getWallet = async (req, res) => {
    try {
        const wallet = await ensureWallet(req.user._id);

        // Get recent transactions (last 10)
        const recentTransactions = wallet.transactions
            .sort((a, b) => b.createdAt - a.createdAt)
            .slice(0, 10);

        res.json({
            success: true,
            data: {
                balance: wallet.balance,
                isLocked: wallet.isLocked,
                lockedReason: wallet.lockedReason,
                recentTransactions
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to fetch wallet',
            details: error.message
        });
    }
};

exports.getTransactionHistory = async (req, res) => {
    try {
        const {
            page = 1,
            limit = 20,
            type,
            source,
            startDate,
            endDate
        } = req.query;

        const wallet = await Wallet.findOne({ user: req.user._id });

        if (!wallet) {
            return res.json({
                success: true,
                data: {
                    transactions: [],
                    summary: {
                        totalCredits: 0,
                        totalDebits: 0,
                        netBalance: 0
                    },
                    pagination: {
                        page: 1,
                        limit: 20,
                        total: 0,
                        pages: 0
                    }
                }
            });
        }

        // Filter transactions
        let transactions = [...wallet.transactions];

        if (type) {
            transactions = transactions.filter(t => t.type === type);
        }

        if (source) {
            transactions = transactions.filter(t => t.source === source);
        }

        if (startDate) {
            const start = new Date(startDate);
            transactions = transactions.filter(t => t.createdAt >= start);
        }

        if (endDate) {
            const end = new Date(endDate);
            transactions = transactions.filter(t => t.createdAt <= end);
        }

        // Sort by date (newest first)
        transactions.sort((a, b) => b.createdAt - a.createdAt);

        // Calculate summary
        const summary = {
            totalCredits: wallet.transactions
                .filter(t => t.type === 'credit' && t.status === 'completed')
                .reduce((sum, t) => sum + t.amount, 0),
            totalDebits: wallet.transactions
                .filter(t => t.type === 'debit' && t.status === 'completed')
                .reduce((sum, t) => sum + t.amount, 0),
            netBalance: wallet.balance
        };

        // Pagination
        const total = transactions.length;
        const pages = Math.ceil(total / limit);
        const skip = (page - 1) * limit;
        const paginatedTransactions = transactions.slice(skip, skip + parseInt(limit));

        res.json({
            success: true,
            data: {
                transactions: paginatedTransactions,
                summary,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to fetch transaction history',
            details: error.message
        });
    }
};

exports.addMoney = async (req, res) => {
    try {
        const { amount } = req.body;

        if (!amount || amount <= 0) {
            return res.status(400).json({
                success: false,
                error: 'Valid amount is required'
            });
        }

        if (amount < 10) {
            return res.status(400).json({
                success: false,
                error: 'Minimum topup amount is ₹10'
            });
        }

        if (amount > 10000) {
            return res.status(400).json({
                success: false,
                error: 'Maximum topup amount is ₹10,000'
            });
        }

        // Create Razorpay Order for Wallet Topup
        const razorpayOrder = await paymentService.createRazorpayOrder(
            amount,
            `topup_${Date.now()}`,
            req.user._id.toString(),
            {
                type: 'wallet_topup',
                userId: req.user._id.toString()
            }
        );

        res.json({
            success: true,
            message: 'Wallet topup initiated',
            data: {
                orderId: razorpayOrder.id,
                amount: razorpayOrder.amount, // in paise
                key: process.env.KEY_ID,
                currency: 'INR'
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to initiate wallet topup',
            details: error.message
        });
    }
};

exports.verifyTopup = async (req, res) => {
    try {
        const { razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;
        const userId = req.user._id.toString();

        if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
            return res.status(400).json({
                success: false,
                error: 'razorpayOrderId, razorpayPaymentId and razorpaySignature are required'
            });
        }

        // 1. The signature proves Razorpay issued this payment for this Razorpay order
        const isValid = paymentService.verifyRazorpaySignature(
            razorpayOrderId,
            razorpayPaymentId,
            razorpaySignature
        );
        if (!isValid) {
            return res.status(400).json({ success: false, error: 'Invalid payment signature' });
        }

        // 2. Ask Razorpay what was actually paid. Never trust an amount from the client.
        let rzOrder;
        let payment;
        try {
            [rzOrder, payment] = await Promise.all([
                paymentService.getRazorpayOrder(razorpayOrderId),
                paymentService.getRazorpayPayment(razorpayPaymentId)
            ]);
        } catch (fetchError) {
            return res.status(502).json({
                success: false,
                error: 'Could not confirm payment with Razorpay. Please try again.'
            });
        }

        // 3. It must be a wallet top-up order created by addMoney for THIS user
        const notes = (rzOrder && rzOrder.notes) || {};
        if (notes.type !== 'wallet_topup' || String(notes.userId) !== userId) {
            return res.status(400).json({ success: false, error: 'This payment is not a wallet top-up for your account' });
        }
        if (!payment || payment.order_id !== razorpayOrderId) {
            return res.status(400).json({ success: false, error: 'Payment does not belong to this top-up' });
        }
        if (!['captured', 'authorized'].includes(payment.status)) {
            return res.status(400).json({ success: false, error: `Payment not completed (status: ${payment.status})` });
        }
        if (payment.amount !== rzOrder.amount) {
            return res.status(400).json({ success: false, error: 'Payment amount does not match the top-up amount' });
        }
        const amount = payment.amount / 100; // paise → rupees

        // 4. Credit at most once per payment (atomic, safe against double-submits)
        const wallet = await ensureWallet(req.user._id);
        if (wallet.isLocked) {
            return res.status(403).json({ success: false, error: 'Wallet is locked', reason: wallet.lockedReason });
        }

        const updated = await creditWalletTopup(req.user._id, amount, razorpayPaymentId, razorpayOrderId);
        if (!updated) {
            // Already credited (or locked in between): return the current state idempotently
            const current = await Wallet.findOne({ user: req.user._id });
            if (current && current.isLocked) {
                return res.status(403).json({ success: false, error: 'Wallet is locked', reason: current.lockedReason });
            }
            return res.json({
                success: true,
                message: 'Transaction already processed',
                data: { newBalance: current ? current.balance : 0 }
            });
        }

        const transactionId = updated.transactions[updated.transactions.length - 1]._id;

        // Send notification
        try {
            const notificationService = require('../services/notification');
            await notificationService.send(
                req.user._id,
                'User',
                {
                    type: 'wallet_credit',
                    title: 'Money Added to Wallet',
                    message: `₹${amount} has been added to your wallet`,
                    data: { amount, newBalance: updated.balance },
                    channels: ['push', 'email']
                }
            );
        } catch (notifError) {
            console.error('Notification error:', notifError);
        }

        res.json({
            success: true,
            message: 'Money added to wallet successfully',
            data: {
                amount,
                newBalance: updated.balance,
                transactionId
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to verify wallet topup',
            details: error.message
        });
    }
};

// Pay an existing, unpaid order of the current user with the wallet
// (e.g. switch a payment_pending Razorpay order to wallet). New orders are
// normally paid by wallet directly in POST /api/orders with paymentMethod 'wallet'.
exports.useForPayment = async (req, res) => {
    try {
        const { orderId } = req.body;

        if (!orderId) {
            return res.status(400).json({ success: false, error: 'Order ID is required' });
        }

        const order = await Order.findOne({ orderId, customer: req.user._id });
        if (!order) {
            return res.status(404).json({ success: false, error: 'Order not found' });
        }
        if (['completed', 'paid', 'refunded'].includes(order.paymentStatus)) {
            return res.status(400).json({ success: false, error: 'Order is already paid' });
        }
        if (['cancelled', 'refunded'].includes(order.status)) {
            return res.status(400).json({ success: false, error: 'Order has been cancelled' });
        }

        // The amount always comes from the order, never from the client
        const amount = order.totalAmount;
        if (req.body.amount !== undefined && Math.abs(Number(req.body.amount) - amount) > 0.01) {
            return res.status(400).json({
                success: false,
                error: 'Amount does not match the order total',
                required: amount
            });
        }

        const wallet = await debitWalletForOrder(req.user._id, amount, order._id, order.orderId);
        if (!wallet) {
            const current = await Wallet.findOne({ user: req.user._id });
            if (current && current.isLocked) {
                return res.status(403).json({ success: false, error: 'Wallet is locked', reason: current.lockedReason });
            }
            return res.status(400).json({
                success: false,
                error: 'Insufficient wallet balance',
                available: current ? current.balance : 0,
                required: amount
            });
        }

        // Mark the order paid
        order.paymentMethod = 'wallet';
        order.paymentStatus = 'completed';
        order.paymentGateway = { ...(order.paymentGateway || {}), provider: 'wallet' };
        if (['payment_pending', 'pending'].includes(order.status)) {
            order.updateStatus('confirmed', req.user._id, 'Paid from wallet. Order confirmed.');
            if (!order.confirmedAt) order.confirmedAt = new Date();
        }
        await order.save();

        const transactionId = wallet.transactions[wallet.transactions.length - 1]._id;

        res.json({
            success: true,
            message: 'Payment deducted from wallet',
            data: {
                orderId: order.orderId,
                deductedAmount: amount,
                newBalance: wallet.balance,
                transactionId
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to process wallet payment',
            details: error.message
        });
    }
};

exports.creditRefund = async (req, res) => {
    try {
        const { userId, amount, orderId, description } = req.body;

        if (!userId || !amount || !orderId) {
            return res.status(400).json({
                success: false,
                error: 'userId, amount, and orderId are required'
            });
        }

        const creditAmount = Number(amount);
        if (!(creditAmount > 0)) {
            return res.status(400).json({ success: false, error: 'Amount must be greater than 0' });
        }

        const order = await Order.findOne({ orderId });

        // Atomic credit (a save() would overwrite concurrent wallet changes)
        const wallet = await creditWallet(userId, creditAmount, {
            source: 'refund',
            description: description || `Refund for order ${orderId}`,
            orderId: order?._id
        });

        const transactionId = wallet.transactions[wallet.transactions.length - 1]._id;

        // Send notification
        try {
            const notificationService = require('../services/notification');
            await notificationService.send(
                userId,
                'User',
                {
                    type: 'wallet_credit',
                    title: 'Refund Credited',
                    message: `₹${amount} refund has been credited to your wallet`,
                    data: {
                        amount,
                        orderId,
                        newBalance: wallet.balance
                    },
                    channels: ['push', 'email']
                }
            );
        } catch (notifError) {
            console.error('Notification error:', notifError);
        }

        res.json({
            success: true,
            message: 'Refund credited to wallet',
            data: {
                newBalance: wallet.balance,
                transactionId
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to credit refund',
            details: error.message
        });
    }
};

exports.adminCredit = async (req, res) => {
    try {
        const { userId, amount, description } = req.body;

        if (!userId || !amount) {
            return res.status(400).json({
                success: false,
                error: 'userId and amount are required'
            });
        }

        if (amount <= 0) {
            return res.status(400).json({
                success: false,
                error: 'Amount must be greater than 0'
            });
        }

        // Atomic credit (a save() would overwrite concurrent wallet changes)
        const wallet = await creditWallet(userId, Number(amount), {
            source: 'admin_credit',
            description: description || 'Credit by admin'
        });

        const transactionId = wallet.transactions[wallet.transactions.length - 1]._id;

        // Send notification
        try {
            const notificationService = require('../services/notification');
            await notificationService.send(
                userId,
                'User',
                {
                    type: 'wallet_credit',
                    title: 'Wallet Credited',
                    message: `₹${amount} has been added to your wallet by admin`,
                    data: {
                        amount,
                        description,
                        newBalance: wallet.balance
                    },
                    channels: ['push', 'email']
                }
            );
        } catch (notifError) {
            console.error('Notification error:', notifError);
        }

        res.json({
            success: true,
            message: 'Amount credited to wallet',
            data: {
                newBalance: wallet.balance,
                transactionId
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to credit wallet',
            details: error.message
        });
    }
};

exports.lockUnlockWallet = async (req, res) => {
    try {
        const { userId } = req.params;
        const { lock, reason } = req.body;

        if (lock === undefined) {
            return res.status(400).json({
                success: false,
                error: 'lock parameter is required'
            });
        }

        if (lock && !reason) {
            return res.status(400).json({
                success: false,
                error: 'Reason is required when locking wallet'
            });
        }

        const wallet = await Wallet.findOne({ user: userId });

        if (!wallet) {
            return res.status(404).json({
                success: false,
                error: 'Wallet not found'
            });
        }

        wallet.isLocked = lock;
        wallet.lockedReason = lock ? reason : null;

        await wallet.save();

        // Send notification
        try {
            const notificationService = require('../services/notification');
            await notificationService.send(
                userId,
                'User',
                {
                    type: 'wallet_credit',
                    title: lock ? 'Wallet Locked' : 'Wallet Unlocked',
                    message: lock
                        ? `Your wallet has been locked. Reason: ${reason}`
                        : 'Your wallet has been unlocked',
                    channels: ['push', 'email']
                }
            );
        } catch (notifError) {
            console.error('Notification error:', notifError);
        }

        res.json({
            success: true,
            message: lock ? 'Wallet locked successfully' : 'Wallet unlocked successfully'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: 'Failed to update wallet status',
            details: error.message
        });
    }
};

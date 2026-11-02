const mongoose = require('mongoose');
const Wallet = require('../models/Wallet');

// Add cashback to wallet (atomic)
async function addCashback(userId, amount, orderId, description) {
    try {
        const wallet = await creditWallet(userId, amount, {
            source: 'cashback',
            description: description || `Cashback for order ${orderId}`,
            orderId
        });
        return { success: true, newBalance: wallet.balance };
    } catch (error) {
        console.error('Cashback error:', error);
        return { success: false, error: error.message };
    }
}

// Add referral bonus (atomic)
async function addReferralBonus(userId, amount, referredUserId) {
    try {
        const wallet = await creditWallet(userId, amount, {
            source: 'referral',
            description: 'Referral bonus for referring user',
            referenceId: referredUserId ? String(referredUserId) : undefined
        });
        return { success: true, newBalance: wallet.balance };
    } catch (error) {
        console.error('Referral bonus error:', error);
        return { success: false, error: error.message };
    }
}

/**
 * Atomically credit a user's wallet (creating it if needed). Use this instead
 * of `wallet.balance += x; wallet.save()`, which overwrites concurrent changes.
 */
async function creditWallet(userId, amount, { source, description, orderId, referenceId, paymentId } = {}) {
    await ensureWallet(userId);
    const tx = { type: 'credit', amount, source, description };
    if (orderId) tx.orderId = orderId;
    if (referenceId) tx.referenceId = referenceId;
    if (paymentId) tx.paymentId = paymentId;
    return applyWalletTransaction({ user: userId }, amount, tx);
}

/**
 * Get the user's wallet, creating it if needed. Safe when called concurrently:
 * an upsert race on the unique `user` index is retried as a plain read.
 */
async function ensureWallet(userId) {
    try {
        return await Wallet.findOneAndUpdate(
            { user: userId },
            { $setOnInsert: { user: userId, balance: 0, transactions: [] } },
            { upsert: true, new: true }
        );
    } catch (error) {
        if (error && error.code === 11000) return Wallet.findOne({ user: userId });
        throw error;
    }
}

/**
 * Atomically change a wallet balance and append the matching transaction in
 * ONE conditional pipeline update. Inside a single $set stage every
 * '$balance' refers to the balance BEFORE this update, so balanceBefore and
 * balanceAfter are exact, and two concurrent requests can never both spend
 * (or both credit) based on the same balance.
 *
 * @param {Object} filter  extra conditions the wallet must meet (e.g. balance >= amount)
 * @param {number} delta   +amount for a credit, -amount for a debit
 * @param {Object} tx      transaction fields (type, amount, source, description, orderId, paymentId, referenceId)
 * @returns the updated wallet, or null if no wallet matched the filter
 */
async function applyWalletTransaction(filter, delta, tx) {
    const newBalance = { $add: ['$balance', delta] };
    const entry = {
        _id: new mongoose.Types.ObjectId(),
        status: 'completed',
        createdAt: new Date(),
        ...tx,
        balanceBefore: '$balance',
        balanceAfter: newBalance
    };
    if (typeof entry.description === 'string') entry.description = { $literal: entry.description };

    return Wallet.findOneAndUpdate(
        filter,
        [{
            $set: {
                balance: newBalance,
                transactions: { $concatArrays: [{ $ifNull: ['$transactions', []] }, [entry]] }
            }
        }],
        { new: true }
    );
}

/**
 * Atomically debit a wallet to pay for an order (format matches useForPayment).
 * @returns the updated wallet, or null if the wallet is missing, locked, or has less than `amount`.
 */
async function debitWalletForOrder(userId, amount, orderObjectId, orderNumber) {
    return applyWalletTransaction(
        { user: userId, isLocked: { $ne: true }, balance: { $gte: amount } },
        -amount,
        {
            type: 'debit',
            amount,
            source: 'payment',
            description: `Payment for order ${orderNumber}`,
            orderId: orderObjectId
        }
    );
}

/**
 * Atomically credit money back to a wallet for an order (refunds).
 */
async function creditWalletForOrder(userId, amount, orderObjectId, description) {
    return applyWalletTransaction(
        { user: userId },
        amount,
        {
            type: 'credit',
            amount,
            source: 'refund',
            description,
            orderId: orderObjectId
        }
    );
}

/**
 * Atomically credit a verified Razorpay wallet top-up, at most once per payment.
 * @returns the updated wallet, or null if the wallet is locked or this payment was already credited.
 */
async function creditWalletTopup(userId, amount, razorpayPaymentId, razorpayOrderId) {
    return applyWalletTransaction(
        { user: userId, isLocked: { $ne: true }, 'transactions.paymentId': { $ne: razorpayPaymentId } },
        amount,
        {
            type: 'credit',
            amount,
            source: 'topup',
            description: 'Wallet topup via Razorpay',
            paymentId: razorpayPaymentId,
            referenceId: razorpayOrderId
        }
    );
}

module.exports = {
    creditWallet,
    addCashback,
    addReferralBonus,
    ensureWallet,
    applyWalletTransaction,
    debitWalletForOrder,
    creditWalletForOrder,
    creditWalletTopup
};

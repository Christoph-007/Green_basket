const Product = require('../models/Product');

const MAX_QUANTITY_PER_ITEM = 1000;

/**
 * Parse a requested item quantity. Must be a finite number >= 1 (the Cart and
 * Order schemas use min: 1). Strings like "2" are accepted and converted, so
 * they are never string-concatenated. Returns null when invalid.
 */
function parseQuantity(value) {
    const n = typeof value === 'string' && value.trim() !== '' ? Number(value) : value;
    if (typeof n !== 'number' || !Number.isFinite(n)) return null;
    if (n < 1 || n > MAX_QUANTITY_PER_ITEM) return null;
    return n;
}

/**
 * Atomically reserve stock for every item, or nothing at all.
 *
 * Each decrement only succeeds while `stock >= quantity`, so two customers
 * buying the last unit at the same moment can't both succeed and stock can
 * never go negative. If any item can't be reserved, the items already
 * reserved in this call are released again.
 *
 * @param {Array<{product, quantity, name?}>} items
 * @returns {{ ok: true } | { ok: false, failedItem }}
 */
async function reserveStock(items) {
    const reserved = [];
    for (const item of items) {
        const updated = await Product.findOneAndUpdate(
            { _id: item.product, stock: { $gte: item.quantity } },
            { $inc: { stock: -item.quantity, totalSales: item.quantity } },
            { new: true }
        );
        if (!updated) {
            await restoreStock(reserved);
            return { ok: false, failedItem: item };
        }
        reserved.push(item);
    }
    return { ok: true };
}

/**
 * Give reserved stock back (order failed, cancelled or expired).
 */
async function restoreStock(items) {
    for (const item of items) {
        await Product.findByIdAndUpdate(item.product, {
            $inc: { stock: item.quantity, totalSales: -item.quantity }
        });
    }
}

/**
 * Best-effort daily sales counters, updated after an order is created.
 * Statistics only, so never fails the order.
 */
async function recordDailySales(items) {
    const today = new Date().toISOString().split('T')[0];
    for (const item of items) {
        try {
            // Same day: add to the counter. New day: reset the counter.
            const sameDay = await Product.updateOne(
                { _id: item.product, lastDailyActivity: today },
                { $inc: { dailySales: item.quantity } }
            );
            if (sameDay.modifiedCount === 0) {
                await Product.updateOne(
                    { _id: item.product, lastDailyActivity: { $ne: today } },
                    { $set: { dailySales: item.quantity, dailyViews: 0, lastDailyActivity: today } }
                );
            }
        } catch (error) {
            console.error('[Stock] daily sales update failed:', error.message);
        }
    }
}

module.exports = { parseQuantity, reserveStock, restoreStock, recordDailySales, MAX_QUANTITY_PER_ITEM };

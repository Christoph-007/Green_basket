/**
 * Admin reporting: CSV exports (orders, users, payouts) and the revenue trend
 * that powers the Finance and Dashboard charts.
 *
 *   GET /api/admin/orders/export          ?status&search&from&to
 *   GET /api/admin/users/export           ?search&blocked
 *   GET /api/financial/admin/payouts/export ?status
 *   GET /api/admin/analytics/revenue-trend  ?period=month|quarter|year
 */
const { stringify } = require('csv-stringify/sync');
const Order = require('../models/Order');
const User = require('../models/User');
const Payout = require('../models/Payout');
const { FULFILLED_STATUSES } = require('../utils/orderStatus');

const MAX_ROWS = 10000;

const escapeRegex = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/** Spreadsheet programs run text that starts with = + - @ as a formula. */
const safeCell = (value) => {
    if (value === null || value === undefined) return '';
    if (value instanceof Date) return value.toISOString();
    if (typeof value === 'string' && /^[=+\-@\t\r]/.test(value)) return `'${value}`;
    return value;
};

const sendCsv = (res, filenameBase, header, rows) => {
    const body = stringify([header, ...rows.map(r => r.map(safeCell))]);
    const stamp = new Date().toISOString().slice(0, 10);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${filenameBase}-${stamp}.csv"`);
    // A leading BOM makes Excel read the file as UTF-8 (₹, names, etc.)
    res.status(200).send('﻿' + body);
};

const parseDate = (value) => {
    if (!value) return null;
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? undefined : d;
};

exports.exportOrders = async (req, res) => {
    try {
        const { status, search, from, to } = req.query;
        const query = {};
        if (status && status !== 'all') query.status = status;
        if (search) query.orderId = { $regex: escapeRegex(search), $options: 'i' };

        const fromDate = parseDate(from);
        const toDate = parseDate(to);
        if (fromDate === undefined || toDate === undefined) {
            return res.status(400).json({ success: false, message: 'from and to must be valid dates' });
        }
        if (fromDate || toDate) {
            query.createdAt = {};
            if (fromDate) query.createdAt.$gte = fromDate;
            if (toDate) query.createdAt.$lte = toDate;
        }

        const orders = await Order.find(query)
            .sort({ createdAt: -1 })
            .limit(MAX_ROWS)
            .populate('customer', 'name phone')
            .populate('merchant', 'businessName')
            .lean();

        sendCsv(res, 'orders', [
            'Order ID', 'Date', 'Status', 'Customer', 'Customer phone', 'Merchant',
            'Delivery type', 'Payment method', 'Payment status', 'Items total', 'Delivery charges', 'Total'
        ], orders.map(o => [
            o.orderId, o.createdAt, o.status, o.customer?.name || 'Unknown', o.customer?.phone || '',
            o.merchant?.businessName || 'Unknown', o.deliveryType, o.paymentMethod, o.paymentStatus,
            o.itemsTotal, o.deliveryCharges, o.totalAmount
        ]));
    } catch (error) {
        console.error('Export orders error:', error);
        res.status(500).json({ success: false, message: 'Failed to export orders', details: error.message });
    }
};

exports.exportUsers = async (req, res) => {
    try {
        const { search, blocked } = req.query;
        const query = {};
        if (search) {
            const rx = { $regex: escapeRegex(search), $options: 'i' };
            query.$or = [{ name: rx }, { email: rx }];
        }
        if (blocked === 'true') query.isBlocked = true;
        if (blocked === 'false') query.isBlocked = { $ne: true };

        const users = await User.find(query)
            .select('name email phone createdAt isBlocked')
            .sort({ createdAt: -1 })
            .limit(MAX_ROWS)
            .lean();

        sendCsv(res, 'users', ['Name', 'Email', 'Phone', 'Joined', 'Blocked'],
            users.map(u => [u.name, u.email, u.phone, u.createdAt, u.isBlocked ? 'yes' : 'no']));
    } catch (error) {
        console.error('Export users error:', error);
        res.status(500).json({ success: false, message: 'Failed to export users', details: error.message });
    }
};

exports.exportPayouts = async (req, res) => {
    try {
        const { status } = req.query;
        const query = {};
        if (status && status !== 'all') query.status = status;

        const payouts = await Payout.find(query)
            .sort({ createdAt: -1 })
            .limit(MAX_ROWS)
            .populate('merchant', 'businessName')
            .lean();

        sendCsv(res, 'payouts', [
            'Payout ID', 'Merchant', 'Period start', 'Period end', 'Orders',
            'Gross revenue', 'Commission', 'Net amount', 'Status', 'Created'
        ], payouts.map(p => [
            p.payoutId, p.merchant?.businessName || 'Unknown', p.period?.startDate, p.period?.endDate,
            p.totalOrders, p.grossRevenue, p.platformCommission?.amount, p.netAmount, p.status, p.createdAt
        ]));
    } catch (error) {
        console.error('Export payouts error:', error);
        res.status(500).json({ success: false, message: 'Failed to export payouts', details: error.message });
    }
};

/* ── Revenue trend ─────────────────────────────────────────────────────── */

/** Start (inclusive) and end (exclusive) of the period containing `ref`, in UTC. */
function periodBounds(period, ref) {
    const y = ref.getUTCFullYear();
    const m = ref.getUTCMonth();
    if (period === 'year') {
        return {
            start: new Date(Date.UTC(y, 0, 1)), end: new Date(Date.UTC(y + 1, 0, 1)),
            prevStart: new Date(Date.UTC(y - 1, 0, 1)), prevEnd: new Date(Date.UTC(y, 0, 1))
        };
    }
    if (period === 'quarter') {
        const q = Math.floor(m / 3) * 3;
        return {
            start: new Date(Date.UTC(y, q, 1)), end: new Date(Date.UTC(y, q + 3, 1)),
            prevStart: new Date(Date.UTC(y, q - 3, 1)), prevEnd: new Date(Date.UTC(y, q, 1))
        };
    }
    return {
        start: new Date(Date.UTC(y, m, 1)), end: new Date(Date.UTC(y, m + 1, 1)),
        prevStart: new Date(Date.UTC(y, m - 1, 1)), prevEnd: new Date(Date.UTC(y, m, 1))
    };
}

const dayKey = (d) => d.toISOString().slice(0, 10);
const monthKey = (d) => d.toISOString().slice(0, 7);

/** Every bucket key from start (inclusive) to end (exclusive). */
function bucketKeys(start, end, groupBy) {
    const keys = [];
    const cursor = new Date(start);
    while (cursor < end) {
        keys.push(groupBy === 'month' ? monthKey(cursor) : dayKey(cursor));
        if (groupBy === 'month') cursor.setUTCMonth(cursor.getUTCMonth() + 1);
        else cursor.setUTCDate(cursor.getUTCDate() + 1);
    }
    return keys;
}

async function revenueBuckets(start, end, groupBy) {
    const rows = await Order.aggregate([
        { $match: { status: { $in: FULFILLED_STATUSES } } },
        { $addFields: { effectiveDate: { $ifNull: ['$deliveredAt', '$updatedAt'] } } },
        { $match: { effectiveDate: { $gte: start, $lt: end } } },
        {
            $group: {
                _id: { $dateToString: { format: groupBy === 'month' ? '%Y-%m' : '%Y-%m-%d', date: '$effectiveDate' } },
                revenue: { $sum: '$totalAmount' },
                orders: { $sum: 1 }
            }
        }
    ]);
    const byKey = new Map(rows.map(r => [r._id, r]));
    return bucketKeys(start, end, groupBy).map(key => ({
        date: key,
        revenue: byKey.get(key)?.revenue || 0,
        orders: byKey.get(key)?.orders || 0
    }));
}

const sum = (rows, field) => rows.reduce((t, r) => t + r[field], 0);

exports.getRevenueTrend = async (req, res) => {
    try {
        const period = ['month', 'quarter', 'year'].includes(req.query.period) ? req.query.period : 'month';
        const groupBy = period === 'year' ? 'month' : 'day';
        const now = new Date();
        const { start, end, prevStart, prevEnd } = periodBounds(period, now);

        // The current period only runs up to today, so the line does not trail off into zeros.
        const upTo = new Date(Math.min(end.getTime(), now.getTime()));
        const upToExclusive = groupBy === 'month'
            ? new Date(Date.UTC(upTo.getUTCFullYear(), upTo.getUTCMonth() + 1, 1))
            : new Date(Date.UTC(upTo.getUTCFullYear(), upTo.getUTCMonth(), upTo.getUTCDate() + 1));
        const currentEnd = new Date(Math.min(end.getTime(), upToExclusive.getTime()));

        const [current, previous] = await Promise.all([
            revenueBuckets(start, currentEnd, groupBy),
            revenueBuckets(prevStart, prevEnd, groupBy)
        ]);

        // Compare like with like: the previous period over the same number of days (or months).
        const previousSameWindow = previous.slice(0, current.length);
        const currentRevenue = sum(current, 'revenue');
        const previousRevenueSameWindow = sum(previousSameWindow, 'revenue');
        const changePct = previousRevenueSameWindow > 0
            ? Math.round(((currentRevenue - previousRevenueSameWindow) / previousRevenueSameWindow) * 1000) / 10
            : null;

        res.json({
            success: true,
            data: {
                period,
                groupBy,
                start: start.toISOString(),
                end: end.toISOString(),
                current,
                previous,
                totals: {
                    currentRevenue,
                    currentOrders: sum(current, 'orders'),
                    previousRevenue: sum(previous, 'revenue'),
                    previousRevenueSameWindow,
                    changePct
                }
            }
        });
    } catch (error) {
        console.error('Revenue trend error:', error);
        res.status(500).json({ success: false, message: 'Failed to load revenue trend', details: error.message });
    }
};

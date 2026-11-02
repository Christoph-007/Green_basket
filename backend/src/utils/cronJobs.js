const cron = require('node-cron');

/**
 * Background jobs (started from server.js when the server runs directly).
 *
 * - Every 5 minutes: online orders still waiting for payment after
 *   PAYMENT_PENDING_TIMEOUT_MINUTES (default 30) are checked with Razorpay
 *   (confirmed if they were actually paid) or cancelled, which releases
 *   their reserved stock and coupon use.
 */
const runCronJobs = () => {
    const { expireUnpaidOrders } = require('../services/orderLifecycle');
    const timeout = Number(process.env.PAYMENT_PENDING_TIMEOUT_MINUTES) || 30;
    let running = false;

    cron.schedule('*/5 * * * *', async () => {
        if (running) return; // don't overlap slow runs
        running = true;
        try {
            const summary = await expireUnpaidOrders({ olderThanMinutes: timeout });
            if (summary.checked) {
                console.log(`[Cron] unpaid orders: checked ${summary.checked}, confirmed ${summary.confirmed}, cancelled ${summary.cancelled}`);
            }
        } catch (error) {
            console.error('[Cron] unpaid-order expiry failed:', error.message);
        } finally {
            running = false;
        }
    });

    console.log(`Cron jobs initialized: unpaid-order expiry every 5 min (timeout ${timeout} min).`);
};

module.exports = runCronJobs;

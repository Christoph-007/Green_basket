/**
 * notify.js — Lightweight notification utility
 * Direct wrappers around SendGrid, Twilio, and FCM for transactional messages.
 * Use this for fire-and-forget notifications from controllers.
 * All functions are non-throwing: they log errors and return { success, error? }.
 */

const sendEmailService = require('./email');
const sendSMSService = require('./sms');
const sendPushService = require('./pushNotification');

// ──────────────────────────────────────────────────────────────
//  EMAIL  (SendGrid + Handlebars template)
// ──────────────────────────────────────────────────────────────
/**
 * @param {Object} opts
 * @param {string} opts.to          - recipient email
 * @param {string} opts.subject     - email subject line
 * @param {string} opts.template    - handlebars template name (without .hbs)
 * @param {Object} opts.data        - template variables
 */
const email = async ({ to, subject, template = 'generic', data = {} }) => {
    try {
        if (!to) return { success: false, error: 'No email address' };
        await sendEmailService({ to, subject, template, data });
        console.log(`📧 Email sent → ${to} [${subject}]`);
        return { success: true };
    } catch (err) {
        console.error(`📧 Email failed → ${to}:`, err.message);
        return { success: false, error: err.message };
    }
};

// ──────────────────────────────────────────────────────────────
//  SMS  (Twilio)
// ──────────────────────────────────────────────────────────────
/**
 * @param {string} to      - phone number
 * @param {string} message  - SMS body (max 1600 chars)
 */
const sms = async (to, message) => {
    try {
        if (!to) return { success: false, error: 'No phone number' };
        await sendSMSService({ to, message });
        console.log(`📱 SMS sent → ${to}`);
        return { success: true };
    } catch (err) {
        console.error(`📱 SMS failed → ${to}:`, err.message);
        return { success: false, error: err.message };
    }
};

// ──────────────────────────────────────────────────────────────
//  PUSH  (Firebase Cloud Messaging)
// ──────────────────────────────────────────────────────────────
/**
 * @param {string} userId  - MongoDB user _id (looks up fcmTokens)
 * @param {Object} payload
 * @param {string} payload.title
 * @param {string} payload.message
 * @param {Object} [payload.data]
 */
const push = async (userId, { title, message, data = {} }) => {
    try {
        if (!userId) return { success: false, error: 'No userId' };
        const result = await sendPushService(userId, { title, message, data });
        console.log(`🔔 Push sent → user ${userId} [${title}]`);
        return { success: true, ...result };
    } catch (err) {
        console.error(`🔔 Push failed → user ${userId}:`, err.message);
        return { success: false, error: err.message };
    }
};

// ──────────────────────────────────────────────────────────────
//  MULTI-CHANNEL  (fire all three in parallel)
// ──────────────────────────────────────────────────────────────
/**
 * Send email + SMS + push in parallel (non-blocking, never throws).
 * @param {Object} opts
 * @param {Object}  opts.user        - { _id, email, phone, name }
 * @param {string}  opts.subject     - email subject
 * @param {string}  opts.template    - email template name
 * @param {Object}  opts.templateData - email template variables
 * @param {string}  opts.smsBody     - SMS text
 * @param {string}  opts.pushTitle   - push notification title
 * @param {string}  opts.pushBody    - push notification body
 * @param {Object}  [opts.pushData]  - push notification data payload
 */
const all = async ({
    user,
    subject,
    template = 'generic',
    templateData = {},
    smsBody,
    pushTitle,
    pushBody,
    pushData = {}
}) => {
    console.log(`🌐 Multi-channel notification initiated for user ${user._id || 'unknown'} [${subject}]`);
    
    if (!user.email && !user.phone && !user._id) {
        console.warn('⚠️ No notification channels available for this user');
        return { success: false, error: 'no channels' };
    }

    const results = await Promise.allSettled([
        user.email ? email({ to: user.email, subject, template, data: templateData }) : Promise.resolve({ success: false, reason: 'no email' }),
        user.phone ? sms(user.phone, smsBody || `${pushTitle}: ${pushBody}`) : Promise.resolve({ success: false, reason: 'no phone' }),
        user._id ? push(user._id, { title: pushTitle || subject, message: pushBody || templateData.message || '', data: pushData }) : Promise.resolve({ success: false, reason: 'no push tokens' })
    ]);

    // Log failures
    results.forEach((res, i) => {
        const channels = ['Email', 'SMS', 'Push'];
        if (res.status === 'rejected') {
            console.error(`❌ ${channels[i]} channel failed:`, res.reason);
        } else if (res.value && res.value.success === false) {
            console.log(`ℹ️ ${channels[i]} channel skipped:`, res.value.error || res.value.reason);
        }
    });

    return {
        email: results[0].value || { success: false, error: results[0].reason },
        sms: results[1].value || { success: false, error: results[1].reason },
        push: results[2].value || { success: false, error: results[2].reason }
    };
};

module.exports = { email, sms, push, all };

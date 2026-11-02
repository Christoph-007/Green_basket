/**
 * Allowed browser origins for CORS (REST API and Socket.IO).
 *
 * - The mobile app sends no Origin header: always allowed.
 * - CORS_ORIGINS (comma-separated) or FRONTEND_URL list the allowed web origins.
 * - Development without a list: all origins allowed (previous behaviour).
 * - Production without a list: browsers are blocked (was "*", which let any
 *   website call the API with a user's credentials).
 */
const parseOrigins = () => (process.env.CORS_ORIGINS || process.env.FRONTEND_URL || '')
    .split(',')
    .map(s => s.trim().replace(/\/$/, ''))
    .filter(Boolean);

const corsOrigin = (origin, callback) => {
    if (!origin) return callback(null, true);
    const allowed = parseOrigins();
    if (allowed.length === 0) return callback(null, process.env.NODE_ENV !== 'production');
    return callback(null, allowed.includes(origin.replace(/\/$/, '')));
};

module.exports = { corsOrigin, parseOrigins };

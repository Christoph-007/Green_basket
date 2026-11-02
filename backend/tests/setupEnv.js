/**
 * Jest setup: give tests safe dummy values for config that modules read at
 * require time (e.g. src/config/razorpay.js throws without KEY_ID).
 * Real values from the environment are never overwritten.
 */
const defaults = {
    NODE_ENV: 'test',
    KEY_ID: 'rzp_test_dummykey',
    KEY_SECRET: 'test_razorpay_secret',
    JWT_SECRET: 'test_jwt_secret_at_least_32_characters_long',
    JWT_EXPIRES_IN: '7d',
    REFRESH_TOKEN_SECRET: 'test_refresh_secret_at_least_32_characters',
    REFRESH_TOKEN_EXPIRES_IN: '30d',
    RAZORPAY_WEBHOOK_SECRET: 'test_webhook_secret'
};

for (const [key, value] of Object.entries(defaults)) {
    if (!process.env[key]) process.env[key] = value;
}

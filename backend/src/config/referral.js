/**
 * Referral System Configuration
 * Defines all referral-related constants and settings
 */

const REFERRAL_CONFIG = {
    // Bonus amounts in INR
    referrerBonus: 100,       // ₹100 for referrer when friend completes first order
    referredBonus: 50,        // ₹50 for new user who signs up with referral code

    // Order requirements
    minOrderForReward: 200,   // Minimum order value to trigger referral reward

    // Code generation settings
    codeLength: 8,            // Length of referral code
    codePrefix: 'GB',         // Prefix for all referral codes (GreenBasket)

    // Expiry settings (optional - for future use)
    bonusExpiryDays: 90,      // Days until referral bonus expires if not used

    // Limits
    maxReferralsPerUser: null, // null = unlimited, set number to limit
};

module.exports = REFERRAL_CONFIG;

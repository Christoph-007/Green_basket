const twilio = require('twilio');

const accountSid = process.env.TWILIO_ACCOUNT_SID || '';
const authToken = process.env.TWILIO_AUTH_TOKEN || '';

let client;
if (accountSid && accountSid.startsWith('AC') && authToken) {
    client = twilio(accountSid, authToken);
} else {
    console.warn('Twilio credentials not configured or invalid. SMS sending will be disabled.');
    // Create dummy client
    client = {
        messages: {
            create: async () => {
                throw new Error('Twilio not configured');
            }
        }
    };
}

const sendSMS = async ({ to, message }) => {
    try {
        // Clean the number: remove spaces, dashes, parentheses
        let cleanNumber = to.toString().replace(/[\s\-()]/g, '');

        // Intelligent formatting for Indian numbers
        if (cleanNumber.length === 10) {
            // Case: 9876543210 -> +919876543210
            cleanNumber = `+91${cleanNumber}`;
        } else if (!cleanNumber.startsWith('+')) {
            // Fallback: If no + prefix, assume it needs +91
            cleanNumber = `+91${cleanNumber}`;
        }

        console.log(`[SMS] Sending to ${cleanNumber} (Length: ${message.length})`);

        await client.messages.create({
            body: message,
            from: process.env.TWILIO_PHONE_NUMBER || '+1234567890',
            to: cleanNumber
        });

        console.log(`[SMS] Successfully sent to ${cleanNumber}`);

        return { success: true };
    } catch (error) {
        console.error('SMS sending error:', error);
        throw error;
    }
};

module.exports = sendSMS;

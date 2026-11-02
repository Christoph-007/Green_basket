const client = require('@sendgrid/client');

// Initialize SendGrid Client
if (process.env.SENDGRID_API_KEY) {
    client.setApiKey(process.env.SENDGRID_API_KEY);
} else {
    console.warn('⚠️ SendGrid API Key missing. Contact sync will be disabled.');
}

/**
 * Splits a full name into first and last name.
 * @param {string} fullName - The full name to split.
 * @returns {{firstName: string, lastName: string}}
 */
const splitName = (fullName) => {
    if (!fullName) return { firstName: '', lastName: '' };
    const parts = fullName.trim().split(/\s+/); // Split by whitespace
    const firstName = parts[0];
    const lastName = parts.slice(1).join(' ') || ''; // Join the rest as last name
    return { firstName, lastName };
};

/**
 * Adds a contact to SendGrid Marketing Contacts.
 * Uses PUT /v3/marketing/contacts
 * 
 * @param {Object} user - The user object (must contain email, name/firstName/lastName)
 * @returns {Promise<boolean>} - True if successful, false otherwise
 */
const addContactToSendGrid = async (user) => {
    try {
        if (!process.env.SENDGRID_API_KEY) {
            console.warn('⚠️ SendGrid API Key not set. Skipping contact sync.');
            return false;
        }

        const listId = process.env.SENDGRID_CONTACT_LIST_ID;
        if (!listId) {
            console.warn('⚠️ SendGrid Contact List ID not set (SENDGRID_CONTACT_LIST_ID). Skipping contact sync.');
            return false;
        }

        const { firstName, lastName } = user.firstName ? user : splitName(user.name);

        const data = {
            contacts: [
                {
                    email: user.email,
                    first_name: firstName,
                    last_name: lastName,
                    // custom_fields: {} // Add custom fields here if needed
                }
            ],
            list_ids: [listId] // Add to specific list
        };

        const request = {
            url: '/v3/marketing/contacts',
            method: 'PUT',
            body: data
        };

        // Send request to SendGrid
        const [response, body] = await client.request(request);

        if (response.statusCode >= 200 && response.statusCode < 300) {
            console.log(`✅ Successfully queued user ${user.email} for SendGrid contact sync.`);
            return true;
        } else {
            console.error(`❌ SendGrid Contact Sync failed with status: ${response.statusCode}`);
            return false;
        }

    } catch (error) {
        // Graceful degradation: Log error but don't throw
        console.error('❌ Error adding contact to SendGrid:', error.response ? error.response.body : error.message);
        return false;
    }
};

module.exports = { addContactToSendGrid };

// This service is now an alias for notification.js to consolidate logic
// notification.js handles multi-channel delivery (Email, Push, SMS) and In-App notifications
// It includes adapters for legacy createNotification calls

module.exports = require('./notification');

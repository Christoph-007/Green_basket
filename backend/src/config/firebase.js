// Firebase Admin SDK Configuration
// Note: This requires a serviceAccountKey.json file or environment variables

let admin, messaging;

try {
    admin = require('firebase-admin');

    // Try to initialize with service account file
    try {
        const serviceAccount = require('./serviceAccountKey.json');
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    } catch (fileError) {
        // Fallback to environment variables
        if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
            admin.initializeApp({
                credential: admin.credential.cert({
                    projectId: process.env.FIREBASE_PROJECT_ID,
                    privateKey: (() => {
                        const key = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
                        if (!key.includes('BEGIN PRIVATE KEY')) throw new Error('Invalid PEM format');
                        return key;
                    })(),
                    clientEmail: process.env.FIREBASE_CLIENT_EMAIL
                })
            });
        } else {
            console.warn('Firebase credentials not configured. Push notifications will be disabled.');
        }
    }

    messaging = admin.messaging();
} catch (error) {
    console.warn('Firebase Admin SDK not initialized:', error.message);
    // Create dummy messaging object for graceful degradation
    messaging = {
        sendMulticast: async () => ({ successCount: 0, failureCount: 0, responses: [] })
    };
}

module.exports = { admin, messaging };

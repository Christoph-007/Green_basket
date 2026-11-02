require('dotenv').config();
const { sendEmail } = require('../src/services/emailService');

async function sendTest() {
    const to = process.argv[2] || process.env.EMAIL_USER;

    if (!to) {
        console.error('❌ No recipient specified. Usage: node scripts/send-test-email.js <email>');
        process.exit(1);
    }

    console.log(`📧 Sending test email to ${to}...`);

    try {
        const result = await sendEmail({
            to,
            subject: 'GreenBasket System Test',
            template: 'emailVerification',
            data: {
                name: 'Test Administrator',
                verificationLink: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/test-verify`
            }
        });

        console.log('✅ Email sent successfully!');
        console.log(`   Message ID: ${result.messageId}`);
    } catch (error) {
        console.error('❌ Failed to send email:', error.message);
        if (error.code === 'EAUTH') {
            console.error('   Hint: Check EMAIL_APP_PASSWORD in .env');
        }
    }
}

sendTest();

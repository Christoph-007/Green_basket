const sgMail = require('@sendgrid/mail');
const handlebars = require('handlebars');
const fs = require('fs').promises;
const path = require('path');

const apiKey = process.env.SENDGRID_API_KEY || '';
if (apiKey && apiKey.startsWith('SG.')) {
    sgMail.setApiKey(apiKey);
} else {
    console.warn('SendGrid API key not configured or invalid. Email sending will be disabled.');
}

const sendEmail = async ({ to, subject, template, data }) => {
    try {
        // Load template
        const templatePath = path.join(__dirname, '../templates/email', `${template}.hbs`);

        let html;
        try {
            const templateContent = await fs.readFile(templatePath, 'utf-8');
            const compiledTemplate = handlebars.compile(templateContent);
            html = compiledTemplate(data);
        } catch (templateError) {
            // Fallback to simple HTML if template not found
            console.warn(`[Email] Template ${template} not found or corrupted, using fallback. Recipient: ${to}`);
            const t = (data && data.title) || subject || 'New Notification';
            const m = (data && data.message) || '';
            html = `
        <html>
          <body>
            <h2>${t}</h2>
            <p>${m}</p>
          </body>
        </html>
      `;
        }

        // Send email
        const fromEmail = process.env.EMAIL_FROM || 'noreply@greenbasket.com';
        console.log(`[Email] Sending to ${to} from ${fromEmail} (Subject: ${subject})`);
        
        await sgMail.send({
            to,
            from: {
                email: fromEmail,
                name: 'Green Basket'
            },
            subject,
            html
        });

        console.log(`[Email] Successfully queued for ${to}`);

        return { success: true };
    } catch (error) {
        console.error('Email sending error:', error);
        throw error;
    }
};

module.exports = sendEmail;

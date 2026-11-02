const nodemailer = require('nodemailer');
const emailConfig = require('../config/email');

// Create transporter
const transporter = nodemailer.createTransport({
  service: emailConfig.service,
  auth: {
    user: emailConfig.auth.user,
    pass: emailConfig.auth.pass
  }
});

// Email templates
const templates = {
  emailVerification: (data) => `
    <html>
      <body style="font-family: Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #4CAF50;">Welcome to Green Basket!</h2>
          <p>Hi ${data.name},</p>
          <p>Thank you for signing up. Please verify your email address by clicking the button below:</p>
          <a href="${data.verificationLink}" 
             style="display: inline-block; padding: 12px 24px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 4px; margin: 20px 0;">
            Verify Email
          </a>
          <p>Or copy this link: ${data.verificationLink}</p>
          <p>Best regards,<br>Green Basket Team</p>
        </div>
      </body>
    </html>
  `,

  orderConfirmation: (data) => `
    <html>
      <body style="font-family: Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #4CAF50;">Order Confirmed!</h2>
          <p>Hi ${data.customerName},</p>
          <p>Your order <strong>${data.orderId}</strong> has been confirmed.</p>
          <div style="background-color: #f5f5f5; padding: 15px; border-radius: 4px; margin: 20px 0;">
            <h3>Order Details:</h3>
            <p><strong>Order ID:</strong> ${data.orderId}</p>
            <p><strong>Total Amount:</strong> ₹${data.totalAmount}</p>
            <p><strong>Delivery Address:</strong> ${data.address}</p>
            <p><strong>Expected Delivery:</strong> ${data.deliveryDate}</p>
          </div>
          <p>Track your order at: <a href="${data.trackingLink}">Track Order</a></p>
          <p>Thank you for shopping with us!</p>
        </div>
      </body>
    </html>
  `,

  merchantApproval: (data) => `
    <html>
      <body style="font-family: Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #4CAF50;">Merchant Account Approved!</h2>
          <p>Hi ${data.merchantName},</p>
          <p>Congratulations! Your merchant account has been approved.</p>
          <p>You can now start adding products and receiving orders.</p>
          <a href="${data.dashboardLink}" 
             style="display: inline-block; padding: 12px 24px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 4px; margin: 20px 0;">
            Go to Dashboard
          </a>
          <p>Welcome to Green Basket!</p>
        </div>
      </body>
    </html>
  `,

  passwordReset: (data) => `
    <html>
      <body style="font-family: Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #4CAF50;">Reset Password</h2>
          <p>Hi ${data.name},</p>
          <p>You requested a password reset. Click the button below to reset your password:</p>
          <a href="${data.resetLink}" 
             style="display: inline-block; padding: 12px 24px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 4px; margin: 20px 0;">
            Reset Password
          </a>
          <p>This link will expire in 1 hour.</p>
          <p>If you didn't request this, please ignore this email.</p>
        </div>
      </body>
    </html>
  `
};

// Send email function
const sendEmail = async ({ to, subject, template, data }) => {
  try {
    const htmlContent = templates[template] ? templates[template](data) : (data.html || JSON.stringify(data));

    const mailOptions = {
      from: emailConfig.from,
      to,
      subject,
      html: htmlContent
    };

    console.log(`📧 Sending email to ${to} via Nodemailer (${emailConfig.service})...`);
    const info = await transporter.sendMail(mailOptions);

    console.log('✅ Email sent successfully:', info.messageId);
    return {
      success: true,
      messageId: info.messageId
    };
  } catch (error) {
    console.error('❌ Nodemailer Email Error:', error);
    throw error;
  }
};

module.exports = { sendEmail };

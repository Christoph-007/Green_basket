module.exports = {
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_APP_PASSWORD
    },
    from: `"Green Basket" <${process.env.EMAIL_USER}>`
};

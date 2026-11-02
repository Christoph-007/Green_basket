const jwt = require('jsonwebtoken');

// Access token. tokenType distinguishes it from refresh tokens, which must
// never be accepted as access tokens (and vice versa).
const generateToken = (id, userType) => {
    return jwt.sign(
        { id, userType, tokenType: 'access' },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );
};

module.exports = generateToken;

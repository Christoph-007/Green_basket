const { body } = require('express-validator');

exports.validateSignup = [
    body('name').trim().notEmpty().withMessage('Name is required'),
    body('email').isEmail().withMessage('Please provide a valid email'),
    body('phone').matches(/^[0-9]{10}$/).withMessage('Please provide a valid 10-digit phone number'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
];

exports.validateLogin = [
    body('email').isEmail().withMessage('Please provide a valid email'),
    body('password').notEmpty().withMessage('Password is required')
];

exports.validateProduct = [
    body('name').trim().notEmpty().withMessage('Product name is required'),
    body('description').trim().notEmpty().withMessage('Description is required'),
    body('price').isNumeric().withMessage('Price must be a number'),
    body('stock').isNumeric().withMessage('Stock must be a number'),
    body('category').notEmpty().withMessage('Category is required')
];

exports.validateOrder = [
    body('items').optional().isArray({ min: 1 }).withMessage('Order must have at least one item'),
    body('deliveryAddress').optional().notEmpty().withMessage('Delivery address is required'),
    body('paymentMethod').isIn(['cod', 'online', 'wallet', 'razorpay', 'phonepe']).withMessage('Invalid payment method')
];

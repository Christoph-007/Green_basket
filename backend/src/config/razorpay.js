const Razorpay = require('razorpay');

let instance;

if (process.env.KEY_ID && process.env.KEY_SECRET) {
    instance = new Razorpay({
        key_id: process.env.KEY_ID,
        key_secret: process.env.KEY_SECRET
    });
} else {
    console.warn('⚠️  Razorpay credentials missing (KEY_ID / KEY_SECRET). Razorpay payments will be disabled.');
    instance = new Proxy({}, {
        get(target, prop) {
            return new Proxy({}, {
                get(t, method) {
                    return () => {
                        throw new Error(`Razorpay is not configured. Set KEY_ID and KEY_SECRET in .env to use razorpay.${String(prop)}.${String(method)}`);
                    };
                }
            });
        }
    });
}

module.exports = instance;

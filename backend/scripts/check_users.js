const mongoose = require('mongoose');
require('dotenv').config({ path: '../.env' });

async function checkUsers() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');
        
        const User = mongoose.model('User', new mongoose.Schema({
            email: String,
            name: String
        }, { strict: false }));
        
        const users = await User.find({}, 'email name phone');
        console.log('Total Users:', users.length);
        console.log('User List:', JSON.stringify(users, null, 2));
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error);
        process.exit(1);
    }
}

checkUsers();

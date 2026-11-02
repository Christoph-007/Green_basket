const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load env vars
dotenv.config();

// Load Models
const User = require('../models/User');
const Merchant = require('../models/Merchant');
const Category = require('../models/Category');
const Product = require('../models/Product');
const Recipe = require('../models/Recipe');
const Admin = require('../models/Admin');
const Address = require('../models/Address');

// Sample Data
const admins = [
    {
        name: 'Admin User',
        email: 'admin@greenbasket.com',
        password: 'admin123',
        role: 'super-admin',
        permissions: ['manage-users', 'manage-merchants', 'manage-products', 'manage-orders', 'manage-content', 'view-analytics']
    }
];

const users = [
    {
        name: 'John Doe',
        email: 'user@example.com',
        password: 'password123',
        phone: '9876543210',
        isEmailVerified: true,
        dietaryPreferences: ['vegetarian', 'organic-only'],
        loyaltyPoints: 250,
        loyaltyTier: 'silver'
    },
    {
        name: 'Jane Smith',
        email: 'jane@example.com',
        password: 'password123',
        phone: '9876543211',
        isEmailVerified: true,
        dietaryPreferences: ['non-vegetarian'],
        loyaltyPoints: 500,
        loyaltyTier: 'gold'
    },
    {
        name: 'Rahul Kumar',
        email: 'rahul@example.com',
        password: 'password123',
        phone: '9876543212',
        isEmailVerified: true,
        dietaryPreferences: ['vegetarian', 'gluten-free'],
        loyaltyPoints: 100,
        loyaltyTier: 'bronze'
    },
    {
        name: 'Christoph Leon',
        email: 'christophleon00762@gmail.com',
        password: 'password123',
        phone: '8590328473',
        isEmailVerified: true,
        dietaryPreferences: ['organic-only'],
        loyaltyPoints: 1000,
        loyaltyTier: 'platinum'
    }
];

const merchants = [
    {
        name: 'Farmer Joe',
        email: 'merchant@example.com',
        password: 'password123',
        phone: '9123456780',
        businessName: 'Green Valley Farms',
        merchantType: 'organic-farmer',
        businessDescription: 'Fresh organic produce directly from the valley. Certified organic farming since 2015.',
        address: {
            street: '123 Farm Lane',
            city: 'Bangalore',
            state: 'Karnataka',
            pincode: '560001',
            landmark: 'Near City Hospital'
        },
        location: {
            type: 'Point',
            coordinates: [77.5946, 12.9716] // Bangalore coordinates
        },
        verificationStatus: 'approved',
        isStoreOpen: true,
        deliveryRadius: 15,
        minimumOrderValue: 200,
        deliveryCharges: 40,
        operatingHours: {
            monday: { open: '08:00', close: '18:00', isOpen: true },
            tuesday: { open: '08:00', close: '18:00', isOpen: true },
            wednesday: { open: '08:00', close: '18:00', isOpen: true },
            thursday: { open: '08:00', close: '18:00', isOpen: true },
            friday: { open: '08:00', close: '18:00', isOpen: true },
            saturday: { open: '08:00', close: '14:00', isOpen: true },
            sunday: { open: '00:00', close: '00:00', isOpen: false }
        }
    },
    {
        name: 'Priya Sharma',
        email: 'priya@example.com',
        password: 'password123',
        phone: '9123456781',
        businessName: 'Fresh Harvest',
        merchantType: 'local-farmer',
        businessDescription: 'Local farm-fresh vegetables and fruits delivered daily.',
        address: {
            street: '456 Market Road',
            city: 'Bangalore',
            state: 'Karnataka',
            pincode: '560002'
        },
        location: {
            type: 'Point',
            coordinates: [77.6088, 12.9698]
        },
        verificationStatus: 'approved',
        isStoreOpen: true,
        deliveryRadius: 10,
        minimumOrderValue: 150,
        deliveryCharges: 30
    },
    {
        name: 'Pending Merchant',
        email: 'pending@example.com',
        password: 'password123',
        phone: '9123456782',
        businessName: 'New Farm',
        merchantType: 'home-grower',
        businessDescription: 'Home-grown vegetables',
        address: {
            street: '789 Garden Street',
            city: 'Bangalore',
            state: 'Karnataka',
            pincode: '560003'
        },
        verificationStatus: 'pending',
        isStoreOpen: false
    }
];

const categories = [
    {
        name: 'Vegetables',
        description: 'Fresh organic vegetables',
        image: 'https://res.cloudinary.com/demo/image/upload/v1/vegetables.jpg',
        icon: 'carrot',
        isActive: true
    },
    {
        name: 'Fruits',
        description: 'Seasonal fresh fruits',
        image: 'https://res.cloudinary.com/demo/image/upload/v1/fruits.jpg',
        icon: 'apple',
        isActive: true
    },
    {
        name: 'Spices',
        description: 'Aromatic spices',
        image: 'https://res.cloudinary.com/demo/image/upload/v1/spices.jpg',
        icon: 'pepper',
        isActive: true
    },
    {
        name: 'Dairy',
        description: 'Fresh dairy products',
        image: 'https://res.cloudinary.com/demo/image/upload/v1/dairy.jpg',
        icon: 'milk',
        isActive: true
    },
    {
        name: 'Grains',
        description: 'Organic grains and pulses',
        image: 'https://res.cloudinary.com/demo/image/upload/v1/grains.jpg',
        icon: 'wheat',
        isActive: true
    }
];

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGODB_URI);
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

const importData = async () => {
    try {
        await connectDB();

        console.log('🗑️  Clearing existing data...');

        // Clear existing data
        await User.deleteMany();
        await Merchant.deleteMany();
        await Category.deleteMany();
        await Product.deleteMany();
        await Recipe.deleteMany();
        await Admin.deleteMany();
        await Address.deleteMany();

        console.log('✅ Data Destroyed...\n');

        // Create Admins
        const createdAdmins = await Admin.create(admins);
        console.log(`✅ Created ${createdAdmins.length} Admin(s)`);

        // Create Users
        const createdUsers = await User.create(users);
        console.log(`✅ Created ${createdUsers.length} User(s)`);

        // Create Addresses for users
        const addresses = [
            {
                user: createdUsers[0]._id,
                label: 'home',
                name: 'John Doe',
                phone: '9876543210',
                addressLine1: '123 Main Street',
                addressLine2: 'Apartment 4B',
                landmark: 'Near City Hospital',
                city: 'Bangalore',
                state: 'Karnataka',
                pincode: '560001',
                location: {
                    type: 'Point',
                    coordinates: [77.5946, 12.9716]
                },
                isDefault: true
            },
            {
                user: createdUsers[0]._id,
                label: 'office',
                name: 'John Doe',
                phone: '9876543210',
                addressLine1: '456 Tech Park',
                city: 'Bangalore',
                state: 'Karnataka',
                pincode: '560100',
                isDefault: false
            },
            {
                user: createdUsers[1]._id,
                label: 'home',
                name: 'Jane Smith',
                phone: '9876543211',
                addressLine1: '789 Park Avenue',
                city: 'Bangalore',
                state: 'Karnataka',
                pincode: '560002',
                isDefault: true
            }
        ];

        const createdAddresses = await Address.create(addresses);
        console.log(`✅ Created ${createdAddresses.length} Address(es)`);

        // Create Merchants
        const createdMerchants = await Merchant.create(merchants);
        const merchant1 = createdMerchants[0]._id;
        const merchant2 = createdMerchants[1]._id;
        console.log(`✅ Created ${createdMerchants.length} Merchant(s)`);

        // Create Categories
        const createdCategories = await Category.create(categories);
        console.log(`✅ Created ${createdCategories.length} Categories`);

        const vegCat = createdCategories.find(c => c.name === 'Vegetables');
        const fruitCat = createdCategories.find(c => c.name === 'Fruits');
        const spiceCat = createdCategories.find(c => c.name === 'Spices');
        const dairyCat = createdCategories.find(c => c.name === 'Dairy');

        // Create Products
        const products = [
            // Vegetables
            {
                name: 'Organic Tomatoes',
                description: 'Fresh, juicy tomatoes grown without pesticides. Perfect for salads and cooking.',
                merchant: merchant1,
                category: vegCat._id,
                price: 60,
                comparePrice: 80,
                unit: 'kg',
                stock: 100,
                lowStockThreshold: 10,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/tomato.jpg',
                images: [
                    { url: 'https://res.cloudinary.com/demo/image/upload/v1/tomato.jpg', publicId: 'demo/tomato' }
                ],
                tags: ['organic', 'farm-fresh', 'best-seller'],
                nutritionalInfo: { calories: 18, protein: 0.9, carbohydrates: 3.9, fat: 0.2, fiber: 1.2 },
                preparationOptions: [
                    { type: 'whole', additionalPrice: 0 },
                    { type: 'chopped', additionalPrice: 5 }
                ],
                availableMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
                status: 'active'
            },
            {
                name: 'Organic Ooty Carrot',
                description: 'Sweet and crunchy organic carrots from Ooty hills.',
                merchant: merchant1,
                category: vegCat._id,
                price: 70,
                comparePrice: 90,
                unit: 'kg',
                stock: 80,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/carrot.jpg',
                images: [
                    { url: 'https://res.cloudinary.com/demo/image/upload/v1/carrot.jpg', publicId: 'demo/carrot' }
                ],
                tags: ['organic', 'farm-fresh'],
                nutritionalInfo: { calories: 41, protein: 0.9, carbohydrates: 9.6, fat: 0.2, fiber: 2.8 },
                availableMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            },
            {
                name: 'Potato',
                description: 'Organic potatoes suitable for all dishes.',
                merchant: merchant1,
                category: vegCat._id,
                price: 40,
                unit: 'kg',
                stock: 200,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/potato.jpg',
                tags: ['organic', 'farm-fresh'],
                availableMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            },
            {
                name: 'Onions',
                description: 'Fresh red onions, essential for Indian cooking.',
                merchant: merchant2,
                category: vegCat._id,
                price: 50,
                unit: 'kg',
                stock: 150,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/onion.jpg',
                tags: ['farm-fresh', 'best-seller'],
                availableMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            },
            {
                name: 'Spinach',
                description: 'Fresh green spinach, rich in iron.',
                merchant: merchant2,
                category: vegCat._id,
                price: 30,
                unit: 'bundle',
                stock: 50,
                lowStockThreshold: 5,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/spinach.jpg',
                tags: ['organic', 'farm-fresh'],
                nutritionalInfo: { calories: 23, protein: 2.9, carbohydrates: 3.6, fat: 0.4, fiber: 2.2 },
                availableMonths: [10, 11, 12, 1, 2, 3]
            },

            // Fruits
            {
                name: 'Red Delicious Apple',
                description: 'Fresh apples from Kashmir valley.',
                merchant: merchant1,
                category: fruitCat._id,
                price: 180,
                comparePrice: 220,
                unit: 'kg',
                stock: 50,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/apple.jpg',
                tags: ['seasonal', 'best-seller'],
                nutritionalInfo: { calories: 52, protein: 0.3, carbohydrates: 14, fat: 0.2, fiber: 2.4 },
                availableMonths: [9, 10, 11, 12]
            },
            {
                name: 'Banana',
                description: 'Fresh bananas from Kerala.',
                merchant: merchant2,
                category: fruitCat._id,
                price: 50,
                unit: 'dozen',
                stock: 100,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/banana.jpg',
                tags: ['farm-fresh', 'best-seller'],
                nutritionalInfo: { calories: 89, protein: 1.1, carbohydrates: 23, fat: 0.3, fiber: 2.6 },
                availableMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            },
            {
                name: 'Mango (Alphonso)',
                description: 'King of mangoes - Alphonso from Ratnagiri.',
                merchant: merchant1,
                category: fruitCat._id,
                price: 300,
                comparePrice: 350,
                unit: 'kg',
                stock: 30,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/mango.jpg',
                tags: ['seasonal', 'best-seller'],
                availableMonths: [3, 4, 5, 6],
                status: 'coming-soon'
            },

            // Spices
            {
                name: 'Turmeric Powder',
                description: 'Pure organic turmeric powder.',
                merchant: merchant1,
                category: spiceCat._id,
                price: 120,
                unit: 'g',
                stock: 60,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/turmeric.jpg',
                tags: ['organic'],
                availableMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            },
            {
                name: 'Chilli Powder',
                description: 'Hot and spicy red chilli powder.',
                merchant: merchant2,
                category: spiceCat._id,
                price: 100,
                unit: 'g',
                stock: 70,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/chilli.jpg',
                tags: ['organic'],
                availableMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            },

            // Dairy
            {
                name: 'Fresh Milk',
                description: 'Farm-fresh cow milk.',
                merchant: merchant2,
                category: dairyCat._id,
                price: 60,
                unit: 'liter',
                stock: 40,
                lowStockThreshold: 10,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/milk.jpg',
                tags: ['farm-fresh'],
                availableMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
            },

            // Low stock product
            {
                name: 'Broccoli',
                description: 'Fresh broccoli florets.',
                merchant: merchant1,
                category: vegCat._id,
                price: 80,
                unit: 'kg',
                stock: 5,
                lowStockThreshold: 10,
                primaryImage: 'https://res.cloudinary.com/demo/image/upload/v1/broccoli.jpg',
                tags: ['organic', 'seasonal'],
                availableMonths: [10, 11, 12, 1, 2, 3]
            }
        ];

        const createdProducts = await Product.create(products);
        console.log(`✅ Created ${createdProducts.length} Product(s)`);

        // Create Recipes
        const carrot = createdProducts.find(p => p.name === 'Organic Ooty Carrot');
        const potato = createdProducts.find(p => p.name === 'Potato');
        const tomato = createdProducts.find(p => p.name === 'Organic Tomatoes');
        const onion = createdProducts.find(p => p.name === 'Onions');
        const spinach = createdProducts.find(p => p.name === 'Spinach');

        const recipes = [
            {
                name: 'Vegetable Curry',
                description: 'A delicious and healthy mixed vegetable curry perfect for lunch or dinner.',
                image: 'https://res.cloudinary.com/demo/image/upload/v1/curry.jpg',
                videoUrl: 'https://youtube.com/watch?v=example',
                cuisine: 'south-indian',
                category: 'lunch',
                servings: 4,
                prepTime: 20,
                cookTime: 30,
                difficulty: 'medium',
                ingredients: [
                    {
                        name: 'Carrots',
                        quantity: 0.2,
                        unit: 'kg',
                        product: carrot._id,
                        isOptional: false
                    },
                    {
                        name: 'Potatoes',
                        quantity: 0.3,
                        unit: 'kg',
                        product: potato._id,
                        isOptional: false
                    },
                    {
                        name: 'Tomatoes',
                        quantity: 0.2,
                        unit: 'kg',
                        product: tomato._id,
                        isOptional: false
                    },
                    {
                        name: 'Onions',
                        quantity: 0.15,
                        unit: 'kg',
                        product: onion._id,
                        isOptional: false
                    }
                ],
                instructions: [
                    { stepNumber: 1, instruction: 'Heat oil in a pan and add cumin seeds.' },
                    { stepNumber: 2, instruction: 'Add chopped onions and sauté until golden brown.' },
                    { stepNumber: 3, instruction: 'Add chopped tomatoes and cook until soft.' },
                    { stepNumber: 4, instruction: 'Add all vegetables and spices, mix well.' },
                    { stepNumber: 5, instruction: 'Add water and cook covered for 20 minutes.' },
                    { stepNumber: 6, instruction: 'Garnish with coriander and serve hot.' }
                ],
                nutritionalInfo: {
                    calories: 250,
                    protein: 8,
                    carbohydrates: 35,
                    fat: 10,
                    fiber: 6
                },
                dietaryTags: ['vegetarian', 'vegan', 'gluten-free'],
                tags: ['curry', 'vegetables', 'healthy', 'indian'],
                status: 'published'
            },
            {
                name: 'Spinach Soup',
                description: 'Healthy and nutritious spinach soup.',
                image: 'https://res.cloudinary.com/demo/image/upload/v1/soup.jpg',
                cuisine: 'continental',
                category: 'dinner',
                servings: 2,
                prepTime: 10,
                cookTime: 15,
                difficulty: 'easy',
                ingredients: [
                    {
                        name: 'Spinach',
                        quantity: 2,
                        unit: 'piece',
                        product: spinach._id,
                        isOptional: false
                    },
                    {
                        name: 'Onions',
                        quantity: 0.1,
                        unit: 'kg',
                        product: onion._id,
                        isOptional: false
                    }
                ],
                instructions: [
                    { stepNumber: 1, instruction: 'Wash and chop spinach.' },
                    { stepNumber: 2, instruction: 'Sauté onions in butter.' },
                    { stepNumber: 3, instruction: 'Add spinach and cook until wilted.' },
                    { stepNumber: 4, instruction: 'Blend with water and season.' },
                    { stepNumber: 5, instruction: 'Serve hot with bread.' }
                ],
                nutritionalInfo: {
                    calories: 120,
                    protein: 5,
                    carbohydrates: 15,
                    fat: 5,
                    fiber: 4
                },
                dietaryTags: ['vegetarian', 'gluten-free'],
                tags: ['soup', 'healthy', 'quick'],
                status: 'published'
            }
        ];

        const createdRecipes = await Recipe.create(recipes);
        console.log(`✅ Created ${createdRecipes.length} Recipe(s)`);

        console.log('\n🎉 Data Import Completed Successfully!\n');
        console.log('📊 Summary:');
        console.log(`   - Admins: ${createdAdmins.length}`);
        console.log(`   - Users: ${createdUsers.length}`);
        console.log(`   - Addresses: ${createdAddresses.length}`);
        console.log(`   - Merchants: ${createdMerchants.length} (${createdMerchants.filter(m => m.verificationStatus === 'approved').length} approved)`);
        console.log(`   - Categories: ${createdCategories.length}`);
        console.log(`   - Products: ${createdProducts.length}`);
        console.log(`   - Recipes: ${createdRecipes.length}`);
        console.log('\n🔐 Test Credentials:');
        console.log('   Admin: admin@greenbasket.com / admin123');
        console.log('   User: user@example.com / password123');
        console.log('   Merchant: merchant@example.com / password123');

        process.exit();

    } catch (error) {
        console.error(`❌ Error: ${error}`);
        process.exit(1);
    }
};

const destroyData = async () => {
    try {
        await connectDB();

        await User.deleteMany();
        await Merchant.deleteMany();
        await Category.deleteMany();
        await Product.deleteMany();
        await Recipe.deleteMany();
        await Admin.deleteMany();
        await Address.deleteMany();

        console.log('🗑️  Data Destroyed!');
        process.exit();
    } catch (error) {
        console.error(`❌ Error: ${error}`);
        process.exit(1);
    }
};

if (process.argv[2] === '-d') {
    destroyData();
} else {
    importData();
}

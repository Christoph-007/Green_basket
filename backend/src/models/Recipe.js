const mongoose = require('mongoose');

const recipeSchema = new mongoose.Schema({
    // Basic Information
    name: {
        type: String,
        required: true,
        trim: true,
        index: 'text'
    },
    description: {
        type: String,
        required: true,
        maxlength: 500
    },

    // Images
    image: {
        type: String,
    },
    videoUrl: String,

    // Recipe Details
    cuisine: {
        type: String,
        enum: ['south-indian', 'north-indian', 'kerala', 'chinese', 'continental', 'italian', 'other']
    },
    category: {
        type: String,
        enum: ['breakfast', 'lunch', 'dinner', 'snack', 'snacks', 'dessert', 'beverage']
    },
    mealType: {
        type: String,
        enum: ['breakfast', 'lunch', 'dinner', 'snack', 'snacks', 'dessert', 'beverage'],
        index: true
    },

    // Servings & Time
    servings: {
        type: Number,
        required: true,
        min: 1
    },
    prepTime: {
        type: Number,  // in minutes
        required: true
    },
    cookTime: {
        type: Number,  // in minutes
        required: true
    },
    totalTime: Number,

    // Difficulty
    difficulty: {
        type: String,
        enum: ['easy', 'medium', 'hard'],
        default: 'medium'
    },

    // Ingredients
    ingredients: [{
        name: {
            type: String,
            required: true
        },
        quantity: {
            type: Number,
            required: true
        },
        unit: {
            type: String,
            required: true,
            enum: ['kg', 'g', 'piece', 'cup', 'tbsp', 'tsp', 'liter', 'ml', 'pinch', 'to-taste', 'bundle']
        },
        product: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Product'
        },
        isOptional: {
            type: Boolean,
            default: false
        }
    }],

    // Instructions
    instructions: [{
        stepNumber: Number,
        instruction: String,
        image: String
    }],

    // Nutritional Info (per serving)
    nutritionalInfo: {
        calories: Number,
        protein: Number,
        carbohydrates: Number,
        fat: Number,
        fiber: Number
    },

    // Dietary Tags
    dietaryTags: [{
        type: String,
        enum: ['vegetarian', 'vegan', 'non-vegetarian', 'gluten-free', 'dairy-free', 'nut-free']
    }],

    // Ratings & Usage
    averageRating: {
        type: Number,
        default: 0,
        min: 0,
        max: 5
    },
    totalRatings: {
        type: Number,
        default: 0
    },
    timesCooked: {
        type: Number,
        default: 0
    },

    // Creator
    createdBy: {
        userType: {
            type: String,
            enum: ['admin', 'user'],
            default: 'admin'
        },
        userId: mongoose.Schema.Types.ObjectId
    },

    // Status
    status: {
        type: String,
        enum: ['draft', 'published', 'archived'],
        default: 'published'
    },

    // SEO
    slug: {
        type: String,
        unique: true
    },
    tags: [String]
}, {
    timestamps: true
});

// Calculate total time and sync meal timing
recipeSchema.pre('save', function (next) {
    this.totalTime = this.prepTime + this.cookTime;

    if (this.category && !this.mealType) {
        this.mealType = this.category;
    } else if (this.mealType && !this.category) {
        this.category = this.mealType;
    }

    if (this.isModified('name') && !this.slug) {
        const baseSlug = this.name.toLowerCase().replace(/[^a-z0-9]+/g, '-');
        const timestamp = Date.now().toString().slice(-6);
        this.slug = `${baseSlug}-${timestamp}`;
    }

    next();
});

module.exports = mongoose.model('Recipe', recipeSchema);

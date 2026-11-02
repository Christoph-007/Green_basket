class RecipeModel {
  final String id;
  final String title;
  final String? description;
  final String? image;
  final int servings;
  final int prepTime; // minutes
  final int cookTime; // minutes
  final String difficulty; // 'easy', 'medium', 'hard'
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final List<String> tags;
  final double? estimatedCost;
  final bool isPublished;
  final double? distance;
  final bool? isNearby;

  RecipeModel({
    required this.id,
    required this.title,
    this.description,
    this.image,
    this.servings = 2,
    this.prepTime = 10,
    this.cookTime = 20,
    this.difficulty = 'easy',
    this.ingredients = const [],
    this.steps = const [],
    this.tags = const [],
    this.estimatedCost,
    this.isPublished = true,
    this.distance,
    this.isNearby,
  });

  int get totalTime => prepTime + cookTime;

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'],
      image: json['image'],
      servings: json['servings'] ?? 2,
      prepTime: json['prepTime'] ?? 10,
      cookTime: json['cookTime'] ?? 20,
      difficulty: json['difficulty'] ?? 'easy',
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => RecipeIngredient.fromJson(e))
          .toList(),
      steps: (json['instructions'] != null)
          ? (json['instructions'] as List)
              .map((i) => (i['instruction'] ?? '').toString())
              .toList()
          : List<String>.from(json['steps'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      estimatedCost: json['estimatedCost']?.toDouble(),
      isPublished: json['isPublished'] ?? true,
      distance: (json['distance'] as num?)?.toDouble(),
      isNearby: json['isNearby'],
    );
  }
}

class RecipeIngredient {
  final String name;
  final double quantity;
  final String unit;
  final String? productId;

  RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    this.productId,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    // Handling case where 'product' might be a populated object (Map) or a raw ID (String)
    String? prodId;
    final productField = json['product'];
    if (productField is Map) {
      prodId = productField['_id']?.toString();
    } else if (productField is String) {
      prodId = productField;
    }
    
    return RecipeIngredient(
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      productId: prodId ?? json['productId'],
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountedPrice;
  final List<String> images;
  final String categoryId;
  final String categoryName;
  final String merchantId;
  final String merchantName;
  final double rating;
  final double merchantRating;
  final int reviewCount;

  final int stock;
  final bool isOrganic;
  final bool isFeatured;
  final bool isAvailable;
  final String unit;
  final List<PreparationOption> preparationOptions;
  final NutritionalInfo? nutritionalInfo;
  final ProductOrigin? origin;
  final List<String> tags;
  final bool isPreBookable;

  final String? distanceLabel;
  final int? etaMins;
  final double? score;
  final String? merchantCity;
  
  // Explicit boolean field for merchant status
  final bool isStoreOpen;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountedPrice,
    required this.images,
    required this.categoryId,
    required this.categoryName,
    required this.merchantId,
    required this.merchantName,
    this.rating = 0.0,
    this.merchantRating = 0.0,
    this.reviewCount = 0,
    required this.stock,
    this.isOrganic = false,
    this.isFeatured = false,
    this.isAvailable = true,
    required this.unit,
    this.preparationOptions = const [],
    this.nutritionalInfo,
    this.origin,
    this.tags = const [],
    this.isPreBookable = false,
    this.distanceLabel,
    this.etaMins,
    this.score,
    this.merchantCity,
    this.isStoreOpen = true,
  });

  double get effectivePrice => discountedPrice ?? price;
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;
  int get discountPercent =>
      hasDiscount ? ((1 - effectivePrice / price) * 100).round() : 0;

  String get primaryImage => images.isNotEmpty ? images.first : '';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Handle images being [{url, publicId}] objects or plain strings
    final rawImages = json['images'] as List<dynamic>? ?? [];
    final parsedImages = rawImages.map((e) {
      if (e is String) return e;
      if (e is Map) return (e['url'] ?? '') as String;
      return '';
    }).where((url) => url.isNotEmpty).toList();

    // Handle merchant being a populated object or a raw ObjectId string
    String mId = '';
    String mName = '';
    double mRating = 0.0;
    bool storeOpen = true;
    final merchant = json['merchant'];
    if (merchant is Map<String, dynamic>) {
      mId = merchant['_id'] ?? '';
      mName = merchant['businessName'] ?? merchant['name'] ?? '';
      mRating = (merchant['averageRating'] ?? 0.0).toDouble();
      storeOpen = merchant['isStoreOpen'] ?? true;
    } else if (merchant is String) {
      mId = merchant;
    } else if (json['merchantId'] != null) {
      mId = json['merchantId'];
    }
    
    // Explicitly check for isStoreOpen in the root if not in merchant
    if (json['isStoreOpen'] != null) {
      storeOpen = json['isStoreOpen'];
    }

    // Handle category being a populated object or a raw ObjectId string
    String catId = '';
    String catName = '';
    final category = json['category'];
    if (category is Map<String, dynamic>) {
      catId = category['_id'] ?? '';
      catName = category['name'] ?? '';
    } else if (category is String) {
      catId = category;
    }

    // Calculate prices
    final dbPrice = (json['price'] ?? 0).toDouble();
    final comparePrice = json['comparePrice'] ?? json['compareAtPrice'];
    double modelPrice = dbPrice;
    double? modelDiscountedPrice;

    if (json['discountedPrice'] != null) {
      modelDiscountedPrice = (json['discountedPrice']).toDouble();
    } else if (comparePrice != null) {
      final cp = (comparePrice).toDouble();
      if (cp > dbPrice) {
        modelPrice = cp;
        modelDiscountedPrice = dbPrice;
      }
    }

    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: modelPrice,
      discountedPrice: modelDiscountedPrice,
      images: parsedImages,
      categoryId: catId,
      categoryName: catName,
      merchantId: mId,
      merchantName: mName,
      rating: (json['rating'] ?? json['averageRating'] ?? 0).toDouble(),
      merchantRating: mRating,
      reviewCount: json['reviewCount'] ?? json['totalReviews'] ?? 0,
      stock: json['stock'] ?? 0,
      isOrganic: json['isOrganic'] ?? (json['tags'] as List?)?.contains('organic') ?? false,
      isFeatured: json['isFeatured'] ?? false,
      isAvailable: json['isAvailable'] ?? (json['status'] == 'active') ?? true,
      unit: json['unit'] ?? 'kg',
      preparationOptions: (json['preparationOptions'] as List<dynamic>? ?? [])
          .map((e) => PreparationOption.fromJson(e))
          .toList(),
      nutritionalInfo: json['nutritionalInfo'] != null 
          ? NutritionalInfo.fromJson(json['nutritionalInfo']) 
          : null,
      origin: json['origin'] != null
          ? ProductOrigin.fromJson(json['origin'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      isPreBookable: json['isPreBookable'] ?? false,
      distanceLabel: json['distance_label'],
      etaMins: json['eta_mins'],
      score: (json['score'] ?? 0.0).toDouble(),
      merchantCity: json['merchantCity'],
      isStoreOpen: storeOpen,
    );
  }
}

class NutritionalInfo {
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? fiber;
  final List<String> vitamins;

  NutritionalInfo({
    this.calories,
    this.protein,
    this.carbohydrates,
    this.fat,
    this.fiber,
    this.vitamins = const [],
  });

  factory NutritionalInfo.fromJson(Map<String, dynamic> json) {
    return NutritionalInfo(
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      vitamins: List<String>.from(json['vitamins'] ?? []),
    );
  }
}

class ProductOrigin {
  final String? farm;
  final String? location;
  final DateTime? harvestDate;

  ProductOrigin({this.farm, this.location, this.harvestDate});

  factory ProductOrigin.fromJson(Map<String, dynamic> json) {
    return ProductOrigin(
      farm: json['farm'],
      location: json['location'],
      harvestDate: json['harvestDate'] != null 
          ? DateTime.tryParse(json['harvestDate']) 
          : null,
    );
  }
}

class PreparationOption {
  final String id;
  final String name;
  final double additionalPrice;

  PreparationOption({
    required this.id,
    required this.name,
    required this.additionalPrice,
  });

  factory PreparationOption.fromJson(Map<String, dynamic> json) {
    return PreparationOption(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['type'] ?? json['name'] ?? 'Custom',
      additionalPrice: (json['additionalPrice'] ?? 0).toDouble(),
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String? image;
  final int productCount;

  CategoryModel({
    required this.id,
    required this.name,
    this.image,
    this.productCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'],
      productCount: json['productsCount'] ?? json['productCount'] ?? 0,
    );
  }
}

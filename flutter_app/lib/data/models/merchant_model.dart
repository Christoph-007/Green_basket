class MerchantModel {
  final String id;
  final String userId;
  final String businessName;
  final String ownerName;
  final String email;
  final String phone;
  final String? logo;
  final String? banner;
  final String status; // 'pending', 'approved', 'suspended', 'rejected'
  final String? description;
  final MerchantAddress? address;
  final double rating;
  final int reviewCount;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final bool isOpen;
  final MerchantSettings? settings;

  MerchantModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phone,
    this.logo,
    this.banner,
    this.status = 'pending',
    this.description,
    this.address,
    this.rating = 0,
    this.reviewCount = 0,
    this.totalProducts = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.isOpen = true,
    this.settings,
  });

  bool get isApproved => status == 'approved';
  bool get isSuspended => status == 'suspended';

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['user']?['_id'] ?? '',
      businessName: json['businessName'] ?? '',
      ownerName: json['ownerName'] ?? json['user']?['name'] ?? '',
      email: json['email'] ?? json['user']?['email'] ?? '',
      phone: json['phone'] ?? json['user']?['phone'] ?? '',
      logo: json['logo'],
      banner: json['banner'],
      status: json['status'] ?? 'pending',
      description: json['description'],
      address: json['address'] != null
          ? MerchantAddress.fromJson(json['address'])
          : null,
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      isOpen: json['isOpen'] ?? true,
      settings: json['settings'] != null
          ? MerchantSettings.fromJson(json['settings'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'ownerName': ownerName,
        'email': email,
        'phone': phone,
        'description': description,
        'isOpen': isOpen,
      };
}

class MerchantAddress {
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;

  MerchantAddress({
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
  });

  factory MerchantAddress.fromJson(Map<String, dynamic> json) {
    return MerchantAddress(
      line1: json['line1'] ?? json['address'] ?? '',
      line2: json['line2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: json['location']?['coordinates']?[1]?.toDouble(),
      longitude: json['location']?['coordinates']?[0]?.toDouble(),
    );
  }
}

class MerchantSettings {
  final double minOrderAmount;
  final double deliveryRadius;
  final int preparationTime;
  final bool autoAcceptOrders;

  MerchantSettings({
    this.minOrderAmount = 0,
    this.deliveryRadius = 5,
    this.preparationTime = 30,
    this.autoAcceptOrders = false,
  });

  factory MerchantSettings.fromJson(Map<String, dynamic> json) {
    return MerchantSettings(
      minOrderAmount: (json['minOrderAmount'] ?? 0).toDouble(),
      deliveryRadius: (json['deliveryRadius'] ?? 5).toDouble(),
      preparationTime: json['preparationTime'] ?? 30,
      autoAcceptOrders: json['autoAcceptOrders'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'minOrderAmount': minOrderAmount,
        'deliveryRadius': deliveryRadius,
        'preparationTime': preparationTime,
        'autoAcceptOrders': autoAcceptOrders,
      };
}

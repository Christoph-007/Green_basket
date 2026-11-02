class UserLocation {
  final double lat;
  final double lng;

  const UserLocation({required this.lat, required this.lng});

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    // Support both {lat, lng} and MongoDB {type: 'Point', coordinates: [lng, lat]}
    if (json['coordinates'] != null && json['coordinates'] is List) {
      final coords = json['coordinates'] as List;
      return UserLocation(
        lng: (coords[0]).toDouble(),
        lat: (coords[1]).toDouble(),
      );
    }
    return UserLocation(
      lat: (json['lat'] ?? json['latitude'] ?? 0).toDouble(),
      lng: (json['lng'] ?? json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatar;
  final bool isVerified;
  final double walletBalance;
  final int loyaltyPoints;
  final String loyaltyTier;
  final String? referralCode;
  final DateTime? dateOfBirth;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final Map<String, dynamic> notificationSettings;
  // Stored home location (used as GPS fallback for nearby merchant discovery)
  final UserLocation? location;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
    this.isVerified = false,
    this.walletBalance = 0.0,
    this.loyaltyPoints = 0,
    this.loyaltyTier = 'bronze',
    this.referralCode,
    this.dateOfBirth,
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.notificationSettings = const {},
    this.location,
  });

  factory UserModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return UserModel(
        id: '',
        name: 'Guest User',
        email: '',
        phone: '',
        role: 'customer',
      );
    }
    UserLocation? loc;
    final rawLoc = json['location'];
    if (rawLoc is Map<String, dynamic>) {
      loc = UserLocation.fromJson(rawLoc);
    }

    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      avatar: json['avatar'],
      isVerified: json['isVerified'] ?? false,
      walletBalance: (json['walletBalance'] ?? json['wallet']?['balance'] ?? 0).toDouble(),
      loyaltyPoints: json['loyaltyPoints'] ?? json['loyalty']?['points'] ?? 0,
      loyaltyTier: json['loyaltyTier'] ?? json['loyalty']?['tier'] ?? 'bronze',
      referralCode: json['referralCode'],
      dateOfBirth: json['dateOfBirth'] != null ? DateTime.tryParse(json['dateOfBirth']) : null,
      dietaryPreferences: List<String>.from(json['dietaryPreferences'] ?? []),
      allergies: List<String>.from(json['allergies'] ?? []),
      notificationSettings: Map<String, dynamic>.from(json['notificationSettings'] ?? {}),
      location: loc,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'avatar': avatar,
        'isVerified': isVerified,
        'walletBalance': walletBalance,
        'loyaltyPoints': loyaltyPoints,
        'loyaltyTier': loyaltyTier,
        'referralCode': referralCode,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'dietaryPreferences': dietaryPreferences,
        'allergies': allergies,
        'notificationSettings': notificationSettings,
        if (location != null) 'location': location!.toJson(),
      };

  UserModel copyWith({
    String? name,
    String? avatar,
    String? role,
    double? walletBalance,
    int? loyaltyPoints,
    String? loyaltyTier,
    DateTime? dateOfBirth,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    Map<String, dynamic>? notificationSettings,
    UserLocation? location,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      isVerified: isVerified,
      walletBalance: walletBalance ?? this.walletBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      loyaltyTier: loyaltyTier ?? this.loyaltyTier,
      referralCode: referralCode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      allergies: allergies ?? this.allergies,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      location: location ?? this.location,
    );
  }
}

# 📊 GreenBasket Models Reference

Complete data models reference for Dart/Flutter implementation.

## Table of Contents
- [Authentication Models](#authentication-models)
- [User Models](#user-models)
- [Product Models](#product-models)
- [Cart Models](#cart-models)
- [Order Models](#order-models)
- [Merchant Models](#merchant-models)
- [Payment Models](#payment-models)
- [Notification Models](#notification-models)

---

## Authentication Models

### LoginRequest
```dart
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}
```

### LoginResponse
```dart
class LoginResponse {
  final String token;
  final String refreshToken;
  final String role;
  final User user;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.role,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
    LoginResponse(
      token: json['token'],
      refreshToken: json['refreshToken'],
      role: json['role'],
      user: User.fromJson(json['user']),
    );
}
```

### SignupRequest
```dart
class SignupRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final List<String> dietaryPreferences;
  final List<String> allergies;

  SignupRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.dietaryPreferences = const [],
    this.allergies = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'password': password,
    'dietaryPreferences': dietaryPreferences,
    'allergies': allergies,
  };
}
```

---

## User Models

### User
```dart
@JsonSerializable()
class User {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final int loyaltyPoints;
  final String loyaltyTier; // bronze, silver, gold, platinum
  final double walletBalance;
  final Referral? referral;
  final NotificationPreferences notificationPreferences;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.isPremium = false,
    this.premiumExpiresAt,
    this.loyaltyPoints = 0,
    this.loyaltyTier = 'bronze',
    this.walletBalance = 0.0,
    this.referral,
    required this.notificationPreferences,
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

### Address
```dart
@JsonSerializable()
class Address {
  @JsonKey(name: '_id')
  final String id;
  final String userId;
  final String label; // Home, Office, Other
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final Location location;
  final bool isDefault;
  final DateTime createdAt;

  Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    required this.location,
    this.isDefault = false,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);

  String get fullAddress => '$street, $city, $state - $pincode';
}

@JsonSerializable()
class Location {
  final String type; // Point
  final List<double> coordinates; // [longitude, latitude]

  Location({
    this.type = 'Point',
    required this.coordinates,
  });

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  double get latitude => coordinates[1];
  double get longitude => coordinates[0];
}
```

### NotificationPreferences
```dart
@JsonSerializable()
class NotificationPreferences {
  final EmailNotifications email;
  final PushNotifications push;
  final SmsNotifications sms;

  NotificationPreferences({
    required this.email,
    required this.push,
    required this.sms,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);
}

@JsonSerializable()
class EmailNotifications {
  final bool orderUpdates;
  final bool offers;
  final bool newsletter;
  final bool productUpdates;

  EmailNotifications({
    this.orderUpdates = true,
    this.offers = true,
    this.newsletter = false,
    this.productUpdates = true,
  });

  factory EmailNotifications.fromJson(Map<String, dynamic> json) =>
      _$EmailNotificationsFromJson(json);
  Map<String, dynamic> toJson() => _$EmailNotificationsToJson(this);
}

@JsonSerializable()
class PushNotifications {
  final bool orderUpdates;
  final bool offers;
  final bool priceDrops;
  final bool backInStock;

  PushNotifications({
    this.orderUpdates = true,
    this.offers = true,
    this.priceDrops = true,
    this.backInStock = true,
  });

  factory PushNotifications.fromJson(Map<String, dynamic> json) =>
      _$PushNotificationsFromJson(json);
  Map<String, dynamic> toJson() => _$PushNotificationsToJson(this);
}

@JsonSerializable()
class SmsNotifications {
  final bool orderUpdates;
  final bool offers;
  final bool otp;

  SmsNotifications({
    this.orderUpdates = true,
    this.offers = false,
    this.otp = true,
  });

  factory SmsNotifications.fromJson(Map<String, dynamic> json) =>
      _$SmsNotificationsFromJson(json);
  Map<String, dynamic> toJson() => _$SmsNotificationsToJson(this);
}
```

---

## Product Models

### Product
```dart
@JsonSerializable()
class Product {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String description;
  final MerchantSummary merchant;
  final CategorySummary category;
  final double price;
  final double? comparePrice;
  final String unit; // kg, g, piece, dozen, bundle, liter
  final int stock;
  final int lowStockThreshold;
  final List<String> tags;
  final List<PreparationOption>? preparationOptions;
  final List<ProductImage> images;
  final String primaryImage;
  final NutritionalInfo? nutritionalInfo;
  final Origin? origin;
  final bool isSeasonal;
  final List<int>? availableMonths;
  final String status; // active, out-of-stock, coming-soon, discontinued
  final double averageRating;
  final int totalReviews;
  final int totalSales;
  final bool isPremiumExclusive;
  final DateTime? premiumAccessStartDate;
  final DateTime? premiumAccessEndDate;
  final bool isPreBookable;
  final DateTime? expectedAvailabilityDate;
  final bool isActive;
  final String? slug;
  final DateTime createdAt;
  
  // Local field
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isWishlisted;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.merchant,
    required this.category,
    required this.price,
    this.comparePrice,
    this.unit = 'kg',
    required this.stock,
    this.lowStockThreshold = 10,
    this.tags = const [],
    this.preparationOptions,
    required this.images,
    required this.primaryImage,
    this.nutritionalInfo,
    this.origin,
    this.isSeasonal = false,
    this.availableMonths,
    this.status = 'active',
    this.averageRating = 0,
    this.totalReviews = 0,
    this.totalSales = 0,
    this.isPremiumExclusive = false,
    this.premiumAccessStartDate,
    this.premiumAccessEndDate,
    this.isPreBookable = false,
    this.expectedAvailabilityDate,
    this.isActive = true,
    this.slug,
    required this.createdAt,
    this.isWishlisted = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  double get discountPercent {
    if (comparePrice == null || comparePrice! <= price) return 0;
    return ((comparePrice! - price) / comparePrice! * 100).roundToDouble();
  }

  bool get hasDiscount => discountPercent > 0;
  bool get isInStock => stock > 0 && status == 'active';
  bool get isLowStock => stock <= lowStockThreshold && stock > 0;
  String get displayPrice => '₹${price.toStringAsFixed(2)}';
  String get displayComparePrice => 
      comparePrice != null ? '₹${comparePrice!.toStringAsFixed(2)}' : '';
}

@JsonSerializable()
class ProductImage {
  final String url;
  final String? publicId;

  ProductImage({required this.url, this.publicId});

  factory ProductImage.fromJson(Map<String, dynamic> json) =>
      _$ProductImageFromJson(json);
  Map<String, dynamic> toJson() => _$ProductImageToJson(this);
}

@JsonSerializable()
class PreparationOption {
  final String type; // whole, cut, chopped, diced, sliced
  final double additionalPrice;

  PreparationOption({required this.type, this.additionalPrice = 0});

  factory PreparationOption.fromJson(Map<String, dynamic> json) =>
      _$PreparationOptionFromJson(json);
  Map<String, dynamic> toJson() => _$PreparationOptionToJson(this);
}

@JsonSerializable()
class NutritionalInfo {
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? fiber;
  final List<String>? vitamins;

  NutritionalInfo({
    this.calories,
    this.protein,
    this.carbohydrates,
    this.fat,
    this.fiber,
    this.vitamins,
  });

  factory NutritionalInfo.fromJson(Map<String, dynamic> json) =>
      _$NutritionalInfoFromJson(json);
  Map<String, dynamic> toJson() => _$NutritionalInfoToJson(this);
}

@JsonSerializable()
class Origin {
  final String? farm;
  final String? location;
  final DateTime? harvestDate;

  Origin({this.farm, this.location, this.harvestDate});

  factory Origin.fromJson(Map<String, dynamic> json) => _$OriginFromJson(json);
  Map<String, dynamic> toJson() => _$OriginToJson(this);
}

@JsonSerializable()
class MerchantSummary {
  @JsonKey(name: '_id')
  final String id;
  final String businessName;
  final double averageRating;
  final String? profileImage;

  MerchantSummary({
    required this.id,
    required this.businessName,
    this.averageRating = 0,
    this.profileImage,
  });

  factory MerchantSummary.fromJson(Map<String, dynamic> json) =>
      _$MerchantSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantSummaryToJson(this);
}

@JsonSerializable()
class CategorySummary {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String? icon;
  final String? image;

  CategorySummary({
    required this.id,
    required this.name,
    this.icon,
    this.image,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) =>
      _$CategorySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$CategorySummaryToJson(this);
}

@JsonSerializable()
class Category {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? image;
  final int order;
  final bool isActive;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.image,
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}
```

---

## Cart Models

### Cart
```dart
@JsonSerializable()
class Cart {
  @JsonKey(name: '_id')
  final String id;
  final String userId;
  final List<CartItem> items;
  final AppliedCoupon? appliedCoupon;
  final double total;
  final double discount;
  final double deliveryCharge;
  final double finalTotal;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.userId,
    this.items = const [],
    this.appliedCoupon,
    this.total = 0,
    this.discount = 0,
    this.deliveryCharge = 0,
    this.finalTotal = 0,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
  Map<String, dynamic> toJson() => _$CartToJson(this);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get hasCoupon => appliedCoupon != null;
  bool get isEmpty => items.isEmpty;
}

@JsonSerializable()
class CartItem {
  final ProductSummary product;
  final int quantity;
  final String? preparation;
  final double price;
  final DateTime addedAt;

  CartItem({
    required this.product,
    required this.quantity,
    this.preparation,
    required this.price,
    required this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);

  double get subtotal => price * quantity;
}

@JsonSerializable()
class AppliedCoupon {
  final String code;
  @JsonKey(name: 'offerId')
  final String offerId;
  final double discount;
  final String discountType; // percentage, fixed

  AppliedCoupon({
    required this.code,
    required this.offerId,
    required this.discount,
    this.discountType = 'percentage',
  });

  factory AppliedCoupon.fromJson(Map<String, dynamic> json) =>
      _$AppliedCouponFromJson(json);
  Map<String, dynamic> toJson() => _$AppliedCouponToJson(this);
}
```

---

## Order Models

### Order
```dart
@JsonSerializable()
class Order {
  @JsonKey(name: '_id')
  final String id;
  final String orderId;
  final String customerId;
  final MerchantSummary merchant;
  final List<OrderItem> items;
  final double itemsTotal;
  final double deliveryCharges;
  final double discount;
  final double totalAmount;
  final String status; // pending, confirmed, ready, out-for-delivery, delivered, cancelled, refunded
  final String paymentStatus; // pending, completed, failed, refunded, paid
  final String paymentMethod; // cod, online, wallet
  final PaymentDetails? paymentDetails;
  final String? couponCode;
  final double? couponDiscount;
  final GiftCardApplied? giftCardApplied;
  final String deliveryType; // home-delivery, pickup
  final Address? deliveryAddress;
  final DeliveryTimeSlot? deliveryTimeSlot;
  final String? deliveryInstructions;
  final DateTime? estimatedDeliveryTime;
  final DeliveryAssignment? deliveryAssignment;
  final DeliveryPersonnel? deliveryPersonnel;
  final List<StatusHistory> statusHistory;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? specialRequests;
  final bool isRecipeOrder;
  final String? recipeId;
  final int? servings;
  final int? rating;
  final String? review;
  final DateTime? reviewedAt;
  final DateTime orderedAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.merchant,
    required this.items,
    required this.itemsTotal,
    this.deliveryCharges = 0,
    this.discount = 0,
    required this.totalAmount,
    this.status = 'pending',
    this.paymentStatus = 'pending',
    required this.paymentMethod,
    this.paymentDetails,
    this.couponCode,
    this.couponDiscount,
    this.giftCardApplied,
    this.deliveryType = 'home-delivery',
    this.deliveryAddress,
    this.deliveryTimeSlot,
    this.deliveryInstructions,
    this.estimatedDeliveryTime,
    this.deliveryAssignment,
    this.deliveryPersonnel,
    this.statusHistory = const [],
    this.cancellationReason,
    this.cancelledBy,
    this.cancelledAt,
    this.specialRequests,
    this.isRecipeOrder = false,
    this.recipeId,
    this.servings,
    this.rating,
    this.review,
    this.reviewedAt,
    required this.orderedAt,
    this.confirmedAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  String get formattedOrderId => '#$orderId';
  bool get isActive => ['pending', 'confirmed', 'ready', 'out-for-delivery'].contains(status);
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get canCancel => status == 'pending' || status == 'confirmed';
  bool get canTrack => ['ready', 'out-for-delivery'].contains(status);
  bool get canReview => isDelivered && rating == null;
  bool get canReturn => isDelivered && deliveredAt != null && 
      DateTime.now().difference(deliveredAt!).inDays <= 7;
}

@JsonSerializable()
class OrderItem {
  final ProductSummary product;
  final String name;
  final double price;
  final int quantity;
  final String? unit;
  final String? preparation;
  final double subtotal;

  OrderItem({
    required this.product,
    required this.name,
    required this.price,
    required this.quantity,
    this.unit,
    this.preparation,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}

@JsonSerializable()
class DeliveryTimeSlot {
  final DateTime date;
  final String startTime;
  final String endTime;

  DeliveryTimeSlot({
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory DeliveryTimeSlot.fromJson(Map<String, dynamic> json) =>
      _$DeliveryTimeSlotFromJson(json);
  Map<String, dynamic> toJson() => _$DeliveryTimeSlotToJson(this);
}

@JsonSerializable()
class DeliveryPersonnel {
  final String name;
  final String phone;
  final String? vehicleNumber;
  final CurrentLocation? currentLocation;

  DeliveryPersonnel({
    required this.name,
    required this.phone,
    this.vehicleNumber,
    this.currentLocation,
  });

  factory DeliveryPersonnel.fromJson(Map<String, dynamic> json) =>
      _$DeliveryPersonnelFromJson(json);
  Map<String, dynamic> toJson() => _$DeliveryPersonnelToJson(this);
}

@JsonSerializable()
class CurrentLocation {
  final double lat;
  final double lng;
  final DateTime updatedAt;

  CurrentLocation({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory CurrentLocation.fromJson(Map<String, dynamic> json) =>
      _$CurrentLocationFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentLocationToJson(this);
}

@JsonSerializable()
class StatusHistory {
  final String status;
  final DateTime timestamp;
  final String? note;
  final String? updatedBy;
  final String? updatedByModel;

  StatusHistory({
    required this.status,
    required this.timestamp,
    this.note,
    this.updatedBy,
    this.updatedByModel,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) =>
      _$StatusHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$StatusHistoryToJson(this);
}

@JsonSerializable()
class GiftCardApplied {
  final String code;
  final double amountApplied;

  GiftCardApplied({
    required this.code,
    required this.amountApplied,
  });

  factory GiftCardApplied.fromJson(Map<String, dynamic> json) =>
      _$GiftCardAppliedFromJson(json);
  Map<String, dynamic> toJson() => _$GiftCardAppliedToJson(this);
}

@JsonSerializable()
class PaymentDetails {
  final String method; // card, upi, netbanking, wallet, emi, cod
  final String? cardNetwork;
  final String? cardLast4;
  final String? upiVpa;
  final String? bank;
  final String? wallet;

  PaymentDetails({
    required this.method,
    this.cardNetwork,
    this.cardLast4,
    this.upiVpa,
    this.bank,
    this.wallet,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) =>
      _$PaymentDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentDetailsToJson(this);
}
```

### CreateOrderRequest
```dart
class CreateOrderRequest {
  final String deliveryAddress;
  final String deliveryType;
  final DeliveryTimeSlotRequest? deliveryTimeSlot;
  final String paymentMethod;
  final String? specialRequests;
  final bool useWallet;
  final double walletAmount;

  CreateOrderRequest({
    required this.deliveryAddress,
    this.deliveryType = 'home-delivery',
    this.deliveryTimeSlot,
    required this.paymentMethod,
    this.specialRequests,
    this.useWallet = false,
    this.walletAmount = 0,
  });

  Map<String, dynamic> toJson() => {
    'deliveryAddress': deliveryAddress,
    'deliveryType': deliveryType,
    if (deliveryTimeSlot != null) 'deliveryTimeSlot': deliveryTimeSlot!.toJson(),
    'paymentMethod': paymentMethod,
    if (specialRequests != null) 'specialRequests': specialRequests,
    'useWallet': useWallet,
    'walletAmount': walletAmount,
  };
}

class DeliveryTimeSlotRequest {
  final String date;
  final String startTime;
  final String endTime;

  DeliveryTimeSlotRequest({
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
  };
}
```

---

## Merchant Models

### Merchant
```dart
@JsonSerializable()
class Merchant {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String email;
  final String phone;
  final String businessName;
  final String merchantType; // home-grower, organic-farmer, local-farmer
  final String? businessDescription;
  final String sellingModel; // retail, wholesale, both
  final bool allowsSubscriptions;
  final Address address;
  final Location? location;
  final String? fssaiLicense;
  final String? gstNumber;
  final String? panNumber;
  final List<Certification> certifications;
  final String? profileImage;
  final List<String> farmImages;
  final String verificationStatus; // pending, under-review, approved, rejected
  final List<String> badges;
  final double averageRating;
  final int totalReviews;
  final int totalOrders;
  final double totalRevenue;
  final OperatingHours? operatingHours;
  final bool isStoreOpen;
  final VacationMode? vacationMode;
  final double deliveryRadius;
  final double minimumOrderValue;
  final double deliveryCharges;
  final double? freeDeliveryAbove;
  final List<DeliveryZone> deliveryZones;
  final BankDetails? bankDetails;
  final bool isActive;
  final DateTime createdAt;

  Merchant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.merchantType,
    this.businessDescription,
    this.sellingModel = 'retail',
    this.allowsSubscriptions = false,
    required this.address,
    this.location,
    this.fssaiLicense,
    this.gstNumber,
    this.panNumber,
    this.certifications = const [],
    this.profileImage,
    this.farmImages = const [],
    this.verificationStatus = 'pending',
    this.badges = const [],
    this.averageRating = 0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.operatingHours,
    this.isStoreOpen = true,
    this.vacationMode,
    this.deliveryRadius = 10,
    this.minimumOrderValue = 0,
    this.deliveryCharges = 0,
    this.freeDeliveryAbove,
    this.deliveryZones = const [],
    this.bankDetails,
    this.isActive = true,
    required this.createdAt,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) => _$MerchantFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantToJson(this);

  bool get isVerified => verificationStatus == 'approved';
  bool get isCurrentlyOpen {
    if (!isStoreOpen) return false;
    if (vacationMode?.isActive == true) {
      final now = DateTime.now();
      if (now.isAfter(vacationMode!.startDate!) && 
          now.isBefore(vacationMode!.endDate!)) {
        return false;
      }
    }
    // Check operating hours...
    return true;
  }
}

@JsonSerializable()
class OperatingHours {
  final DaySchedule? monday;
  final DaySchedule? tuesday;
  final DaySchedule? wednesday;
  final DaySchedule? thursday;
  final DaySchedule? friday;
  final DaySchedule? saturday;
  final DaySchedule? sunday;

  OperatingHours({
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
    this.sunday,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) =>
      _$OperatingHoursFromJson(json);
  Map<String, dynamic> toJson() => _$OperatingHoursToJson(this);
}

@JsonSerializable()
class DaySchedule {
  final String? open;
  final String? close;
  final bool? isOpen;

  DaySchedule({this.open, this.close, this.isOpen});

  factory DaySchedule.fromJson(Map<String, dynamic> json) =>
      _$DayScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$DayScheduleToJson(this);
}

@JsonSerializable()
class VacationMode {
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? message;

  VacationMode({
    this.isActive = false,
    this.startDate,
    this.endDate,
    this.message,
  });

  factory VacationMode.fromJson(Map<String, dynamic> json) =>
      _$VacationModeFromJson(json);
  Map<String, dynamic> toJson() => _$VacationModeToJson(this);
}

@JsonSerializable()
class DeliveryZone {
  final String id;
  final String name;
  final double radiusKm;
  final double deliveryCharge;
  final double minimumOrder;
  final double? freeDeliveryAbove;
  final String estimatedDeliveryTime;
  final bool isActive;

  DeliveryZone({
    required this.id,
    required this.name,
    required this.radiusKm,
    required this.deliveryCharge,
    this.minimumOrder = 0,
    this.freeDeliveryAbove,
    this.estimatedDeliveryTime = '30-45 mins',
    this.isActive = true,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) =>
      _$DeliveryZoneFromJson(json);
  Map<String, dynamic> toJson() => _$DeliveryZoneToJson(this);
}

@JsonSerializable()
class BankDetails {
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final String? branch;

  BankDetails({
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    this.branch,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) =>
      _$BankDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$BankDetailsToJson(this);
}

@JsonSerializable()
class Certification {
  final String name;
  final String? issuedBy;
  final DateTime? issuedDate;
  final DateTime? expiryDate;
  final String? document;

  Certification({
    required this.name,
    this.issuedBy,
    this.issuedDate,
    this.expiryDate,
    this.document,
  });

  factory Certification.fromJson(Map<String, dynamic> json) =>
      _$CertificationFromJson(json);
  Map<String, dynamic> toJson() => _$CertificationToJson(this);
}
```

---

## Payment Models

### PaymentMethod
```dart
@JsonSerializable()
class PaymentMethod {
  final String id;
  final String name;
  final bool enabled;
  final String? icon;

  PaymentMethod({
    required this.id,
    required this.name,
    this.enabled = true,
    this.icon,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentMethodToJson(this);
}
```

### CreatePaymentResponse
```dart
@JsonSerializable()
class CreatePaymentResponse {
  final String gateway; // stripe, phonepe
  final String paymentIntentId;
  final String clientSecret;
  final double amount;
  final String currency;

  CreatePaymentResponse({
    required this.gateway,
    required this.paymentIntentId,
    required this.clientSecret,
    required this.amount,
    this.currency = 'inr',
  });

  factory CreatePaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$CreatePaymentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CreatePaymentResponseToJson(this);
}
```

### Wallet
```dart
@JsonSerializable()
class Wallet {
  final double balance;
  final String currency;
  final bool isLocked;
  final double totalCredited;
  final double totalDebited;

  Wallet({
    required this.balance,
    this.currency = 'INR',
    this.isLocked = false,
    this.totalCredited = 0,
    this.totalDebited = 0,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);
  Map<String, dynamic> toJson() => _$WalletToJson(this);
}

@JsonSerializable()
class WalletTransaction {
  @JsonKey(name: '_id')
  final String id;
  final String type; // credit, debit
  final double amount;
  final double balance;
  final String description;
  final String source; // topup, order, refund, referral
  final String? orderId;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balance,
    required this.description,
    required this.source,
    this.orderId,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);

  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';
}
```

---

## Notification Models

### AppNotification
```dart
@JsonSerializable()
class AppNotification {
  @JsonKey(name: '_id')
  final String id;
  final String type; // order, offer, system
  final String title;
  final String message;
  final NotificationData data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}

@JsonSerializable()
class NotificationData {
  final String? orderId;
  final String? orderNumber;
  final String? productId;
  final String? offerId;

  NotificationData({
    this.orderId,
    this.orderNumber,
    this.productId,
    this.offerId,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) =>
      _$NotificationDataFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationDataToJson(this);
}
```

---

## Enum Reference

### OrderStatus
```dart
enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  ready('Ready for Pickup'),
  outForDelivery('Out for Delivery'),
  delivered('Delivered'),
  cancelled('Cancelled'),
  refunded('Refunded');

  final String displayName;
  const OrderStatus(this.displayName);
}
```

### PaymentMethod
```dart
enum PaymentMethodType {
  card('Credit/Debit Card'),
  upi('UPI'),
  netBanking('Net Banking'),
  wallet('Wallet'),
  emi('EMI'),
  cod('Cash on Delivery');

  final String displayName;
  const PaymentMethodType(this.displayName);
}
```

### LoyaltyTier
```dart
enum LoyaltyTier {
  bronze('Bronze', 0),
  silver('Silver', 500),
  gold('Gold', 1500),
  platinum('Platinum', 3000);

  final String displayName;
  final int minPoints;
  const LoyaltyTier(this.displayName, this.minPoints);
}
```

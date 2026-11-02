# 🚀 GreenBasket Flutter Implementation Guide

Complete guide for building the Flutter frontend for GreenBasket backend.

## Table of Contents
1. [Project Setup](#1-project-setup)
2. [Architecture](#2-architecture)
3. [API Service Layer](#3-api-service-layer)
4. [Models](#4-models)
5. [State Management](#5-state-management)
6. [Authentication Flow](#6-authentication-flow)
7. [Key Features Implementation](#7-key-features-implementation)
8. [Push Notifications](#8-push-notifications)
9. [Deep Linking](#9-deep-linking)

---

## 1. PROJECT SETUP

### Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  get: ^4.6.6
  
  # Networking
  dio: ^5.4.0
  retrofit: ^4.0.3
  
  # Storage
  get_storage: ^2.1.1
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.10
  firebase_analytics: ^10.8.0
  
  # Local Notifications
  flutter_local_notifications: ^16.3.0
  
  # Maps & Location
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  
  # Images
  cached_network_image: ^3.3.1
  image_picker: ^1.0.7
  
  # UI Components
  shimmer: ^3.0.0
  flutter_slidable: ^3.0.1
  carousel_slider: ^4.2.1
  smooth_page_indicator: ^1.1.0
  
  # Utils
  intl: ^0.19.0
  url_launcher: ^6.2.2
  share_plus: ^7.2.1
  path_provider: ^2.1.1
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  retrofit_generator: ^8.0.6
  json_serializable: ^6.7.1
```

### Project Structure
```
lib/
├── main.dart
├── app.dart
├── bindings/
│   ├── app_bindings.dart
│   └── auth_bindings.dart
├── config/
│   ├── constants.dart
│   ├── theme.dart
│   └── routes.dart
├── data/
│   ├── models/
│   │   ├── user.dart
│   │   ├── product.dart
│   │   ├── order.dart
│   │   ├── cart.dart
│   │   ├── address.dart
│   │   ├── merchant.dart
│   │   └── ...
│   ├── providers/
│   │   └── api_client.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── product_repository.dart
│   │   ├── cart_repository.dart
│   │   └── order_repository.dart
│   └── services/
│       ├── storage_service.dart
│       ├── notification_service.dart
│       └── location_service.dart
├── modules/
│   ├── auth/
│   │   ├── login/
│   │   ├── signup/
│   │   └── forgot_password/
│   ├── home/
│   ├── products/
│   ├── cart/
│   ├── checkout/
│   ├── orders/
│   ├── profile/
│   ├── merchant/
│   └── admin/
├── widgets/
│   ├── common/
│   ├── cards/
│   ├── buttons/
│   └── inputs/
└── utils/
    ├── helpers.dart
    ├── extensions.dart
    └── validators.dart
```

---

## 2. ARCHITECTURE

### Clean Architecture with GetX

```
Presentation Layer (UI/Widgets)
         ↕
   Controller Layer (GetX)
         ↕
  Repository Layer (Abstract)
         ↕
   Data Layer (API/Local)
```

### Main Entry Point
```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'app.dart';
import 'bindings/app_bindings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize bindings
  AppBindings().dependencies();
  
  runApp(const GreenBasketApp());
}

// app.dart
class GreenBasketApp extends StatelessWidget {
  const GreenBasketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GreenBasket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialBinding: AppBindings(),
      getPages: AppRoutes.pages,
      initialRoute: AppRoutes.splash,
    );
  }
}
```

---

## 3. API SERVICE LAYER

### API Client with Dio
```dart
// data/providers/api_client.dart
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../services/storage_service.dart';

class ApiClient {
  late Dio dio;
  final StorageService _storage = Get.find<StorageService>();
  
  static const String baseUrl = 'https://api.greenbasket.com/api';
  // For development: 'http://localhost:6000/api'
  
  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors
    dio.interceptors.add(_authInterceptor());
    dio.interceptors.add(_logInterceptor());
    dio.interceptors.add(_errorInterceptor());
  }
  
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, try refresh
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry request
            final token = _storage.getToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            return handler.resolve(await dio.fetch(error.requestOptions));
          } else {
            // Logout user
            _storage.clearAll();
            Get.offAllNamed('/login');
          }
        }
        return handler.next(error);
      },
    );
  }
  
  Interceptor _logInterceptor() {
    return LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      error: true,
    );
  }
  
  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        final message = _handleError(error);
        Get.snackbar('Error', message);
        return handler.next(error);
      },
    );
  }
  
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        return data?['message'] ?? 'Something went wrong';
      default:
        return 'An unexpected error occurred';
    }
  }
  
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = _storage.getRefreshToken();
      if (refreshToken == null) return false;
      
      final response = await dio.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });
      
      if (response.data['success']) {
        await _storage.saveToken(response.data['data']['token']);
        await _storage.saveRefreshToken(response.data['data']['refreshToken']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
```

### API Endpoints
```dart
// data/providers/api_endpoints.dart
class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String userSignup = '/auth/user/signup';
  static const String userLogin = '/auth/user/login';
  static const String verifyEmail = '/auth/user/verify-email';
  static const String forgotPassword = '/auth/user/forgot-password';
  static const String resetPassword = '/auth/user/reset-password';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  
  // User
  static const String profile = '/users/profile';
  static const String addresses = '/users/addresses';
  static const String notificationPrefs = '/users/notification-preferences';
  static const String fcmToken = '/users/fcm-token';
  
  // Products
  static const String products = '/products';
  static const String searchProducts = '/products/search';
  
  // Cart
  static const String cart = '/cart';
  static const String addToCart = '/cart/add';
  static const String recipeToCart = '/cart/recipe-to-cart';
  
  // Orders
  static const String orders = '/orders';
  static const String myOrders = '/orders/my-orders';
  
  // Payment
  static const String createPayment = '/payment/create-order';
  static const String verifyPayment = '/payment/verify';
  
  // Wallet
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  static const String addMoney = '/wallet/add-money';
  
  // Wishlist
  static const String wishlist = '/wishlist';
  
  // Notifications
  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';
}
```

---

## 4. MODELS

### Base Model
```dart
// data/models/base_model.dart
abstract class BaseModel {
  Map<String, dynamic> toJson();
}

// Generic API Response
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? count;
  final int? total;
  final int? page;
  final int? pages;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.count,
    this.total,
    this.page,
    this.pages,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      count: json['count'],
      total: json['total'],
      page: json['page'],
      pages: json['pages'],
    );
  }
}
```

### User Model
```dart
// data/models/user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

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
  final String loyaltyTier;
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

@JsonSerializable()
class Referral {
  final String code;
  final double totalEarned;

  Referral({required this.code, this.totalEarned = 0});

  factory Referral.fromJson(Map<String, dynamic> json) => _$ReferralFromJson(json);
  Map<String, dynamic> toJson() => _$ReferralToJson(this);
}

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

### Product Model
```dart
// data/models/product.dart
import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

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
  final String unit;
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
  final String status;
  final double averageRating;
  final int totalReviews;
  final int totalSales;
  final bool isPremiumExclusive;
  final bool isPreBookable;
  final bool isActive;
  final DateTime createdAt;
  
  // Local field (not from API)
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
    this.isPreBookable = false,
    this.isActive = true,
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
  final String type;
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

  MerchantSummary({
    required this.id,
    required this.businessName,
    this.averageRating = 0,
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

  CategorySummary({required this.id, required this.name, this.icon});

  factory CategorySummary.fromJson(Map<String, dynamic> json) =>
      _$CategorySummaryFromJson(json);
  Map<String, dynamic> toJson() => _$CategorySummaryToJson(this);
}
```

### Cart Model
```dart
// data/models/cart.dart
import 'package:json_annotation/json_annotation.dart';
import 'product.dart';

part 'cart.g.dart';

@JsonSerializable()
class Cart {
  @JsonKey(name: '_id')
  final String id;
  final List<CartItem> items;
  final AppliedCoupon? appliedCoupon;
  final double total;
  final double discount;
  final double deliveryCharge;
  final double finalTotal;

  Cart({
    required this.id,
    this.items = const [],
    this.appliedCoupon,
    this.total = 0,
    this.discount = 0,
    this.deliveryCharge = 0,
    this.finalTotal = 0,
  });

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
  Map<String, dynamic> toJson() => _$CartToJson(this);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get hasCoupon => appliedCoupon != null;
  bool get isEmpty => items.isEmpty;
}

@JsonSerializable()
class CartItem {
  final Product product;
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

  AppliedCoupon({
    required this.code,
    required this.offerId,
    required this.discount,
  });

  factory AppliedCoupon.fromJson(Map<String, dynamic> json) =>
      _$AppliedCouponFromJson(json);
  Map<String, dynamic> toJson() => _$AppliedCouponToJson(this);
}
```

### Order Model
```dart
// data/models/order.dart
import 'package:json_annotation/json_annotation.dart';
import 'address.dart';
import 'product.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  @JsonKey(name: '_id')
  final String id;
  final String orderId;
  final List<OrderItem> items;
  final double itemsTotal;
  final double deliveryCharges;
  final double discount;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String? couponCode;
  final double? couponDiscount;
  final String deliveryType;
  final Address? deliveryAddress;
  final DeliveryTimeSlot? deliveryTimeSlot;
  final DateTime? estimatedDeliveryTime;
  final DeliveryPersonnel? deliveryPersonnel;
  final List<StatusHistory> statusHistory;
  final String? specialRequests;
  final DateTime orderedAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final bool canCancel;
  final bool canReturn;
  final bool canReview;

  Order({
    required this.id,
    required this.orderId,
    required this.items,
    required this.itemsTotal,
    this.deliveryCharges = 0,
    this.discount = 0,
    required this.totalAmount,
    this.status = 'pending',
    this.paymentStatus = 'pending',
    required this.paymentMethod,
    this.couponCode,
    this.couponDiscount,
    this.deliveryType = 'home-delivery',
    this.deliveryAddress,
    this.deliveryTimeSlot,
    this.estimatedDeliveryTime,
    this.deliveryPersonnel,
    this.statusHistory = const [],
    this.specialRequests,
    required this.orderedAt,
    this.confirmedAt,
    this.deliveredAt,
    this.canCancel = false,
    this.canReturn = false,
    this.canReview = false,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);

  String get formattedOrderId => '#$orderId';
  bool get isActive => ['pending', 'confirmed', 'ready', 'out-for-delivery'].contains(status);
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
class ProductSummary {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String? primaryImage;

  ProductSummary({required this.id, required this.name, this.primaryImage});

  factory ProductSummary.fromJson(Map<String, dynamic> json) =>
      _$ProductSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ProductSummaryToJson(this);
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

  String get displayText => '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  
  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
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

  StatusHistory({
    required this.status,
    required this.timestamp,
    this.note,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) =>
      _$StatusHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$StatusHistoryToJson(this);
}
```

---

## 5. STATE MANAGEMENT

### Auth Controller
```dart
// modules/auth/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/storage_service.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = Get.find<AuthRepository>();
  final StorageService _storage = Get.find<StorageService>();
  
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }
  
  Future<void> checkAuthStatus() async {
    final token = _storage.getToken();
    if (token != null) {
      await getProfile();
    }
  }
  
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      final response = await _authRepo.login(email, password);
      
      await _storage.saveToken(response.token);
      await _storage.saveRefreshToken(response.refreshToken);
      await _storage.saveUserRole(response.role);
      
      currentUser.value = response.user;
      isLoggedIn.value = true;
      
      // Navigate based on role
      _navigateBasedOnRole(response.role);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    List<String> dietaryPreferences = const [],
    List<String> allergies = const [],
  }) async {
    try {
      isLoading.value = true;
      final response = await _authRepo.signup(
        name: name,
        email: email,
        phone: phone,
        password: password,
        dietaryPreferences: dietaryPreferences,
        allergies: allergies,
      );
      
      Get.snackbar('Success', 'Account created! Please verify your email.');
      Get.offNamed('/verify-email', arguments: {'email': email});
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> getProfile() async {
    try {
      final user = await _authRepo.getProfile();
      currentUser.value = user;
      isLoggedIn.value = true;
    } catch (e) {
      await logout();
    }
  }
  
  Future<void> logout() async {
    await _authRepo.logout();
    await _storage.clearAll();
    currentUser.value = null;
    isLoggedIn.value = false;
    Get.offAllNamed('/login');
  }
  
  void _navigateBasedOnRole(String role) {
    switch (role) {
      case 'user':
        Get.offAllNamed('/home');
        break;
      case 'merchant':
        Get.offAllNamed('/merchant/dashboard');
        break;
      case 'admin':
        Get.offAllNamed('/admin/dashboard');
        break;
      default:
        Get.offAllNamed('/home');
    }
  }
  
  // Getters
  bool get isUser => _storage.getUserRole() == 'user';
  bool get isMerchant => _storage.getUserRole() == 'merchant';
  bool get isAdmin => _storage.getUserRole() == 'admin';
}
```

### Cart Controller
```dart
// modules/cart/controllers/cart_controller.dart
import 'package:get/get.dart';
import '../../../data/models/cart.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/cart_repository.dart';

class CartController extends GetxController {
  final CartRepository _cartRepo = Get.find<CartRepository>();
  
  final Rx<Cart?> cart = Rx<Cart?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchCart();
  }
  
  Future<void> fetchCart() async {
    try {
      isLoading.value = true;
      error.value = '';
      final data = await _cartRepo.getCart();
      cart.value = data;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> addToCart({
    required String productId,
    required int quantity,
    String? preparation,
  }) async {
    try {
      isLoading.value = true;
      await _cartRepo.addToCart(
        productId: productId,
        quantity: quantity,
        preparation: preparation,
      );
      await fetchCart();
      Get.snackbar('Success', 'Added to cart');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity < 1) {
      await removeFromCart(productId);
      return;
    }
    
    try {
      await _cartRepo.updateCartItem(productId, quantity: quantity);
      await fetchCart();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
  
  Future<void> removeFromCart(String productId) async {
    try {
      await _cartRepo.removeFromCart(productId);
      await fetchCart();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
  
  Future<void> clearCart() async {
    try {
      await _cartRepo.clearCart();
      await fetchCart();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
  
  Future<void> applyCoupon(String code) async {
    try {
      await _cartRepo.applyCoupon(code);
      await fetchCart();
      Get.snackbar('Success', 'Coupon applied');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
  
  Future<void> removeCoupon() async {
    try {
      await _cartRepo.removeCoupon();
      await fetchCart();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
  
  // Getters
  int get itemCount => cart.value?.itemCount ?? 0;
  double get totalAmount => cart.value?.finalTotal ?? 0;
  bool get hasItems => itemCount > 0;
  List<CartItem> get items => cart.value?.items ?? [];
}
```

---

## 6. AUTHENTICATION FLOW

### Login Screen
```dart
// modules/auth/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                  ),
                ),
                const SizedBox(height: 40),
                // Title
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 32),
                // Email Field
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    if (!GetUtils.isEmail(value!)) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password Field
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Password is required';
                    if (value!.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.toNamed('/forgot-password'),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                                if (formKey.currentState!.validate()) {
                                  controller.login(
                                    emailController.text.trim(),
                                    passwordController.text,
                                  );
                                }
                              },
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator()
                            : const Text('LOGIN'),
                      )),
                ),
                const SizedBox(height: 24),
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?'),
                    TextButton(
                      onPressed: () => Get.toNamed('/signup'),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 7. KEY FEATURES IMPLEMENTATION

### Product List with Infinite Scroll
```dart
// modules/products/controllers/product_list_controller.dart
import 'package:get/get.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';

class ProductListController extends GetxController {
  final ProductRepository _productRepo = Get.find<ProductRepository>();
  
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString error = ''.obs;
  
  int _page = 1;
  final int _limit = 20;
  
  String? categoryId;
  String? searchQuery;
  String sortBy = 'newest';
  
  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      categoryId = args['categoryId'];
      searchQuery = args['searchQuery'];
    }
    fetchProducts();
  }
  
  Future<void> fetchProducts({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      products.clear();
      hasMore.value = true;
    }
    
    if (isLoading.value || isLoadingMore.value) return;
    
    try {
      if (_page == 1) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }
      error.value = '';
      
      final result = await _productRepo.getProducts(
        page: _page,
        limit: _limit,
        category: categoryId,
        search: searchQuery,
        sort: sortBy,
      );
      
      if (refresh) {
        products.assignAll(result.items);
      } else {
        products.addAll(result.items);
      }
      
      hasMore.value = result.hasMore;
      _page++;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
  
  void changeSort(String sort) {
    sortBy = sort;
    fetchProducts(refresh: true);
  }
}
```

### Checkout Flow
```dart
// modules/checkout/controllers/checkout_controller.dart
import 'package:get/get.dart';
import '../../../data/models/address.dart';
import '../../../data/models/cart.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../cart/controllers/cart_controller.dart';

class CheckoutController extends GetxController {
  final CartRepository _cartRepo = Get.find<CartRepository>();
  final OrderRepository _orderRepo = Get.find<OrderRepository>();
  final PaymentRepository _paymentRepo = Get.find<PaymentRepository>();
  final CartController _cartController = Get.find<CartController>();
  
  final Rx<Cart?> cart = Rx<Cart?>(null);
  final Rx<Address?> selectedAddress = Rx<Address?>(null);
  final RxString selectedPaymentMethod = 'online'.obs;
  final RxString selectedTimeSlot = ''.obs;
  final RxString specialInstructions = ''.obs;
  final RxBool useWallet = false.obs;
  final RxDouble walletAmount = 0.0.obs;
  
  final RxBool isCreatingOrder = false.obs;
  final RxBool isProcessingPayment = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    cart.value = _cartController.cart.value;
  }
  
  Future<void> createOrder() async {
    if (selectedAddress.value == null) {
      Get.snackbar('Error', 'Please select delivery address');
      return;
    }
    
    try {
      isCreatingOrder.value = true;
      
      final order = await _orderRepo.createOrder(
        deliveryAddress: selectedAddress.value!.id,
        deliveryType: 'home-delivery',
        paymentMethod: selectedPaymentMethod.value,
        specialRequests: specialInstructions.value,
        useWallet: useWallet.value,
        walletAmount: useWallet.value ? walletAmount.value : 0,
      );
      
      if (selectedPaymentMethod.value == 'cod') {
        // COD - Order complete
        await _cartController.clearCart();
        Get.offNamed('/order-success', arguments: {'order': order});
      } else {
        // Online payment
        await _processPayment(order);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isCreatingOrder.value = false;
    }
  }
  
  Future<void> _processPayment(Order order) async {
    try {
      isProcessingPayment.value = true;
      
      // Initialize payment with Stripe/PhonePe
      final paymentData = await _paymentRepo.createPaymentOrder(
        orderId: order.id,
        paymentMethod: selectedPaymentMethod.value,
      );
      
      // Open payment gateway (Stripe/PhonePe)
      final success = await _openPaymentGateway(paymentData);
      
      if (success) {
        // Verify payment
        await _paymentRepo.verifyPayment(
          orderId: order.id,
          paymentIntentId: paymentData['paymentIntentId'],
        );
        
        await _cartController.clearCart();
        Get.offNamed('/order-success', arguments: {'order': order});
      } else {
        Get.snackbar('Payment Failed', 'Please try again');
      }
    } catch (e) {
      Get.snackbar('Error', 'Payment failed: $e');
    } finally {
      isProcessingPayment.value = false;
    }
  }
  
  Future<bool> _openPaymentGateway(Map<String, dynamic> paymentData) async {
    // Implement Stripe/PhonePe native SDK integration
    // Return true if payment successful
    return true;
  }
  
  double get orderTotal => cart.value?.finalTotal ?? 0;
  double get finalTotal => useWallet.value 
      ? (orderTotal - walletAmount.value).clamp(0, double.infinity)
      : orderTotal;
}
```

### Order Tracking with Real-time Updates
```dart
// modules/orders/controllers/order_tracking_controller.dart
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';

class OrderTrackingController extends GetxController {
  final OrderRepository _orderRepo = Get.find<OrderRepository>();
  late IO.Socket socket;
  
  final Rx<Order?> order = Rx<Order?>(null);
  final RxBool isLoading = true.obs;
  final Rx<CurrentLocation?> agentLocation = Rx<CurrentLocation?>(null);
  
  String orderId = '';
  
  @override
  void onInit() {
    super.onInit();
    orderId = Get.arguments['orderId'];
    fetchOrderDetails();
    _connectSocket();
  }
  
  @override
  void onClose() {
    socket.disconnect();
    super.onClose();
  }
  
  Future<void> fetchOrderDetails() async {
    try {
      isLoading.value = true;
      final data = await _orderRepo.getOrderById(orderId);
      order.value = data;
      
      if (data.deliveryPersonnel?.currentLocation != null) {
        agentLocation.value = data.deliveryPersonnel!.currentLocation;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  
  void _connectSocket() {
    socket = IO.io('https://api.greenbasket.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    
    socket.onConnect((_) {
      print('Socket connected');
      socket.emit('join_order', orderId);
    });
    
    socket.on('order:status_update', (data) {
      if (data['orderId'] == orderId) {
        fetchOrderDetails();
        Get.snackbar('Order Update', 'Status: ${data['status']}');
      }
    });
    
    socket.on('order:location_update', (data) {
      if (data['orderId'] == orderId) {
        agentLocation.value = CurrentLocation(
          lat: data['location']['lat'],
          lng: data['location']['lng'],
          updatedAt: DateTime.now(),
        );
      }
    });
    
    socket.onDisconnect((_) => print('Socket disconnected'));
  }
}
```

---

## 8. PUSH NOTIFICATIONS

### Firebase Messaging Service
```dart
// data/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

class NotificationService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final StorageService _storage = Get.find<StorageService>();
  
  @override
  void onInit() {
    super.onInit();
    _initNotifications();
  }
  
  Future<void> _initNotifications() async {
    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _storage.saveFcmToken(token);
      // Send to backend
      await _sendTokenToServer(token);
    }
    
    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_sendTokenToServer);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background/terminated tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
  }
  
  Future<void> _sendTokenToServer(String token) async {
    // Call API to register FCM token
    // POST /api/users/fcm-token
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }
  
  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'greenbasket_channel',
            'GreenBasket Notifications',
            channelDescription: 'Order updates and offers',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['orderId'],
      );
    }
  }
  
  void _onNotificationTap(NotificationResponse response) {
    final orderId = response.payload;
    if (orderId != null) {
      Get.toNamed('/order/$orderId');
    }
  }
  
  void _handleNotificationOpen(RemoteMessage message) {
    final orderId = message.data['orderId'];
    if (orderId != null) {
      Get.toNamed('/order/$orderId');
    }
  }
}
```

---

## 9. DEEP LINKING

### Deep Link Handler
```dart
// utils/deep_link_handler.dart
import 'package:get/get.dart';
import 'package:uni_links/uni_links.dart';

class DeepLinkHandler {
  static Future<void> init() async {
    // Handle initial link (app opened from terminated state)
    final initialLink = await getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink);
    }
    
    // Handle links when app is in background
    linkStream.listen((String? link) {
      if (link != null) {
        _handleLink(link);
      }
    });
  }
  
  static void _handleLink(String link) {
    final uri = Uri.parse(link);
    
    if (uri.scheme == 'greenbasket') {
      final path = uri.path;
      final id = uri.pathSegments.last;
      
      switch (path) {
        case '/product':
          Get.toNamed('/product/$id');
          break;
        case '/order':
          Get.toNamed('/order/$id');
          break;
        case '/category':
          Get.toNamed('/category/$id');
          break;
        case '/referral':
          Get.toNamed('/signup', arguments: {'referralCode': id});
          break;
      }
    }
  }
}
```

---

## Build Commands

```bash
# Generate JSON models
flutter pub run build_runner build

# Run app
flutter run

# Build APK
flutter build apk --release

# Build App Bundle
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

---

## Environment Configuration

Create `lib/config/environments.dart`:

```dart
class Environments {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';
  
  static String current = development;
  
  static String get baseUrl {
    switch (current) {
      case development:
        return 'http://localhost:6000/api';
      case staging:
        return 'https://staging-api.greenbasket.com/api';
      case production:
        return 'https://api.greenbasket.com/api';
      default:
        return 'http://localhost:6000/api';
    }
  }
}
```

---

## Testing

```dart
// Example widget test
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:greenbasket/main.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const GreenBasketApp());
    await tester.pumpAndSettle();
    
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
```

# GreenBasket Flutter — API Endpoint Mapping & Data Models

## Complete API Endpoint Reference

This document maps every backend endpoint to its corresponding Flutter implementation (Retrofit service, Bloc event, and screen).

---

## Authentication APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/auth/user/signup` | POST | `AuthApi.signup()` | `AuthSignupRequested` | SignupScreen → OtpScreen |
| `/api/auth/user/login` | POST | `AuthApi.login()` | `AuthLoginRequested` | LoginScreen → HomeScreen |
| `/api/auth/user/verify-email` | POST | `AuthApi.verifyEmail()` | `AuthVerifyEmailRequested` | OtpScreen → HomeScreen |
| `/api/auth/user/forgot-password` | POST | `AuthApi.forgotPassword()` | `AuthForgotPasswordRequested` | ForgotPasswordScreen → OtpScreen |
| `/api/auth/user/reset-password` | POST | `AuthApi.resetPassword()` | `AuthResetPasswordRequested` | OtpScreen → LoginScreen |
| `/api/auth/refresh-token` | POST | `AuthApi.refreshToken()` | (Automatic via interceptor) | Background |
| `/api/auth/logout` | POST | `AuthApi.logout()` | `AuthLogoutRequested` | ProfileScreen → LoginScreen |

**Request/Response Models**:
```dart
// lib/data/models/auth_models.dart

@JsonSerializable()
class SignupRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
}

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;
}

@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
}

@JsonSerializable()
class VerifyEmailRequest {
  final String email;
  final String otp;
}
```

---

## Product APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/products` | GET | `ProductApi.getProducts(page, limit, category?, tags?)` | `ProductLoadRequested` | HomeScreen, ProductListingScreen |
| `/api/products/search` | GET | `ProductApi.searchProducts(query, filters)` | `ProductSearchRequested` | SearchScreen |
| `/api/products/:id` | GET | `ProductApi.getProductById(id)` | `ProductDetailLoadRequested` | ProductDetailScreen |

**Request/Response Models**:
```dart
// lib/data/models/product_model.dart

@JsonSerializable()
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? comparePrice;
  final String unit;
  final int stock;
  final String primaryImage;
  final List<String> images;
  final List<String> tags;
  final double averageRating;
  final int totalReviews;
  final CategoryModel category;
  final MerchantSummary merchant;
  final NutritionalInfo? nutritionalInfo;
  final List<PreparationOption>? preparationOptions;
  final bool isPremiumExclusive;
  final bool isPreBookable;
  final DateTime? expectedAvailabilityDate;
  
  // Convert to domain entity
  Product toEntity() => Product(...);
}

@JsonSerializable()
class PreparationOption {
  final String type; // 'whole', 'cut', 'chopped', 'diced', 'sliced'
  final double additionalPrice;
}

@JsonSerializable()
class NutritionalInfo {
  final double? calories;
  final double? protein;
  final double? carbohydrates;
  final double? fat;
  final double? fiber;
  final List<String>? vitamins;
}
```

---

## Category APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/categories` | GET | `CategoryApi.getCategories()` | `CategoryLoadRequested` | HomeScreen, CategoriesScreen |
| `/api/categories/:id` | GET | `CategoryApi.getCategoryById(id)` | `CategoryDetailLoadRequested` | ProductListingScreen |

**Request/Response Models**:
```dart
// lib/data/models/category_model.dart

@JsonSerializable()
class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final String? icon;
  final List<String>? subCategories;
  final bool isActive;
  
  Category toEntity() => Category(...);
}
```

---

## Cart APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/cart` | GET | `CartApi.getCart()` | `CartLoadRequested` | CartScreen (on mount) |
| `/api/cart/add` | POST | `CartApi.addToCart(productId, quantity, preparation?)` | `CartItemAdded` | ProductDetailScreen, ProductCard |
| `/api/cart/update/:productId` | PUT | `CartApi.updateCartItem(productId, quantity)` | `CartItemQuantityUpdated` | CartScreen |
| `/api/cart/remove/:productId` | DELETE | `CartApi.removeFromCart(productId)` | `CartItemRemoved` | CartScreen |
| `/api/cart/clear` | DELETE | `CartApi.clearCart()` | `CartCleared` | CartScreen |
| `/api/cart/recipe-to-cart` | POST | `CartApi.addRecipeToCart(recipeId, servings)` | `CartRecipeAdded` | RecipeDetailScreen |

**Request/Response Models**:
```dart
// lib/data/models/cart_model.dart

@JsonSerializable()
class CartModel {
  final List<CartItemModel> items;
  final double total;
  final double discount;
  final double deliveryCharge;
  final double finalTotal;
  final AppliedCouponModel? appliedCoupon;
  
  Cart toEntity() => Cart(...);
}

@JsonSerializable()
class CartItemModel {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String? preparation;
  final String imageUrl;
  final String unit;
  final int stock; // To show "Only X left" warnings
  
  CartItem toEntity() => CartItem(...);
}

@JsonSerializable()
class AddToCartRequest {
  final String productId;
  final int quantity;
  final String? preparation;
}

@JsonSerializable()
class ApplyCouponRequest {
  final String code;
}

@JsonSerializable()
class AppliedCouponModel {
  final String code;
  final String offerId;
  final double discount;
}
```

---

## Order APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/orders` | POST | `OrderApi.createOrder(request)` | `OrderPlaceRequested` | CheckoutScreen → OrderSuccessScreen |
| `/api/orders/my-orders` | GET | `OrderApi.getMyOrders(status?, page, limit)` | `OrdersLoadRequested` | OrdersScreen |
| `/api/orders/:id` | GET | `OrderApi.getOrderById(id)` | `OrderDetailLoadRequested` | OrderDetailScreen |
| `/api/orders/:id/cancel` | PATCH | `OrderApi.cancelOrder(id, reason)` | `OrderCancelRequested` | OrderDetailScreen |
| `/api/orders/:id/location` | PATCH | `OrderApi.updateLocation(id, lat, lng)` | (Merchant-only) | N/A |

**Request/Response Models**:
```dart
// lib/data/models/order_model.dart

@JsonSerializable()
class CreateOrderRequest {
  final String addressId;
  final String paymentMethod; // 'cod', 'online', 'wallet'
  final String? couponCode;
  final DeliverySlot? deliverySlot;
  final String? specialRequests;
}

@JsonSerializable()
class DeliverySlot {
  final DateTime date;
  final String startTime; // "09:00"
  final String endTime;   // "11:00"
}

@JsonSerializable()
class OrderModel {
  final String id;
  final String orderId; // Display ID like "GB1234567890"
  final String status; // 'pending', 'confirmed', 'preparing', 'out-for-delivery', 'delivered', 'cancelled'
  final List<OrderItemModel> items;
  final double itemsTotal;
  final double deliveryCharges;
  final double discount;
  final double totalAmount;
  final String? couponCode;
  final double couponDiscount;
  final AddressModel deliveryAddress;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime orderedAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final DateTime? estimatedDeliveryTime;
  final DeliveryPersonnel? deliveryPersonnel;
  final List<StatusHistory> statusHistory;
  
  Order toEntity() => Order(...);
}

@JsonSerializable()
class OrderItemModel {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String unit;
  final String? preparation;
  final double subtotal;
  final String imageUrl;
}

@JsonSerializable()
class DeliveryPersonnel {
  final String name;
  final String phone;
  final String? vehicleNumber;
  final Location? currentLocation;
}

@JsonSerializable()
class Location {
  final double lat;
  final double lng;
  final DateTime updatedAt;
}

@JsonSerializable()
class StatusHistory {
  final String status;
  final DateTime timestamp;
  final String? note;
}
```

---

## User APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/users/profile` | GET | `UserApi.getProfile()` | `ProfileLoadRequested` | ProfileScreen |
| `/api/users/profile` | PUT | `UserApi.updateProfile(request)` | `ProfileUpdateRequested` | EditProfileScreen |
| `/api/users/addresses` | GET | `UserApi.getAddresses()` | `AddressesLoadRequested` | AddressManagementScreen, CheckoutScreen |
| `/api/users/addresses` | POST | `UserApi.addAddress(request)` | `AddressAddRequested` | AddAddressScreen |
| `/api/users/addresses/:id` | PUT | `UserApi.updateAddress(id, request)` | `AddressUpdateRequested` | EditAddressScreen |
| `/api/users/addresses/:id` | DELETE | `UserApi.deleteAddress(id)` | `AddressDeleteRequested` | AddressManagementScreen |
| `/api/users/fcm-token` | POST | `UserApi.registerFCMToken(token, deviceType)` | (Background on app start) | Bootstrap |

**Request/Response Models**:
```dart
// lib/data/models/user_model.dart

@JsonSerializable()
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final List<String>? dietaryPreferences;
  final List<String>? allergies;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final int loyaltyPoints;
  final String loyaltyTier; // 'bronze', 'silver', 'gold', 'platinum'
  final double walletBalance;
  final ReferralInfo? referral;
  final NotificationPreferences notificationPreferences;
  
  User toEntity() => User(...);
}

@JsonSerializable()
class UpdateProfileRequest {
  final String? name;
  final String? phone;
  final List<String>? dietaryPreferences;
  final List<String>? allergies;
  final String? profileImage; // Base64 or Cloudinary URL
}

@JsonSerializable()
class AddressModel {
  final String id;
  final String label; // 'home', 'office', 'other'
  final String? name;
  final String? phone;
  final String addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final Location? location;
  
  Address toEntity() => Address(...);
}

@JsonSerializable()
class AddAddressRequest {
  final String label;
  final String? name;
  final String? phone;
  final String addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  final double? lat;
  final double? lng;
}
```

---

## Wishlist APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/wishlist` | GET | `WishlistApi.getWishlist()` | `WishlistLoadRequested` | WishlistScreen |
| `/api/wishlist/add` | POST | `WishlistApi.addToWishlist(productId)` | `WishlistItemAdded` | ProductDetailScreen, ProductCard |
| `/api/wishlist/remove/:productId` | DELETE | `WishlistApi.removeFromWishlist(productId)` | `WishlistItemRemoved` | WishlistScreen, ProductCard |
| `/api/wishlist/move-to-cart/:productId` | POST | `WishlistApi.moveToCart(productId)` | `WishlistItemMovedToCart` | WishlistScreen |
| `/api/wishlist/check/:productId` | GET | `WishlistApi.checkWishlisted(productId)` | (Check on product detail load) | ProductDetailScreen |

---

## Notification APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/notifications` | GET | `NotificationApi.getNotifications(page, limit)` | `NotificationsLoadRequested` | NotificationsScreen |
| `/api/notifications/unread-count` | GET | `NotificationApi.getUnreadCount()` | `NotificationBadgeUpdateRequested` | HomeScreen (app bar) |
| `/api/notifications/:id/read` | PATCH | `NotificationApi.markAsRead(id)` | `NotificationMarkedAsRead` | NotificationsScreen |
| `/api/notifications/read-all` | PATCH | `NotificationApi.markAllAsRead()` | `NotificationsMarkedAllAsRead` | NotificationsScreen |
| `/api/notifications/:id` | DELETE | `NotificationApi.deleteNotification(id)` | `NotificationDeleted` | NotificationsScreen |
| `/api/notifications/clear-all` | DELETE | `NotificationApi.clearAll()` | `NotificationsClearedAll` | NotificationsScreen |

**Request/Response Models**:
```dart
// lib/data/models/notification_model.dart

@JsonSerializable()
class NotificationModel {
  final String id;
  final String type; // 'order_placed', 'order_delivered', 'price_drop', etc.
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Extra payload (orderId, productId, etc.)
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String? actionUrl; // Deep link
  final String? imageUrl;
  final bool read;
  final DateTime createdAt;
  
  AppNotification toEntity() => AppNotification(...);
}
```

---

## Recipe APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/recipes` | GET | `RecipeApi.getRecipes(page, limit, category?, difficulty?)` | `RecipesLoadRequested` | HomeScreen, RecipesScreen |
| `/api/recipes/search` | GET | `RecipeApi.searchRecipes(query)` | `RecipeSearchRequested` | RecipesScreen |
| `/api/recipes/:id` | GET | `RecipeApi.getRecipeById(id)` | `RecipeDetailLoadRequested` | RecipeDetailScreen |
| `/api/recipes/:id/calculate-ingredients` | POST | `RecipeApi.calculateIngredients(id, servings)` | `RecipeIngredientsCalculated` | RecipeDetailScreen |

**Request/Response Models**:
```dart
// lib/data/models/recipe_model.dart

@JsonSerializable()
class RecipeModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final String? videoUrl;
  final String cuisine;
  final String category; // 'breakfast', 'lunch', 'dinner', 'snack', 'dessert'
  final int servings;
  final int prepTime; // minutes
  final int cookTime; // minutes
  final int totalTime; // minutes
  final String difficulty; // 'easy', 'medium', 'hard'
  final List<IngredientModel> ingredients;
  final List<InstructionStep> instructions;
  final NutritionalInfo? nutritionalInfo;
  final List<String> dietaryTags;
  final double averageRating;
  final int totalRatings;
  final int timesCooked;
  
  Recipe toEntity() => Recipe(...);
}

@JsonSerializable()
class IngredientModel {
  final String name;
  final double quantity;
  final String unit;
  final String? productId; // Link to actual product
  final bool isOptional;
}

@JsonSerializable()
class InstructionStep {
  final int stepNumber;
  final String instruction;
  final String? image;
}
```

---

## Search APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/search/products` | GET | `SearchApi.searchProducts(query, filters)` | `SearchQuerySubmitted` | SearchScreen |
| `/api/search/suggestions` | GET | `SearchApi.getSuggestions(query)` | `SearchSuggestionsRequested` | SearchScreen (while typing) |
| `/api/search/trending` | GET | `SearchApi.getTrending()` | `SearchTrendingLoadRequested` | SearchScreen (default state) |

---

## Wallet APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/wallet` | GET | `WalletApi.getWallet()` | `WalletLoadRequested` | WalletScreen, ProfileScreen |
| `/api/wallet/transactions` | GET | `WalletApi.getTransactions(page, limit)` | `WalletTransactionsLoadRequested` | WalletScreen |
| `/api/wallet/add-money` | POST | `WalletApi.addMoney(amount)` | `WalletTopUpRequested` | WalletScreen |
| `/api/wallet/verify-topup` | POST | `WalletApi.verifyTopup(paymentIntentId)` | `WalletTopUpVerified` | WalletScreen (after Stripe PaymentSheet) |

---

## Offer/Coupon APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/offers/available` | GET | `OfferApi.getAvailableOffers()` | `OffersLoadRequested` | CartScreen (coupon sheet) |
| `/api/offers/cart/apply-coupon` | POST | `OfferApi.applyCoupon(code)` | `CartCouponApplied` | CartScreen |
| `/api/offers/cart/remove-coupon` | DELETE | `OfferApi.removeCoupon()` | `CartCouponRemoved` | CartScreen |
| `/api/offers/flash-sales` | GET | `OfferApi.getFlashSales()` | `FlashSalesLoadRequested` | HomeScreen |

---

## Review APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/reviews/product/:productId` | GET | `ReviewApi.getProductReviews(productId, page, limit)` | `ProductReviewsLoadRequested` | ProductDetailScreen |
| `/api/reviews` | POST | `ReviewApi.submitReview(orderId, productId?, rating, comment, images?)` | `ReviewSubmitRequested` | OrderDetailScreen (after delivery) |

---

## Payment APIs

| Endpoint | Method | Retrofit Service | Bloc Event | Screen/Flow |
|---|---|---|---|---|
| `/api/payment/create-payment-intent` | POST | `PaymentApi.createPaymentIntent(amount, orderId)` | `PaymentIntentCreated` | CheckoutScreen (Stripe PaymentSheet) |
| `/api/payment/verify` | POST | `PaymentApi.verifyPayment(paymentIntentId, orderId)` | `PaymentVerified` | CheckoutScreen → OrderSuccessScreen |
| `/api/payment/webhook` | POST | (Backend only — Stripe webhook handler) | N/A | Background |
| `/api/payment/refund/:orderId` | POST | `PaymentApi.requestRefund(orderId)` | `RefundRequested` | OrderDetailScreen |
| `/api/payment/methods` | GET | `PaymentApi.getPaymentMethods()` | `PaymentMethodsLoadRequested` | CheckoutScreen |
| `/api/payment/status/:orderId` | GET | `PaymentApi.getPaymentStatus(orderId)` | `PaymentStatusChecked` | OrderDetailScreen |

---

## Implementation Notes

1. **Retrofit Generation**: Run `flutter pub run build_runner build --delete-conflicting-outputs` after defining API services
2. **JSON Serialization**: All models use `@JsonSerializable()` and require `part 'filename.g.dart';`
3. **Error Handling**: All API calls wrapped in try-catch, errors mapped via `ErrorInterceptor`
4. **Pagination**: Use `page` and `limit` query params (default: page=1, limit=20)
5. **Caching**: Products, categories, user profile cached in Hive with TTL
6. **Offline**: Cart operations work offline, sync when online

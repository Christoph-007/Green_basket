# GreenBasket Flutter Frontend — Complete Specification

## 1. Executive Summary

**GreenBasket Mini** is a premium grocery e-commerce Flutter application enabling consumers to browse farm-fresh products, manage carts, place orders with multiple payment options, track deliveries in real-time, explore recipes, and enjoy loyalty/referral rewards — all powered by a 204-endpoint Node.js backend.

### Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Framework | Flutter | ≥ 3.22.x (latest stable) |
| Language | Dart | ≥ 3.4 |
| State Mgmt | **flutter_bloc** (Bloc/Cubit) | ^8.1 |
| Networking | **dio** + **retrofit** | dio ^5.4, retrofit ^4.1 |
| Local DB | **hive_flutter** | ^2.0 |
| Secure Storage | **flutter_secure_storage** | ^9.0 |
| Navigation | **go_router** | ^14.0 |
| DI | **get_it** + **injectable** | get_it ^7.6, injectable ^2.4 |
| Image Cache | **cached_network_image** | ^3.3 |
| Notifications | **firebase_messaging** | ^15.0 |
| Payments | **flutter_stripe** | ^10.1 |
| Animations | **lottie** | ^3.1 |

### Key Features (Consumer App — Phase 1)

- JWT authentication with token refresh
- Product browsing with search, filter, sort
- Category-based navigation
- Cart with offline persistence + coupon support
- Multi-step checkout with address selection
- Real-time order tracking
- Wishlist with price-drop & stock notifications
- User profile & address management
- Push notifications (FCM)
- Recipes with "add ingredients to cart"
- Loyalty points & referral rewards
- Wallet balance & top-up
- Ratings & reviews

### Why Bloc?

| Criterion | Bloc | Riverpod | Provider |
|---|---|---|---|
| Separation of concerns | ✅ Excellent | ✅ Good | ⚠️ Moderate |
| Testability | ✅ Built-in | ✅ Good | ⚠️ Manual |
| Scalability | ✅ Enterprise | ✅ Good | ❌ Limited |
| Dev tooling | ✅ bloc_test, observer | ✅ Good | ⚠️ Basic |
| Team onboarding | ⚠️ Medium curve | ⚠️ Medium | ✅ Easy |

**Decision**: Bloc provides the strongest separation between UI and business logic, built-in testing utilities (`bloc_test`), and scales well for 20+ feature modules. The event-driven architecture maps cleanly to API calls and complex state transitions (e.g., multi-step checkout, order status tracking).

---

## 2. Technical Architecture

### 2.1 Project Structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + GoRouter + BlocProviders
├── bootstrap.dart                    # DI setup, Hive init, env config
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   ├── app_radius.dart
│   │   ├── app_shadows.dart
│   │   ├── app_durations.dart
│   │   └── api_endpoints.dart
│   ├── theme/
│   │   ├── app_theme.dart            # ThemeData (light + dark)
│   │   └── app_text_theme.dart
│   ├── network/
│   │   ├── api_client.dart           # Dio instance + interceptors
│   │   ├── auth_interceptor.dart     # Attach JWT, handle 401 refresh
│   │   ├── error_interceptor.dart
│   │   ├── api_exceptions.dart
│   │   └── network_info.dart         # connectivity_plus wrapper
│   ├── storage/
│   │   ├── secure_storage.dart       # Token storage
│   │   └── local_storage.dart        # Hive boxes
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   ├── debouncer.dart
│   │   └── extensions.dart
│   ├── error/
│   │   ├── failures.dart
│   │   └── error_handler.dart
│   └── di/
│       └── injection.dart            # get_it registration
│
├── data/
│   ├── models/                       # JSON-serializable data classes
│   │   ├── user_model.dart
│   │   ├── product_model.dart
│   │   ├── category_model.dart
│   │   ├── cart_model.dart
│   │   ├── order_model.dart
│   │   ├── address_model.dart
│   │   ├── review_model.dart
│   │   ├── recipe_model.dart
│   │   ├── notification_model.dart
│   │   ├── wishlist_model.dart
│   │   ├── wallet_model.dart
│   │   ├── offer_model.dart
│   │   └── api_response.dart
│   ├── datasources/
│   │   ├── remote/                   # Retrofit API services
│   │   │   ├── auth_api.dart
│   │   │   ├── product_api.dart
│   │   │   ├── cart_api.dart
│   │   │   ├── order_api.dart
│   │   │   ├── user_api.dart
│   │   │   ├── wishlist_api.dart
│   │   │   ├── notification_api.dart
│   │   │   └── recipe_api.dart
│   │   └── local/
│   │       ├── cart_local.dart
│   │       ├── search_history_local.dart
│   │       └── user_cache.dart
│   └── repositories/                 # Repo implementations
│       ├── auth_repository_impl.dart
│       ├── product_repository_impl.dart
│       ├── cart_repository_impl.dart
│       ├── order_repository_impl.dart
│       ├── user_repository_impl.dart
│       ├── wishlist_repository_impl.dart
│       └── recipe_repository_impl.dart
│
├── domain/
│   ├── entities/                     # Pure Dart domain objects
│   │   ├── user.dart
│   │   ├── product.dart
│   │   ├── category.dart
│   │   ├── cart.dart
│   │   ├── order.dart
│   │   └── address.dart
│   ├── repositories/                 # Abstract repo interfaces
│   │   ├── auth_repository.dart
│   │   ├── product_repository.dart
│   │   ├── cart_repository.dart
│   │   ├── order_repository.dart
│   │   ├── user_repository.dart
│   │   ├── wishlist_repository.dart
│   │   └── recipe_repository.dart
│   └── usecases/                     # Optional use-case layer
│       ├── login_usecase.dart
│       ├── get_products_usecase.dart
│       └── place_order_usecase.dart
│
├── presentation/
│   ├── blocs/
│   │   ├── auth/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── product/
│   │   ├── cart/
│   │   ├── order/
│   │   ├── wishlist/
│   │   ├── profile/
│   │   ├── search/
│   │   ├── notification/
│   │   └── recipe/
│   ├── screens/
│   │   ├── splash/
│   │   ├── onboarding/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   └── otp_screen.dart
│   │   ├── home/
│   │   ├── categories/
│   │   ├── product_listing/
│   │   ├── product_detail/
│   │   ├── search/
│   │   ├── cart/
│   │   ├── checkout/
│   │   ├── order_success/
│   │   ├── orders/
│   │   ├── order_detail/
│   │   ├── profile/
│   │   ├── edit_profile/
│   │   ├── addresses/
│   │   ├── wishlist/
│   │   ├── notifications/
│   │   ├── recipes/
│   │   ├── recipe_detail/
│   │   ├── wallet/
│   │   └── settings/
│   └── widgets/                      # Reusable UI components
│       ├── buttons/
│       ├── inputs/
│       ├── cards/
│       ├── navigation/
│       ├── feedback/
│       ├── loaders/
│       └── common/
│
├── routes/
│   └── app_router.dart               # GoRouter config
│
└── gen/                              # Generated code (freezed, retrofit, injectable)
```

### 2.2 Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # Networking
  dio: ^5.4.3
  retrofit: ^4.1.0
  json_annotation: ^4.9.0
  connectivity_plus: ^6.0.3

  # Navigation
  go_router: ^14.2.0

  # Dependency Injection
  get_it: ^7.6.9
  injectable: ^2.4.1

  # Local Storage
  hive_flutter: ^2.0.0
  flutter_secure_storage: ^9.2.2

  # UI & Design
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  flutter_svg: ^2.0.10
  lottie: ^3.1.2
  google_fonts: ^6.2.1
  smooth_page_indicator: ^1.1.0
  flutter_staggered_grid_view: ^0.7.0
  pinput: ^5.0.0

  # Firebase
  firebase_core: ^3.3.0
  firebase_messaging: ^15.0.4

  # Payments
  flutter_stripe: ^10.1.1
  flutter_stripe_android: ^10.1.1

  # Utilities
  intl: ^0.19.0
  url_launcher: ^6.3.0
  share_plus: ^9.0.0
  image_picker: ^1.1.2
  permission_handler: ^11.3.1
  flutter_rating_bar: ^4.0.1
  pull_to_refresh_flutter3: ^2.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7
  mocktail: ^1.0.3
  build_runner: ^2.4.11
  retrofit_generator: ^8.1.2
  json_serializable: ^6.8.0
  injectable_generator: ^2.6.1
  flutter_lints: ^4.0.0
```

### 2.3 Network Layer

**Dio Configuration** — single instance via `get_it`:

```dart
// core/network/api_client.dart
Dio createDio(SecureStorage secureStorage) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,         // from env
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.addAll([
    AuthInterceptor(secureStorage, dio),
    ErrorInterceptor(),
    LogInterceptor(requestBody: true, responseBody: true),
  ]);
  return dio;
}
```

**Auth Interceptor** — auto-attaches JWT and handles 401 with token refresh:

```dart
// core/network/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  // onRequest: attach 'Authorization: Bearer <accessToken>'
  // onError: if 401 → call /api/auth/refresh-token → retry original request
  //          if refresh fails → emit AuthLogout event, navigate to login
}
```

### 2.4 Local Storage Strategy

| Store | Technology | Contents |
|---|---|---|
| JWT tokens | `flutter_secure_storage` | accessToken, refreshToken |
| Cart (offline) | Hive box `cart_box` | Cart items JSON |
| Search history | Hive box `search_box` | Recent 20 queries |
| User prefs | Hive box `prefs_box` | Theme, onboarding seen, language |
| Product cache | Hive box `product_cache` | Last-fetched products (TTL: 5 min) |

### 2.5 Error Handling Architecture

```
API Error → ErrorInterceptor → maps to AppException subclass
  ├── NetworkException     (no connectivity)
  ├── ServerException      (5xx)
  ├── UnauthorizedException (401 after refresh fails)
  ├── ValidationException  (400 with field errors)
  ├── NotFoundException    (404)
  └── UnknownException     (catch-all)

Bloc catches AppException → emits FeatureError state with user-friendly message
UI renders ErrorStateWidget with retry callback
```

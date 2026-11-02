# GreenBasket — State Management, Navigation & API Integration

## 6. State Management Strategy

### 6.1 Architecture Overview

Each feature module has its own Bloc/Cubit:

```
BlocProvider tree (in app.dart):
├── AuthBloc              (global — persistent)
├── CartBloc              (global — persistent, offline-synced)
├── NotificationBloc      (global — badge count)
├── ProfileCubit          (global — user data cache)
└── Feature screens inject their own Blocs via BlocProvider at route level:
    ├── ProductListBloc
    ├── ProductDetailCubit
    ├── SearchBloc
    ├── OrdersBloc
    ├── OrderDetailCubit
    ├── WishlistBloc
    ├── CheckoutBloc
    ├── AddressBloc
    └── RecipeBloc
```

### 6.2 State Pattern (per feature)

Each Bloc follows this pattern:

```dart
// States (using Equatable)
abstract class FeatureState extends Equatable {}
class FeatureInitial extends FeatureState {}
class FeatureLoading extends FeatureState {}    // full-screen loader
class FeatureLoaded extends FeatureState {
  final List<Item> items;
  final bool hasReachedMax;               // for pagination
}
class FeatureError extends FeatureState {
  final String message;
  final VoidCallback? retry;
}
class FeatureActionLoading extends FeatureState {} // inline action (add to cart)
```

### 6.3 Key Blocs Detail

**AuthBloc**:
- Events: `LoginRequested`, `SignupRequested`, `LogoutRequested`, `TokenRefreshed`, `CheckAuthStatus`
- States: `AuthInitial`, `AuthLoading`, `Authenticated(user)`, `Unauthenticated`, `AuthError(message)`
- Persistence: tokens in `flutter_secure_storage`, user profile in Hive cache

**CartBloc**:
- Events: `LoadCart`, `AddItem(productId, qty, prep)`, `UpdateQuantity(productId, qty)`, `RemoveItem(productId)`, `ClearCart`, `ApplyCoupon(code)`, `RemoveCoupon`
- States: `CartInitial`, `CartLoading`, `CartLoaded(cart, itemCount, total)`, `CartError`
- **Offline**: Cart saved to Hive on every change, synced with API when online. Merge strategy: API is source of truth; local-only items get POSTed on reconnect.

**SearchBloc**:
- Events: `SearchQueryChanged(query)` (debounced 300ms), `LoadSuggestions`, `ClearSearch`
- States: `SearchInitial(recentSearches, trending)`, `SearchSuggestions(suggestions)`, `SearchResults(products, query, hasMore)`, `SearchLoading`
- `transformEvents`: uses `debounceTime(300ms)` on `SearchQueryChanged`

**CheckoutBloc**:
- Events: `SelectAddress(id)`, `SelectTimeSlot(date, slot)`, `SelectPayment(method)`, `PlaceOrder`, `NextStep`, `PreviousStep`
- States: `CheckoutState(step: 0-3, address?, slot?, paymentMethod?, isPlacingOrder)`
- Emits `OrderPlaced(orderId)` on success → navigate to OrderSuccess

### 6.4 State Persistence

| Data | Storage | TTL | Sync |
|---|---|---|---|
| JWT tokens | SecureStorage | Until logout | On app start |
| User profile | Hive `user_cache` | 30 min | On login, pull-to-refresh |
| Cart items | Hive `cart_box` | Persistent | Bi-directional with API |
| Search history | Hive `search_box` | Persistent | Local only |
| Products cache | Hive `product_cache` | 5 min | On list load |
| Onboarding seen | Hive `prefs_box` | Permanent | Local only |

---

## 7. Navigation Structure

### 7.1 Route Definitions (GoRouter)

```dart
// routes/app_router.dart
final goRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isAuth = authBloc.state is Authenticated;
    final isAuthRoute = state.matchedLocation.startsWith('/auth');
    final isSplash = state.matchedLocation == '/splash';
    if (isSplash) return null; // splash handles its own redirect
    if (!isAuth && !isAuthRoute) return '/auth/login';
    if (isAuth && isAuthRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => OnboardingScreen()),

    // Auth routes (no bottom nav)
    GoRoute(path: '/auth/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/auth/signup', builder: (_, __) => SignupScreen()),
    GoRoute(path: '/auth/forgot-password', builder: (_, __) => ForgotPasswordScreen()),
    GoRoute(path: '/auth/verify-email', builder: (_, __) => OtpScreen()),

    // Main shell (with bottom navigation)
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => MainShell(navigationShell: shell),
      branches: [
        // Tab 0: Home
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (_, __) => HomeScreen()),
        ]),
        // Tab 1: Categories
        StatefulShellBranch(routes: [
          GoRoute(path: '/categories', builder: (_, __) => CategoriesScreen()),
        ]),
        // Tab 2: Cart
        StatefulShellBranch(routes: [
          GoRoute(path: '/cart', builder: (_, __) => CartScreen()),
        ]),
        // Tab 3: Wishlist
        StatefulShellBranch(routes: [
          GoRoute(path: '/wishlist', builder: (_, __) => WishlistScreen()),
        ]),
        // Tab 4: Profile
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (_, __) => ProfileScreen()),
        ]),
      ],
    ),

    // Non-tabbed routes (push on top of shell)
    GoRoute(path: '/products/:categoryId', builder: ...),  // Product Listing
    GoRoute(path: '/product/:id', builder: ...),            // Product Detail
    GoRoute(path: '/search', builder: ...),
    GoRoute(path: '/checkout', builder: ...),
    GoRoute(path: '/order-success/:orderId', builder: ...),
    GoRoute(path: '/orders', builder: ...),
    GoRoute(path: '/orders/:id', builder: ...),             // Order Detail
    GoRoute(path: '/profile/edit', builder: ...),
    GoRoute(path: '/addresses', builder: ...),
    GoRoute(path: '/addresses/add', builder: ...),
    GoRoute(path: '/addresses/edit/:id', builder: ...),
    GoRoute(path: '/notifications', builder: ...),
    GoRoute(path: '/settings', builder: ...),
    GoRoute(path: '/recipes', builder: ...),
    GoRoute(path: '/recipes/:id', builder: ...),
    GoRoute(path: '/wallet', builder: ...),
    GoRoute(path: '/loyalty', builder: ...),
    GoRoute(path: '/referral', builder: ...),
    GoRoute(path: '/help', builder: ...),
  ],
);
```

### 7.2 Navigation Flow Diagram

```
Splash ──→ Onboarding (first time) ──→ Login
       ──→ Login (returning, no token)
       ──→ Home (valid token)

Login ←→ Sign Up
Login → Forgot Password → OTP → Login

Home ──→ Search, Product Listing, Product Detail, Notifications
Categories ──→ Product Listing ──→ Product Detail
Product Detail ──→ Cart (via add)
Cart ──→ Checkout (4 steps) ──→ Order Success ──→ Home / Order Detail
Profile ──→ Orders / Addresses / Edit Profile / Wallet / Recipes / Settings
```

### 7.3 Deep Linking

| URI Pattern | Screen |
|---|---|
| `greenbasket://product/{id}` | Product Detail |
| `greenbasket://order/{id}` | Order Detail |
| `greenbasket://offers` | Home (offers tab) |

---

## 8. API Integration

### 8.1 Retrofit Service Architecture

```dart
// data/datasources/remote/auth_api.dart
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio) = _AuthApi;

  @POST('/api/auth/user/signup')
  Future<ApiResponse<UserModel>> signup(@Body() SignupRequest body);

  @POST('/api/auth/user/login')
  Future<ApiResponse<AuthTokens>> login(@Body() LoginRequest body);

  @POST('/api/auth/refresh-token')
  Future<ApiResponse<AuthTokens>> refreshToken(@Body() RefreshRequest body);

  @POST('/api/auth/logout')
  Future<ApiResponse<void>> logout();
}
```

Same pattern for `ProductApi`, `CartApi`, `OrderApi`, `UserApi`, `WishlistApi`, `NotificationApi`, `RecipeApi`, `SearchApi`.

### 8.2 Key Request/Response Models

```dart
// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors; // field-level validation errors
}

// Auth
class LoginRequest { String email; String password; }
class SignupRequest { String name; String email; String phone; String password; }
class AuthTokens { String accessToken; String refreshToken; UserModel user; }

// Product
class ProductModel { String id; String name; String description; double price;
  double? comparePrice; String unit; int stock; String primaryImage;
  List<String> tags; double averageRating; int totalReviews;
  String categoryId; String merchantName; /* ... */ }

// Cart
class CartModel { List<CartItemModel> items; double total; double discount;
  double deliveryCharge; double finalTotal; AppliedCoupon? appliedCoupon; }
class CartItemModel { String productId; String name; int quantity;
  double price; String? preparation; String imageUrl; }

// Order
class CreateOrderRequest { String addressId; String paymentMethod;
  String? couponCode; DeliverySlot? deliverySlot; String? specialRequests; }
class OrderModel { String id; String orderId; String status;
  List<OrderItemModel> items; double totalAmount; DateTime orderedAt;
  AddressModel? deliveryAddress; /* ... */ }
```

### 8.3 Token Refresh Flow

```
Request → 401 Unauthorized
  → Lock (prevent parallel refresh attempts)
  → POST /api/auth/refresh-token { refreshToken }
  → Success: store new tokens → retry original request
  → Failure: clear tokens → emit Unauthenticated → navigate to Login
  → Unlock
```

### 8.4 Caching Strategy

| Endpoint | Cache | TTL | Invalidation |
|---|---|---|---|
| GET /products | In-memory + Hive | 5 min | Pull-to-refresh, product update |
| GET /categories | Hive | 1 hour | App restart |
| GET /cart | Hive (offline) | Persistent | API sync on online |
| GET /user/profile | Hive | 30 min | Profile edit |
| GET /notifications | In-memory only | 2 min | Pull-to-refresh |
| GET /orders | No cache | — | Always fresh |

### 8.5 Offline Support

- **Works offline**: View cached products, manage cart, view cached profile, browse search history
- **Requires online**: Login/signup, checkout, place order, wishlist sync, notifications
- **Offline banner**: When `connectivity_plus` reports no connection, show persistent top banner (amber, "You're offline — some features may not work", 40dp height)

# GreenBasket Flutter — Performance Optimization Guide

## Performance Targets

| Metric | Target | Critical Threshold |
|---|---|---|
| Cold Start Time | < 2s | < 3s |
| Hot Start Time | < 0.5s | < 1s |
| Frame Rate | 60 FPS | 50 FPS |
| Frame Build Time | < 16ms | < 20ms |
| App Size (APK) | < 30MB | < 50MB |
| Memory Usage | < 150MB | < 250MB |
| Network Request Time | < 500ms | < 1s |
| Image Load Time | < 300ms | < 500ms |

---

## 1. Build Performance

### 1.1 Reduce App Size

**Enable Code Shrinking (Android)**:

```gradle
// android/app/build.gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt')
    }
}
```

**Split APKs by ABI**:

```gradle
android {
    splits {
        abi {
            enable true
            reset()
            include 'armeabi-v7a', 'arm64-v8a', 'x86_64'
            universalApk false
        }
    }
}
```

**Analyze App Size**:

```bash
# Build with size analysis
flutter build apk --analyze-size
flutter build appbundle --analyze-size

# View size breakdown
flutter build apk --target-platform android-arm64 --analyze-size --tree-shake-icons
```

### 1.2 Optimize Images

**Use WebP Format**:

```dart
// Automatically convert PNGs to WebP
// pubspec.yaml
flutter:
  assets:
    - assets/images/
  # Flutter will automatically convert to WebP in release builds
```

**Compress Images**:

```bash
# Install ImageMagick
brew install imagemagick

# Compress all PNGs
find assets/images -name "*.png" -exec convert {} -quality 85 {} \;

# Convert to WebP
find assets/images -name "*.png" -exec cwebp -q 80 {} -o {}.webp \;
```

**Use Appropriate Image Sizes**:

```dart
// Don't load full-res images for thumbnails
CachedNetworkImage(
  imageUrl: product.thumbnailUrl, // Use thumbnail, not full image
  width: 100,
  height: 100,
  fit: BoxFit.cover,
  memCacheWidth: 100 * 3, // 3x for high-DPI screens
  memCacheHeight: 100 * 3,
)
```

### 1.3 Tree-Shake Icons

```bash
# Only include used Material Icons
flutter build apk --tree-shake-icons
```

---

## 2. Runtime Performance

### 2.1 Optimize Widget Builds

**Use `const` Constructors**:

```dart
// ❌ Bad: Rebuilds on every parent rebuild
Widget build(BuildContext context) {
  return Container(
    padding: EdgeInsets.all(16),
    child: Text('Hello'),
  );
}

// ✅ Good: Const widgets never rebuild
Widget build(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Hello'),
  );
}
```

**Use `RepaintBoundary` for Expensive Widgets**:

```dart
// Isolate expensive animations
RepaintBoundary(
  child: LottieAnimation(asset: 'loading.json'),
)
```

**Avoid Rebuilding Entire Trees**:

```dart
// ❌ Bad: Entire list rebuilds on state change
BlocBuilder<CartBloc, CartState>(
  builder: (context, state) {
    return ListView.builder(
      itemCount: state.items.length,
      itemBuilder: (context, index) => CartItemCard(state.items[index]),
    );
  },
)

// ✅ Good: Only rebuild when items change
BlocSelector<CartBloc, CartState, List<CartItem>>(
  selector: (state) => state.items,
  builder: (context, items) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => CartItemCard(items[index]),
    );
  },
)
```

### 2.2 Optimize Lists

**Use `ListView.builder` (Not `ListView`)**:

```dart
// ❌ Bad: Builds all items upfront
ListView(
  children: products.map((p) => ProductCard(p)).toList(),
)

// ✅ Good: Lazy builds items as scrolled
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) => ProductCard(products[index]),
)
```

**Add `cacheExtent` for Smoother Scrolling**:

```dart
ListView.builder(
  cacheExtent: 500, // Preload 500px ahead
  itemCount: products.length,
  itemBuilder: (context, index) => ProductCard(products[index]),
)
```

**Use `AutomaticKeepAliveClientMixin` for Tabs**:

```dart
class ProductListTab extends StatefulWidget {
  @override
  _ProductListTabState createState() => _ProductListTabState();
}

class _ProductListTabState extends State<ProductListTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Preserve state when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return ListView.builder(...);
  }
}
```

### 2.3 Optimize Images

**Use `CachedNetworkImage` with Proper Config**:

```dart
CachedNetworkImage(
  imageUrl: product.imageUrl,
  memCacheWidth: 300, // Resize in memory
  memCacheHeight: 300,
  maxWidthDiskCache: 600, // Resize on disk
  maxHeightDiskCache: 600,
  placeholder: (context, url) => ShimmerBox(width: 150, height: 150),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fadeInDuration: Duration(milliseconds: 200),
)
```

**Configure Cache Manager**:

```dart
// lib/core/utils/cache_manager.dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager extends CacheManager {
  static const key = 'customCacheKey';

  static final CustomCacheManager _instance = CustomCacheManager._();
  factory CustomCacheManager() => _instance;

  CustomCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 200,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );
}

// Use in CachedNetworkImage
CachedNetworkImage(
  imageUrl: url,
  cacheManager: CustomCacheManager(),
)
```

### 2.4 Debounce User Input

```dart
// lib/core/utils/debouncer.dart
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

// Usage in SearchScreen
class _SearchScreenState extends State<SearchScreen> {
  final _debouncer = Debouncer(delay: Duration(milliseconds: 300));

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      context.read<SearchBloc>().add(SearchQueryChanged(query));
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
```

### 2.5 Optimize Network Requests

**Batch API Calls**:

```dart
// ❌ Bad: Multiple sequential calls
final user = await userApi.getProfile();
final orders = await orderApi.getOrders();
final notifications = await notificationApi.getNotifications();

// ✅ Good: Parallel calls
final results = await Future.wait([
  userApi.getProfile(),
  orderApi.getOrders(),
  notificationApi.getNotifications(),
]);
```

**Implement Request Caching**:

```dart
// lib/core/network/cache_interceptor.dart
class CacheInterceptor extends Interceptor {
  final Map<String, CacheEntry> _cache = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'GET') {
      final cacheKey = options.uri.toString();
      final cached = _cache[cacheKey];

      if (cached != null && !cached.isExpired) {
        return handler.resolve(
          Response(
            requestOptions: options,
            data: cached.data,
            statusCode: 200,
          ),
        );
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
      final cacheKey = response.requestOptions.uri.toString();
      _cache[cacheKey] = CacheEntry(
        data: response.data,
        expiresAt: DateTime.now().add(Duration(minutes: 5)),
      );
    }
    handler.next(response);
  }
}

class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

**Use HTTP/2**:

```dart
// Dio automatically uses HTTP/2 if server supports it
final dio = Dio(BaseOptions(
  baseUrl: baseUrl,
  connectTimeout: Duration(seconds: 15),
  receiveTimeout: Duration(seconds: 15),
));
```

---

## 3. Memory Optimization

### 3.1 Dispose Controllers and Streams

```dart
class _MyScreenState extends State<MyScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = someStream.listen((data) {
      // Handle data
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _subscription?.cancel();
    super.dispose();
  }
}
```

### 3.2 Use `ChangeNotifier` Carefully

```dart
// ❌ Bad: Notifies all listeners on every change
class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];

  void addItem(CartItem item) {
    _items.add(item);
    notifyListeners(); // Rebuilds entire cart UI
  }
}

// ✅ Good: Use Bloc for granular updates
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<CartItemAdded>((event, emit) {
      final newItems = [...state.items, event.item];
      emit(CartLoaded(items: newItems)); // Only rebuilds BlocBuilder
    });
  }
}
```

### 3.3 Clear Image Cache Periodically

```dart
// Clear cache on low memory warning
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

void clearImageCache() async {
  await DefaultCacheManager().emptyCache();
  imageCache.clear();
  imageCache.clearLiveImages();
}

// Call on app lifecycle change
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      clearImageCache();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

---

## 4. Startup Performance

### 4.1 Lazy Load Dependencies

```dart
// ❌ Bad: Register all dependencies upfront
Future<void> configureDependencies() async {
  getIt.registerSingleton<AuthRepository>(AuthRepositoryImpl());
  getIt.registerSingleton<ProductRepository>(ProductRepositoryImpl());
  getIt.registerSingleton<OrderRepository>(OrderRepositoryImpl());
  // ... 20 more repositories
}

// ✅ Good: Lazy registration
Future<void> configureDependencies() async {
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  getIt.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl());
  getIt.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl());
}
```

### 4.2 Defer Non-Critical Initialization

```dart
// lib/bootstrap.dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Critical: Must complete before app starts
  await Firebase.initializeApp();
  await LocalStorage.init();
  await configureDependencies();

  runApp(MyApp());

  // Non-critical: Can happen after app starts
  Future.delayed(Duration(seconds: 2), () {
    _initializeNonCritical();
  });
}

Future<void> _initializeNonCritical() async {
  await FirebaseAnalytics.instance.logAppOpen();
  await _checkForUpdates();
  await _syncOfflineData();
}
```

### 4.3 Use Splash Screen Wisely

```dart
// Don't block on splash screen
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Show splash for minimum 1.5s for branding
    await Future.delayed(Duration(milliseconds: 1500));

    // Check auth status (fast, from secure storage)
    final hasToken = await getIt<SecureStorage>().getAccessToken();

    if (hasToken != null) {
      context.go('/');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset('assets/animations/splash_logo.json'),
      ),
    );
  }
}
```

---

## 5. Animation Performance

### 5.1 Use `AnimatedBuilder` Instead of `setState`

```dart
// ❌ Bad: Rebuilds entire widget
class _MyWidgetState extends State<MyWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _controller.value,
      child: ExpensiveWidget(), // Rebuilds on every frame!
    );
  }
}

// ✅ Good: Only rebuilds animated part
class _MyWidgetState extends State<MyWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _controller.value,
          child: child,
        );
      },
      child: ExpensiveWidget(), // Built once, reused
    );
  }
}
```

### 5.2 Optimize Lottie Animations

```dart
// Limit frame rate for complex animations
Lottie.asset(
  'assets/animations/loading.json',
  frameRate: FrameRate(30), // Instead of 60fps
  width: 80,
  height: 80,
)
```

### 5.3 Use `ImplicitlyAnimatedWidget` for Simple Animations

```dart
// Instead of AnimationController for simple transitions
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  width: isExpanded ? 200 : 100,
  height: isExpanded ? 200 : 100,
  color: isExpanded ? Colors.blue : Colors.red,
)
```

---

## 6. Profiling & Debugging

### 6.1 Use Flutter DevTools

```bash
# Run app in profile mode
flutter run --profile

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

**Performance Tab**:
- Track frame rendering times
- Identify jank (frames > 16ms)
- View widget rebuild counts

**Memory Tab**:
- Monitor memory usage
- Detect memory leaks
- Analyze heap snapshots

**Network Tab**:
- View all HTTP requests
- Check request/response times
- Identify slow endpoints

### 6.2 Performance Overlay

```dart
// Enable in debug mode
MaterialApp(
  showPerformanceOverlay: true, // Shows FPS
  debugShowCheckedModeBanner: false,
)
```

### 6.3 Timeline Trace

```dart
import 'dart:developer' as developer;

void expensiveOperation() {
  developer.Timeline.startSync('ExpensiveOperation');
  // ... do work
  developer.Timeline.finishSync();
}
```

View in DevTools → Timeline tab

### 6.4 Benchmark Specific Operations

```dart
// test/performance/benchmark_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Product list rendering benchmark', () async {
    final stopwatch = Stopwatch()..start();

    // Render 100 product cards
    for (int i = 0; i < 100; i++) {
      ProductCard(product: testProduct);
    }

    stopwatch.stop();
    print('Rendered 100 cards in ${stopwatch.elapsedMilliseconds}ms');
    expect(stopwatch.elapsedMilliseconds, lessThan(100));
  });
}
```

---

## 7. Production Optimizations

### 7.1 Enable Obfuscation

```bash
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
flutter build ios --obfuscate --split-debug-info=build/ios/symbols
```

### 7.2 Disable Debugging in Release

```dart
// lib/main.dart
void main() {
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {}; // Disable prints
  }
  runApp(MyApp());
}
```

### 7.3 Use Release Mode for Testing

```bash
# Profile mode (for performance testing)
flutter run --profile

# Release mode (exact production build)
flutter run --release
```

---

## 8. Performance Checklist

### Build Time
- [ ] App size < 50MB
- [ ] Code shrinking enabled
- [ ] Tree-shaking enabled
- [ ] Images optimized (WebP)
- [ ] Unused assets removed

### Runtime
- [ ] All lists use `.builder`
- [ ] `const` constructors used
- [ ] Images cached properly
- [ ] Network requests debounced
- [ ] No blocking operations on main thread

### Memory
- [ ] Controllers disposed
- [ ] Streams closed
- [ ] Image cache cleared periodically
- [ ] No memory leaks (verified in DevTools)

### Startup
- [ ] Cold start < 3s
- [ ] Dependencies lazy-loaded
- [ ] Non-critical init deferred
- [ ] Splash screen optimized

### Animations
- [ ] Frame rate ≥ 60 FPS
- [ ] `RepaintBoundary` used for complex widgets
- [ ] Lottie animations optimized
- [ ] No jank during scrolling

---

## 9. Performance Monitoring in Production

### Firebase Performance Monitoring

```dart
// lib/main.dart
import 'package:firebase_performance/firebase_performance.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Enable performance monitoring
  FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

  runApp(MyApp());
}

// Track custom traces
Future<void> loadProducts() async {
  final trace = FirebasePerformance.instance.newTrace('load_products');
  await trace.start();

  try {
    final products = await productRepository.getProducts();
    trace.setMetric('product_count', products.length);
    return products;
  } finally {
    await trace.stop();
  }
}

// Track HTTP requests (automatic with Dio + Firebase Performance plugin)
```

### Custom Metrics

```dart
// Track app-specific metrics
class PerformanceMonitor {
  static void trackCheckoutTime(Duration duration) {
    FirebaseAnalytics.instance.logEvent(
      name: 'checkout_duration',
      parameters: {'duration_ms': duration.inMilliseconds},
    );
  }

  static void trackSearchTime(String query, Duration duration) {
    FirebaseAnalytics.instance.logEvent(
      name: 'search_duration',
      parameters: {
        'query': query,
        'duration_ms': duration.inMilliseconds,
      },
    );
  }
}
```

---

## 10. Quick Wins

1. **Use `const` everywhere possible** → 20-30% fewer rebuilds
2. **Replace `ListView` with `ListView.builder`** → 50% less memory
3. **Add `cacheExtent` to lists** → Smoother scrolling
4. **Debounce search input** → 80% fewer API calls
5. **Use `CachedNetworkImage`** → 90% faster image loads
6. **Enable code shrinking** → 40% smaller APK
7. **Lazy load dependencies** → 30% faster startup
8. **Use WebP images** → 25-35% smaller images
9. **Batch API calls** → 50% faster data loading
10. **Profile before optimizing** → Focus on actual bottlenecks

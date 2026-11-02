# GreenBasket Flutter — Implementation Guide (Part 2)

## Phase 3: Network Layer & Dependency Injection

### Step 3.1: Secure Storage

Create `lib/core/storage/secure_storage.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
```

### Step 3.2: Hive Local Storage

Create `lib/core/storage/local_storage.dart`:

```dart
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const String cartBoxName = 'cart_box';
  static const String searchBoxName = 'search_box';
  static const String prefsBoxName = 'prefs_box';
  static const String productCacheBoxName = 'product_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(cartBoxName),
      Hive.openBox(searchBoxName),
      Hive.openBox(prefsBoxName),
      Hive.openBox(productCacheBoxName),
    ]);
  }

  Box get cartBox => Hive.box(cartBoxName);
  Box get searchBox => Hive.box(searchBoxName);
  Box get prefsBox => Hive.box(prefsBoxName);
  Box get productCacheBox => Hive.box(productCacheBoxName);
}
```

### Step 3.3: API Exceptions

Create `lib/core/network/api_exceptions.dart`:

```dart
class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException() : super('No internet connection');
}

class ServerException extends AppException {
  ServerException([String? message]) 
      : super(message ?? 'Server error occurred', 500);
}

class UnauthorizedException extends AppException {
  UnauthorizedException() : super('Unauthorized', 401);
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;
  ValidationException(String message, [this.errors]) : super(message, 400);
}

class NotFoundException extends AppException {
  NotFoundException([String? message]) 
      : super(message ?? 'Resource not found', 404);
}

class UnknownException extends AppException {
  UnknownException([String? message]) 
      : super(message ?? 'An unknown error occurred');
}
```

### Step 3.4: Auth Interceptor

Create `lib/core/network/auth_interceptor.dart`:

```dart
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final Dio _dio;

  AuthInterceptor(this._secureStorage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken != null) {
          final response = await _dio.post(
            '/api/auth/refresh-token',
            data: {'refreshToken': refreshToken},
            options: Options(headers: {'requiresAuth': false}),
          );

          if (response.statusCode == 200) {
            final newAccessToken = response.data['data']['accessToken'];
            final newRefreshToken = response.data['data']['refreshToken'];
            
            await _secureStorage.saveTokens(newAccessToken, newRefreshToken);

            // Retry original request
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            final cloneReq = await _dio.fetch(opts);
            return handler.resolve(cloneReq);
          }
        }
      } catch (e) {
        // Refresh failed, clear tokens
        await _secureStorage.clearTokens();
        // Emit logout event via EventBus or Bloc
      }
    }
    handler.next(err);
  }
}
```

### Step 3.5: Error Interceptor

Create `lib/core/network/error_interceptor.dart`:

```dart
import 'package:dio/dio.dart';
import 'api_exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = NetworkException();
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final message = err.response?.data?['message'] ?? 'Request failed';
        
        switch (statusCode) {
          case 400:
            exception = ValidationException(
              message,
              err.response?.data?['errors'],
            );
            break;
          case 401:
            exception = UnauthorizedException();
            break;
          case 404:
            exception = NotFoundException(message);
            break;
          case 500:
          case 502:
          case 503:
            exception = ServerException(message);
            break;
          default:
            exception = UnknownException(message);
        }
        break;
      default:
        exception = NetworkException();
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
      ),
    );
  }
}
```

### Step 3.6: API Client

Create `lib/core/network/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import '../constants/app_config.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

class ApiClient {
  late final Dio dio;

  ApiClient(SecureStorage secureStorage) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.addAll([
      AuthInterceptor(secureStorage, dio),
      ErrorInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print(obj), // Use logger package in production
      ),
    ]);
  }
}
```

### Step 3.7: Dependency Injection Setup

Create `lib/core/di/injection.dart`:

```dart
import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../storage/secure_storage.dart';
import '../storage/local_storage.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Storage
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());
  getIt.registerLazySingleton<LocalStorage>(() => LocalStorage());

  // Network
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<SecureStorage>()),
  );

  // Repositories will be registered here later
  // Blocs will be registered here later
}
```

### Step 3.8: Bootstrap

Create `lib/bootstrap.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/di/injection.dart';
import 'core/storage/local_storage.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive
  await LocalStorage.init();
  
  // Setup DI
  await configureDependencies();
}
```

---

## Phase 4: Core Components

### Step 4.1: Primary Button

Create `lib/presentation/widgets/buttons/gb_primary_button.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_durations.dart';

class GBPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const GBPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.fullWidth = true,
  });

  @override
  State<GBPrimaryButton> createState() => _GBPrimaryButtonState();
}

class _GBPrimaryButtonState extends State<GBPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.button,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading
          ? _handleTapDown
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading
          ? _handleTapUp
          : null,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: AppTypography.buttonLg,
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

### Step 4.2: Text Field

Create `lib/presentation/widgets/inputs/gb_text_field.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

class GBTextField extends StatelessWidget {
  final String? label;
  final String hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool enabled;
  final int maxLines;
  final void Function(String)? onChanged;

  const GBTextField({
    super.key,
    this.label,
    required this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.errorText,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.titleSm.copyWith(color: AppColors.neutral700),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          maxLines: maxLines,
          onChanged: onChanged,
          style: AppTypography.bodyMd.copyWith(color: AppColors.neutral900),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.neutral500),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.neutral500)
                : null,
            suffixIcon: suffixIcon,
            errorText: errorText,
            filled: true,
            fillColor: enabled ? AppColors.neutral100 : AppColors.neutral100.withOpacity(0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.neutral300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.neutral300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
```

### Step 4.3: Shimmer Loader

Create `lib/presentation/widgets/loaders/shimmer_loader.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';

class ShimmerLoader extends StatelessWidget {
  final Widget child;

  const ShimmerLoader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmer,
      highlightColor: AppColors.shimmerHighlight,
      child: child,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
```

---

**Continue to Phase 5...**

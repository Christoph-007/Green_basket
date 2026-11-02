import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // ── API ────────────────────────────────────────────────────────────
  // ── Connection config ──────────────────────────────────────────────
  // Set the backend at build/run time instead of editing this file:
  //   flutter run --dart-define=API_URL=http://10.0.2.2:5002/api        (Android emulator)
  //   flutter run --dart-define=API_URL=http://localhost:5002/api       (iOS simulator)
  //   flutter run --dart-define=API_URL=http://192.168.1.20:5002/api    (real device, your PC's LAN IP)
  // If not explicitly set via API_URL, detects platform automatically:
  static String get baseUrl {
    const explicit = String.fromEnvironment('API_URL');
    if (explicit.isNotEmpty) return explicit;
    if (kIsWeb) return 'http://localhost:5002/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:5002/api';
    return 'http://localhost:5002/api';
  }

  /// Socket.IO server = the API URL without the trailing "/api"
  static String get socketUrl {
    const explicit = String.fromEnvironment('SOCKET_URL');
    if (explicit.isNotEmpty) return explicit;
    return baseUrl.endsWith('/api') ? baseUrl.substring(0, baseUrl.length - 4) : baseUrl;
  }
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // ── Pagination ─────────────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ── Storage keys ───────────────────────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';
  static const String onboardedKey = 'onboarded';
  static const String fcmTokenKey = 'fcm_token';
  static const String cartCacheKey = 'cart_cache';

  // ── User roles ─────────────────────────────────────────────────────
  static const String roleCustomer = 'customer';
  static const String roleMerchant = 'merchant';
  static const String roleAdmin = 'admin';

  // ── App info ───────────────────────────────────────────────────────
  static const String appName = 'GreenBasket';
  static const String appVersion = '1.0.0';

  // ── OTP ────────────────────────────────────────────────────────────
  static const int otpResendSeconds = 60;

  // ── Image quality ──────────────────────────────────────────────────
  static const int imageCacheWidth = 800;

  // ── Loyalty tiers (synced with backend) ────────────────────────────
  static const Map<String, Map<String, int>> loyaltyTiers = {
    'bronze': {'min': 0, 'max': 499},
    'silver': {'min': 500, 'max': 999},
    'gold': {'min': 1000, 'max': 2499},
    'platinum': {'min': 2500, 'max': 999999},
  };

  // ── Stripe ─────────────────────────────────────────────────────────
}

import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../../config/constants.dart';
import '../models/user_model.dart';

class StorageService {
  final _box = GetStorage();

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<void> init() => GetStorage.init();

  // Token
  String? get token => _box.read(AppConstants.tokenKey);
  void saveToken(String token) => _box.write(AppConstants.tokenKey, token);
  void clearToken() => _box.remove(AppConstants.tokenKey);

  // Refresh Token
  String? get refreshToken => _box.read(AppConstants.refreshTokenKey);
  void saveRefreshToken(String token) =>
      _box.write(AppConstants.refreshTokenKey, token);
  void clearRefreshToken() => _box.remove(AppConstants.refreshTokenKey);

  // User
  UserModel? get user {
    final json = _box.read(AppConstants.userKey);
    if (json == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  void saveUser(UserModel user) =>
      _box.write(AppConstants.userKey, jsonEncode(user.toJson()));
  void clearUser() => _box.remove(AppConstants.userKey);

  // Role
  String? get role => _box.read(AppConstants.roleKey);
  void saveRole(String role) => _box.write(AppConstants.roleKey, role);

  // Onboarding
  bool get isOnboarded => _box.read(AppConstants.onboardedKey) ?? false;
  void setOnboarded() => _box.write(AppConstants.onboardedKey, true);

  // Recent searches (newest first, at most 8)
  List<String> get recentSearches {
    final raw = _box.read(AppConstants.recentSearchesKey);
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return <String>[];
  }

  void addRecentSearch(String term) {
    final text = term.trim();
    if (text.isEmpty) return;
    final list = recentSearches
      ..removeWhere((e) => e.toLowerCase() == text.toLowerCase());
    list.insert(0, text);
    _box.write(AppConstants.recentSearchesKey, list.take(8).toList());
  }

  void clearRecentSearches() => _box.remove(AppConstants.recentSearchesKey);

  // Merchant: play a sound and vibrate when a new order arrives (on by default)
  bool get orderAlertSound => _box.read(AppConstants.orderAlertSoundKey) ?? true;
  void setOrderAlertSound(bool on) =>
      _box.write(AppConstants.orderAlertSoundKey, on);

  // Appearance: 'system' (default), 'light' or 'dark'
  String get themeMode => _box.read(AppConstants.themeModeKey) ?? 'system';
  void setThemeMode(String mode) => _box.write(AppConstants.themeModeKey, mode);

  // The explanation before the first location permission prompt was shown
  bool get locationExplained =>
      _box.read(AppConstants.locationExplainedKey) ?? false;
  void setLocationExplained() =>
      _box.write(AppConstants.locationExplainedKey, true);

  // FCM Token
  String? get fcmToken => _box.read(AppConstants.fcmTokenKey);
  void saveFcmToken(String token) =>
      _box.write(AppConstants.fcmTokenKey, token);

  bool get isLoggedIn => token != null;

  void clearAll() => _box.erase();
}

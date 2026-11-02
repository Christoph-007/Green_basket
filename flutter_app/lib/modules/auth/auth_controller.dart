import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/socket_service.dart';
import '../../data/services/notification_service.dart';

class AuthController extends GetxController {
  final _repo = AuthRepository();
  final _storage = StorageService();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final user = Rxn<UserModel>();

  bool get isLoggedIn => _storage.isLoggedIn;
  String get role => _storage.role ?? AppConstants.roleCustomer;

  @override
  void onInit() {
    super.onInit();
    user.value = _storage.user;
    // Auto-connect socket if user is already logged in
    if (_storage.isLoggedIn) {
      SocketService.to.connect();
      fetchProfile();
    }
  }

  Future<void> fetchProfile() async {
    try {
      if (!_storage.isLoggedIn) return;
      final profile = await _repo.getProfile(role: role);
      // Keep the current role
      final updatedUser = profile.copyWith(role: role);
      user.value = updatedUser;
      _storage.saveUser(updatedUser);
    } catch (e) {
      print('Error fetching profile: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
          logout();
        }
      }
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _repo.login(email: email, password: password);
      if (result['success'] == true) {
        // Clear previous session data first to prevent profile mismatch
        _storage.clearAll();
        
        final token = result['token'] ?? result['data']?['token'];
        _storage.saveToken(token);

        final refreshToken =
            result['refreshToken'] ?? result['data']?['refreshToken'];
        if (refreshToken != null) _storage.saveRefreshToken(refreshToken);
        
        final topRole = result['role'] ?? result['data']?['role'];
        final uJson = Map<String, dynamic>.from(result['user'] ?? result['data']?['user'] ?? {});
        
        // Ensure role exists in the user model data
        if (topRole != null && (uJson['role'] == null || uJson['role'] == '')) {
          uJson['role'] = topRole;
        }

        final u = UserModel.fromJson(uJson);
        final finalRole = topRole ?? u.role;
        final updatedUser = u.copyWith(role: finalRole);

        _storage.saveUser(updatedUser);
        _storage.saveRole(finalRole);
        user.value = updatedUser;
        SocketService.to.connect();
        NotificationService.to.syncToken();
        _navigateByRole(finalRole);
      } else {
        errorMessage.value = result['message'] ?? 'Login failed';
      }
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Network error. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _repo.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      if (result['success'] == true) {
        Get.toNamed(Routes.otp, arguments: {'email': email, 'role': role});
      } else {
        errorMessage.value = result['message'] ?? 'Registration failed';
      }
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Network error. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _repo.verifyOtp(email: email, otp: otp);
      if (result['success'] == true) {
        // Clear previous session data first to prevent profile mismatch
        _storage.clearAll();

        final token = result['token'] ?? result['data']?['token'];
        _storage.saveToken(token);

        final refreshToken =
            result['refreshToken'] ?? result['data']?['refreshToken'];
        if (refreshToken != null) _storage.saveRefreshToken(refreshToken);
        
        final topRole = result['role'] ?? result['data']?['role'];
        final uJson = Map<String, dynamic>.from(result['user'] ?? result['data']?['user'] ?? {});
        
        // Ensure role exists in the user model data
        if (topRole != null && (uJson['role'] == null || uJson['role'] == '')) {
          uJson['role'] = topRole;
        }

        final u = UserModel.fromJson(uJson);
        final finalRole = topRole ?? u.role;
        final updatedUser = u.copyWith(role: finalRole);

        _storage.saveUser(updatedUser);
        _storage.saveRole(finalRole);
        user.value = updatedUser;
        SocketService.to.connect();
        NotificationService.to.syncToken();
        Get.snackbar('Success', 'Email verified successfully');
        _navigateByRole(finalRole);
      } else {
        errorMessage.value = result['message'] ?? 'Invalid OTP';
      }
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Network error. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp(String email) async {
    try {
      await _repo.resendOtp(email);
      Get.snackbar('OTP Sent', 'A new OTP has been sent to your email.');
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Failed to resend OTP';
    }
  }

  /// Sends a password-reset OTP. Opens the reset screen unless [openResetScreen]
  /// is false (used by "Resend code" on that screen).
  Future<void> forgotPassword(String email, {bool openResetScreen = true}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _repo.forgotPassword(email);
      if (result['success'] == true) {
        Get.snackbar(
          'OTP Sent',
          'A 6-digit code has been sent to $email',
          snackPosition: SnackPosition.BOTTOM,
        );
        if (openResetScreen) {
          Get.toNamed(Routes.resetPassword, arguments: {'email': email});
        }
      } else {
        errorMessage.value = result['message'] ?? 'Failed to send OTP';
      }
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Network error. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Returns true when the password was reset.
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final result = await _repo.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      if (result['success'] == true) {
        Get.snackbar(
          'Password Reset',
          'Your password has been changed. Please log in.',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offAllNamed(Routes.login);
        return true;
      }
      errorMessage.value = result['message'] ?? 'Password reset failed';
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Network error. Please try again.';
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  void logout() {
    NotificationService.to.removeToken();
    SocketService.to.disconnect();
    _storage.clearAll();
    user.value = null;
    Get.offAllNamed(Routes.login);
  }

  void _navigateByRole(String role) {
    final r = role.toLowerCase().trim();
    if (r == AppConstants.roleMerchant) {
      Get.offAllNamed(Routes.merchantDashboard);
    } else if (r == AppConstants.roleAdmin || r == 'super-admin' || r == 'moderator') {
      Get.offAllNamed(Routes.adminDashboard);
    } else {
      Get.offAllNamed(Routes.customerHome);
    }
  }
}

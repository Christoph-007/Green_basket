# GreenBasket Flutter — Security Audit Checklist

## Critical Security Requirements

### ✅ = Implemented | ⚠️ = Needs Review | ❌ = Not Implemented

---

## 1. Authentication & Authorization

### 1.1 Token Management
- [ ] JWT tokens stored in `flutter_secure_storage` (encrypted)
- [ ] Access tokens never logged or exposed
- [ ] Refresh tokens rotated on each use
- [ ] Tokens cleared on logout
- [ ] Auto-logout on token expiration
- [ ] Biometric authentication option (fingerprint/face)
- [ ] Session timeout after inactivity (30 min)

**Implementation**:
```dart
// ✅ Secure token storage
class SecureStorage {
  final _storage = FlutterSecureStorage();
  
  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }
  
  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}

// ❌ Insecure: Don't use SharedPreferences for tokens
SharedPreferences.setString('token', accessToken); // NEVER DO THIS
```

### 1.2 Password Security
- [ ] Minimum 8 characters enforced
- [ ] Requires uppercase, lowercase, number
- [ ] Password never stored locally
- [ ] Password never logged
- [ ] Password strength indicator shown
- [ ] "Show password" toggle available
- [ ] Password reset via OTP only

**Validation**:
```dart
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password required';
  if (value.length < 8) return 'Minimum 8 characters';
  if (!value.contains(RegExp(r'[A-Z]'))) return 'Need uppercase letter';
  if (!value.contains(RegExp(r'[a-z]'))) return 'Need lowercase letter';
  if (!value.contains(RegExp(r'[0-9]'))) return 'Need number';
  return null;
}
```

### 1.3 Session Management
- [ ] Single session per device (optional)
- [ ] Active sessions viewable in profile
- [ ] Ability to logout from all devices
- [ ] Session invalidation on password change
- [ ] No session data in URL parameters

---

## 2. Data Protection

### 2.1 Sensitive Data Storage
- [ ] Payment info NEVER stored locally
- [ ] Credit card numbers NEVER stored
- [ ] CVV NEVER stored
- [ ] Personal data encrypted in Hive
- [ ] Biometric data handled by OS only
- [ ] User preferences encrypted if sensitive

**Encryption Example**:
```dart
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptedStorage {
  final _key = encrypt.Key.fromSecureRandom(32);
  final _iv = encrypt.IV.fromSecureRandom(16);
  final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  String encryptData(String plainText) {
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }

  String decryptData(String encrypted) {
    return _encrypter.decrypt64(encrypted, iv: _iv);
  }
}
```

### 2.2 Data Transmission
- [ ] All API calls over HTTPS only
- [ ] Certificate pinning enabled (production)
- [ ] No sensitive data in GET parameters
- [ ] Request/response encryption for PII
- [ ] TLS 1.2+ enforced

**Certificate Pinning**:
```dart
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';

void configureCertificatePinning(Dio dio) {
  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
    client.badCertificateCallback = (cert, host, port) {
      // Pin your server's certificate
      return cert.sha1.toString() == 'YOUR_CERT_SHA1_HASH';
    };
    return client;
  };
}
```

### 2.3 Local Data Security
- [ ] Cart data encrypted if contains PII
- [ ] Search history clearable by user
- [ ] No sensitive data in logs
- [ ] App data cleared on uninstall
- [ ] Clipboard cleared after paste (passwords)

---

## 3. Network Security

### 3.1 API Communication
- [ ] Base URL from environment variable
- [ ] No API keys in client code
- [ ] Request timeout configured (15s)
- [ ] Retry logic with exponential backoff
- [ ] Rate limiting handled gracefully
- [ ] CORS properly configured on backend

**Secure API Client**:
```dart
class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl, // From environment
      connectTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'X-App-Version': AppConfig.appVersion,
      },
    ));

    // ❌ NEVER hardcode API keys
    // dio.options.headers['X-API-Key'] = 'sk_live_xxxxx';
  }
}
```

### 3.2 Input Validation
- [ ] All user input sanitized
- [ ] Email format validated
- [ ] Phone number format validated
- [ ] XSS prevention (HTML encoding)
- [ ] SQL injection prevention (backend)
- [ ] File upload validation (type, size)

**Input Sanitization**:
```dart
String sanitizeInput(String input) {
  return input
      .trim()
      .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
      .replaceAll(RegExp(r'[^\w\s@.-]'), ''); // Remove special chars
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email required';
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) return 'Invalid email';
  return null;
}
```

### 3.3 Error Handling
- [ ] No stack traces exposed to users
- [ ] Generic error messages for auth failures
- [ ] Detailed errors only in dev mode
- [ ] Errors logged to crash reporting (Firebase)
- [ ] No sensitive data in error messages

```dart
// ✅ Good: Generic user-facing message
if (error is UnauthorizedException) {
  showError('Invalid credentials. Please try again.');
}

// ❌ Bad: Exposes implementation details
if (error is UnauthorizedException) {
  showError('JWT token expired at ${error.timestamp}'); // DON'T DO THIS
}
```

---

## 4. Payment Security

### 4.1 Stripe Integration
- [ ] `flutter_stripe` SDK up to date
- [ ] Payment verification on backend (via Stripe webhook or PaymentIntent status)
- [ ] No payment details stored locally
- [ ] PaymentIntent client secret never logged
- [ ] Failed payments logged
- [ ] Refund flow secured via backend

**Secure Payment Flow**:
```dart
Future<void> initiatePayment(String orderId, double amount) async {
  // 1. Create PaymentIntent on backend
  final intent = await paymentApi.createPaymentIntent(orderId, amount);

  // 2. Initialize Stripe PaymentSheet
  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: intent.clientSecret,
      merchantDisplayName: 'GreenBasket',
      style: ThemeMode.system,
    ),
  );

  // 3. Present PaymentSheet (Stripe handles card entry securely)
  await Stripe.instance.presentPaymentSheet();

  // 4. Verify on backend (CRITICAL — confirm PaymentIntent status)
  final verified = await paymentApi.verifyPayment(
    paymentIntentId: intent.paymentIntentId,
    orderId: orderId,
  );

  if (verified) {
    navigateToOrderSuccess();
  } else {
    showError('Payment verification failed');
  }
}
```

### 4.2 Wallet Security
- [ ] Wallet balance encrypted
- [ ] Transaction history immutable
- [ ] Wallet top-up verified on backend
- [ ] Withdrawal limits enforced
- [ ] Suspicious activity flagged

---

## 5. Privacy & Compliance

### 5.1 User Data Collection
- [ ] Privacy policy linked in app
- [ ] Terms of service accepted on signup
- [ ] Data collection consent obtained
- [ ] Analytics opt-out available
- [ ] Push notification permission requested
- [ ] Location permission justified
- [ ] Camera permission justified

**Permission Requests**:
```dart
Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.request();
  
  if (status.isDenied) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Camera Permission'),
        content: Text('We need camera access to scan QR codes and upload product images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  return status.isGranted;
}
```

### 5.2 Data Deletion
- [ ] Account deletion available
- [ ] Data export available (GDPR)
- [ ] Local data cleared on account deletion
- [ ] Backend data deletion confirmed
- [ ] Deletion confirmation required

### 5.3 Third-Party Services
- [ ] Firebase privacy policy disclosed
- [ ] Stripe privacy policy disclosed
- [ ] Google Sign-In privacy disclosed
- [ ] Analytics tracking disclosed
- [ ] Crash reporting disclosed

---

## 6. Code Security

### 6.1 Obfuscation & Minification
- [ ] Code obfuscation enabled (release)
- [ ] ProGuard rules configured (Android)
- [ ] Debug symbols stripped (iOS)
- [ ] Source maps not uploaded to stores
- [ ] Reverse engineering difficult

**Build Commands**:
```bash
# Android with obfuscation
flutter build apk --release --obfuscate --split-debug-info=build/symbols

# iOS with obfuscation
flutter build ios --release --obfuscate --split-debug-info=build/symbols
```

### 6.2 Dependency Security
- [ ] All dependencies up to date
- [ ] No known vulnerabilities (run `flutter pub outdated`)
- [ ] Unused dependencies removed
- [ ] Dependencies from trusted sources only
- [ ] License compliance checked

**Audit Dependencies**:
```bash
# Check for outdated packages
flutter pub outdated

# Check for security vulnerabilities (use third-party tool)
# https://github.com/dart-lang/pub/issues/2156
```

### 6.3 Code Quality
- [ ] No hardcoded secrets
- [ ] No debug code in production
- [ ] No commented-out sensitive code
- [ ] Linter rules enforced
- [ ] Code review required for PRs

**Linter Rules** (`analysis_options.yaml`):
```yaml
linter:
  rules:
    - avoid_print
    - avoid_web_libraries_in_flutter
    - no_logic_in_create_state
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - use_key_in_widget_constructors
```

---

## 7. Deep Link Security

### 7.1 Deep Link Validation
- [ ] Deep link URLs validated
- [ ] No sensitive data in deep links
- [ ] Deep link authentication required
- [ ] Malicious links rejected
- [ ] Deep link logging for audit

**Secure Deep Link Handling**:
```dart
void handleDeepLink(Uri uri) {
  // Validate domain
  if (uri.host != 'greenbasket.com') {
    print('Invalid deep link domain: ${uri.host}');
    return;
  }

  // Validate path
  final allowedPaths = ['/product/', '/order/', '/offers'];
  if (!allowedPaths.any((path) => uri.path.startsWith(path))) {
    print('Invalid deep link path: ${uri.path}');
    return;
  }

  // Require authentication for sensitive routes
  if (uri.path.startsWith('/order/') && !isAuthenticated) {
    navigateToLogin(redirectTo: uri.toString());
    return;
  }

  // Navigate
  context.go(uri.path);
}
```

---

## 8. Push Notification Security

### 8.1 FCM Security
- [ ] FCM tokens refreshed periodically
- [ ] Tokens sent to backend securely
- [ ] Notification payload validated
- [ ] No sensitive data in notifications
- [ ] Notification actions authenticated

**Secure FCM Implementation**:
```dart
class FCMService {
  Future<void> initialize() async {
    // Get token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _sendTokenToBackend(token);
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(_sendTokenToBackend);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      // Validate message source
      if (message.data['source'] != 'greenbasket-backend') {
        print('Invalid notification source');
        return;
      }

      // Show notification
      _showNotification(message);
    });
  }

  Future<void> _sendTokenToBackend(String token) async {
    await userApi.registerFCMToken(
      token: token,
      deviceType: Platform.isIOS ? 'ios' : 'android',
    );
  }
}
```

---

## 9. Logging & Monitoring

### 9.1 Secure Logging
- [ ] No passwords logged
- [ ] No tokens logged
- [ ] No PII logged
- [ ] Logs sanitized in production
- [ ] Crash reports anonymized

**Secure Logger**:
```dart
class SecureLogger {
  static void log(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      print(message);
      if (data != null) print(data);
    } else {
      // In production, send to Firebase Analytics (sanitized)
      final sanitized = _sanitizeData(data);
      FirebaseAnalytics.instance.logEvent(
        name: 'app_log',
        parameters: sanitized,
      );
    }
  }

  static Map<String, dynamic> _sanitizeData(Map<String, dynamic>? data) {
    if (data == null) return {};
    
    final sanitized = Map<String, dynamic>.from(data);
    
    // Remove sensitive keys
    sanitized.remove('password');
    sanitized.remove('token');
    sanitized.remove('accessToken');
    sanitized.remove('refreshToken');
    sanitized.remove('cvv');
    sanitized.remove('cardNumber');
    
    return sanitized;
  }
}
```

### 9.2 Crash Reporting
- [ ] Firebase Crashlytics enabled
- [ ] User IDs anonymized
- [ ] Stack traces sanitized
- [ ] Crash alerts configured
- [ ] Critical crashes escalated

---

## 10. Security Testing

### 10.1 Penetration Testing
- [ ] OWASP Mobile Top 10 tested
- [ ] Man-in-the-middle attack tested
- [ ] SSL pinning bypass tested
- [ ] Root/jailbreak detection tested
- [ ] Reverse engineering attempted

### 10.2 Automated Security Scans
- [ ] Static code analysis (SonarQube)
- [ ] Dependency vulnerability scan
- [ ] APK/IPA security scan
- [ ] API security scan (backend)

**Run Security Scan**:
```bash
# Analyze code
flutter analyze

# Check for common issues
dart analyze --fatal-infos

# Use third-party security scanner
# https://github.com/MobSF/Mobile-Security-Framework-MobSF
```

---

## 11. Incident Response

### 11.1 Security Incident Plan
- [ ] Incident response team identified
- [ ] Escalation process documented
- [ ] User notification plan ready
- [ ] Breach disclosure timeline defined
- [ ] Post-incident review process

### 11.2 Emergency Actions
- [ ] Force logout all users (if needed)
- [ ] Invalidate all tokens (if needed)
- [ ] Disable features remotely (Firebase Remote Config)
- [ ] Push emergency update
- [ ] Communicate with users

---

## 12. Compliance Checklist

### 12.1 GDPR (EU)
- [ ] Privacy policy available
- [ ] Data collection consent
- [ ] Right to access data
- [ ] Right to delete data
- [ ] Right to export data
- [ ] Data breach notification (72h)

### 12.2 CCPA (California)
- [ ] Privacy notice at collection
- [ ] Opt-out of data sale
- [ ] Data deletion on request
- [ ] Non-discrimination for opt-out

### 12.3 India (IT Act, DPDP)
- [ ] Data localization (if required)
- [ ] Consent for data processing
- [ ] Data security measures
- [ ] Grievance officer appointed

---

## Security Audit Sign-Off

| Area | Status | Auditor | Date |
|---|---|---|---|
| Authentication | ⚠️ Needs Review | | |
| Data Protection | ⚠️ Needs Review | | |
| Network Security | ⚠️ Needs Review | | |
| Payment Security | ⚠️ Needs Review | | |
| Privacy & Compliance | ⚠️ Needs Review | | |
| Code Security | ⚠️ Needs Review | | |
| Deep Link Security | ⚠️ Needs Review | | |
| Push Notifications | ⚠️ Needs Review | | |
| Logging & Monitoring | ⚠️ Needs Review | | |
| Security Testing | ❌ Not Started | | |
| Incident Response | ❌ Not Started | | |
| Compliance | ⚠️ Needs Review | | |

**Overall Security Rating**: ⚠️ **Needs Improvement**

---

## Quick Security Wins

1. **Enable certificate pinning** → Prevent MITM attacks
2. **Use `flutter_secure_storage`** → Encrypt tokens
3. **Enable obfuscation** → Prevent reverse engineering
4. **Validate all inputs** → Prevent injection attacks
5. **Use HTTPS only** → Encrypt data in transit
6. **Implement rate limiting** → Prevent brute force
7. **Add biometric auth** → Extra security layer
8. **Clear clipboard after paste** → Prevent data leaks
9. **Sanitize error messages** → Don't expose internals
10. **Keep dependencies updated** → Patch vulnerabilities

---

## Resources

- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [Stripe Security](https://stripe.com/docs/security)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [GDPR Compliance](https://gdpr.eu/)

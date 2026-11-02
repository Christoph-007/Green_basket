import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/data/providers/api_provider.dart';
import 'package:greenbasket_app/data/services/storage_service.dart';

class NotificationService extends GetxService {
  late FirebaseMessaging _fcm;
  final _api = ApiProvider();
  final _storage = Get.find<StorageService>();
  bool _initialized = false;

  static NotificationService get to => Get.find();

  Future<void> init() async {
    try {
      // 0. Initialize FCM instance (only after Firebase.initializeApp check)
      _fcm = FirebaseMessaging.instance;
      _initialized = true;

      // 1. Request Permission (iOS/Android 13+)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[NotificationService] User granted permission');
      } else {
        debugPrint('[NotificationService] User declined or has not accepted permission');
      }

      // 2. Setup Listeners
      _setupListeners();

      // 3. Register Token if logged in
      if (_storage.isLoggedIn) {
        await syncToken();
      }
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }
  }

  void _setupListeners() {
    // Handling messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[NotificationService] Foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? 'Notification',
          message.notification!.body ?? '',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
        );
      }
    });

    // Handling messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[NotificationService] Message opened app: ${message.data}');
      // TODO: Navigate based on message.data['actionUrl']
    });
  }

  Future<void> syncToken() async {
    if (!_initialized) return;
    try {
      // On iOS, wait for APNS token before requesting FCM token
      if (GetPlatform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          // Retry up to 5 times with 2-second delays
          for (int i = 0; i < 5; i++) {
            await Future.delayed(const Duration(seconds: 2));
            apnsToken = await _fcm.getAPNSToken();
            if (apnsToken != null) break;
          }
          if (apnsToken == null) {
            debugPrint('[NotificationService] APNS token unavailable after retries');
            return;
          }
        }
      }

      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('[NotificationService] FCM Token: $token');
        
        // Only sync if token changed or not synced yet
        if (_storage.fcmToken != token) {
          final response = await _api.post('/notifications/fcm-token', data: {
            'token': token,
            'deviceType': GetPlatform.isIOS ? 'ios' : (GetPlatform.isAndroid ? 'android' : 'web'),
          });

          if (response.statusCode == 200) {
            _storage.saveFcmToken(token);
            debugPrint('[NotificationService] Token synced successfully');
          }
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Sync error: $e');
    }
  }

  Future<void> removeToken() async {
    if (!_initialized) return;
    try {
      String? token = _storage.fcmToken;
      if (token != null) {
        await _api.delete('/notifications/fcm-token', data: {'token': token});
        _storage.saveFcmToken('');
      }
    } catch (e) {
      debugPrint('[NotificationService] Remove error: $e');
    }
  }
}

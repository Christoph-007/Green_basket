import 'package:firebase_core/firebase_core.dart';
import 'package:greenbasket_app/data/services/theme_controller.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:greenbasket_app/data/services/notification_service.dart';
import 'package:greenbasket_app/data/services/storage_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage first
  await GetStorage.init();
  Get.put(StorageService());
  // Reads the saved appearance and sets the palette before the first screen is built.
  Get.put(ThemeController());

  // Global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Always register NotificationService so GetX can find it even if Firebase fails
  final notifService = Get.put(NotificationService());

  try {
    debugPrint('[Firebase] Initializing...');
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS: explicit options (plist auto-detection is unreliable in firebase_core 3.x).
      // This appId is the iOS app; other platforms must not use it.
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyA4DEKwUbfFmAQaDa1zuznwzjHtLWZmQlI',
          appId: '1:572406014195:ios:0cd465b8a0d009d080d786',
          messagingSenderId: '572406014195',
          projectId: 'greenbasket-2e72e',
          storageBucket: 'greenbasket-2e72e.firebasestorage.app',
          iosBundleId: 'com.greenbasket.greenbasketApp',
        ),
      );
    } else {
      // Android: configuration comes from android/app/google-services.json (see README).
      // Without that file this throws and is caught below, so the app still runs, just without push.
      await Firebase.initializeApp();
    }
    debugPrint('[Firebase] Initialized successfully');
    
    // Initialize Notification Service (requires Firebase)
    await notifService.init();
  } catch (e) {
    debugPrint('[Firebase] Initialization Error: $e');
    debugPrint('[Firebase] Push notifications are off. Android needs android/app/google-services.json, iOS needs GoogleService-Info.plist (see flutter_app/README.md).');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const App());
}

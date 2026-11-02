import 'package:firebase_core/firebase_core.dart';
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

  // Global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Always register NotificationService so GetX can find it even if Firebase fails
  final notifService = Get.put(NotificationService());

  try {
    // Initialize Firebase with explicit options (plist auto-detection unreliable in firebase_core 3.x)
    debugPrint('[Firebase] Initializing...');
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
    debugPrint('[Firebase] Initialized successfully');
    
    // Initialize Notification Service (requires Firebase)
    await notifService.init();
  } catch (e) {
    debugPrint('[Firebase] Initialization Error: $e');
    debugPrint('[Firebase] TIP: Ensure google-services.json (Android) or GoogleService-Info.plist (iOS) is present.');
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

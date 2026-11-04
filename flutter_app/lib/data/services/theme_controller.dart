import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/services/storage_service.dart';

/// Remembers whether the app should look light, dark, or follow the phone,
/// and switches the colour palette (and rebuilds the app) when that changes.
class ThemeController extends GetxController with WidgetsBindingObserver {
  static ThemeController get to => Get.find<ThemeController>();

  final mode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    mode.value = _fromName(StorageService().themeMode);
    // The palette must be right before the first screen is built.
    AppColors.usePalette(_wantsDark() ? AppPalette.dark : AppPalette.light);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// The phone switched between light and dark while we follow it.
  @override
  void didChangePlatformBrightness() {
    if (mode.value == ThemeMode.system) _apply();
  }

  void setMode(ThemeMode value) {
    if (mode.value == value) return;
    mode.value = value;
    StorageService().setThemeMode(value.name);
    _apply();
  }

  bool _wantsDark() {
    switch (mode.value) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  void _apply() {
    AppColors.usePalette(_wantsDark() ? AppPalette.dark : AppPalette.light);
    Get.changeThemeMode(mode.value);
    // Colours are read when a widget builds, so rebuild everything.
    Get.forceAppUpdate();
  }

  static ThemeMode _fromName(String name) => ThemeMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => ThemeMode.light,
      );
}

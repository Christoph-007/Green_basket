import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';

/// One place for in-app messages. Each method shows a GetX snackbar with the
/// same position and timing GetX uses by default, so only the colours are
/// decided here. Fill colours are chosen so the text meets contrast rules.
class GBSnack {
  GBSnack._();

  static void success(String title, String message,
          {SnackPosition? position, Duration? duration}) =>
      _show(title, message, AppColors.successFill, Colors.white, position, duration);

  static void error(String title, String message,
          {SnackPosition? position, Duration? duration}) =>
      _show(title, message, AppColors.errorFill, Colors.white, position, duration);

  static void info(String title, String message,
          {SnackPosition? position, Duration? duration}) =>
      _show(title, message, AppColors.infoFill, Colors.white, position, duration);

  /// Dark text on amber: white on amber fails contrast.
  static void warning(String title, String message,
          {SnackPosition? position, Duration? duration}) =>
      _show(title, message, AppColors.warning, AppColors.textPrimary, position, duration);

  /// Default GetX look (neutral), for messages that are neither good nor bad.
  static void plain(String title, String message,
          {SnackPosition? position, Duration? duration}) =>
      Get.snackbar(
        title,
        message,
        snackPosition: position,
        duration: duration,
      );

  static void _show(String title, String message, Color background,
      Color foreground, SnackPosition? position, Duration? duration) {
    Get.snackbar(
      title,
      message,
      backgroundColor: background,
      colorText: foreground,
      snackPosition: position,
      duration: duration,
    );
  }
}

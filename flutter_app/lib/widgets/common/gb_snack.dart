import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/copy.dart';
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

  static String? _lastErrorText;
  static DateTime? _lastErrorAt;

  /// Shows what went wrong in plain words ([friendlyError]). The same text is
  /// not repeated within four seconds, so several failing calls do not stack
  /// up identical messages.
  static void fromError(Object error, {String title = 'Something went wrong'}) {
    final text = friendlyError(error);
    final now = DateTime.now();
    if (_lastErrorText == text &&
        _lastErrorAt != null &&
        now.difference(_lastErrorAt!) < const Duration(seconds: 4)) {
      return;
    }
    _lastErrorText = text;
    _lastErrorAt = now;
    GBSnack.error(title, text, position: SnackPosition.BOTTOM);
  }

  /// A message with one action button, for example Undo. The button closes the
  /// message and then runs [onAction].
  static void withAction(
    String title,
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
    SnackPosition? position,
    Duration duration = const Duration(seconds: 5),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      duration: duration,
      mainButton: TextButton(
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        onPressed: () {
          Get.closeCurrentSnackbar();
          onAction();
        },
        child: Text(
          actionLabel,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

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

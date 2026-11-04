import 'package:dio/dio.dart';

/// Plain, short wording for things going wrong. Always say what happened and
/// what the person can do about it; never show codes or raw server text for
/// server-side failures.
class AppCopy {
  AppCopy._();

  static const offline = 'No internet connection. Check it and try again.';
  static const slow = 'This is taking too long. Please try again.';
  static const signIn = 'Please sign in again.';
  static const server = 'Something went wrong on our side. Please try again.';
  static const generic = 'Something went wrong. Please try again.';
}

/// Turns any error into a message a customer can act on.
///
/// For client errors (400 to 499) the server's own message is used when there
/// is one, because it explains the problem ("Coupon is not valid").
String friendlyError(Object error, {String fallback = AppCopy.generic}) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
        return AppCopy.offline;
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppCopy.slow;
      default:
        break;
    }
    final status = error.response?.statusCode;
    if (status == 401) return AppCopy.signIn;
    if (status != null && status >= 500) return AppCopy.server;
    final data = error.response?.data;
    if (status != null && data is Map && data['message'] is String) {
      final message = (data['message'] as String).trim();
      if (message.isNotEmpty) return message;
    }
  }
  return fallback;
}

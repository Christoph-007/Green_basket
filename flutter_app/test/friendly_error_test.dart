import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenbasket_app/config/copy.dart';

DioException _error({
  DioExceptionType type = DioExceptionType.badResponse,
  int? status,
  Object? data,
}) {
  final request = RequestOptions(path: '/x');
  return DioException(
    requestOptions: request,
    type: type,
    response: status == null
        ? null
        : Response(requestOptions: request, statusCode: status, data: data),
  );
}

void main() {
  group('friendlyError', () {
    test('no connection', () {
      expect(friendlyError(_error(type: DioExceptionType.connectionError)),
          AppCopy.offline);
    });

    test('timeouts', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(friendlyError(_error(type: type)), AppCopy.slow);
      }
    });

    test('401 asks to sign in again', () {
      expect(friendlyError(_error(status: 401)), AppCopy.signIn);
    });

    test('5xx never shows server text', () {
      expect(
        friendlyError(_error(status: 500, data: {'message': 'MongoError: x'})),
        AppCopy.server,
      );
    });

    test('4xx shows the server message', () {
      expect(
        friendlyError(_error(status: 400, data: {'message': 'Coupon not valid'})),
        'Coupon not valid',
      );
    });

    test('4xx without a message and other errors use the fallback', () {
      expect(friendlyError(_error(status: 404)), AppCopy.generic);
      expect(friendlyError(Exception('boom')), AppCopy.generic);
      expect(friendlyError(Exception('boom'), fallback: 'Custom'), 'Custom');
    });
  });
}

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import '../../config/constants.dart';
import '../../utils/single_flight.dart';
import '../services/network_status.dart';

class ApiProvider {
  late final Dio _dio;
  final _storage = GetStorage();
  // Requests that hit 401 together share a single token refresh.
  final _refreshGate = SingleFlight<bool?>();

  static final ApiProvider _instance = ApiProvider._internal();
  factory ApiProvider() => _instance;

  ApiProvider._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.read(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        NetworkStatus.isOffline.value = false;
        handler.next(response);
      },
      onError: (error, handler) async {
        // No answer at all means the server cannot be reached; any answer
        // (even an error page) means it can.
        if (error.response != null) {
          NetworkStatus.isOffline.value = false;
        } else if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          NetworkStatus.isOffline.value = true;
        }
        final request = error.requestOptions;
        final isAuthCall = request.path.contains('/auth/');
        if (error.response?.statusCode != 401 || isAuthCall) {
          return handler.next(error);
        }

        // A request we already retried with a fresh token and that is still
        // refused means the session really is over.
        if (request.extra['retried'] == true) {
          _logout();
          return handler.next(error);
        }

        // Another request may have renewed the token while this one was in flight.
        final sentWith = request.headers['Authorization'];
        final currentToken = _storage.read(AppConstants.tokenKey);
        final alreadyRenewed =
            currentToken != null && sentWith != 'Bearer $currentToken';

        final refreshed = alreadyRenewed ? true : await _refreshToken();

        if (refreshed == true) {
          request.headers['Authorization'] =
              'Bearer ${_storage.read(AppConstants.tokenKey)}';
          request.extra['retried'] = true;
          try {
            final response = await _dio.fetch(request);
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          }
        }

        // false: the server refused the refresh token -> sign out.
        // null: the server could not be reached -> keep the session, fail this request only.
        if (refreshed == false) _logout();
        handler.next(error);
      },
    ));
  }

  /// Refresh the JWT using the stored refresh token. Concurrent callers share one call.
  /// Returns true when renewed, false when the server refused the refresh token
  /// (the session is over) and null when the server could not be reached.
  Future<bool?> _refreshToken() => _refreshGate.run(_requestNewToken);

  Future<bool?> _requestNewToken() async {
    final refreshToken = _storage.read(AppConstants.refreshTokenKey);
    if (refreshToken == null) return false;
    try {
      final response = await Dio(BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeout),
      )).post('/auth/refresh-token', data: {'refreshToken': refreshToken});

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newToken = response.data['data']?['token'] ??
            response.data['token'];
        final newRefresh = response.data['data']?['refreshToken'] ??
            response.data['refreshToken'];
        if (newToken != null) {
          _storage.write(AppConstants.tokenKey, newToken);
        }
        if (newRefresh != null) {
          _storage.write(AppConstants.refreshTokenKey, newRefresh);
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // The server answered and refused the refresh token.
      if (status == 400 || status == 401 || status == 403) return false;
      // No answer (offline, timeout, server error): do not sign the user out.
      return null;
    } catch (_) {
      return null;
    }
  }

  void _logout() {
    _storage.erase();
    // Several requests can fail together; only navigate once.
    if (Get.currentRoute != '/login') Get.offAllNamed('/login');
  }

  // ── HTTP Methods ─────────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    return _dio.get(path, queryParameters: params);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return _dio.delete(path, data: data);
  }

  Future<Response> uploadFile(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
  }) async {
    final Map<String, dynamic> data = {
      fieldName: await MultipartFile.fromFile(filePath),
    };
    if (extraFields != null) {
      data.addAll(extraFields);
    }
    final formData = FormData.fromMap(data);
    return _dio.post(path, data: formData);
  }

  /// Multipart upload from in-memory bytes (e.g. a file picked on Android,
  /// where pickers may return content:// URIs without a file path).
  Future<Response> uploadBytes(
    String path, {
    required List<int> bytes,
    required String filename,
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
  }) async {
    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(bytes, filename: filename),
      ...?extraFields,
    });
    return _dio.post(path, data: formData);
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? count;
  final int? total;
  final int? page;
  final int? pages;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.count,
    this.total,
    this.page,
    this.pages,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: fromData != null && json['data'] != null
          ? fromData(json['data'])
          : null,
      count: json['count'],
      total: json['total'],
      page: json['page'],
      pages: json['pages'],
    );
  }
}

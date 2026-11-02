import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import '../../config/constants.dart';

class ApiProvider {
  late final Dio _dio;
  final _storage = GetStorage();
  bool _isRefreshing = false;

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
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/')) {
          // Attempt token refresh
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request with new token
            final opts = error.requestOptions;
            opts.headers['Authorization'] =
                'Bearer ${_storage.read(AppConstants.tokenKey)}';
            try {
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          } else {
            _logout();
          }
        }
        handler.next(error);
      },
    ));
  }

  /// Refresh JWT using stored refresh token
  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final refreshToken = _storage.read(AppConstants.refreshTokenKey);
      if (refreshToken == null) return false;

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
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _logout() {
    _storage.erase();
    Get.offAllNamed('/login');
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

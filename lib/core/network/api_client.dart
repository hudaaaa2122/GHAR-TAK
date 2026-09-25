import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import '../../constants/api_endpoints.dart';
import 'api_response.dart';

final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(storage: ref.watch(tokenStorageProvider));
});

class ApiClient {
  ApiClient({required TokenStorage storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_refreshing) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final req = error.requestOptions;
              final token = await _storage.accessToken;
              req.headers['Authorization'] = 'Bearer $token';
              try {
                final clone = await _dio.fetch(req);
                return handler.resolve(clone);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  final TokenStorage _storage;
  bool _refreshing = false;

  Dio get dio => _dio;

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    _refreshing = true;
    try {
      final res = await Dio(
        BaseOptions(baseUrl: AppConfig.apiBaseUrl),
      ).post(ApiEndpoints.refresh, queryParameters: {'refresh_token': refresh});
      final body = res.data;
      if (body is! Map) return false;
      final data = body['data'] is Map ? body['data'] as Map : body;
      final access = data['access_token']?.toString();
      final newRefresh = data['refresh_token']?.toString() ?? refresh;
      if (access == null) return false;
      await _storage.saveTokens(accessToken: access, refreshToken: newRefresh);
      return true;
    } on DioException catch (e) {
      // Only drop the session on definitive auth rejection — not network blips.
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        await _storage.clear();
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic raw)? mapData,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return _parse(res.data, mapData: mapData);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    T Function(dynamic raw)? mapData,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) async {
    try {
      final res = await _dio.post(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          receiveTimeout: receiveTimeout,
          sendTimeout: sendTimeout,
        ),
      );
      return _parse(res.data, mapData: mapData);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ApiResponse<T>> postMultipart<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? query,
    T Function(dynamic raw)? mapData,
  }) async {
    try {
      final res = await _dio.post(
        path,
        data: formData,
        queryParameters: query,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
        ),
      );
      return _parse(res.data, mapData: mapData);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    T Function(dynamic raw)? mapData,
  }) async {
    try {
      final res = await _dio.put(path, data: body, queryParameters: query);
      return _parse(res.data, mapData: mapData);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    T Function(dynamic raw)? mapData,
  }) async {
    try {
      final res = await _dio.delete(path, data: body, queryParameters: query);
      return _parse(res.data, mapData: mapData);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    T Function(dynamic raw)? mapData,
  }) async {
    try {
      final res = await _dio.patch(path, data: body, queryParameters: query);
      return _parse(res.data, mapData: mapData);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiResponse<T> _parse<T>(
    dynamic data, {
    T Function(dynamic raw)? mapData,
  }) {
    if (data is Map<String, dynamic>) {
      return ApiResponse.fromJson(data, mapData: mapData);
    }
    if (data is Map) {
      return ApiResponse.fromJson(
        Map<String, dynamic>.from(data),
        mapData: mapData,
      );
    }
    return ApiResponse(
      success: true,
      data: mapData != null ? mapData(data) : data as T?,
    );
  }

  ApiException _mapError(DioException e) {
    final data = e.response?.data;
    String message = e.message ?? 'Network error';
    if (data is Map) {
      final detail = data['detail'];
      final parts = <String>[];

      if (detail is String && detail.isNotEmpty) {
        parts.add(detail);
      } else if (detail is List) {
        for (final item in detail) {
          if (item is Map) {
            final msg = item['msg']?.toString() ?? item['message']?.toString();
            final loc = item['loc'];
            final field = loc is List && loc.isNotEmpty
                ? loc.last.toString()
                : null;
            if (msg != null && msg.isNotEmpty) {
              parts.add(field != null && field != 'body' ? '$field: $msg' : msg);
            }
          } else {
            parts.add(item.toString());
          }
        }
      }

      final nested = data['data'];
      if (nested is Map) {
        final errors = nested['errors'] ?? nested['error'] ?? nested['message'];
        if (errors is Map) {
          errors.forEach((k, v) {
            if (v is List) {
              parts.add('$k: ${v.join(', ')}');
            } else if (v != null) {
              parts.add('$k: $v');
            }
          });
        } else if (errors is List) {
          for (final e in errors) {
            parts.add(e.toString());
          }
        } else if (errors != null) {
          parts.add(errors.toString());
        }
      }

      if (data['message'] != null &&
          data['message'].toString().isNotEmpty &&
          !parts.contains(data['message'].toString())) {
        parts.add(data['message'].toString());
      }

      if (parts.isNotEmpty) {
        // Prefer specific messages over bare "Validation error".
        final specific = parts
            .where((p) => p.trim().toLowerCase() != 'validation error')
            .toList();
        message = (specific.isNotEmpty ? specific : parts).join('\n');
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      message =
          'Order is taking longer than usual. Checking if it went through…';
      return ApiException(message, statusCode: e.response?.statusCode, isTimeout: true);
    } else if (e.type == DioExceptionType.connectionError) {
      message =
          'Cannot reach server at ${AppConfig.apiBaseUrl}. Is the API running?';
    }
    return ApiException(message, statusCode: e.response?.statusCode);
  }
}
import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

/// A failed API call. [code] carries the server's machine-readable reason
/// (e.g. `NO_SCANS`, `CHAT_LIMIT`) so screens can react without parsing text.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}

class ApiService {
  final Dio _dio;
  final StorageService _storageService;
  void Function()? onUnauthorized;

  ApiService(this._storageService) : _dio = Dio() {
    _dio.options.baseUrl = ApiEndpoints.baseUrl;
    _dio.options.connectTimeout = const Duration(milliseconds: AppConfig.apiTimeoutMs);
    _dio.options.receiveTimeout = const Duration(milliseconds: AppConfig.apiTimeoutMs);
    _dio.options.sendTimeout = const Duration(milliseconds: AppConfig.apiTimeoutMs);

    // Add interceptor to append JWT token dynamically
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Generic request runner with single-retry on timeout. Requests that are not
  // safe to repeat (an AI scan spends a credit) pass retryOnTimeout: false.
  Future<Response> _runRequest(
    Future<Response> Function() requestFn, {
    bool retryOnTimeout = true,
  }) async {
    try {
      return await requestFn();
    } on DioException catch (e) {
      if (retryOnTimeout &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout)) {
        // Retry exactly once on timeout
        try {
          return await requestFn();
        } on DioException catch (retryError) {
          throw _parseDioError(retryError);
        } catch (e) {
          throw 'Connection failed after retry.';
        }
      }
      throw _parseDioError(e);
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  // Parse errors into user-friendly messages
  ApiException _parseDioError(DioException error) {
    final response = error.response;
    final data = response?.data;
    final code = data is Map && data['code'] is String ? data['code'] as String : null;
    return ApiException(
      _messageFor(error),
      statusCode: response?.statusCode,
      code: code,
    );
  }

  String _messageFor(DioException error) {
    print('DEBUG: ApiService._parseDioError() - Type: ${error.type}, Error: ${error.error}, Message: ${error.message}');
    // The status code and body are what actually name the failure.
    print('DEBUG: ${error.requestOptions.method} ${error.requestOptions.uri}');
    print('DEBUG: Status: ${error.response?.statusCode} ${error.response?.statusMessage}');
    print('DEBUG: Body: ${error.response?.data}');
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your network and try again.';
    }

    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return 'No internet connection. Please check your Wi-Fi or cellular network. Details: ${error.error}';
    }


    final response = error.response;
    if (response != null) {
      final code = response.statusCode;
      if (code == 401) {
        return 'Session expired. Please log in again.';
      }
      if (code == 403) {
        return 'You do not have permission to perform this action.';
      }
      // Expected outcomes (no scans left, chat limit, bad input) carry a
      // human-readable message from the server; prefer it.
      if (code != null &&
          code < 500 &&
          response.data is Map &&
          response.data['message'] != null) {
        return response.data['message'].toString();
      }
      if (code == 404) {
        return 'Requested resource not found.';
      }
      if (code != null && code >= 500) {
        return 'Server error ($code). Our team is looking into it.';
      }
    }

    return 'Failed to connect to the server. Please try again.';
  }

  // Public wrapper methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _runRequest(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Duration? timeout,
    bool retryOnTimeout = true,
  }) {
    final options = timeout == null
        ? null
        : Options(sendTimeout: timeout, receiveTimeout: timeout);
    return _runRequest(
      () => _dio.post(path, data: data, options: options),
      retryOnTimeout: retryOnTimeout,
    );
  }

  Future<Response> put(String path, {dynamic data}) {
    return _runRequest(() => _dio.put(path, data: data));
  }

  Future<Response> delete(String path, {dynamic data}) {
    return _runRequest(() => _dio.delete(path, data: data));
  }
}

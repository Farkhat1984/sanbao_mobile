/// Dio HTTP client setup with interceptors.
///
/// Provides a singleton-style [DioClient] configured with auth,
/// retry, logging, and correlation-id interceptors.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/config/env.dart';
import 'package:sanbao_flutter/core/network/api_exceptions.dart';
import 'package:sanbao_flutter/core/network/api_interceptor.dart';
import 'package:sanbao_flutter/core/storage/secure_storage.dart';

/// Wrapper around [Dio] with preconfigured interceptors and error mapping.
class DioClient {
  DioClient({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.addAll([
      CorrelationIdInterceptor(),
      AuthInterceptor(secureStorage: _secureStorage, dio: _dio),
      RetryInterceptor(dio: _dio),
      LoggingInterceptor(),
    ]);
  }

  final SecureStorageService _secureStorage;
  late final Dio _dio;

  /// The raw Dio instance, for cases requiring direct access (e.g., streaming).
  Dio get dio => _dio;

  /// Executes a GET request and returns the parsed response data.
  Future<T> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Executes a POST request and returns the parsed response data.
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Executes a PUT request and returns the parsed response data.
  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Executes a DELETE request and returns the parsed response data.
  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Executes a PATCH request and returns the parsed response data.
  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Sends a POST request with streaming response.
  ///
  /// Returns a [Response] with [ResponseType.stream] to allow
  /// line-by-line NDJSON parsing.
  Future<Response<ResponseBody>> postStream(
    String path, {
    Object? data,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<ResponseBody>(
        path,
        data: data,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: AppConfig.streamTimeout,
        ),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Handles response status codes and returns typed data.
  T _handleResponse<T>(Response<T> response) {
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      return response.data as T;
    }

    // Extract error message from response body
    final errorBody = response.data;
    String message = 'Unknown error';
    int? limit;

    if (errorBody is Map<String, Object?>) {
      message = (errorBody['error'] as String?) ?? message;
      limit = errorBody['limit'] as int?;
    }

    throw switch (statusCode) {
      400 => ValidationException(message: message),
      401 => UnauthorizedException(
          message: message,
          requestPath: response.requestOptions.path,
        ),
      403 => ForbiddenException(
          message: message,
          requestPath: response.requestOptions.path,
        ),
      404 => NotFoundException(
          message: message,
          requestPath: response.requestOptions.path,
        ),
      429 => RateLimitException(
          message: message,
          limit: limit,
          requestPath: response.requestOptions.path,
        ),
      _ => ServerException(
          message: message,
          statusCode: statusCode,
          requestPath: response.requestOptions.path,
        ),
    };
  }

  /// Maps [DioException] to typed [ApiException].
  ApiException _mapDioException(DioException e) {
    if (e.error is ApiException) {
      return e.error! as ApiException;
    }

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        TimeoutException(requestPath: e.requestOptions.path),
      DioExceptionType.connectionError =>
        NetworkException(requestPath: e.requestOptions.path),
      DioExceptionType.badResponse => _mapBadResponse(e),
      DioExceptionType.cancel =>
        const NetworkException(message: 'Request cancelled'),
      _ => ServerException(
          message: e.message ?? 'Unknown error',
          requestPath: e.requestOptions.path,
        ),
    };
  }

  ApiException _mapBadResponse(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    final data = e.response?.data;
    String message = 'Server error';

    if (data is Map<String, Object?>) {
      message = (data['error'] as String?) ?? message;
    } else if (data is String) {
      message = data;
    }

    return switch (statusCode) {
      401 => UnauthorizedException(
          message: message,
          requestPath: e.requestOptions.path,
        ),
      403 => ForbiddenException(
          message: message,
          requestPath: e.requestOptions.path,
        ),
      404 => NotFoundException(
          message: message,
          requestPath: e.requestOptions.path,
        ),
      429 => RateLimitException(
          message: message,
          requestPath: e.requestOptions.path,
        ),
      _ => ServerException(
          message: message,
          statusCode: statusCode,
          requestPath: e.requestOptions.path,
        ),
    };
  }
}

/// Riverpod provider for the [DioClient].
final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient(secureStorage: secureStorage);
});

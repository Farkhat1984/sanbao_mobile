/// Dio interceptors for auth, retry, logging, and correlation ID.
///
/// Attaches JWT tokens, handles 401 refresh, adds correlation IDs,
/// and provides structured logging for all requests.
library;

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/config/env.dart';
import 'package:sanbao_flutter/core/network/api_exceptions.dart';
import 'package:sanbao_flutter/core/storage/secure_storage.dart';

/// Interceptor that attaches the JWT access token to every request
/// and handles 401 responses by attempting a token refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorageService secureStorage,
    required Dio dio,
  })  : _secureStorage = secureStorage,
        _dio = dio;

  final SecureStorageService _secureStorage;
  final Dio _dio;

  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
      _pendingRequests = [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Avoid infinite refresh loops
    if (err.requestOptions.extra['isRetry'] == true) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      // Queue this request to retry after refresh completes
      _pendingRequests.add((options: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const TokenRefreshException();
      }

      // Backend expects {token} and returns {token, user, expiresAt}
      final response = await _dio.post<Map<String, Object?>>(
        '${AppConfig.authEndpoint}/refresh',
        data: {'token': refreshToken},
        options: Options(extra: {'isRetry': true}),
      );

      // Backend returns single Bearer token as "token"
      final newAccessToken = response.data?['token'] as String?;
      final newRefreshToken = response.data?['token'] as String?;

      if (newAccessToken == null) {
        throw const TokenRefreshException();
      }

      await _secureStorage.saveAccessToken(newAccessToken);
      if (newRefreshToken != null) {
        await _secureStorage.saveRefreshToken(newRefreshToken);
      }

      // Retry the original request
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      err.requestOptions.extra['isRetry'] = true;
      final retryResponse = await _dio.fetch<Object?>(err.requestOptions);
      handler.resolve(retryResponse);

      // Retry all queued requests
      for (final pending in _pendingRequests) {
        pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
        pending.options.extra['isRetry'] = true;
        try {
          final retryResp = await _dio.fetch<Object?>(pending.options);
          pending.handler.resolve(retryResp);
        } on DioException catch (e) {
          pending.handler.reject(e);
        }
      }
    } on ApiException {
      // Token refresh failed, reject all pending
      await _secureStorage.clearTokens();
      handler.next(err);
      for (final pending in _pendingRequests) {
        pending.handler.next(err);
      }
    } on DioException {
      await _secureStorage.clearTokens();
      handler.next(err);
      for (final pending in _pendingRequests) {
        pending.handler.next(err);
      }
    } finally {
      _isRefreshing = false;
      _pendingRequests.clear();
    }
  }
}

/// Interceptor that adds a unique correlation ID to every request.
class CorrelationIdInterceptor extends Interceptor {
  static final _random = Random();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.headers.containsKey(AppConfig.correlationHeader)) {
      options.headers[AppConfig.correlationHeader] = _generateCorrelationId();
    }
    handler.next(options);
  }

  static String _generateCorrelationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final randomPart = List.generate(
      8,
      (_) => _random.nextInt(36).toRadixString(36),
    ).join();
    return 'mob-$timestamp-$randomPart';
  }
}

/// Interceptor that retries failed requests with exponential backoff.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = AppConfig.maxRetryAttempts,
    this.retryDelay = AppConfig.retryDelay,
  }) : _dio = dio;

  final Dio _dio;
  final int maxRetries;
  final Duration retryDelay;

  /// HTTP methods considered safe to retry.
  static const _retryableMethods = {'GET', 'HEAD', 'OPTIONS'};

  /// Status codes worth retrying.
  static const _retryableStatusCodes = {408, 429, 500, 502, 503, 504};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;

    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    final isRetryable = _isRetryableError(err);
    if (!isRetryable) {
      handler.next(err);
      return;
    }

    final delay = retryDelay * pow(2, retryCount);
    await Future<void>.delayed(delay);

    err.requestOptions.extra['retryCount'] = retryCount + 1;

    try {
      final response = await _dio.fetch<Object?>(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _isRetryableError(DioException err) {
    // Only retry safe methods or explicit retryable status codes
    final method = err.requestOptions.method.toUpperCase();
    final statusCode = err.response?.statusCode;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return _retryableMethods.contains(method);
    }

    if (statusCode != null && _retryableStatusCodes.contains(statusCode)) {
      // Always retry 429 (rate limit) and 503 (service unavailable)
      if (statusCode == 429 || statusCode == 503) return true;
      // Only retry server errors for safe methods
      return _retryableMethods.contains(method);
    }

    if (err.type == DioExceptionType.connectionError) {
      return true;
    }

    return false;
  }
}

/// Interceptor that logs request and response details in debug mode.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (Env.enableDebugLogging || kDebugMode) {
      final correlationId = options.headers[AppConfig.correlationHeader];
      debugPrint(
        '[API] --> ${options.method} ${options.uri} '
        '[correlationId=$correlationId]',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    if (Env.enableDebugLogging || kDebugMode) {
      debugPrint(
        '[API] <-- ${response.statusCode} ${response.requestOptions.uri} '
        '(${response.data.runtimeType})',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (Env.enableDebugLogging || kDebugMode) {
      debugPrint(
        '[API] <!! ${err.response?.statusCode ?? "N/A"} '
        '${err.requestOptions.uri} - ${err.message}',
      );
    }
    handler.next(err);
  }
}

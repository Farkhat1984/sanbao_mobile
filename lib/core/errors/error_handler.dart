/// Global error handler with Sentry integration.
///
/// Captures uncaught exceptions, Flutter framework errors,
/// and zone errors, forwarding them to Sentry when configured.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/config/env.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/core/network/api_exceptions.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Centralized error handler for the application.
abstract final class ErrorHandler {
  /// Initializes error handling infrastructure.
  ///
  /// Must be called before [runApp]. Sets up Flutter error handlers,
  /// and optionally initializes Sentry.
  static Future<void> initialize({
    required FutureOr<void> Function() appRunner,
  }) async {
    // Catch Flutter framework errors
    FlutterError.onError = _handleFlutterError;

    // Catch errors in the platform dispatcher
    PlatformDispatcher.instance.onError = (error, stack) {
      _reportError(error, stack, fatal: true);
      return true;
    };

    if (Env.isSentryEnabled) {
      await SentryFlutter.init(
        (options) {
          options
            ..dsn = Env.sentryDsn
            ..environment = Env.environment
            ..tracesSampleRate = Env.isProduction ? 0.2 : 1.0
            ..attachStacktrace = true
            ..sendDefaultPii = false
            ..enableAutoSessionTracking = true
            ..enableAutoPerformanceTracing = true
            ..maxBreadcrumbs = 100;
        },
        appRunner: appRunner,
      );
    } else {
      // Run without Sentry
      unawaited(
        runZonedGuarded(
          () async {
            await appRunner();
          },
          _reportError,
        ),
      );
    }
  }

  /// Reports an error to Sentry (if enabled) and logs it.
  static Future<void> _reportError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    // Never report expected failures to Sentry
    if (error is Failure) {
      debugPrint('[ErrorHandler] Failure: ${error.message}');
      return;
    }

    // Never report expected API exceptions to Sentry
    if (error is ApiException) {
      debugPrint('[ErrorHandler] ApiException: ${error.message}');
      return;
    }

    debugPrint('[ErrorHandler] ${fatal ? "FATAL" : "Error"}: $error');
    debugPrint('[ErrorHandler] StackTrace: $stackTrace');

    if (Env.isSentryEnabled) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap({'fatal': fatal}),
      );
    }
  }

  /// Handles Flutter framework errors.
  static void _handleFlutterError(FlutterErrorDetails details) {
    debugPrint('[ErrorHandler] Flutter error: ${details.exception}');
    debugPrint('[ErrorHandler] Library: ${details.library}');

    if (Env.isSentryEnabled) {
      Sentry.captureException(
        details.exception,
        stackTrace: details.stack,
      );
    }

    // In debug mode, also print to console
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  }

  /// Captures a non-fatal error with optional context.
  ///
  /// Call this for caught exceptions that should still be tracked.
  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    Map<String, String>? tags,
    Map<String, Object?>? extra,
  }) async {
    debugPrint('[ErrorHandler] Captured: $error');

    if (Env.isSentryEnabled) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (tags != null) {
            tags.forEach(scope.setTag);
          }
          if (extra != null) {
            // ignore: deprecated_member_use
            extra.forEach(scope.setExtra);
          }
        },
      );
    }
  }

  /// Captures a message-only event (no exception).
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
  }) async {
    debugPrint('[ErrorHandler] Message [$level]: $message');

    if (Env.isSentryEnabled) {
      await Sentry.captureMessage(message, level: level);
    }
  }

  /// Adds a breadcrumb for debugging trails.
  static void addBreadcrumb({
    required String message,
    String? category,
    Map<String, String>? data,
  }) {
    if (Env.isSentryEnabled) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Sets the current user for error context.
  static Future<void> setUser({
    required String id,
    String? email,
    String? name,
  }) async {
    if (Env.isSentryEnabled) {
      await Sentry.configureScope((scope) {
        scope.setUser(SentryUser(
          id: id,
          email: email,
          name: name,
        ),);
      });
    }
  }

  /// Clears the current user (on logout).
  static Future<void> clearUser() async {
    if (Env.isSentryEnabled) {
      await Sentry.configureScope((scope) {
        scope.setUser(null);
      });
    }
  }

  /// Converts any exception to a [Failure] for domain-level handling.
  static Failure toFailure(Object error) {
    if (error is Failure) return error;

    if (error is ApiException) {
      return switch (error) {
        UnauthorizedException() ||
        TokenRefreshException() =>
          const AuthFailure(),
        ForbiddenException() => const PermissionFailure(),
        NotFoundException() => const NotFoundFailure(),
        ValidationException(:final message) =>
          ValidationFailure(message: message),
        RateLimitException(:final message, :final retryAfterSeconds) =>
          RateLimitFailure(
            message: message,
            retryAfterSeconds: retryAfterSeconds,
          ),
        NetworkException() => const NetworkFailure(),
        TimeoutException() => const TimeoutFailure(),
        ServerException(:final message, :final statusCode) => ServerFailure(
            message: message,
            statusCode: statusCode,
          ),
        StreamException(:final message) => ServerFailure(message: message),
        ParseException(:final message) => ServerFailure(message: message),
      };
    }

    return UnknownFailure(message: error.toString());
  }
}

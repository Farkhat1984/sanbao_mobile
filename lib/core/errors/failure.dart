/// Sealed failure class for domain-level error handling.
///
/// Failures represent expected error conditions that the UI
/// should handle gracefully (as opposed to exceptions, which
/// indicate programming errors).
library;

/// Base sealed class for domain failures.
///
/// Use pattern matching to handle all failure types exhaustively:
/// ```dart
/// switch (failure) {
///   case ServerFailure(:final message):
///     showError(message);
///   case NetworkFailure():
///     showOfflineIndicator();
///   // ...
/// }
/// ```
sealed class Failure {
  const Failure({
    required this.message,
    this.code,
  });

  /// Human-readable error message suitable for display.
  final String message;

  /// Optional error code for programmatic handling.
  final String? code;

  @override
  String toString() => '$runtimeType: $message (code=$code)';
}

/// Server returned an error response.
final class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    this.statusCode,
    super.code,
  });

  /// HTTP status code from the server.
  final int? statusCode;
}

/// Network connectivity failure.
final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Нет подключения к интернету',
    super.code = 'NETWORK_ERROR',
  });
}

/// Request timed out.
final class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Превышено время ожидания',
    super.code = 'TIMEOUT',
  });
}

/// Authentication failure (token expired, invalid credentials).
final class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Требуется авторизация',
    super.code = 'AUTH_ERROR',
  });
}

/// Permission/authorization failure.
final class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'Недостаточно прав',
    super.code = 'PERMISSION_ERROR',
  });
}

/// Rate limit exceeded.
final class RateLimitFailure extends Failure {
  const RateLimitFailure({
    super.message = 'Слишком много запросов',
    this.retryAfterSeconds,
    super.code = 'RATE_LIMIT',
  });

  /// Seconds until retry is allowed.
  final int? retryAfterSeconds;
}

/// Input validation failure.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.fieldErrors = const {},
    super.code = 'VALIDATION_ERROR',
  });

  /// Per-field error messages.
  final Map<String, String> fieldErrors;
}

/// Cache/local storage failure.
final class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Ошибка локального хранилища',
    super.code = 'CACHE_ERROR',
  });
}

/// Resource not found.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Ресурс не найден',
    super.code = 'NOT_FOUND',
  });
}

/// Unknown/unexpected failure.
final class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Произошла неизвестная ошибка',
    super.code = 'UNKNOWN',
  });
}

/// Converts a [Failure] to a user-friendly message in Russian.
String failureToMessage(Failure failure) => failure.message;

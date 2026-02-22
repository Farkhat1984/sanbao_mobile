/// Typed exception hierarchy for API errors.
///
/// Uses sealed classes for exhaustive pattern matching in error handlers.
library;

/// Base sealed class for all API-related exceptions.
sealed class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.requestPath,
  });

  /// Human-readable error message.
  final String message;

  /// HTTP status code, if applicable.
  final int? statusCode;

  /// The API path that caused the error.
  final String? requestPath;

  @override
  String toString() =>
      'ApiException: $message [status=$statusCode, path=$requestPath]';
}

/// 401 - User is not authenticated.
final class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Authentication required',
    super.requestPath,
  }) : super(statusCode: 401);
}

/// 403 - User does not have permission.
final class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'Access denied',
    super.requestPath,
  }) : super(statusCode: 403);
}

/// 404 - Resource not found.
final class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.requestPath,
  }) : super(statusCode: 404);
}

/// 400 - Bad request or validation error.
final class ValidationException extends ApiException {
  const ValidationException({
    required super.message,
    this.errors = const {},
    super.requestPath,
  }) : super(statusCode: 400);

  /// Field-level validation errors.
  final Map<String, List<String>> errors;
}

/// 429 - Rate limit exceeded.
final class RateLimitException extends ApiException {
  const RateLimitException({
    super.message = 'Too many requests. Please wait.',
    this.retryAfterSeconds,
    this.limit,
    super.requestPath,
  }) : super(statusCode: 429);

  /// Seconds until the rate limit resets.
  final int? retryAfterSeconds;

  /// The limit that was exceeded.
  final int? limit;
}

/// 500+ - Server-side error.
final class ServerException extends ApiException {
  const ServerException({
    super.message = 'Internal server error',
    super.statusCode = 500,
    super.requestPath,
  });
}

/// Network connectivity error (no internet, DNS failure, etc.).
final class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Network error. Check your connection.',
    super.requestPath,
  }) : super(statusCode: null);
}

/// Request timed out.
final class TimeoutException extends ApiException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.requestPath,
  }) : super(statusCode: null);
}

/// Stream connection was interrupted.
final class StreamException extends ApiException {
  const StreamException({
    super.message = 'Stream connection lost',
    super.requestPath,
  }) : super(statusCode: null);
}

/// Token refresh failed — user must re-authenticate.
final class TokenRefreshException extends ApiException {
  const TokenRefreshException({
    super.message = 'Session expired. Please log in again.',
    super.requestPath,
  }) : super(statusCode: 401);
}

/// Parse error — response could not be decoded.
final class ParseException extends ApiException {
  const ParseException({
    super.message = 'Failed to parse server response',
    this.rawResponse,
    super.requestPath,
  }) : super(statusCode: null);

  /// The raw response body, for debugging.
  final String? rawResponse;
}

/// Utility to extract a user-friendly message from any [ApiException].
String apiExceptionToUserMessage(ApiException exception) => switch (exception) {
      UnauthorizedException() => 'Сессия истекла. Войдите снова.',
      ForbiddenException() => 'Доступ запрещён.',
      NotFoundException() => 'Ресурс не найден.',
      ValidationException(:final message) => message,
      RateLimitException(:final message) => message,
      ServerException() => 'Ошибка сервера. Попробуйте позже.',
      NetworkException() => 'Нет подключения к интернету.',
      TimeoutException() => 'Превышено время ожидания.',
      StreamException() => 'Соединение прервано.',
      TokenRefreshException() => 'Сессия истекла. Войдите снова.',
      ParseException() => 'Ошибка обработки ответа.',
    };

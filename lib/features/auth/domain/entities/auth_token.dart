/// Authentication token pair entity.
///
/// Holds the JWT access token, refresh token, and expiry metadata
/// returned from login/register API calls.
library;

/// Immutable representation of an authentication token pair.
///
/// The [accessToken] is used in the Authorization header for API calls.
/// The [refreshToken] is used to obtain a new access token when expired.
class AuthToken {
  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// JWT access token for authenticating API requests.
  final String accessToken;

  /// Refresh token for obtaining a new access token.
  final String refreshToken;

  /// Expiration time of the access token.
  final DateTime expiresAt;

  /// Whether the access token has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the token will expire within the given [duration].
  ///
  /// Useful for proactive refresh before actual expiry.
  bool expiresWithin(Duration duration) =>
      DateTime.now().add(duration).isAfter(expiresAt);

  /// Creates a copy with the given fields replaced.
  AuthToken copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) =>
      AuthToken(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  @override
  String toString() =>
      'AuthToken(expiresAt=$expiresAt, isExpired=$isExpired)';
}

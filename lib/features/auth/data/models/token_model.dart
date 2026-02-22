/// Authentication token data model with JSON serialization.
///
/// Maps between the API token response and the domain [AuthToken] entity.
library;

import 'package:sanbao_flutter/features/auth/domain/entities/auth_token.dart';

/// Data transfer object for authentication token API responses.
///
/// Handles parsing of token payloads from login, register,
/// and refresh endpoints.
class TokenModel {
  const TokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  /// Creates a [TokenModel] from a domain [AuthToken] entity.
  factory TokenModel.fromEntity(AuthToken token) => TokenModel(
        accessToken: token.accessToken,
        refreshToken: token.refreshToken,
        expiresAt: token.expiresAt,
      );

  /// Parses a [TokenModel] from a JSON map.
  ///
  /// Supports both `expiresAt` (ISO string) and `expiresIn` (seconds)
  /// response formats.
  factory TokenModel.fromJson(Map<String, Object?> json) {
    final DateTime expiresAt;

    if (json['expiresAt'] is String) {
      expiresAt = DateTime.parse(json['expiresAt']! as String);
    } else if (json['expiresIn'] is int) {
      expiresAt = DateTime.now().add(
        Duration(seconds: json['expiresIn']! as int),
      );
    } else {
      // Default to 1 hour if no expiry info provided
      expiresAt = DateTime.now().add(const Duration(hours: 1));
    }

    return TokenModel(
      accessToken: json['accessToken']! as String,
      refreshToken: json['refreshToken']! as String,
      expiresAt: expiresAt,
    );
  }

  /// JWT access token.
  final String accessToken;

  /// Refresh token.
  final String refreshToken;

  /// Access token expiration time.
  final DateTime expiresAt;

  /// Converts this model to a JSON map.
  Map<String, Object?> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
      };

  /// Converts this data model to a domain [AuthToken] entity.
  AuthToken toEntity() => AuthToken(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
      );
}

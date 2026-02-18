/// Local data source for authentication token persistence.
///
/// Wraps [SecureStorageService] to provide auth-specific storage
/// operations for tokens and cached user data.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/storage/secure_storage.dart';
import 'package:sanbao_flutter/features/auth/data/models/token_model.dart';
import 'package:sanbao_flutter/features/auth/data/models/user_model.dart';

/// Keys for auth-specific secure storage entries.
abstract final class _AuthStorageKeys {
  static const String tokenExpiresAt = 'sanbao_token_expires_at';
  static const String cachedUser = 'sanbao_cached_user';
}

/// Local data source for persisting auth tokens and cached user data.
///
/// Uses [SecureStorageService] for encrypted storage of sensitive data.
class AuthLocalDataSource {
  const AuthLocalDataSource({required SecureStorageService secureStorage})
      : _secureStorage = secureStorage;

  final SecureStorageService _secureStorage;

  // ---- Token Persistence ----

  /// Stores the full token pair securely.
  Future<void> saveTokens(TokenModel tokens) async {
    await Future.wait([
      _secureStorage.saveAccessToken(tokens.accessToken),
      _secureStorage.saveRefreshToken(tokens.refreshToken),
      _secureStorage.write(
        key: _AuthStorageKeys.tokenExpiresAt,
        value: tokens.expiresAt.toIso8601String(),
      ),
    ]);
  }

  /// Retrieves the stored token pair, if available.
  ///
  /// Returns `null` if either access or refresh token is missing.
  Future<TokenModel?> getTokens() async {
    final results = await Future.wait([
      _secureStorage.getAccessToken(),
      _secureStorage.getRefreshToken(),
      _secureStorage.read(_AuthStorageKeys.tokenExpiresAt),
    ]);

    final accessToken = results[0];
    final refreshToken = results[1];
    final expiresAtStr = results[2];

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }

    DateTime expiresAt;
    if (expiresAtStr != null) {
      expiresAt =
          DateTime.tryParse(expiresAtStr) ??
          DateTime.now().add(const Duration(hours: 1));
    } else {
      expiresAt = DateTime.now().add(const Duration(hours: 1));
    }

    return TokenModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  /// Clears all stored tokens.
  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.clearTokens(),
      _secureStorage.deleteKey(_AuthStorageKeys.tokenExpiresAt),
    ]);
  }

  /// Whether tokens exist in storage (quick check).
  Future<bool> hasTokens() async {
    final accessToken = await _secureStorage.getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // ---- Cached User ----

  /// Caches the user profile for offline access and quick startup.
  Future<void> cacheUser(UserModel user) async {
    final json = jsonEncode(user.toJson());
    await Future.wait([
      _secureStorage.write(key: _AuthStorageKeys.cachedUser, value: json),
      _secureStorage.saveUserId(user.id),
      _secureStorage.saveUserEmail(user.email),
    ]);
  }

  /// Retrieves the cached user profile.
  ///
  /// Returns `null` if no user is cached.
  Future<UserModel?> getCachedUser() async {
    final json = await _secureStorage.read(_AuthStorageKeys.cachedUser);
    if (json == null || json.isEmpty) return null;

    try {
      final map = jsonDecode(json) as Map<String, Object?>;
      return UserModel.fromJson(map);
    } on FormatException {
      // Corrupted cache, clear it
      await _secureStorage.deleteKey(_AuthStorageKeys.cachedUser);
      return null;
    }
  }

  /// Clears all cached auth data (tokens + user).
  Future<void> clearAll() async {
    await Future.wait([
      clearTokens(),
      _secureStorage.deleteKey(_AuthStorageKeys.cachedUser),
      // Note: we don't clear userId/userEmail for analytics context
    ]);
  }
}

/// Riverpod provider for [AuthLocalDataSource].
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSource(
    secureStorage: ref.watch(secureStorageProvider),
  ),
);

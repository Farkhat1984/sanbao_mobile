/// Secure storage wrapper for sensitive data (tokens, credentials).
///
/// Uses [FlutterSecureStorage] with platform-appropriate encryption.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys used for secure storage entries.
abstract final class SecureStorageKeys {
  static const String accessToken = 'sanbao_access_token';
  static const String refreshToken = 'sanbao_refresh_token';
  static const String userId = 'sanbao_user_id';
  static const String userEmail = 'sanbao_user_email';
  static const String biometricEnabled = 'sanbao_biometric_enabled';
  static const String pinCode = 'sanbao_pin_code';
}

/// Service providing typed access to the device secure storage.
class SecureStorageService {
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  final FlutterSecureStorage _storage;

  // ---- Access Token ----

  /// Retrieves the stored access token.
  Future<String?> getAccessToken() =>
      _storage.read(key: SecureStorageKeys.accessToken);

  /// Stores the access token securely.
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: SecureStorageKeys.accessToken, value: token);

  // ---- Refresh Token ----

  /// Retrieves the stored refresh token.
  Future<String?> getRefreshToken() =>
      _storage.read(key: SecureStorageKeys.refreshToken);

  /// Stores the refresh token securely.
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: SecureStorageKeys.refreshToken, value: token);

  // ---- Clear Tokens ----

  /// Removes both access and refresh tokens (logout).
  Future<void> clearTokens() async {
    await _storage.delete(key: SecureStorageKeys.accessToken);
    await _storage.delete(key: SecureStorageKeys.refreshToken);
  }

  // ---- User Info ----

  /// Retrieves the stored user ID.
  Future<String?> getUserId() =>
      _storage.read(key: SecureStorageKeys.userId);

  /// Stores the user ID.
  Future<void> saveUserId(String id) =>
      _storage.write(key: SecureStorageKeys.userId, value: id);

  /// Retrieves the stored user email.
  Future<String?> getUserEmail() =>
      _storage.read(key: SecureStorageKeys.userEmail);

  /// Stores the user email.
  Future<void> saveUserEmail(String email) =>
      _storage.write(key: SecureStorageKeys.userEmail, value: email);

  // ---- Biometric ----

  /// Whether biometric authentication is enabled.
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: SecureStorageKeys.biometricEnabled);
    return value == 'true';
  }

  /// Sets the biometric authentication preference.
  Future<void> setBiometricEnabled({required bool enabled}) =>
      _storage.write(
        key: SecureStorageKeys.biometricEnabled,
        value: enabled.toString(),
      );

  // ---- PIN ----

  /// Retrieves the stored PIN code.
  Future<String?> getPinCode() =>
      _storage.read(key: SecureStorageKeys.pinCode);

  /// Stores the PIN code.
  Future<void> savePinCode(String pin) =>
      _storage.write(key: SecureStorageKeys.pinCode, value: pin);

  /// Removes the stored PIN code.
  Future<void> clearPinCode() =>
      _storage.delete(key: SecureStorageKeys.pinCode);

  // ---- Generic ----

  /// Reads a value by arbitrary key.
  Future<String?> read(String key) => _storage.read(key: key);

  /// Writes a value by arbitrary key.
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  /// Deletes a value by arbitrary key.
  Future<void> deleteKey(String key) => _storage.delete(key: key);

  /// Wipes all stored data (full logout / reset).
  Future<void> clearAll() => _storage.deleteAll();

  /// Checks if a key exists in secure storage.
  Future<bool> containsKey(String key) => _storage.containsKey(key: key);
}

/// Riverpod provider for [SecureStorageService].
final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

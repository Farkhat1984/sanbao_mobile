/// Two-factor authentication setup use case.
///
/// Handles 2FA setup, enable, disable, and verification operations.
library;

import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/core/errors/error_handler.dart';
import 'package:sanbao_flutter/features/auth/domain/repositories/auth_repository.dart';

/// Manages 2FA setup and verification.
class Setup2faUseCase {
  const Setup2faUseCase({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;

  /// Retrieves the 2FA setup data (secret + QR code).
  ///
  /// If 2FA is already enabled, returns a result with [enabled] = true.
  Future<TwoFactorSetupResult> getSetupData() async {
    try {
      return await _repository.setup2fa();
    } on Failure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }

  /// Enables 2FA by verifying a TOTP code.
  ///
  /// [code] is the 6-digit code from the authenticator app.
  Future<void> enable({required String code}) async {
    try {
      await _repository.enable2fa(code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }

  /// Disables 2FA by verifying a TOTP code.
  ///
  /// [code] is the 6-digit code from the authenticator app.
  Future<void> disable({required String code}) async {
    try {
      await _repository.disable2fa(code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }

  /// Verifies a TOTP code during the login flow.
  ///
  /// Returns `true` if the code is valid.
  Future<bool> verify({required String code}) async {
    try {
      return await _repository.verify2fa(code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }
}

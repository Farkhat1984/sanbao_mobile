/// Login use case.
///
/// Orchestrates email/password authentication through the repository.
library;

import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/core/errors/error_handler.dart';
import 'package:sanbao_flutter/features/auth/domain/entities/user.dart';
import 'package:sanbao_flutter/features/auth/domain/repositories/auth_repository.dart';

/// Authenticates a user with email and password.
///
/// Returns the authenticated [User] on success, or throws a [Failure].
/// When 2FA is required, throws [AuthFailure] with code `2FA_REQUIRED`.
class LoginUseCase {
  const LoginUseCase({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;

  /// Executes the login operation.
  ///
  /// [params] contains the email, password, and optional TOTP code.
  Future<User> call(LoginParams params) async {
    try {
      return await _repository.login(params);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }
}

/// Logout use case.
///
/// Clears local tokens and notifies the server of session termination.
library;

import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/core/errors/error_handler.dart';
import 'package:sanbao_flutter/features/auth/domain/repositories/auth_repository.dart';

/// Logs out the current user by clearing stored tokens.
///
/// Always clears local state, even if the server call fails.
class LogoutUseCase {
  const LogoutUseCase({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;

  /// Executes the logout operation.
  Future<void> call() async {
    try {
      await _repository.logout();
    } on Failure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }
}

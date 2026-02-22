/// Register use case.
///
/// Orchestrates new user registration through the repository.
library;

import 'package:sanbao_flutter/core/errors/error_handler.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/features/auth/domain/repositories/auth_repository.dart';

/// Registers a new user account with name, email, and password.
///
/// Does NOT automatically log in -- the user must authenticate
/// separately after registration.
class RegisterUseCase {
  const RegisterUseCase({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;

  /// Executes the registration operation.
  ///
  /// [params] contains the name, email, and password.
  /// Throws [ValidationFailure] if the email is taken or inputs are invalid.
  Future<void> call(RegisterParams params) async {
    try {
      await _repository.register(params);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }
}

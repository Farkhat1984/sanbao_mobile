/// Implementation of the profile repository.
///
/// Delegates to the remote data source and maps API exceptions
/// to domain failures.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/core/network/api_exceptions.dart';
import 'package:sanbao_flutter/features/auth/domain/entities/user.dart';
import 'package:sanbao_flutter/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:sanbao_flutter/features/profile/domain/repositories/profile_repository.dart';

/// Concrete implementation of [ProfileRepository].
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<User> getProfile() async {
    try {
      return await _remoteDataSource.getProfile();
    } on ApiException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? locale,
  }) async {
    try {
      return await _remoteDataSource.updateProfile(
        name: name,
        locale: locale,
      );
    } on ApiException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<User> updateAvatar({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      return await _remoteDataSource.updateAvatar(
        imageBytes: imageBytes,
        fileName: fileName,
      );
    } on ApiException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _remoteDataSource.deleteAccount();
    } on ApiException catch (e) {
      throw _mapException(e);
    }
  }

  /// Maps API exceptions to domain failures.
  Failure _mapException(ApiException exception) => switch (exception) {
        UnauthorizedException() =>
          const AuthFailure(message: 'Сессия истекла. Войдите снова.'),
        ForbiddenException() =>
          const PermissionFailure(message: 'Доступ запрещён.'),
        NotFoundException() =>
          const NotFoundFailure(message: 'Профиль не найден.'),
        NetworkException() => const NetworkFailure(),
        TimeoutException() => const TimeoutFailure(),
        ValidationException(:final message) =>
          ValidationFailure(message: message),
        _ => ServerFailure(
            message: exception.message,
            statusCode: exception.statusCode,
          ),
      };
}

/// Riverpod provider for [ProfileRepository].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDataSource = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(remoteDataSource: remoteDataSource);
});

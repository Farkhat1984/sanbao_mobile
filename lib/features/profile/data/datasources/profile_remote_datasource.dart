/// Remote data source for profile operations.
///
/// Handles GET/PUT/POST/DELETE calls to /api/profile endpoints.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/auth/domain/entities/user.dart';

/// Remote data source for profile operations via the REST API.
class ProfileRemoteDataSource {
  ProfileRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  static String get _basePath => AppConfig.profileEndpoint;

  /// Fetches the current user's profile.
  ///
  /// GET /api/profile
  Future<User> getProfile() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      _basePath,
    );

    final userJson = response['user'] as Map<String, Object?>? ??
        (response.containsKey('id') ? response : {});

    return _parseUser(userJson);
  }

  /// Updates the user's profile fields.
  ///
  /// PUT /api/profile
  Future<User> updateProfile({
    String? name,
    String? locale,
  }) async {
    final response = await _dioClient.put<Map<String, Object?>>(
      _basePath,
      data: {
        if (name != null) 'name': name,
        if (locale != null) 'locale': locale,
      },
    );

    final userJson = response['user'] as Map<String, Object?>? ??
        (response.containsKey('id') ? response : {});

    return _parseUser(userJson);
  }

  /// Uploads a new avatar image.
  ///
  /// POST /api/profile/avatar (multipart form data)
  Future<User> updateAvatar({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(
        imageBytes,
        filename: fileName,
      ),
    });

    final response = await _dioClient.post<Map<String, Object?>>(
      '$_basePath/avatar',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    final userJson = response['user'] as Map<String, Object?>? ??
        (response.containsKey('id') ? response : {});

    return _parseUser(userJson);
  }

  /// Permanently deletes the user's account.
  ///
  /// DELETE /api/profile
  Future<void> deleteAccount() async {
    await _dioClient.delete<Map<String, Object?>>(
      _basePath,
    );
  }

  /// Parses a user JSON map into a [User] entity.
  User _parseUser(Map<String, Object?> json) => User(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String?,
        image: json['image'] as String?,
        role: UserRole.fromString(json['role'] as String? ?? 'user'),
        locale: json['locale'] as String? ?? 'ru',
        emailVerified: json['emailVerified'] as bool? ?? false,
        twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
        subscriptionTier: SubscriptionTier.fromString(
          json['subscriptionTier'] as String? ?? 'free',
        ),
        isBanned: json['isBanned'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}

/// Riverpod provider for [ProfileRemoteDataSource].
final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ProfileRemoteDataSource(dioClient: dioClient);
});

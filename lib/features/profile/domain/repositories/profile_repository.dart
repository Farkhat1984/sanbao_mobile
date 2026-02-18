/// Abstract profile repository.
///
/// Defines the contract for user profile operations including
/// retrieval, updates, avatar management, and account deletion.
library;

import 'dart:typed_data';

import 'package:sanbao_flutter/features/auth/domain/entities/user.dart';

/// Contract for profile data access.
abstract class ProfileRepository {
  /// Fetches the current user's profile.
  Future<User> getProfile();

  /// Updates the user's profile fields.
  Future<User> updateProfile({
    String? name,
    String? locale,
  });

  /// Uploads a new avatar image.
  ///
  /// [imageBytes] is the raw image data, [fileName] is the original file name.
  /// Returns the updated user with the new avatar URL.
  Future<User> updateAvatar({
    required Uint8List imageBytes,
    required String fileName,
  });

  /// Permanently deletes the user's account.
  ///
  /// This is irreversible and requires explicit confirmation in the UI.
  Future<void> deleteAccount();
}

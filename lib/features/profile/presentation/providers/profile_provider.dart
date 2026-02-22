/// Riverpod providers for profile state management.
///
/// Provides reactive access to the user profile and update operations.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/features/auth/domain/entities/user.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:sanbao_flutter/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:sanbao_flutter/features/profile/domain/repositories/profile_repository.dart';

// ---- Profile State ----

/// Sealed state for profile operations.
sealed class ProfileState {
  const ProfileState();
}

final class ProfileIdle extends ProfileState {
  const ProfileIdle();
}

final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

final class ProfileSuccess extends ProfileState {
  const ProfileSuccess({required this.user});
  final User user;
}

final class ProfileError extends ProfileState {
  const ProfileError({required this.message});
  final String message;
}

/// Notifier managing profile operations.
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier({
    required ProfileRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const ProfileIdle());

  final ProfileRepository _repository;
  final Ref _ref;

  /// Loads the user profile from the server.
  Future<void> loadProfile() async {
    state = const ProfileLoading();
    try {
      final user = await _repository.getProfile();
      state = ProfileSuccess(user: user);
    } on Failure catch (f) {
      state = ProfileError(message: f.message);
    } catch (e) {
      debugPrint('[ProfileNotifier] Error loading profile: $e');
      state = const ProfileError(message: 'Не удалось загрузить профиль');
    }
  }

  /// Updates the user's name and/or locale.
  Future<bool> updateProfile({
    String? name,
    String? locale,
  }) async {
    state = const ProfileLoading();
    try {
      final updatedUser = await _repository.updateProfile(
        name: name,
        locale: locale,
      );
      state = ProfileSuccess(user: updatedUser);
      // Refresh the auth state with updated user data
      await _ref.read(authStateProvider.notifier).refreshUser();
      return true;
    } on Failure catch (f) {
      state = ProfileError(message: f.message);
      return false;
    } catch (e) {
      debugPrint('[ProfileNotifier] Error updating profile: $e');
      state = const ProfileError(message: 'Не удалось обновить профиль');
      return false;
    }
  }

  /// Uploads a new avatar image.
  Future<bool> updateAvatar({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    state = const ProfileLoading();
    try {
      final updatedUser = await _repository.updateAvatar(
        imageBytes: imageBytes,
        fileName: fileName,
      );
      state = ProfileSuccess(user: updatedUser);
      await _ref.read(authStateProvider.notifier).refreshUser();
      return true;
    } on Failure catch (f) {
      state = ProfileError(message: f.message);
      return false;
    } catch (e) {
      debugPrint('[ProfileNotifier] Error updating avatar: $e');
      state = const ProfileError(message: 'Не удалось обновить аватар');
      return false;
    }
  }

  /// Deletes the user's account.
  Future<bool> deleteAccount() async {
    state = const ProfileLoading();
    try {
      await _repository.deleteAccount();
      return true;
    } on Failure catch (f) {
      state = ProfileError(message: f.message);
      return false;
    } catch (e) {
      debugPrint('[ProfileNotifier] Error deleting account: $e');
      state = const ProfileError(message: 'Не удалось удалить аккаунт');
      return false;
    }
  }
}

/// Provider for profile state and operations.
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository: repository, ref: ref);
});

/// Whether a profile operation is in progress.
final isProfileLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(profileProvider);
  return state is ProfileLoading;
});

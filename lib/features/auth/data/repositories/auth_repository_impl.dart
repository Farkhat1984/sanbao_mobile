/// Concrete implementation of [AuthRepository].
///
/// Coordinates between [AuthRemoteDataSource] for API calls and
/// [AuthLocalDataSource] for token/user persistence.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/errors/error_handler.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/core/network/api_exceptions.dart';
import 'package:sanbao_flutter/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:sanbao_flutter/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:sanbao_flutter/features/auth/data/models/user_model.dart';
import 'package:sanbao_flutter/features/auth/domain/entities/auth_token.dart';
import 'package:sanbao_flutter/features/auth/domain/entities/user.dart';
import 'package:sanbao_flutter/features/auth/domain/repositories/auth_repository.dart';

/// Concrete [AuthRepository] implementation.
///
/// Handles all authentication flows including:
/// - Email/password login with optional 2FA
/// - Registration
/// - Google Sign-In
/// - Token refresh
/// - Session management
/// - 2FA setup/enable/disable/verify
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remote = remoteDataSource,
        _local = localDataSource;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<User> login(LoginParams params) async {
    try {
      final result = await _remote.login(
        email: params.email,
        password: params.password,
        totpCode: params.totpCode,
      );

      // Persist tokens and cache user
      await _local.saveTokens(result.tokens);
      await _local.cacheUser(result.user);

      // Set Sentry user context
      await ErrorHandler.setUser(
        id: result.user.id,
        email: result.user.email,
        name: result.user.name,
      );

      return result.user.toEntity();
    } on ValidationException catch (e) {
      // Check for 2FA required error
      if (e.message.contains('2FA_REQUIRED') ||
          e.message.contains('2fa_required')) {
        throw const AuthFailure(
          message: 'Требуется двухфакторная аутентификация',
          code: '2FA_REQUIRED',
        );
      }
      if (e.message.contains('2FA_INVALID') ||
          e.message.contains('2fa_invalid')) {
        throw const AuthFailure(
          message: 'Неверный код двухфакторной аутентификации',
          code: '2FA_INVALID',
        );
      }
      throw ValidationFailure(message: e.message);
    } on UnauthorizedException {
      throw const AuthFailure(
        message: 'Неверный email или пароль',
      );
    } on ApiException catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }

  @override
  Future<void> register(RegisterParams params) async {
    try {
      await _remote.register(
        email: params.email,
        password: params.password,
        name: params.name,
      );
    } on ApiException catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }

  @override
  Future<User> signInWithGoogle(GoogleSignInParams params) async {
    try {
      final result = await _remote.signInWithGoogle(
        idToken: params.idToken,
      );

      // Persist tokens and cache user
      await _local.saveTokens(result.tokens);
      await _local.cacheUser(result.user);

      // Set Sentry user context
      await ErrorHandler.setUser(
        id: result.user.id,
        email: result.user.email,
        name: result.user.name,
      );

      return result.user.toEntity();
    } on ApiException catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Get the refresh token to invalidate server-side
      final tokens = await _local.getTokens();
      if (tokens != null) {
        await _remote.logout(refreshToken: tokens.refreshToken);
      }
    } catch (e) {
      // Log but don't fail -- we always clear local state
      debugPrint('[AuthRepository] Server logout error: $e');
    } finally {
      // Always clear local tokens regardless of server response
      await _local.clearAll();
      await ErrorHandler.clearUser();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      // Check if we have tokens first
      final hasTokens = await _local.hasTokens();
      if (!hasTokens) return null;

      // Try to get fresh user data from server
      final userModel = await _remote.getCurrentUser();
      await _local.cacheUser(userModel);

      return userModel.toEntity();
    } on UnauthorizedException {
      // Token expired and refresh failed
      await _local.clearAll();
      return null;
    } on TokenRefreshException {
      await _local.clearAll();
      return null;
    } on ApiException {
      // Network error -- try returning cached user
      final cached = await _local.getCachedUser();
      return cached?.toEntity();
    }
  }

  @override
  Future<AuthToken> refreshToken() async {
    final storedTokens = await _local.getTokens();
    if (storedTokens == null) {
      throw const AuthFailure(
        message: 'Нет сохранённой сессии',
        code: 'NO_SESSION',
      );
    }

    try {
      final newTokens = await _remote.refreshToken(
        refreshToken: storedTokens.refreshToken,
      );
      await _local.saveTokens(newTokens);
      return newTokens.toEntity();
    } on ApiException catch (e) {
      // If refresh fails, clear everything
      await _local.clearAll();
      throw ErrorHandler.toFailure(e);
    }
  }

  @override
  Future<bool> hasValidSession() async {
    final tokens = await _local.getTokens();
    if (tokens == null) return false;

    // If the token has not expired, consider the session valid
    final entity = tokens.toEntity();
    if (!entity.isExpired) return true;

    // Token expired but we have a refresh token -- try refresh
    try {
      await refreshToken();
      return true;
    } on Failure {
      return false;
    }
  }

  @override
  Future<TwoFactorSetupResult> setup2fa() async {
    try {
      final response = await _remote.get2faSetup();

      // If already enabled, return immediately
      if (response['enabled'] == true) {
        return const TwoFactorSetupResult(
          secret: '',
          qrCodeUrl: '',
          enabled: true,
        );
      }

      return TwoFactorSetupResult(
        secret: response['secret']! as String,
        qrCodeUrl: response['qrCodeUrl']! as String,
        enabled: false,
      );
    } on ApiException catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }

  @override
  Future<void> enable2fa({required String code}) async {
    try {
      await _remote.post2fa(action: 'enable', code: code);

      // Update cached user to reflect 2FA enabled
      final cached = await _local.getCachedUser();
      if (cached != null) {
        final updated = UserModel(
          id: cached.id,
          name: cached.name,
          email: cached.email,
          image: cached.image,
          role: cached.role,
          locale: cached.locale,
          emailVerified: cached.emailVerified,
          twoFactorEnabled: true,
          subscriptionTier: cached.subscriptionTier,
          isBanned: cached.isBanned,
          createdAt: cached.createdAt,
        );
        await _local.cacheUser(updated);
      }
    } on ApiException catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }

  @override
  Future<void> disable2fa({required String code}) async {
    try {
      await _remote.post2fa(action: 'disable', code: code);

      // Update cached user to reflect 2FA disabled
      final cached = await _local.getCachedUser();
      if (cached != null) {
        final updated = UserModel(
          id: cached.id,
          name: cached.name,
          email: cached.email,
          image: cached.image,
          role: cached.role,
          locale: cached.locale,
          emailVerified: cached.emailVerified,
          twoFactorEnabled: false,
          subscriptionTier: cached.subscriptionTier,
          isBanned: cached.isBanned,
          createdAt: cached.createdAt,
        );
        await _local.cacheUser(updated);
      }
    } on ApiException catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }

  @override
  Future<bool> verify2fa({required String code}) async {
    try {
      final response = await _remote.post2fa(action: 'verify', code: code);
      return (response['valid'] as bool?) ?? false;
    } on ApiException catch (e) {
      throw ErrorHandler.toFailure(e);
    }
  }
}

/// Riverpod provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  ),
);

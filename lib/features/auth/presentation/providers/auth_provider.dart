/// Riverpod providers for authentication state management.
///
/// Provides reactive auth state, current user, and action providers
/// for login, register, and logout operations.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sanbao_flutter/features/auth/domain/entities/user.dart';
import 'package:sanbao_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:sanbao_flutter/features/auth/domain/usecases/login_usecase.dart';
import 'package:sanbao_flutter/features/auth/domain/usecases/logout_usecase.dart';
import 'package:sanbao_flutter/features/auth/domain/usecases/register_usecase.dart';
import 'package:sanbao_flutter/features/auth/domain/usecases/setup_2fa_usecase.dart';
import 'package:sanbao_flutter/features/notifications/presentation/providers/notification_provider.dart';

// ---- Use Case Providers ----

/// Provider for the [LoginUseCase].
final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(
    repository: ref.watch(authRepositoryProvider),
  ),
);

/// Provider for the [RegisterUseCase].
final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(
    repository: ref.watch(authRepositoryProvider),
  ),
);

/// Provider for the [LogoutUseCase].
final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(
    repository: ref.watch(authRepositoryProvider),
  ),
);

/// Provider for the [Setup2faUseCase].
final setup2faUseCaseProvider = Provider<Setup2faUseCase>(
  (ref) => Setup2faUseCase(
    repository: ref.watch(authRepositoryProvider),
  ),
);

// ---- Auth State ----

/// Sealed state for authentication.
sealed class AuthState {
  const AuthState();
}

/// Initial state before auth check completes.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth check is in progress.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  /// The authenticated user.
  final User user;
}

/// User is not authenticated.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.message});

  /// Optional message explaining why (e.g., session expired).
  final String? message;
}

/// Authentication error.
final class AuthError extends AuthState {
  const AuthError({required this.failure});

  /// The failure that occurred.
  final Failure failure;
}

/// Notifier that manages the global authentication state.
///
/// On initialization, checks for an existing session. Provides
/// methods for login, register, Google sign-in, and logout.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required AuthRepository repository,
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _repository = repository,
        _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        super(const AuthInitial()) {
    // Check for existing session on creation
    _checkSession();
  }

  final AuthRepository _repository;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;

  /// Checks if there is a valid stored session.
  Future<void> _checkSession() async {
    state = const AuthLoading();

    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user: user);
      } else {
        state = const AuthUnauthenticated();
      }
    } on Failure catch (f) {
      debugPrint('[AuthNotifier] Session check failed: ${f.message}');
      state = const AuthUnauthenticated();
    } catch (e) {
      debugPrint('[AuthNotifier] Session check error: $e');
      state = const AuthUnauthenticated();
    }
  }

  /// Authenticates with email and password.
  ///
  /// On success, updates state to [AuthAuthenticated].
  /// On 2FA required, throws [AuthFailure] with code `2FA_REQUIRED`.
  Future<void> login({
    required String email,
    required String password,
    String? totpCode,
  }) async {
    state = const AuthLoading();

    try {
      final user = await _loginUseCase(
        LoginParams(
          email: email,
          password: password,
          totpCode: totpCode,
        ),
      );
      state = AuthAuthenticated(user: user);
    } on AuthFailure catch (f) {
      // Re-throw 2FA errors for the UI to handle
      if (f.code == '2FA_REQUIRED' || f.code == '2FA_INVALID') {
        state = const AuthUnauthenticated();
        rethrow;
      }
      state = AuthError(failure: f);
    } on Failure catch (f) {
      state = AuthError(failure: f);
    }
  }

  /// Registers a new user account, then logs them in.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();

    try {
      await _registerUseCase(
        RegisterParams(
          name: name,
          email: email,
          password: password,
        ),
      );

      // Auto-login after successful registration
      final user = await _loginUseCase(
        LoginParams(email: email, password: password),
      );
      state = AuthAuthenticated(user: user);
    } on Failure catch (f) {
      state = AuthError(failure: f);
    }
  }

  /// Signs in with Google credentials.
  Future<void> signInWithGoogle({required String idToken}) async {
    state = const AuthLoading();

    try {
      final user = await _repository.signInWithGoogle(
        GoogleSignInParams(idToken: idToken),
      );
      state = AuthAuthenticated(user: user);
    } on Failure catch (f) {
      state = AuthError(failure: f);
    }
  }

  /// Signs in with Apple credentials.
  Future<void> signInWithApple({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? fullName,
    String? nonce,
  }) async {
    state = const AuthLoading();

    try {
      final user = await _repository.signInWithApple(
        AppleSignInParams(
          identityToken: identityToken,
          authorizationCode: authorizationCode,
          email: email,
          fullName: fullName,
          nonce: nonce,
        ),
      );
      state = AuthAuthenticated(user: user);
    } on Failure catch (f) {
      state = AuthError(failure: f);
    }
  }

  /// Requests a WhatsApp OTP for the given phone number.
  Future<void> requestWhatsAppOtp({required String phone}) async {
    try {
      await _repository.requestWhatsAppOtp(
        WhatsAppOtpRequestParams(phone: phone),
      );
    } on Failure catch (f) {
      state = AuthError(failure: f);
      rethrow;
    }
  }

  /// Verifies a WhatsApp OTP and authenticates the user.
  Future<void> verifyWhatsAppOtp({
    required String phone,
    required String code,
  }) async {
    state = const AuthLoading();

    try {
      final user = await _repository.verifyWhatsAppOtp(
        WhatsAppVerifyParams(phone: phone, code: code),
      );
      state = AuthAuthenticated(user: user);
    } on Failure catch (f) {
      state = AuthError(failure: f);
    }
  }

  /// Logs out the current user.
  Future<void> logout() async {
    try {
      await _logoutUseCase();
    } catch (e) {
      debugPrint('[AuthNotifier] Logout error: $e');
    } finally {
      state = const AuthUnauthenticated();
    }
  }

  /// Refreshes the current user profile.
  Future<void> refreshUser() async {
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user: user);
      }
    } catch (e) {
      debugPrint('[AuthNotifier] User refresh error: $e');
    }
  }
}

/// Global auth state provider.
///
/// This is the single source of truth for whether the user is
/// authenticated. The router watches this for redirect decisions.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(
    repository: ref.watch(authRepositoryProvider),
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
  ),);

/// Convenience provider that extracts the current user or null.
final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authStateProvider);
  return switch (state) {
    AuthAuthenticated(:final user) => user,
    _ => null,
  };
});

/// Whether the user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final state = ref.watch(authStateProvider);
  return state is AuthAuthenticated;
});

/// Whether the auth state is still loading (initial check).
final isAuthLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(authStateProvider);
  return state is AuthLoading || state is AuthInitial;
});

/// Provider for the auth error message, if any.
final authErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(authStateProvider);
  return switch (state) {
    AuthError(:final failure) => failure.message,
    _ => null,
  };
});

/// Provider that observes auth state changes and manages the
/// notification polling lifecycle.
///
/// Starts polling when the user becomes authenticated, and stops
/// polling when they log out. This provider should be watched
/// early in the widget tree (e.g., in the root app widget or
/// the router provider) to ensure it stays alive.
final authNotificationBridgeProvider = Provider<void>((ref) {
  final authState = ref.watch(authStateProvider);

  switch (authState) {
    case AuthAuthenticated():
      // User just logged in or app restored session -- start polling
      startNotificationPollingRef(ref);
    case AuthUnauthenticated():
    case AuthError():
      // User logged out or auth failed -- stop polling
      stopNotificationPollingRef(ref);
    case AuthInitial():
    case AuthLoading():
      // Still loading, do nothing
      break;
  }
});

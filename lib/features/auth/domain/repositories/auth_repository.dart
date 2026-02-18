/// Abstract authentication repository interface.
///
/// Defines the contract for all auth operations. The data layer provides
/// the concrete implementation [AuthRepositoryImpl].
library;

import 'package:sanbao_flutter/features/auth/domain/entities/auth_token.dart';
import 'package:sanbao_flutter/features/auth/domain/entities/user.dart';

/// Parameters for the login operation.
class LoginParams {
  const LoginParams({
    required this.email,
    required this.password,
    this.totpCode,
  });

  /// User email address.
  final String email;

  /// User password.
  final String password;

  /// Optional TOTP code for 2FA-enabled accounts.
  final String? totpCode;
}

/// Parameters for the registration operation.
class RegisterParams {
  const RegisterParams({
    required this.email,
    required this.password,
    this.name,
  });

  /// User display name (optional).
  final String? name;

  /// User email address.
  final String email;

  /// User password (must meet minimum requirements).
  final String password;
}

/// Parameters for Google Sign-In.
class GoogleSignInParams {
  const GoogleSignInParams({
    required this.idToken,
  });

  /// The Google ID token obtained from the Google Sign-In SDK.
  final String idToken;
}

/// Result of a 2FA setup request.
class TwoFactorSetupResult {
  const TwoFactorSetupResult({
    required this.secret,
    required this.qrCodeUrl,
    required this.enabled,
  });

  /// The TOTP secret for manual entry.
  final String secret;

  /// Data URL of the QR code image for scanning.
  final String qrCodeUrl;

  /// Whether 2FA is already enabled.
  final bool enabled;
}

/// Abstract repository defining all authentication operations.
///
/// Implementations should handle network calls, token persistence,
/// and error mapping to domain [Failure] types.
abstract class AuthRepository {
  /// Authenticates with email and password credentials.
  ///
  /// Returns the authenticated [User] and persists tokens.
  /// Throws [AuthFailure] on invalid credentials.
  /// Throws a special error with code `2FA_REQUIRED` when 2FA is needed.
  Future<User> login(LoginParams params);

  /// Creates a new user account.
  ///
  /// Throws [ValidationFailure] if the email is taken or password is weak.
  Future<void> register(RegisterParams params);

  /// Authenticates with a Google ID token.
  ///
  /// Creates the account if it does not exist, or links it.
  Future<User> signInWithGoogle(GoogleSignInParams params);

  /// Logs out the current user.
  ///
  /// Clears stored tokens and notifies the server.
  Future<void> logout();

  /// Retrieves the currently authenticated user's profile.
  ///
  /// Returns `null` if no valid session exists.
  Future<User?> getCurrentUser();

  /// Refreshes the access token using the stored refresh token.
  ///
  /// Returns the new [AuthToken] or throws [AuthFailure] if
  /// the refresh token is invalid/expired.
  Future<AuthToken> refreshToken();

  /// Checks whether the user has a valid stored session.
  ///
  /// Does NOT call the server -- only checks local token storage.
  Future<bool> hasValidSession();

  /// Retrieves the 2FA setup data (secret + QR code).
  ///
  /// If 2FA is already enabled, returns a result with [enabled] = true.
  Future<TwoFactorSetupResult> setup2fa();

  /// Enables 2FA by verifying a TOTP code.
  Future<void> enable2fa({required String code});

  /// Disables 2FA by verifying a TOTP code.
  Future<void> disable2fa({required String code});

  /// Verifies a TOTP code during login flow.
  ///
  /// Returns `true` if the code is valid.
  Future<bool> verify2fa({required String code});
}

/// Remote data source for authentication API calls.
///
/// Communicates with the Sanbao backend auth endpoints
/// using the configured [DioClient].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/api_exceptions.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/auth/data/models/token_model.dart';
import 'package:sanbao_flutter/features/auth/data/models/user_model.dart';

/// Remote data source handling all auth-related API calls.
///
/// Endpoints:
/// - POST /api/auth/login
/// - POST /api/auth/register
/// - POST /api/auth/mobile/google
/// - POST /api/auth/apple
/// - POST /api/auth/whatsapp/request
/// - POST /api/auth/whatsapp/verify
/// - POST /api/auth/logout
/// - POST /api/auth/refresh
/// - GET  /api/auth/me
/// - GET  /api/auth/2fa (setup)
/// - POST /api/auth/2fa (enable/disable/verify)
class AuthRemoteDataSource {
  const AuthRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  static String get _basePath => AppConfig.authEndpoint;

  /// Authenticates with email/password credentials.
  ///
  /// Returns a map containing `user` and `tokens` on success.
  /// The server may return a 2FA_REQUIRED error if 2FA is enabled.
  /// Backend returns `{token, user, expiresAt}` (Bearer token format).
  Future<({UserModel user, TokenModel tokens})> login({
    required String email,
    required String password,
    String? totpCode,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '$_basePath/login',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        if (totpCode != null) 'totpCode': totpCode,
      },
    );

    _assertSuccessResponse(response);

    final user = UserModel.fromJson(
      response['user']! as Map<String, Object?>,
    );
    final tokens = _parseBearerTokenResponse(response);

    return (user: user, tokens: tokens);
  }

  /// Registers a new user account.
  ///
  /// Throws [ValidationException] if the email is already taken
  /// or inputs fail validation.
  Future<void> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '$_basePath/register',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name.trim(),
      },
    );

    _assertSuccessResponse(response);
  }

  /// Authenticates or links a Google account via ID token.
  ///
  /// Returns the user and tokens if the account exists or was created.
  /// Backend endpoint: POST /api/auth/mobile/google → {token, user, expiresAt}
  Future<({UserModel user, TokenModel tokens})> signInWithGoogle({
    required String idToken,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '$_basePath/mobile/google',
      data: {'idToken': idToken},
    );

    _assertSuccessResponse(response);

    final user = UserModel.fromJson(
      response['user']! as Map<String, Object?>,
    );
    final tokens = _parseBearerTokenResponse(response);

    return (user: user, tokens: tokens);
  }

  /// Authenticates or links an Apple account via identity token.
  ///
  /// Returns the user and tokens if the account exists or was created.
  /// Backend endpoint: POST /api/auth/apple → {token, user, expiresAt}
  Future<({UserModel user, TokenModel tokens})> signInWithApple({
    required String identityToken,
    String? email,
    String? fullName,
    String? nonce,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '$_basePath/apple',
      data: {
        'identityToken': identityToken,
        if (email != null) 'email': email,
        if (fullName != null) 'fullName': fullName,
        if (nonce != null) 'nonce': nonce,
      },
    );

    _assertSuccessResponse(response);

    final user = UserModel.fromJson(
      response['user']! as Map<String, Object?>,
    );
    final tokens = _parseBearerTokenResponse(response);

    return (user: user, tokens: tokens);
  }

  /// Requests a WhatsApp OTP for the given phone number.
  ///
  /// The server sends a verification code via WhatsApp Business API.
  Future<void> requestWhatsAppOtp({required String phone}) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '$_basePath/whatsapp/request',
      data: {'phone': phone.trim()},
    );

    _assertSuccessResponse(response);
  }

  /// Verifies a WhatsApp OTP and authenticates the user.
  ///
  /// Returns the user and tokens if the code is valid.
  Future<({UserModel user, TokenModel tokens})> verifyWhatsAppOtp({
    required String phone,
    required String code,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '$_basePath/whatsapp/verify',
      data: {
        'phone': phone.trim(),
        'code': code.replaceAll(RegExp(r'\s'), ''),
      },
    );

    _assertSuccessResponse(response);

    final user = UserModel.fromJson(
      response['user']! as Map<String, Object?>,
    );
    final tokens = TokenModel.fromJson(
      response['tokens']! as Map<String, Object?>,
    );

    return (user: user, tokens: tokens);
  }

  /// Notifies the server that the user is logging out.
  ///
  /// The server invalidates the refresh token.
  Future<void> logout({required String refreshToken}) async {
    try {
      await _dioClient.post<Map<String, Object?>>(
        '$_basePath/logout',
        data: {'refreshToken': refreshToken},
      );
    } on ApiException {
      // Swallow server errors during logout -- we clear tokens locally
      // regardless of the server response.
    }
  }

  /// Refreshes the access token using a refresh token.
  ///
  /// Returns the new token pair.
  Future<TokenModel> refreshToken({required String refreshToken}) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '$_basePath/refresh',
      data: {'refreshToken': refreshToken},
    );

    return TokenModel.fromJson(response);
  }

  /// Retrieves the authenticated user's profile.
  ///
  /// Requires a valid access token in the Authorization header
  /// (handled automatically by [AuthInterceptor]).
  Future<UserModel> getCurrentUser() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '$_basePath/me',
    );

    return UserModel.fromJson(response);
  }

  /// Retrieves the 2FA setup data.
  ///
  /// Returns the TOTP secret, QR code URL, and whether 2FA is enabled.
  Future<Map<String, Object?>> get2faSetup() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '$_basePath/2fa',
    );

    return response;
  }

  /// Performs a 2FA action: enable, disable, or verify.
  ///
  /// [action] must be one of: "enable", "disable", "verify".
  /// [code] is the 6-digit TOTP code.
  Future<Map<String, Object?>> post2fa({
    required String action,
    required String code,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '$_basePath/2fa',
      data: {
        'action': action,
        'code': code.replaceAll(RegExp(r'\s'), ''),
      },
    );

    return response;
  }

  /// Parses a Bearer-token response from mobile auth endpoints.
  ///
  /// Backend returns `{token, expiresAt}` (single Bearer token, no refresh).
  /// We map `token` → `accessToken` and use it as `refreshToken` too since
  /// the proxy middleware converts Bearer → NextAuth session cookie.
  TokenModel _parseBearerTokenResponse(Map<String, Object?> response) {
    final token = response['token']! as String;
    return TokenModel(
      accessToken: token,
      refreshToken: token,
      expiresAt: response['expiresAt'] is String
          ? DateTime.parse(response['expiresAt']! as String)
          : DateTime.now().add(const Duration(days: 30)),
    );
  }

  /// Validates that the response indicates success.
  void _assertSuccessResponse(Map<String, Object?> response) {
    final error = response['error'];
    if (error is String && error.isNotEmpty) {
      throw ValidationException(message: error);
    }
  }
}

/// Riverpod provider for [AuthRemoteDataSource].
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(
    dioClient: ref.watch(dioClientProvider),
  ),
);

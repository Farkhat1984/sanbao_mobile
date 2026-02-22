/// Login screen.
///
/// Social-only authentication screen with Google, Apple, and WhatsApp
/// sign-in buttons. Follows the Sanbao "Soft Corporate Minimalism" style.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/config/env.dart';
import 'package:sanbao_flutter/core/config/routes.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:sanbao_flutter/features/auth/presentation/widgets/social_login_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// The main login screen of the application.
///
/// Provides social-only authentication:
/// - Google Sign-In
/// - Apple Sign-In (iOS/macOS)
/// - WhatsApp Sign-In (phone + OTP)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _errorMessage;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _isWhatsAppLoading = false;

  bool get _isAnyLoading =>
      _isGoogleLoading || _isAppleLoading || _isWhatsAppLoading;

  // ---- Google Sign-In ----

  Future<void> _handleGoogleSignIn() async {
    if (!Env.isGoogleSignInEnabled) return;

    setState(() {
      _errorMessage = null;
      _isGoogleLoading = true;
    });

    try {
      final googleSignIn = GoogleSignIn(
        // serverClientId — Web Client ID from Firebase, needed to get idToken
        // for backend authentication. On Android, clientId is not needed
        // (handled by google-services.json). On iOS, the plugin reads
        // clientId from GoogleService-Info.plist automatically.
        serverClientId: Env.googleClientId,
        scopes: ['email', 'profile'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        setState(() {
          _errorMessage = 'Не удалось получить токен Google';
          _isGoogleLoading = false;
        });
        return;
      }

      await ref.read(authStateProvider.notifier).signInWithGoogle(
            idToken: idToken,
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка входа через Google';
          _isGoogleLoading = false;
        });
      }
    }
  }

  // ---- Apple Sign-In ----

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _errorMessage = null;
      _isAppleLoading = true;
    });

    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        setState(() {
          _errorMessage = 'Не удалось получить токен Apple';
          _isAppleLoading = false;
        });
        return;
      }

      String? fullName;
      final givenName = credential.givenName;
      final familyName = credential.familyName;
      if (givenName != null || familyName != null) {
        fullName = [givenName, familyName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
        if (fullName.isEmpty) fullName = null;
      }

      await ref.read(authStateProvider.notifier).signInWithApple(
            identityToken: identityToken,
            authorizationCode: credential.authorizationCode,
            email: credential.email,
            fullName: fullName,
            nonce: rawNonce,
          );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        setState(() => _isAppleLoading = false);
        return;
      }
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка входа через Apple';
          _isAppleLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка входа через Apple';
          _isAppleLoading = false;
        });
      }
    }
  }

  // ---- WhatsApp Sign-In (phone + OTP) ----

  Future<void> _handleWhatsAppSignIn() async {
    setState(() {
      _errorMessage = null;
      _isWhatsAppLoading = true;
    });

    try {
      final result = await _showPhoneInputSheet();
      if (result == null) {
        setState(() => _isWhatsAppLoading = false);
        return;
      }

      // Request OTP
      await ref.read(authStateProvider.notifier).requestWhatsAppOtp(
            phone: result,
          );

      if (!mounted) return;

      // Show OTP input
      final code = await _showOtpInputSheet(result);
      if (code == null) {
        setState(() => _isWhatsAppLoading = false);
        return;
      }

      // Verify OTP
      await ref.read(authStateProvider.notifier).verifyWhatsAppOtp(
            phone: result,
            code: code,
          );
    } on Failure catch (f) {
      if (mounted) {
        setState(() {
          _errorMessage = f.message;
          _isWhatsAppLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка входа через WhatsApp';
          _isWhatsAppLoading = false;
        });
      }
    }
  }

  /// Shows a bottom sheet for phone number input.
  /// Returns the phone number or null if cancelled.
  Future<String?> _showPhoneInputSheet() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colors = ctx.sanbaoColors;

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Вход через WhatsApp',
                  style: ctx.textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Введите номер телефона, на который '
                  'придёт код подтверждения в WhatsApp',
                  style: ctx.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                  ],
                  decoration: const InputDecoration(
                    hintText: '+7 999 123 45 67',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: SanbaoRadius.md,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return 'Введите корректный номер телефона';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(ctx).pop(controller.text.trim());
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: SanbaoRadius.md,
                    ),
                  ),
                  child: const Text(
                    'Получить код',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows a bottom sheet for OTP code input.
  /// Returns the OTP code or null if cancelled.
  Future<String?> _showOtpInputSheet(String phone) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colors = ctx.sanbaoColors;

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Введите код',
                  style: ctx.textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Код отправлен на $phone в WhatsApp',
                  style: ctx.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: ctx.textTheme.headlineSmall?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    hintText: '------',
                    border: OutlineInputBorder(
                      borderRadius: SanbaoRadius.md,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 4) {
                      return 'Введите код из WhatsApp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(ctx).pop(controller.text.trim());
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius: SanbaoRadius.md,
                    ),
                  ),
                  child: const Text(
                    'Подтвердить',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (_, state) {
      if (state is AuthAuthenticated) {
        context.goNamed(RouteNames.chat);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  _buildHeader(context),
                  const SizedBox(height: 40),
                  _buildAuthCard(context),
                  const SizedBox(height: 24),
                  _buildFooter(context),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.sanbaoColors;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SanbaoColors.gradientStart, SanbaoColors.gradientEnd],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x264F6EF7),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.explore_outlined,
            size: 36,
            color: SanbaoColors.textInverse,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppConfig.appName,
          style: context.textTheme.headlineMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppConfig.appDescription,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    final colors = context.sanbaoColors;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: SanbaoRadius.lg,
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: SanbaoShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Войти в аккаунт',
            style: context.textTheme.headlineSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите способ входа',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.errorLight,
                borderRadius: SanbaoRadius.sm,
              ),
              child: Text(
                _errorMessage!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Social login buttons
          _buildSocialButtons(),
        ],
      ),
    );
  }

  Widget _buildSocialButtons() {
    final showApple = SocialLoginButton.isAppleSignInAvailable;
    final showGoogle = Env.isGoogleSignInEnabled;

    return Column(
      children: [
        // Google Sign-In
        if (showGoogle) ...[
          SocialLoginButton(
            provider: SocialProvider.google,
            onPressed: _handleGoogleSignIn,
            isLoading: _isGoogleLoading,
            isDisabled: _isAnyLoading && !_isGoogleLoading,
            label: 'Войти через Google',
          ),
          const SizedBox(height: 12),
        ],

        // Apple Sign-In (iOS/macOS per Apple HIG)
        if (showApple) ...[
          SocialLoginButton(
            provider: SocialProvider.apple,
            onPressed: _handleAppleSignIn,
            isLoading: _isAppleLoading,
            isDisabled: _isAnyLoading && !_isAppleLoading,
            label: 'Войти через Apple',
          ),
          const SizedBox(height: 12),
        ],

        // WhatsApp Sign-In
        SocialLoginButton(
          provider: SocialProvider.whatsapp,
          onPressed: _handleWhatsAppSignIn,
          isLoading: _isWhatsAppLoading,
          isDisabled: _isAnyLoading && !_isWhatsAppLoading,
          label: 'Войти через WhatsApp',
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colors = context.sanbaoColors;

    return Text(
      'Продолжая, вы соглашаетесь с условиями '
      'использования и политикой конфиденциальности',
      style: context.textTheme.bodySmall?.copyWith(
        color: colors.textMuted,
      ),
      textAlign: TextAlign.center,
    );
  }
}

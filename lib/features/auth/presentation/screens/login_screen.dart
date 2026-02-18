/// Login screen.
///
/// Full login screen with email/password, Google Sign-In,
/// biometric unlock, and 2FA support. Matches the Sanbao
/// design system with the "Soft Corporate Minimalism" style.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/config/env.dart';
import 'package:sanbao_flutter/core/config/routes.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:sanbao_flutter/features/auth/presentation/widgets/login_form.dart';
import 'package:sanbao_flutter/features/auth/presentation/widgets/social_login_button.dart';
import 'package:sanbao_flutter/features/auth/presentation/widgets/two_factor_input.dart';

/// The main login screen of the application.
///
/// Provides:
/// - Email/password login form
/// - Google Sign-In button
/// - Biometric unlock option (fingerprint/face)
/// - 2FA verification when required
/// - Navigation to registration
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _errorMessage;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _show2faInput = false;
  String? _pendingEmail;
  String? _pendingPassword;
  String? _twoFactorError;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    if (!AppConfig.enableBiometricAuth) return;

    try {
      final localAuth = LocalAuthentication();
      final canCheck = await localAuth.canCheckBiometrics;
      final isSupported = await localAuth.isDeviceSupported();

      if (mounted) {
        setState(() {
          _biometricAvailable = canCheck && isSupported;
        });
      }
    } catch (_) {
      // Biometric not available
    }
  }

  Future<void> _handleLogin(LoginFormData data) async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(authStateProvider.notifier).login(
            email: data.email,
            password: data.password,
          );
      // Navigation is handled by the router redirect
    } on AuthFailure catch (f) {
      if (f.code == '2FA_REQUIRED') {
        setState(() {
          _show2faInput = true;
          _pendingEmail = data.email;
          _pendingPassword = data.password;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _errorMessage = f.message;
        _isLoading = false;
      });
    } on Failure catch (f) {
      setState(() {
        _errorMessage = f.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Произошла ошибка. Попробуйте позже.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handle2faSubmit(String code) async {
    if (_pendingEmail == null || _pendingPassword == null) return;

    setState(() {
      _twoFactorError = null;
      _isLoading = true;
    });

    try {
      await ref.read(authStateProvider.notifier).login(
            email: _pendingEmail!,
            password: _pendingPassword!,
            totpCode: code,
          );
      // Navigation is handled by the router redirect
    } on AuthFailure catch (f) {
      setState(() {
        _twoFactorError = f.message;
        _isLoading = false;
      });
    } on Failure catch (f) {
      setState(() {
        _twoFactorError = f.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _twoFactorError = 'Неверный код. Попробуйте ещё раз.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!Env.isGoogleSignInEnabled) return;

    setState(() {
      _errorMessage = null;
      _isGoogleLoading = true;
    });

    try {
      final googleSignIn = GoogleSignIn(
        clientId: Env.googleClientId,
        scopes: ['email', 'profile'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled
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
      // Navigation is handled by the router redirect
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка входа через Google';
        _isGoogleLoading = false;
      });
    }
  }

  Future<void> _handleBiometricAuth() async {
    final localAuth = LocalAuthentication();

    try {
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Войдите с помощью биометрии',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        // If biometric succeeds, try to restore the session
        // using stored credentials
        await ref.read(authStateProvider.notifier).refreshUser();
      }
    } catch (_) {
      // Biometric auth failed or cancelled
    }
  }

  void _navigateToRegister() {
    context.goNamed(RouteNames.register);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes for navigation
    ref.listen<AuthState>(authStateProvider, (_, state) {
      if (state is AuthAuthenticated) {
        context.goNamed(RouteNames.chat);
      }
    });

    return Scaffold(
      body: _show2faInput
          ? _build2faScreen(context)
          : _buildLoginScreen(context),
    );
  }

  Widget _buildLoginScreen(BuildContext context) {
    final colors = context.sanbaoColors;

    return SafeArea(
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

                // Logo and title
                _buildHeader(context),
                const SizedBox(height: 40),

                // Login form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: SanbaoRadius.lg,
                    border: Border.all(
                      color: colors.border,
                      width: 0.5,
                    ),
                    boxShadow: SanbaoShadows.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Вход в аккаунт',
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Введите данные для входа',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Login form
                      LoginForm(
                        onSubmit: _handleLogin,
                        isLoading: _isLoading,
                        errorMessage: _errorMessage,
                        onForgotPassword: () {
                          // TODO: Implement forgot password
                        },
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      _buildDivider(context),
                      const SizedBox(height: 20),

                      // Google Sign-In
                      if (Env.isGoogleSignInEnabled)
                        SocialLoginButton(
                          provider: SocialProvider.google,
                          onPressed: _handleGoogleSignIn,
                          isLoading: _isGoogleLoading,
                          isDisabled: _isLoading,
                          label: 'Войти через Google',
                        ),

                      // Biometric
                      if (_biometricAvailable) ...[
                        const SizedBox(height: 12),
                        _buildBiometricButton(context),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Register link
                _buildRegisterLink(context),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build2faScreen(BuildContext context) {
    final colors = context.sanbaoColors;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: SanbaoRadius.lg,
                border: Border.all(
                  color: colors.border,
                  width: 0.5,
                ),
                boxShadow: SanbaoShadows.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _show2faInput = false;
                          _pendingEmail = null;
                          _pendingPassword = null;
                          _twoFactorError = null;
                        });
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Shield icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colors.accentLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 32,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Двухфакторная аутентификация',
                    style: context.textTheme.titleLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Введите 6-значный код из приложения-аутентификатора',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // OTP Input
                  TwoFactorInput(
                    onCompleted: _handle2faSubmit,
                    errorText: _twoFactorError,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 16),
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
        // Sanbao logo/compass icon
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

  Widget _buildDivider(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      children: [
        Expanded(child: Divider(color: colors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'или',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.border)),
      ],
    );
  }

  Widget _buildBiometricButton(BuildContext context) {
    final colors = context.sanbaoColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _handleBiometricAuth,
        borderRadius: SanbaoRadius.md,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.bgSurfaceAlt,
            borderRadius: SanbaoRadius.md,
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                size: 22,
                color: colors.accent,
              ),
              const SizedBox(width: 12),
              Text(
                'Войти с биометрией',
                style: context.textTheme.labelLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Нет аккаунта? ',
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: _navigateToRegister,
          child: Text(
            'Зарегистрируйтесь',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

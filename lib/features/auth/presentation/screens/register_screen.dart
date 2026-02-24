/// Registration screen.
///
/// Full registration screen with name, email, password, confirm password,
/// terms checkbox, Google Sign-In, and navigation to login.
/// Matches the Sanbao "Soft Corporate Minimalism" design system.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
import 'package:sanbao_flutter/core/utils/validators.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_input.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:sanbao_flutter/features/auth/presentation/widgets/social_login_button.dart';

/// The registration screen of the application.
///
/// Provides:
/// - Name field
/// - Email field
/// - Password field with visibility toggle
/// - Confirm password field
/// - Terms and conditions checkbox
/// - Register button
/// - Google Sign-In button
/// - Navigation to login screen
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _hasAttemptedSubmit = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _hasAttemptedSubmit = true);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Необходимо принять условия использования';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await ref.read(authStateProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Navigation is handled by the router redirect
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

  Future<void> _handleGoogleSignIn() async {
    if (!Env.isGoogleSignInEnabled) return;

    setState(() {
      _errorMessage = null;
      _isGoogleLoading = true;
    });

    try {
      final googleSignIn = GoogleSignIn(
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
      setState(() {
        _errorMessage = 'Ошибка входа через Google';
        _isGoogleLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    context.goNamed(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes for navigation
    ref.listen<AuthState>(authStateProvider, (_, state) {
      if (state is AuthAuthenticated) {
        context.goNamed(RouteNames.chat);
      }
    });

    final colors = context.sanbaoColors;

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
                  const SizedBox(height: 32),

                  // Header
                  _buildHeader(context),
                  const SizedBox(height: 32),

                  // Registration form card
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
                    child: _buildForm(context),
                  ),

                  const SizedBox(height: 24),

                  // Login link
                  _buildLoginLink(context),
                  const SizedBox(height: 32),
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
        // Logo
        Container(
          width: 64,
          height: 64,
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
            size: 32,
            color: SanbaoColors.textInverse,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Создать аккаунт',
          style: context.textTheme.headlineSmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Начните работу с ${AppConfig.appName}',
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = context.sanbaoColors;

    return Form(
      key: _formKey,
      autovalidateMode: _hasAttemptedSubmit
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name field
          SanbaoInput(
            controller: _nameController,
            focusNode: _nameFocusNode,
            label: 'Имя',
            hint: 'Иван Иванов',
            prefixIcon: Icons.person_outlined,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            enabled: !_isLoading,
            validator: (value) =>
                Validators.required(value, fieldName: 'Имя'),
            onSubmitted: (_) => _emailFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Email field
          SanbaoInput(
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: 'Email',
            hint: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !_isLoading,
            validator: Validators.email,
            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Password field
          SanbaoInput(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: 'Пароль',
            hint: 'Минимум 8 символов',
            prefixIcon: Icons.lock_outlined,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !_isLoading,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: colors.textMuted,
              ),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
            validator: Validators.password,
            onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Confirm password field
          SanbaoInput(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            label: 'Подтверждение пароля',
            hint: 'Повторите пароль',
            prefixIcon: Icons.lock_outlined,
            obscureText: _obscureConfirmPassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !_isLoading,
            suffix: IconButton(
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: colors.textMuted,
              ),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
            validator: Validators.confirmPassword(
              _passwordController.text,
            ),
            onSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: 16),

          // Terms checkbox
          _buildTermsCheckbox(context),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colors.errorLight,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(
                  color: colors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: colors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Register button
          SanbaoButton(
            label: 'Зарегистрироваться',
            onPressed: _isLoading ? null : _handleRegister,
            isLoading: _isLoading,
            isExpanded: true,
            size: SanbaoButtonSize.large,
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
              label: 'Зарегистрироваться через Google',
            ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: _isLoading
                ? null
                : (value) =>
                    setState(() => _acceptedTerms = value ?? false),
            activeColor: colors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide(color: colors.border, width: 1.5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: _isLoading
                ? null
                : () => setState(() => _acceptedTerms = !_acceptedTerms),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: RichText(
                text: TextSpan(
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Я принимаю '),
                    TextSpan(
                      text: 'условия использования',
                      style: TextStyle(
                        color: colors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // TODO(dev): Open terms of service
                        },
                    ),
                    const TextSpan(text: ' и '),
                    TextSpan(
                      text: 'политику конфиденциальности',
                      style: TextStyle(
                        color: colors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // TODO(dev): Open privacy policy
                        },
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildLoginLink(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Уже есть аккаунт? ',
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: _navigateToLogin,
          child: Text(
            'Войдите',
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

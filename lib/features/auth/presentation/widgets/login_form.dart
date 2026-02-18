/// Login form widget with validation.
///
/// Provides email/password fields with real-time validation,
/// password visibility toggle, and form submission handling.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/utils/validators.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_input.dart';

/// Parameters passed from the login form on submission.
class LoginFormData {
  const LoginFormData({
    required this.email,
    required this.password,
  });

  /// The email address entered by the user.
  final String email;

  /// The password entered by the user.
  final String password;
}

/// A validated login form with email and password fields.
///
/// Handles local validation before calling [onSubmit] with
/// the form data. Displays server-side errors via [errorMessage].
class LoginForm extends StatefulWidget {
  const LoginForm({
    required this.onSubmit,
    super.key,
    this.isLoading = false,
    this.errorMessage,
    this.onForgotPassword,
    this.initialEmail,
  });

  /// Called when the form is submitted with valid data.
  final ValueChanged<LoginFormData> onSubmit;

  /// Whether the form is in a loading state.
  final bool isLoading;

  /// Server-side error message to display.
  final String? errorMessage;

  /// Called when the "Forgot password?" link is tapped.
  final VoidCallback? onForgotPassword;

  /// Pre-filled email address (e.g., from registration redirect).
  final String? initialEmail;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _hasAttemptedSubmit = true);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(
      LoginFormData(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Form(
      key: _formKey,
      autovalidateMode: _hasAttemptedSubmit
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            enabled: !widget.isLoading,
            validator: Validators.email,
            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Password field
          SanbaoInput(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: 'Пароль',
            hint: 'Введите пароль',
            prefixIcon: Icons.lock_outlined,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            enabled: !widget.isLoading,
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пароль обязателен';
              }
              if (value.length < AppConfig.passwordMinLength) {
                return 'Минимум ${AppConfig.passwordMinLength} символов';
              }
              return null;
            },
            onSubmitted: (_) => _submit(),
          ),

          // Forgot password link
          if (widget.onForgotPassword != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.isLoading ? null : widget.onForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Забыли пароль?',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.accent,
                  ),
                ),
              ),
            ),
          ],

          // Error message
          if (widget.errorMessage != null) ...[
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
                      widget.errorMessage!,
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

          // Submit button
          SanbaoButton(
            label: 'Войти',
            onPressed: widget.isLoading ? null : _submit,
            isLoading: widget.isLoading,
            isExpanded: true,
            size: SanbaoButtonSize.large,
          ),
        ],
      ),
    );
  }
}

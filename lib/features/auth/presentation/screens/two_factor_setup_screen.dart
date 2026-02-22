/// Two-factor authentication setup wizard screen.
///
/// A multi-step flow that guides the user through enabling 2FA:
/// 1. Introduction -- explains benefits, "Включить" button
/// 2. QR Code -- displays QR for scanning + manual secret key
/// 3. Verification -- 6-digit TOTP code entry
/// 4. Success -- confirmation message
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_card.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/two_factor_provider.dart';
import 'package:sanbao_flutter/features/auth/presentation/widgets/two_factor_input.dart';

/// Number of steps in the setup wizard.
const _totalSteps = 4;

/// The 2FA setup wizard screen.
///
/// Navigates through introduction, QR code display, verification,
/// and success steps. Uses [TwoFactorSetupNotifier] for state management.
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  int _currentStep = 0;
  String? _verificationError;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final setupState = ref.watch(twoFactorSetupProvider);

    // Listen for state changes to advance steps automatically
    ref.listen<TwoFactorSetupState>(twoFactorSetupProvider, (previous, next) {
      _handleStateTransition(next);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка 2FA'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _StepIndicator(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
              ),
            ),

            // Step content
            Expanded(
              child: AnimatedSwitcher(
                duration: SanbaoAnimations.durationNormal,
                switchInCurve: SanbaoAnimations.smoothCurve,
                switchOutCurve: SanbaoAnimations.smoothCurve,
                child: _buildStepContent(setupState, colors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStateTransition(TwoFactorSetupState state) {
    switch (state) {
      case TwoFactorQrReady():
        if (_currentStep < 1) {
          setState(() => _currentStep = 1);
        }
      case TwoFactorEnabled():
        setState(() {
          _currentStep = 3;
          _verificationError = null;
        });
        // Refresh the user so the twoFactorEnabled flag updates
        ref.read(authStateProvider.notifier).refreshUser();
      case TwoFactorError(:final message):
        if (_currentStep == 2) {
          // Show error on verification step
          setState(() => _verificationError = message);
          // Recover state to allow retry
          ref.read(twoFactorSetupProvider.notifier).recoverFromError();
        }
      case TwoFactorVerifying():
        setState(() => _verificationError = null);
      case TwoFactorInitial():
      case TwoFactorLoading():
      case TwoFactorDisabled():
        break;
    }
  }

  Widget _buildStepContent(
    TwoFactorSetupState state,
    SanbaoColorScheme colors,
  ) =>
      switch (_currentStep) {
      0 => _IntroStep(
          key: const ValueKey('step-intro'),
          isLoading: state is TwoFactorLoading,
          onEnable: () {
            ref.read(twoFactorSetupProvider.notifier).fetchSetupData();
          },
        ),
      1 => _QrCodeStep(
          key: const ValueKey('step-qr'),
          state: state,
          onNext: () => setState(() => _currentStep = 2),
        ),
      2 => _VerificationStep(
          key: const ValueKey('step-verify'),
          errorText: _verificationError,
          isVerifying: state is TwoFactorVerifying,
          onCompleted: (code) {
            ref.read(twoFactorSetupProvider.notifier).verifyAndEnable(
                  code: code,
                );
          },
        ),
      3 => _SuccessStep(
          key: const ValueKey('step-success'),
          onDone: () => context.pop(true),
        ),
      _ => const SizedBox.shrink(),
    };
}

// ---- Step Indicator ----

/// Horizontal step indicator with animated progress line.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        // Even indices are dots, odd are connecting lines
        if (index.isOdd) {
          final lineStep = index ~/ 2;
          final isCompleted = lineStep < currentStep;

          return Expanded(
            child: AnimatedContainer(
              duration: SanbaoAnimations.durationNormal,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCompleted ? colors.accent : colors.border,
                borderRadius: SanbaoRadius.full,
              ),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isActive = stepIndex == currentStep;
        final isCompleted = stepIndex < currentStep;

        return AnimatedContainer(
          duration: SanbaoAnimations.durationNormal,
          width: isActive ? 28 : 20,
          height: isActive ? 28 : 20,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? colors.accent
                : colors.bgSurfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isActive
                  ? colors.accent
                  : colors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: colors.textInverse,
                  )
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: isActive ? 12 : 10,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? colors.textInverse
                          : colors.textMuted,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}

// ---- Step 1: Introduction ----

/// Introduction step explaining 2FA benefits.
class _IntroStep extends StatelessWidget {
  const _IntroStep({
    required this.isLoading,
    required this.onEnable,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Shield icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SanbaoColors.gradientStart, SanbaoColors.gradientEnd],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SanbaoColors.accent.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Двухфакторная\nаутентификация',
            textAlign: TextAlign.center,
            style: context.textTheme.headlineSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Добавьте дополнительный уровень защиты '
            'вашего аккаунта с помощью приложения-аутентификатора.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Benefit list
          const _BenefitItem(
            icon: Icons.lock_rounded,
            title: 'Защита от взлома',
            description:
                'Даже если пароль будет скомпрометирован, '
                'злоумышленник не сможет войти без кода.',
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.phone_android_rounded,
            title: 'Приложение-аутентификатор',
            description:
                'Используйте Google Authenticator, Authy '
                'или другое TOTP-приложение.',
          ),
          const SizedBox(height: 16),
          const _BenefitItem(
            icon: Icons.speed_rounded,
            title: 'Быстро и просто',
            description:
                'Настройка занимает менее минуты. '
                'Отсканируйте QR-код и введите проверочный код.',
          ),

          const SizedBox(height: 40),

          // Enable button
          SizedBox(
            width: double.infinity,
            child: SanbaoButton(
              label: 'Включить 2FA',
              variant: SanbaoButtonVariant.gradient,
              size: SanbaoButtonSize.large,
              isExpanded: true,
              isLoading: isLoading,
              leadingIcon: Icons.security_rounded,
              onPressed: onEnable,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// A single benefit item with icon, title, and description.
class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SanbaoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Step 2: QR Code ----

/// QR code display step with manual secret key option.
class _QrCodeStep extends StatelessWidget {
  const _QrCodeStep({
    required this.state,
    required this.onNext,
    super.key,
  });

  final TwoFactorSetupState state;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    // Extract QR data from state via local binding for type promotion
    final currentState = state;
    if (currentState is! TwoFactorQrReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final qrCodeUrl = currentState.qrCodeUrl;
    final secret = currentState.secret;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          Text(
            'Отсканируйте QR-код',
            style: context.textTheme.titleLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Откройте приложение-аутентификатор и отсканируйте '
            'QR-код ниже, чтобы добавить аккаунт Sanbao.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // QR code display
          _QrCodeImage(
            qrCodeUrl: qrCodeUrl,
          ),

          const SizedBox(height: 24),

          // Manual secret key
          _SecretKeyCard(secret: secret),

          const SizedBox(height: 32),

          // Next button
          SizedBox(
            width: double.infinity,
            child: SanbaoButton(
              label: 'Далее',
              size: SanbaoButtonSize.large,
              isExpanded: true,
              trailingIcon: Icons.arrow_forward_rounded,
              onPressed: onNext,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Renders the QR code from a data URL (base64 PNG).
class _QrCodeImage extends StatelessWidget {
  const _QrCodeImage({required this.qrCodeUrl});

  final String qrCodeUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    // Parse base64 data from data URL
    final imageBytes = _parseDataUrl(qrCodeUrl);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SanbaoRadius.lg,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: SanbaoColors.accent.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: imageBytes != null
          ? Image.memory(
              imageBytes,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _QrCodePlaceholder(
                size: 200,
                colors: colors,
              ),
            )
          : _QrCodePlaceholder(
              size: 200,
              colors: colors,
            ),
    );
  }

  /// Parses a data URL like `data:image/png;base64,iVBOR...` into bytes.
  Uint8List? _parseDataUrl(String url) {
    try {
      if (url.startsWith('data:')) {
        final commaIndex = url.indexOf(',');
        if (commaIndex != -1) {
          return base64Decode(url.substring(commaIndex + 1));
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// Placeholder shown when the QR code image fails to load.
class _QrCodePlaceholder extends StatelessWidget {
  const _QrCodePlaceholder({
    required this.size,
    required this.colors,
  });

  final double size;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 64,
            color: colors.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            'QR-код недоступен',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
}

/// Card displaying the TOTP secret key with a copy button.
class _SecretKeyCard extends StatelessWidget {
  const _SecretKeyCard({required this.secret});

  final String secret;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    // Format secret in groups of 4 for readability
    final formattedSecret = _formatSecret(secret);

    return SanbaoCard(
      color: colors.bgSurfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.key_rounded,
                size: 16,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Или введите ключ вручную',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _copySecret(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: SanbaoRadius.sm,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formattedSecret,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'JetBrains Mono',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: colors.accent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите, чтобы скопировать ключ',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _copySecret(BuildContext context) {
    Clipboard.setData(ClipboardData(text: secret));
    HapticFeedback.lightImpact();
    if (context.mounted) {
      context.showSuccessSnackBar('Ключ скопирован в буфер обмена');
    }
  }

  /// Formats the secret in groups of 4 characters for readability.
  String _formatSecret(String secret) {
    final buffer = StringBuffer();
    for (var i = 0; i < secret.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(secret[i]);
    }
    return buffer.toString();
  }
}

// ---- Step 3: Verification ----

/// Verification step where the user enters the 6-digit TOTP code.
class _VerificationStep extends StatelessWidget {
  const _VerificationStep({
    required this.onCompleted,
    super.key,
    this.errorText,
    this.isVerifying = false,
  });

  final ValueChanged<String> onCompleted;
  final String? errorText;
  final bool isVerifying;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // Lock icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.accentLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pin_rounded,
              size: 32,
              color: colors.accent,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Введите проверочный код',
            style: context.textTheme.titleLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Откройте приложение-аутентификатор и введите '
            '6-значный код для подтверждения настройки.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 40),

          TwoFactorInput(
            onCompleted: onCompleted,
            errorText: errorText,
            isLoading: isVerifying,
            isDisabled: isVerifying,
          ),

          const SizedBox(height: 24),

          // Help text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.infoLight,
              borderRadius: SanbaoRadius.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colors.info,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Код обновляется каждые 30 секунд. '
                    'Если код не принимается, дождитесь '
                    'нового и попробуйте снова.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.info,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---- Step 4: Success ----

/// Success step confirming 2FA has been enabled.
class _SuccessStep extends StatelessWidget {
  const _SuccessStep({
    required this.onDone,
    super.key,
  });

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 48),

          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.successLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 48,
              color: colors.success,
            ),
          ),

          const SizedBox(height: 32),

          Text(
            '2FA успешно включена!',
            style: context.textTheme.headlineSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Двухфакторная аутентификация настроена. '
            'Теперь при входе в аккаунт потребуется '
            'код из приложения-аутентификатора.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Security tips
          SanbaoCard(
            color: colors.successLight,
            borderColor: colors.success.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      size: 18,
                      color: colors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Важные рекомендации',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TipRow(
                  text: 'Не удаляйте приложение-аутентификатор',
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _TipRow(
                  text: 'Сохраните секретный ключ в надёжном месте',
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _TipRow(
                  text: 'При смене устройства перенесите аккаунты',
                  colors: colors,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Done button
          SizedBox(
            width: double.infinity,
            child: SanbaoButton(
              label: 'Готово',
              size: SanbaoButtonSize.large,
              isExpanded: true,
              leadingIcon: Icons.check_rounded,
              onPressed: onDone,
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// A single tip row with a bullet point.
class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.text,
    required this.colors,
  });

  final String text;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: colors.success,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
}

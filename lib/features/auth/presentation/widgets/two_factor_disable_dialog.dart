/// Dialog for disabling two-factor authentication.
///
/// Requires the user to enter their current TOTP code to confirm
/// the 2FA disable action, preventing accidental deactivation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/two_factor_provider.dart';
import 'package:sanbao_flutter/features/auth/presentation/widgets/two_factor_input.dart';


/// Shows a dialog to disable 2FA with TOTP verification.
///
/// Returns `true` if 2FA was successfully disabled.
Future<bool> showDisableTwoFactorDialog({
  required BuildContext context,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: SanbaoColors.mobileOverlay,
    builder: (context) => const _DisableTwoFactorDialog(),
  );
  return result ?? false;
}

/// Internal dialog widget for 2FA disable flow.
class _DisableTwoFactorDialog extends ConsumerStatefulWidget {
  const _DisableTwoFactorDialog();

  @override
  ConsumerState<_DisableTwoFactorDialog> createState() =>
      _DisableTwoFactorDialogState();
}

class _DisableTwoFactorDialogState
    extends ConsumerState<_DisableTwoFactorDialog> {
  bool _isDisabling = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    // Listen for 2FA state changes
    ref.listen<TwoFactorSetupState>(twoFactorSetupProvider, (previous, next) {
      switch (next) {
        case TwoFactorDisabled():
          // Success -- refresh user and close dialog
          ref.read(authStateProvider.notifier).refreshUser();
          Navigator.of(context).pop(true);
        case TwoFactorError(:final message):
          setState(() {
            _isDisabling = false;
            _errorText = message;
          });
          ref.read(twoFactorSetupProvider.notifier).recoverFromError();
        case TwoFactorLoading():
          setState(() {
            _isDisabling = true;
            _errorText = null;
          });
        default:
          break;
      }
    });

    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: SanbaoRadius.lg),
      backgroundColor: colors.bgSurface,
      surfaceTintColor: Colors.transparent,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      title: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 22,
            color: colors.warning,
          ),
          const SizedBox(width: 8),
          Text(
            'Отключить 2FA',
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Для отключения двухфакторной аутентификации '
            'введите текущий код из приложения-аутентификатора.',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.warningLight,
              borderRadius: SanbaoRadius.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: colors.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Без 2FA ваш аккаунт будет защищён только паролем.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.warning,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TwoFactorInput(
            onCompleted: _onCodeCompleted,
            errorText: _errorText,
            isLoading: _isDisabling,
            isDisabled: _isDisabling,
          ),
          const SizedBox(height: 16),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDisabling ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Отмена',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }

  void _onCodeCompleted(String code) {
    ref.read(twoFactorSetupProvider.notifier).disable(code: code);
  }
}

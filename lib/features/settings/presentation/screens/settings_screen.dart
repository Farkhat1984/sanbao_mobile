/// Settings screen.
///
/// Contains theme toggle (System/Light/Dark), biometric lock toggle,
/// 2FA toggle, notification toggles, language selector, about section,
/// logout, and account deletion (with confirmation dialog).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/config/routes.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_card.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/two_factor_provider.dart';
import 'package:sanbao_flutter/features/auth/presentation/widgets/two_factor_disable_dialog.dart';
import 'package:sanbao_flutter/features/profile/presentation/providers/profile_provider.dart';
import 'package:sanbao_flutter/features/profile/presentation/widgets/locale_selector.dart';
import 'package:sanbao_flutter/features/settings/presentation/providers/settings_provider.dart';
import 'package:sanbao_flutter/features/settings/presentation/widgets/notification_settings.dart';
import 'package:sanbao_flutter/features/settings/presentation/widgets/theme_toggle.dart';

/// Settings screen with all preference controls.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AppearanceSection(),
          const SizedBox(height: 16),
          _SecuritySection(),
          const SizedBox(height: 16),
          _DataSection(),
          const SizedBox(height: 16),
          const NotificationSettingsCard(),
          const SizedBox(height: 16),
          _LanguageSection(),
          const SizedBox(height: 16),
          _AboutSection(),
          const SizedBox(height: 24),
          _DangerSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
}

// ---- Appearance Section ----

class _AppearanceSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final currentMode = ref.watch(themeModeProvider);

    return SanbaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Оформление',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Выберите тему приложения',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          ThemeToggle(
            currentMode: currentMode,
            onModeChanged: (mode) {
              ref.read(themeModeProvider.notifier).setThemeMode(mode);
            },
          ),
        ],
      ),
    );
  }
}

// ---- Security Section ----

class _SecuritySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final is2faEnabled = ref.watch(isTwoFactorEnabledProvider);

    return SanbaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Безопасность',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Biometric lock row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: biometricEnabled
                      ? colors.accentLight
                      : colors.bgSurfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fingerprint_rounded,
                  size: 20,
                  color: biometricEnabled
                      ? colors.accent
                      : colors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Биометрическая блокировка',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Face ID или отпечаток пальца',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: biometricEnabled,
                onChanged: (value) =>
                    _toggleBiometric(context, ref, value),
              ),
            ],
          ),

          // Divider between security settings
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: colors.border,
            ),
          ),

          // 2FA row
          _TwoFactorRow(
            isEnabled: is2faEnabled,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    if (enable) {
      // Verify biometric availability first
      final localAuth = LocalAuthentication();
      final canAuthenticate = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();

      if (!canAuthenticate || !isDeviceSupported) {
        if (context.mounted) {
          context.showErrorSnackBar(
            'Биометрическая аутентификация недоступна на этом устройстве',
          );
        }
        return;
      }

      // Authenticate to enable
      final didAuthenticate = await localAuth.authenticate(
        localizedReason: 'Подтвердите для включения биометрической блокировки',
      );

      if (didAuthenticate) {
        unawaited(ref.read(biometricEnabledProvider.notifier).setEnabled(enabled: true));
      }
    } else {
      unawaited(ref.read(biometricEnabledProvider.notifier).setEnabled(enabled: false));
    }
  }
}

// ---- Two-Factor Authentication Row ----

/// Row showing 2FA status with enable/disable action.
class _TwoFactorRow extends ConsumerWidget {
  const _TwoFactorRow({required this.isEnabled});

  final bool isEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;

    return GestureDetector(
      onTap: () => _handleTap(context, ref),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? colors.accentLight
                  : colors.bgSurfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 20,
              color: isEnabled
                  ? colors.accent
                  : colors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Двухфакторная аутентификация',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEnabled ? 'Включена' : 'Отключена',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: isEnabled ? colors.success : colors.textMuted,
                    fontWeight: isEnabled ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (isEnabled)
            // Disable button
            SanbaoButton(
              label: 'Выключить',
              variant: SanbaoButtonVariant.ghost,
              size: SanbaoButtonSize.small,
              onPressed: () => _handleDisable(context),
            )
          else
            // Enable button
            SanbaoButton(
              label: 'Настроить',
              variant: SanbaoButtonVariant.ghost,
              size: SanbaoButtonSize.small,
              onPressed: () => _navigateToSetup(context),
            ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (isEnabled) {
      _handleDisable(context);
    } else {
      _navigateToSetup(context);
    }
  }

  void _navigateToSetup(BuildContext context) {
    context.push(RoutePaths.twoFactorSetup);
  }

  Future<void> _handleDisable(BuildContext context) async {
    final disabled = await showDisableTwoFactorDialog(context: context);
    if (disabled && context.mounted) {
      context.showSuccessSnackBar('Двухфакторная аутентификация отключена');
    }
  }
}

// ---- Data Section ----

class _DataSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SanbaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Данные',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Knowledge base row
          GestureDetector(
            onTap: () => context.push(RoutePaths.knowledge),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
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
                        'База знаний',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ваши файлы и документы',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: colors.border),
          ),

          // Memory row
          GestureDetector(
            onTap: () => context.push(RoutePaths.memory),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.bgSurfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology_outlined,
                    size: 20,
                    color: colors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Память AI',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Что AI помнит о вас',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Language Section ----

class _LanguageSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final user = ref.watch(currentUserProvider);
    final currentLocale = user?.locale ?? 'ru';

    return SanbaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Язык',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LocaleSelector(
            currentLocale: currentLocale,
            onLocaleChanged: (locale) {
              ref.read(profileProvider.notifier).updateProfile(locale: locale);
            },
          ),
        ],
      ),
    );
  }
}

// ---- About Section ----

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SanbaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'О приложении',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const _AboutRow(
            label: 'Версия',
            value: '${AppConfig.appVersion} (${AppConfig.buildNumber})',
          ),
          const SizedBox(height: 8),
          const _AboutRow(
            label: 'Описание',
            value: AppConfig.appDescription,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // App logo
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [SanbaoColors.gradientStart, SanbaoColors.gradientEnd],
                  ),
                  borderRadius: SanbaoRadius.md,
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.appName,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'AI-платформа для профессионалов',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---- Danger Section ----

class _DangerSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;

    return Column(
      children: [
        // Logout
        SizedBox(
          width: double.infinity,
          child: SanbaoButton(
            label: 'Выйти из аккаунта',
            variant: SanbaoButtonVariant.secondary,
            leadingIcon: Icons.logout_rounded,
            isExpanded: true,
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ),
        const SizedBox(height: 16),
        // Delete account
        SanbaoCard(
          borderColor: colors.error.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: colors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Зона опасности',
                    style: context.textTheme.titleSmall?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Удаление аккаунта необратимо. Все данные, '
                'разговоры и файлы будут уничтожены.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SanbaoButton(
                label: 'Удалить аккаунт',
                variant: SanbaoButtonVariant.ghost,
                size: SanbaoButtonSize.small,
                leadingIcon: Icons.delete_forever_rounded,
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final firstConfirm = await showSanbaoConfirmDialog(
      context: context,
      title: 'Удалить аккаунт?',
      message: 'Это действие необратимо. Все ваши данные, '
          'включая разговоры, файлы и настройки, будут '
          'безвозвратно удалены.',
      confirmLabel: 'Продолжить',
      isDestructive: true,
    );

    if (!firstConfirm || !context.mounted) return;

    // Double confirmation for destructive action
    final secondConfirm = await showSanbaoConfirmDialog(
      context: context,
      title: 'Вы уверены?',
      message: 'Это последнее предупреждение. '
          'Нажмите "Удалить навсегда" для подтверждения.',
      confirmLabel: 'Удалить навсегда',
      isDestructive: true,
    );

    if (!secondConfirm || !context.mounted) return;

    final success =
        await ref.read(profileProvider.notifier).deleteAccount();

    if (success && context.mounted) {
      await ref.read(authStateProvider.notifier).logout();
    } else if (context.mounted) {
      context.showErrorSnackBar('Не удалось удалить аккаунт');
    }
  }
}

/// Settings screen.
///
/// Contains theme toggle (System/Light/Dark), biometric lock toggle,
/// notification toggles, language selector, about section, logout,
/// and account deletion (with confirmation dialog).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_card.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:sanbao_flutter/features/profile/presentation/providers/profile_provider.dart';
import 'package:sanbao_flutter/features/profile/presentation/widgets/locale_selector.dart';
import 'package:sanbao_flutter/features/settings/presentation/providers/settings_provider.dart';
import 'package:sanbao_flutter/features/settings/presentation/widgets/notification_settings.dart';
import 'package:sanbao_flutter/features/settings/presentation/widgets/theme_toggle.dart';

/// Settings screen with all preference controls.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
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
        ref.read(biometricEnabledProvider.notifier).setEnabled(true);
      }
    } else {
      ref.read(biometricEnabledProvider.notifier).setEnabled(false);
    }
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
          _AboutRow(
            label: 'Версия',
            value: '${AppConfig.appVersion} (${AppConfig.buildNumber})',
          ),
          const SizedBox(height: 8),
          _AboutRow(
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
      cancelLabel: 'Отмена',
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
      cancelLabel: 'Отмена',
      isDestructive: true,
    );

    if (!secondConfirm || !context.mounted) return;

    final success =
        await ref.read(profileProvider.notifier).deleteAccount();

    if (success && context.mounted) {
      ref.read(authStateProvider.notifier).logout();
    } else if (context.mounted) {
      context.showErrorSnackBar('Не удалось удалить аккаунт');
    }
  }
}

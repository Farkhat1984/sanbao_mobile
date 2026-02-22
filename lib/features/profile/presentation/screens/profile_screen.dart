/// Profile overview screen.
///
/// Displays the user's large avatar, name, email, locale, subscription
/// tier badge, 2FA status, edit button, and logout button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_avatar.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_card.dart';
import 'package:sanbao_flutter/features/auth/domain/entities/user.dart';
import 'package:sanbao_flutter/features/auth/presentation/providers/auth_provider.dart';

/// Profile overview screen showing user info, subscription, and actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile/edit'),
            icon: Icon(
              Icons.edit_outlined,
              color: colors.accent,
              size: 20,
            ),
            tooltip: 'Редактировать',
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Text(
                'Пользователь не найден',
                style: context.textTheme.bodyLarge?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AvatarSection(user: user),
                const SizedBox(height: 24),
                _InfoSection(user: user),
                const SizedBox(height: 24),
                _SecuritySection(user: user),
                const SizedBox(height: 24),
                _ActionsSection(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

// ---- Avatar & Name Section ----

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Column(
      children: [
        SanbaoAvatar(
          imageUrl: user.image,
          name: user.displayName,
          size: SanbaoAvatarSize.xxl,
        ),
        const SizedBox(height: 16),
        Text(
          user.displayName,
          style: context.textTheme.headlineSmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        _SubscriptionTierBadge(tier: user.subscriptionTier),
      ],
    );
  }
}

class _SubscriptionTierBadge extends StatelessWidget {
  const _SubscriptionTierBadge({required this.tier});

  final SubscriptionTier tier;

  @override
  Widget build(BuildContext context) {
    final (variant, label, icon) = switch (tier) {
      SubscriptionTier.free => (
          SanbaoBadgeVariant.neutral,
          'Бесплатный',
          Icons.star_border_rounded,
        ),
      SubscriptionTier.pro => (
          SanbaoBadgeVariant.accent,
          'Про',
          Icons.workspace_premium_rounded,
        ),
      SubscriptionTier.business => (
          SanbaoBadgeVariant.legal,
          'Бизнес',
          Icons.business_rounded,
        ),
    };

    return SanbaoBadge(
      label: label,
      variant: variant,
      icon: icon,
      size: SanbaoBadgeSize.large,
    );
  }
}

// ---- Info Section ----

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final localeLabel = user.locale == 'ru' ? 'Русский' : 'English';
    final memberSince = user.createdAt != null
        ? DateFormat('dd MMMM yyyy', 'ru').format(user.createdAt!)
        : 'Неизвестно';

    return SanbaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Имя',
            value: user.displayName,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
            trailing: user.emailVerified
                ? Icon(Icons.verified_rounded,
                    size: 16, color: colors.success,)
                : Icon(Icons.warning_amber_rounded,
                    size: 16, color: colors.warning,),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.language_rounded,
            label: 'Язык',
            value: localeLabel,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Участник с',
            value: memberSince,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Роль',
            value: switch (user.role) {
              UserRole.admin => 'Администратор',
              UserRole.pro => 'Про',
              UserRole.user => 'Пользователь',
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      children: [
        Icon(icon, size: 18, color: colors.textMuted),
        const SizedBox(width: 10),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          trailing!,
        ],
      ],
    );
  }
}

// ---- Security Section ----

class _SecuritySection extends StatelessWidget {
  const _SecuritySection({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

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
                  color: user.twoFactorEnabled
                      ? colors.successLight
                      : colors.bgSurfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  user.twoFactorEnabled
                      ? Icons.shield_rounded
                      : Icons.shield_outlined,
                  size: 20,
                  color: user.twoFactorEnabled
                      ? colors.success
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
                      user.twoFactorEnabled ? 'Включена' : 'Отключена',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: user.twoFactorEnabled
                            ? colors.success
                            : colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SanbaoBadge(
                label: user.twoFactorEnabled ? 'Активна' : 'Выкл',
                variant: user.twoFactorEnabled
                    ? SanbaoBadgeVariant.success
                    : SanbaoBadgeVariant.neutral,
                size: SanbaoBadgeSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Actions Section ----

class _ActionsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SanbaoButton(
            label: 'Подписка и оплата',
            variant: SanbaoButtonVariant.secondary,
            leadingIcon: Icons.credit_card_rounded,
            isExpanded: true,
            onPressed: () => context.push('/billing'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SanbaoButton(
            label: 'База знаний',
            variant: SanbaoButtonVariant.secondary,
            leadingIcon: Icons.menu_book_rounded,
            isExpanded: true,
            onPressed: () => context.push('/knowledge'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SanbaoButton(
            label: 'Настройки',
            variant: SanbaoButtonVariant.secondary,
            leadingIcon: Icons.settings_outlined,
            isExpanded: true,
            onPressed: () => context.push('/settings'),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: SanbaoButton(
            label: 'Выйти',
            variant: SanbaoButtonVariant.ghost,
            leadingIcon: Icons.logout_rounded,
            isExpanded: true,
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ),
      ],
    );
}

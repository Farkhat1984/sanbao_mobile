/// Notification preference toggles widget.
///
/// Displays a card with individual switches for global notifications,
/// chat messages, and app updates.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_card.dart';
import 'package:sanbao_flutter/features/settings/presentation/providers/settings_provider.dart';

/// A card displaying notification preference toggles.
class NotificationSettingsCard extends ConsumerWidget {
  const NotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return SanbaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Уведомления',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _SettingsToggle(
            icon: Icons.notifications_outlined,
            title: 'Push-уведомления',
            subtitle: 'Получать уведомления от приложения',
            value: settings.enabled,
            onChanged: (_) => notifier.toggleEnabled(),
          ),
          if (settings.enabled) ...[
            Divider(color: colors.border, height: 24),
            _SettingsToggle(
              icon: Icons.chat_outlined,
              title: 'Сообщения чата',
              subtitle: 'Уведомления о новых ответах',
              value: settings.chatNotifications,
              onChanged: (_) => notifier.toggleChatNotifications(),
            ),
            const SizedBox(height: 12),
            _SettingsToggle(
              icon: Icons.system_update_outlined,
              title: 'Обновления',
              subtitle: 'Уведомления о новых возможностях',
              value: settings.updateNotifications,
              onChanged: (_) => notifier.toggleUpdateNotifications(),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single toggle row with icon, title, subtitle, and switch.
class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.bgSurfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: colors.textMuted),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

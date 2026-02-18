/// Notification list widget shown as a bottom sheet.
///
/// Displays all notifications with read/unread styling,
/// swipe-to-delete, pull-to-refresh, mark-as-read on tap,
/// "mark all as read" action, and empty state.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanbao_flutter/core/config/routes.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/empty_state.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/features/notifications/domain/entities/notification.dart';
import 'package:sanbao_flutter/features/notifications/presentation/providers/notification_provider.dart';

/// Shows the notification list as a bottom sheet.
void showNotificationList({required BuildContext context}) {
  showSanbaoBottomSheet<void>(
    context: context,
    maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    builder: (context) => const _NotificationListContent(),
  );
}

class _NotificationListContent extends ConsumerWidget {
  const _NotificationListContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsListProvider);
    final colors = context.sanbaoColors;
    final hasUnread = ref.watch(hasUnreadNotificationsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Уведомления',
                  style: context.textTheme.headlineSmall,
                ),
              ),
              if (hasUnread)
                TextButton(
                  onPressed: () {
                    ref
                        .read(notificationsListProvider.notifier)
                        .markAllAsRead();
                    HapticFeedback.lightImpact();
                  },
                  child: Text(
                    'Прочитать все',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: colors.accent,
                    ),
                  ),
                ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: colors.textMuted,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Content
        Flexible(
          child: notifications.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => EmptyState.error(
              message: 'Не удалось загрузить уведомления',
              onRetry: () => ref
                  .read(notificationsListProvider.notifier)
                  .refresh(),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'Нет уведомлений',
                  message: 'Здесь будут появляться важные уведомления',
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(notificationsListProvider.notifier)
                      .refresh();
                },
                color: colors.accent,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: colors.border,
                  ),
                  itemBuilder: (context, index) {
                    final notification = items[index];
                    return _DismissibleNotificationItem(
                      notification: notification,
                      onTap: () {
                        if (!notification.isRead) {
                          ref
                              .read(notificationsListProvider.notifier)
                              .markAsRead(notification.id);
                        }
                        _handleNotificationTap(context, notification);
                      },
                      onDismissed: () {
                        ref
                            .read(notificationsListProvider.notifier)
                            .delete(notification.id);
                        HapticFeedback.mediumImpact();
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Navigates to the relevant screen based on the notification type
  /// and associated data (conversation, task, billing, etc.).
  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) {
    // Close the bottom sheet
    Navigator.of(context).pop();

    // Navigate based on notification type and data
    switch (notification.type) {
      case NotificationType.message:
        // Navigate to the conversation
        final conversationId = notification.conversationId ??
            notification.data['conversationId'] as String?;
        if (conversationId != null) {
          context.go('${RoutePaths.chat}/$conversationId');
        }
      case NotificationType.task:
        final taskId = notification.data['taskId'] as String?;
        if (taskId != null) {
          context.push(RoutePaths.tasks);
        }
      case NotificationType.billing:
        context.push(RoutePaths.billing);
      case NotificationType.system:
        // System notifications may link to specific screens
        final targetPath = notification.data['path'] as String?;
        if (targetPath != null) {
          context.push(targetPath);
        }
    }
  }
}

/// Wraps a notification item with Dismissible for swipe-to-delete.
class _DismissibleNotificationItem extends StatelessWidget {
  const _DismissibleNotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.1),
          borderRadius: SanbaoRadius.sm,
        ),
        child: Icon(
          Icons.delete_outline,
          color: colors.error,
          size: 22,
        ),
      ),
      child: _NotificationItem(
        notification: notification,
        onTap: onTap,
      ),
    );
  }
}

/// Individual notification item in the list.
class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: SanbaoRadius.md,
      child: AnimatedContainer(
        duration: SanbaoAnimations.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread
              ? colors.accentLight.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: SanbaoRadius.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _iconBgColor(notification.type, colors),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconForType(notification.type),
                size: 18,
                color: _iconFgColor(notification.type, colors),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatTime(notification.createdAt),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Type label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _iconBgColor(notification.type, colors),
                          borderRadius: SanbaoRadius.sm,
                        ),
                        child: Text(
                          notification.type.label,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: _iconFgColor(notification.type, colors),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Unread dot
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: SanbaoColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForType(NotificationType type) => switch (type) {
        NotificationType.task => Icons.task_alt_outlined,
        NotificationType.message => Icons.chat_bubble_outline,
        NotificationType.system => Icons.info_outline,
        NotificationType.billing => Icons.payment_outlined,
      };

  static Color _iconBgColor(
    NotificationType type,
    SanbaoColorScheme colors,
  ) =>
      switch (type) {
        NotificationType.task => colors.accentLight,
        NotificationType.message => colors.successLight,
        NotificationType.system => colors.infoLight,
        NotificationType.billing => colors.warningLight,
      };

  static Color _iconFgColor(
    NotificationType type,
    SanbaoColorScheme colors,
  ) =>
      switch (type) {
        NotificationType.task => colors.accent,
        NotificationType.message => colors.success,
        NotificationType.system => colors.info,
        NotificationType.billing => colors.warning,
      };

  String _formatTime(DateTime date) {
    if (date.isToday) return date.timeString;
    if (date.isYesterday) return 'Вчера ${date.timeString}';
    final daysAgo = date.daysAgo;
    if (daysAgo < 7) return '$daysAgo дн. назад';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Empty state widget with icon, message, and optional action.
///
/// Used when a list or screen has no content to display.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// A placeholder widget for empty lists, search results, etc.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    super.key,
    this.icon,
    this.title,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
  });

  /// Creates an empty state for no conversations.
  const EmptyState.noConversations({
    super.key,
  })  : icon = Icons.chat_bubble_outline_rounded,
        title = 'Нет диалогов',
        message = 'Начните новый диалог, чтобы он появился здесь',
        actionLabel = 'Новый диалог',
        onAction = null,
        iconSize = 64,
        iconColor = null;

  /// Creates an empty state for no search results.
  const EmptyState.noResults({
    super.key,
  })  : icon = Icons.search_off_rounded,
        title = 'Ничего не найдено',
        message = 'Попробуйте изменить поисковый запрос',
        actionLabel = null,
        onAction = null,
        iconSize = 64,
        iconColor = null;

  /// Creates an empty state for an error.
  factory EmptyState.error({
    Key? key,
    required String message,
    VoidCallback? onRetry,
  }) =>
      EmptyState(
        key: key,
        icon: Icons.error_outline_rounded,
        title: 'Произошла ошибка',
        message: message,
        actionLabel: onRetry != null ? 'Повторить' : null,
        onAction: onRetry,
        iconColor: SanbaoColors.error,
      );

  /// Creates an empty state for no internet connection.
  factory EmptyState.noConnection({
    Key? key,
    VoidCallback? onRetry,
  }) =>
      EmptyState(
        key: key,
        icon: Icons.wifi_off_rounded,
        title: 'Нет подключения',
        message: 'Проверьте подключение к интернету и попробуйте снова',
        actionLabel: 'Повторить',
        onAction: onRetry,
      );

  /// The large icon displayed at the top.
  final IconData? icon;

  /// Optional title text (displayed larger).
  final String? title;

  /// Description/message text.
  final String message;

  /// Optional action button label.
  final String? actionLabel;

  /// Optional action button callback.
  final VoidCallback? onAction;

  /// Size of the icon.
  final double iconSize;

  /// Color override for the icon.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: iconColor ?? colors.textMuted,
              ),
              const SizedBox(height: 24),
            ],
            if (title != null) ...[
              Text(
                title!,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              SanbaoButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: SanbaoButtonVariant.secondary,
                size: SanbaoButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Conversation list entry widget with swipe actions.
///
/// Displays the conversation title, last message preview,
/// timestamp, and supports swipe-to-pin and swipe-to-delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/utils/formatters.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/conversation.dart';

/// A single conversation entry in the sidebar list.
///
/// Supports:
/// - Tap to open
/// - Swipe left to delete
/// - Swipe right to pin/unpin
/// - Long press for context menu
class ConversationItem extends StatelessWidget {
  const ConversationItem({
    required this.conversation,
    super.key,
    this.isSelected = false,
    this.onTap,
    this.onPin,
    this.onArchive,
    this.onDelete,
    this.onRename,
  });

  /// The conversation to display.
  final Conversation conversation;

  /// Whether this conversation is currently selected.
  final bool isSelected;

  /// Callback when the item is tapped.
  final VoidCallback? onTap;

  /// Callback when the pin action is triggered.
  final VoidCallback? onPin;

  /// Callback when the archive action is triggered.
  final VoidCallback? onArchive;

  /// Callback when the delete action is triggered.
  final VoidCallback? onDelete;

  /// Callback when the rename action is triggered.
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Dismissible(
      key: Key(conversation.id),
      background: _buildSwipeBackground(
        color: colors.accent,
        icon: conversation.isPinned
            ? Icons.push_pin_outlined
            : Icons.push_pin_rounded,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: colors.error,
        icon: Icons.delete_rounded,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.lightImpact();
        if (direction == DismissDirection.startToEnd) {
          onPin?.call();
          return false; // Don't dismiss, just pin
        } else {
          return _confirmDelete(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
        }
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap?.call();
        },
        onLongPress: () => _showContextMenu(context),
        child: AnimatedContainer(
          duration: SanbaoAnimations.durationFast,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.accentLight
                : Colors.transparent,
            borderRadius: SanbaoRadius.md,
          ),
          child: Row(
            children: [
              // Agent avatar / conversation icon
              _buildAvatar(context, colors),

              const SizedBox(width: 12),

              // Title and preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        if (conversation.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin_rounded,
                              size: 12,
                              color: colors.accent,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            conversation.title,
                            style: context.textTheme.titleSmall?.copyWith(
                              color: isSelected
                                  ? colors.accent
                                  : colors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Preview text
                    if (conversation.lastMessagePreview != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        conversation.lastMessagePreview!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Timestamp
              Text(
                Formatters.formatRelative(conversation.updatedAt),
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, SanbaoColorScheme colors) {
    if (conversation.hasAgent) {
      final color = conversation.agentColor?.toColor() ?? colors.accent;
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: SanbaoRadius.sm,
        ),
        child: Center(
          child: Text(
            (conversation.agentName ?? 'A').initials,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.accentLight,
        borderRadius: SanbaoRadius.sm,
      ),
      child: Icon(
        Icons.chat_bubble_outline_rounded,
        size: 16,
        color: colors.accent,
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required AlignmentGeometry alignment,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: SanbaoRadius.md,
        ),
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(icon, color: color, size: 22),
      );

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить чат?'),
        content: const Text(
          'Все сообщения будут удалены без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: SanbaoColors.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    final colors = context.sanbaoColors;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                conversation.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                color: colors.accent,
              ),
              title: Text(
                conversation.isPinned ? 'Открепить' : 'Закрепить',
              ),
              onTap: () {
                Navigator.of(context).pop();
                onPin?.call();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.edit_rounded,
                color: colors.textSecondary,
              ),
              title: const Text('Переименовать'),
              onTap: () {
                Navigator.of(context).pop();
                onRename?.call();
              },
            ),
            ListTile(
              leading: Icon(
                conversation.isArchived
                    ? Icons.unarchive_rounded
                    : Icons.archive_rounded,
                color: colors.textSecondary,
              ),
              title: Text(
                conversation.isArchived ? 'Разархивировать' : 'Архивировать',
              ),
              onTap: () {
                Navigator.of(context).pop();
                onArchive?.call();
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.delete_rounded,
                color: colors.error,
              ),
              title: Text(
                'Удалить',
                style: TextStyle(color: colors.error),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                final confirmed = await _confirmDelete(context);
                if (confirmed) onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

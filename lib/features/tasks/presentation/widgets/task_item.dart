/// Task item card for the tasks list.
///
/// Displays task title, status badge, progress bar, and step count.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/features/tasks/domain/entities/task.dart';
import 'package:sanbao_flutter/features/tasks/presentation/widgets/task_progress.dart';

/// A card displaying a task's summary information.
///
/// Shows the title, status badge, circular progress indicator,
/// and step count. Tapping opens the task detail.
class TaskItem extends StatelessWidget {
  const TaskItem({
    required this.task,
    required this.onTap,
    super.key,
  });

  /// The task to display.
  final Task task;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: SanbaoRadius.lg,
          border: Border.all(color: colors.border, width: 0.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Progress indicator
            TaskProgress(task: task, size: 48),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusBadge(status: task.status),
                      const SizedBox(width: 8),
                      if (task.steps.isNotEmpty)
                        Text(
                          '${task.completedStepCount}/${task.steps.length} шагов',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  // Linear progress bar
                  if (task.status == TaskStatus.running) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: SanbaoRadius.full,
                      child: LinearProgressIndicator(
                        value: task.progress > 0 ? task.progress : null,
                        minHeight: 3,
                        backgroundColor: colors.bgSurfaceAlt,
                        color: colors.accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Timestamp
            Text(
              _formatTime(task.createdAt),
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    if (date.isToday) return date.timeString;
    if (date.isYesterday) return 'Вчера';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, variant) = switch (status) {
      TaskStatus.pending => ('Ожидание', SanbaoBadgeVariant.neutral),
      TaskStatus.running => ('Выполняется', SanbaoBadgeVariant.accent),
      TaskStatus.completed => ('Завершена', SanbaoBadgeVariant.success),
      TaskStatus.failed => ('Ошибка', SanbaoBadgeVariant.error),
    };

    return SanbaoBadge(
      label: label,
      variant: variant,
      size: SanbaoBadgeSize.small,
    );
  }
}

/// Circular task progress indicator with percentage.
///
/// Displays a circular progress ring with the completion
/// percentage in the center.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/tasks/domain/entities/task.dart';

/// A circular progress indicator for task completion.
///
/// Shows an animated circular ring with the percentage number
/// in the center. Color changes based on task status.
class TaskProgress extends StatelessWidget {
  const TaskProgress({
    required this.task,
    super.key,
    this.size = 48,
    this.strokeWidth = 3.5,
  });

  /// The task whose progress to display.
  final Task task;

  /// Outer diameter of the progress ring.
  final double size;

  /// Width of the progress stroke.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final progressColor = _colorForStatus(task.status, colors);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: colors.bgSurfaceAlt,
            ),
          ),
          // Progress arc
          SizedBox(
            width: size,
            height: size,
            child: task.status == TaskStatus.running && task.progress <= 0
                ? CircularProgressIndicator(
                    strokeWidth: strokeWidth,
                    color: progressColor,
                  )
                : CircularProgressIndicator(
                    value: task.progress.clamp(0.0, 1.0),
                    strokeWidth: strokeWidth,
                    color: progressColor,
                    strokeCap: StrokeCap.round,
                  ),
          ),
          // Percentage text
          Text(
            '${task.progressPercent}%',
            style: context.textTheme.labelSmall?.copyWith(
              color: progressColor,
              fontWeight: FontWeight.w600,
              fontSize: size * 0.22,
            ),
          ),
        ],
      ),
    );
  }

  static Color _colorForStatus(
    TaskStatus status,
    SanbaoColorScheme colors,
  ) =>
      switch (status) {
        TaskStatus.pending => colors.textMuted,
        TaskStatus.running => colors.accent,
        TaskStatus.completed => colors.success,
        TaskStatus.failed => colors.error,
      };
}

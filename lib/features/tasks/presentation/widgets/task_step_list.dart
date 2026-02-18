/// Expandable task step list widget.
///
/// Displays an ordered list of task steps with status icons
/// and optional output text.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/tasks/domain/entities/task_step.dart';

/// An expandable list of task execution steps.
///
/// Each step shows an icon indicating its status, the step title,
/// and optionally the step output when expanded.
class TaskStepList extends StatelessWidget {
  const TaskStepList({
    required this.steps,
    super.key,
    this.isExpanded = false,
  });

  /// The steps to display.
  final List<TaskStep> steps;

  /// Whether all steps should be shown expanded by default.
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    final colors = context.sanbaoColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Шаги (${steps.length})',
          style: context.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;
          return _StepItem(step: step, isLast: isLast);
        }),
      ],
    );
  }
}

class _StepItem extends StatefulWidget {
  const _StepItem({
    required this.step,
    required this.isLast,
  });

  final TaskStep step;
  final bool isLast;

  @override
  State<_StepItem> createState() => _StepItemState();
}

class _StepItemState extends State<_StepItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final step = widget.step;
    final hasOutput = step.output != null && step.output!.isNotEmpty;

    return GestureDetector(
      onTap: hasOutput ? () => setState(() => _expanded = !_expanded) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status icon column with connecting line
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  _StatusIcon(status: step.status),
                  if (!widget.isLast)
                    Container(
                      width: 1.5,
                      height: _expanded ? 60 : 20,
                      color: colors.border,
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hasOutput)
                        Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 16,
                          color: colors.textMuted,
                        ),
                    ],
                  ),
                  if (_expanded && hasOutput) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.bgSurfaceAlt,
                        borderRadius: SanbaoRadius.sm,
                      ),
                      child: Text(
                        step.output!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontFamily: 'JetBrainsMono',
                          fontSize: 11,
                        ),
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final TaskStepStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return switch (status) {
      TaskStepStatus.pending => Icon(
          Icons.radio_button_unchecked,
          size: 18,
          color: colors.textMuted,
        ),
      TaskStepStatus.running => SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.accent,
          ),
        ),
      TaskStepStatus.completed => Icon(
          Icons.check_circle,
          size: 18,
          color: colors.success,
        ),
      TaskStepStatus.failed => Icon(
          Icons.error,
          size: 18,
          color: colors.error,
        ),
    };
  }
}

/// Animated usage progress bar with label, current/max values.
///
/// Changes color at 80% (warning) and 95% (critical) thresholds.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// An animated progress indicator showing resource usage.
class UsageIndicator extends StatelessWidget {
  const UsageIndicator({
    required this.label,
    required this.currentValue,
    required this.maxValue,
    required this.progress,
    super.key,
    this.formatValue,
  });

  /// Label describing the resource (e.g., "Сообщения").
  final String label;

  /// Current usage value as a formatted string.
  final String currentValue;

  /// Maximum limit as a formatted string.
  final String maxValue;

  /// Progress fraction (0.0 to 1.0).
  final double progress;

  /// Optional custom value formatter.
  final String Function(String current, String max)? formatValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final barColor = _resolveBarColor(colors);
    final trackColor = colors.bgSurfaceAlt;
    final valueText = formatValue?.call(currentValue, maxValue) ??
        '$currentValue / $maxValue';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              valueText,
              style: context.textTheme.bodySmall?.copyWith(
                color: _isWarning ? barColor : colors.textSecondary,
                fontWeight: _isWarning ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _AnimatedProgressBar(
          progress: progress,
          barColor: barColor,
          trackColor: trackColor,
        ),
      ],
    );
  }

  bool get _isWarning => progress >= 0.8;
  bool get _isCritical => progress >= 0.95;

  Color _resolveBarColor(SanbaoColorScheme colors) {
    if (_isCritical) return colors.error;
    if (_isWarning) return colors.warning;
    return colors.accent;
  }
}

/// Animates the progress bar fill on mount and value changes.
class _AnimatedProgressBar extends StatefulWidget {
  const _AnimatedProgressBar({
    required this.progress,
    required this.barColor,
    required this.trackColor,
  });

  final double progress;
  final Color barColor;
  final Color trackColor;

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationSlow,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(
      CurvedAnimation(parent: _controller, curve: SanbaoAnimations.smoothCurve),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = _progressAnimation.value;
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: SanbaoAnimations.smoothCurve,
        ),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) => Container(
          height: 8,
          decoration: BoxDecoration(
            color: widget.trackColor,
            borderRadius: SanbaoRadius.full,
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: SanbaoAnimations.durationFast,
                decoration: BoxDecoration(
                  color: widget.barColor,
                  borderRadius: SanbaoRadius.full,
                ),
              ),
            ),
          ),
        ),
      );
}

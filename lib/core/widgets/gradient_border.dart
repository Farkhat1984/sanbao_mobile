/// Animated gradient border for the chat input field.
///
/// Rotates a conic gradient around the border using a custom painter,
/// matching the web's `gradient-border-animated` CSS class.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';

/// A widget that wraps its child with an animated rotating gradient border.
///
/// Used primarily around the chat input field to indicate focus state.
class GradientBorder extends StatefulWidget {
  const GradientBorder({
    required this.child,
    super.key,
    this.isActive = false,
    this.borderRadius,
    this.strokeWidth = 1.5,
    this.opacity = 0.45,
    this.activeOpacity = 1.0,
    this.rotationDuration = const Duration(seconds: 4),
    this.colors,
  });

  /// The child widget to wrap with the gradient border.
  final Widget child;

  /// Whether the gradient border is active (e.g., input is focused).
  final bool isActive;

  /// Border radius. Defaults to chat input radius (32px).
  final BorderRadius? borderRadius;

  /// Width of the gradient border stroke.
  final double strokeWidth;

  /// Opacity when inactive.
  final double opacity;

  /// Opacity when active.
  final double activeOpacity;

  /// Duration for one full rotation.
  final Duration rotationDuration;

  /// Gradient colors. Defaults to the animated border palette.
  final List<Color>? colors;

  @override
  State<GradientBorder> createState() => _GradientBorderState();
}

class _GradientBorderState extends State<GradientBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: widget.rotationDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? SanbaoRadius.input;

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) => AnimatedOpacity(
        opacity: widget.isActive ? widget.activeOpacity : widget.opacity,
        duration: SanbaoAnimations.durationNormal,
        curve: SanbaoAnimations.smoothCurve,
        child: CustomPaint(
          painter: _GradientBorderPainter(
            angle: _rotationController.value * 2 * math.pi,
            borderRadius: effectiveRadius,
            strokeWidth: widget.strokeWidth,
            colors: widget.colors ?? SanbaoColors.animatedBorderColors,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.strokeWidth),
            child: child,
          ),
        ),
      ),
      child: widget.child,
    );
  }
}

/// Custom painter that draws a rotating conic gradient border.
class _GradientBorderPainter extends CustomPainter {
  _GradientBorderPainter({
    required this.angle,
    required this.borderRadius,
    required this.strokeWidth,
    required this.colors,
  });

  final double angle;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    // Create conic gradient starting from the current angle
    final gradient = SweepGradient(
      startAngle: angle,
      endAngle: angle + 2 * math.pi,
      colors: colors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) =>
      angle != oldDelegate.angle ||
      strokeWidth != oldDelegate.strokeWidth;
}

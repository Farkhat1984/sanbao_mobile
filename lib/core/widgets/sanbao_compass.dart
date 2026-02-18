/// Animated compass/scales icon for the Sanbao brand.
///
/// Supports three states:
/// - idle: static scales icon
/// - loading: smooth rotation
/// - thinking: wobble animation (+/-8 degrees over 2s)
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';

/// Animation state for the compass/scales icon.
enum CompassState {
  /// Static, no animation.
  idle,

  /// Smooth continuous rotation (loading/connecting).
  loading,

  /// Wobble animation (AI is thinking/generating).
  thinking,
}

/// An animated scales/compass icon representing the Sanbao brand.
///
/// The icon animates between idle, loading, and thinking states
/// with smooth transitions.
class SanbaoCompass extends StatefulWidget {
  const SanbaoCompass({
    super.key,
    this.state = CompassState.idle,
    this.size = 24,
    this.color,
  });

  /// Current animation state.
  final CompassState state;

  /// Icon size in logical pixels.
  final double size;

  /// Icon color override.
  final Color? color;

  @override
  State<SanbaoCompass> createState() => _SanbaoCompassState();
}

class _SanbaoCompassState extends State<SanbaoCompass>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _thinkingController;

  @override
  void initState() {
    super.initState();

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _thinkingController = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.thinkingDuration,
    );

    _updateAnimationState();
  }

  @override
  void didUpdateWidget(SanbaoCompass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    switch (widget.state) {
      case CompassState.idle:
        _loadingController.stop();
        _thinkingController.stop();
        _loadingController.reset();
        _thinkingController.reset();
      case CompassState.loading:
        _thinkingController.stop();
        _thinkingController.reset();
        _loadingController.repeat();
      case CompassState.thinking:
        _loadingController.stop();
        _loadingController.reset();
        _thinkingController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _thinkingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? SanbaoColors.accent;

    return AnimatedBuilder(
      animation: Listenable.merge([_loadingController, _thinkingController]),
      builder: (context, child) {
        double rotation = 0;

        if (widget.state == CompassState.loading) {
          rotation = _loadingController.value * 2 * math.pi;
        } else if (widget.state == CompassState.thinking) {
          // Wobble: sine wave between -8 and +8 degrees
          final maxAngle = SanbaoAnimations.thinkingMaxRotation * math.pi / 180;
          rotation = math.sin(_thinkingController.value * 2 * math.pi) *
              maxAngle;
        }

        return Transform.rotate(
          angle: rotation,
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _ScalesIconPainter(color: color),
      ),
    );
  }
}

/// Custom painter for the scales/balance icon.
class _ScalesIconPainter extends CustomPainter {
  _ScalesIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Stand/pillar
    canvas.drawLine(
      Offset(cx, h * 0.15),
      Offset(cx, h * 0.85),
      paint,
    );

    // Base
    canvas.drawLine(
      Offset(cx - w * 0.2, h * 0.85),
      Offset(cx + w * 0.2, h * 0.85),
      paint,
    );

    // Beam (horizontal bar)
    canvas.drawLine(
      Offset(w * 0.1, h * 0.25),
      Offset(w * 0.9, h * 0.25),
      paint,
    );

    // Top triangle/pivot
    final pivotPath = Path()
      ..moveTo(cx - w * 0.06, h * 0.2)
      ..lineTo(cx, h * 0.12)
      ..lineTo(cx + w * 0.06, h * 0.2);
    canvas.drawPath(pivotPath, paint);

    // Left pan strings
    canvas.drawLine(
      Offset(w * 0.15, h * 0.25),
      Offset(w * 0.1, h * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.15, h * 0.25),
      Offset(w * 0.3, h * 0.5),
      paint,
    );

    // Left pan (arc)
    final leftPan = Path()
      ..moveTo(w * 0.05, h * 0.5)
      ..quadraticBezierTo(w * 0.2, h * 0.6, w * 0.35, h * 0.5);
    canvas.drawPath(leftPan, paint);

    // Right pan strings
    canvas.drawLine(
      Offset(w * 0.85, h * 0.25),
      Offset(w * 0.7, h * 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.85, h * 0.25),
      Offset(w * 0.9, h * 0.5),
      paint,
    );

    // Right pan (arc)
    final rightPan = Path()
      ..moveTo(w * 0.65, h * 0.5)
      ..quadraticBezierTo(w * 0.8, h * 0.6, w * 0.95, h * 0.5);
    canvas.drawPath(rightPan, paint);
  }

  @override
  bool shouldRepaint(_ScalesIconPainter oldDelegate) =>
      color != oldDelegate.color;
}

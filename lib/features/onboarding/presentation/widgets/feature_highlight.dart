/// Feature highlight card for onboarding steps.
///
/// Displays an icon with a label in a glass-styled card,
/// used to illustrate key features during the onboarding flow.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// A compact card highlighting a single feature with icon and text.
///
/// Used in the onboarding step illustrations to show
/// capabilities like chat, agents, documents, etc.
class FeatureHighlight extends StatelessWidget {
  const FeatureHighlight({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
    this.delay = Duration.zero,
  });

  /// The icon representing the feature.
  final IconData icon;

  /// Short label describing the feature.
  final String label;

  /// Accent color for the icon background.
  final Color color;

  /// Stagger delay for enter animation.
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return _AnimatedEntry(
      delay: delay,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: SanbaoRadius.md,
          border: Border.all(
            color: colors.border.withValues(alpha: 0.7),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: SanbaoRadius.sm,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Staggered fade-slide entry animation for feature highlights.
class _AnimatedEntry extends StatefulWidget {
  const _AnimatedEntry({
    required this.delay,
    required this.child,
  });

  final Duration delay;
  final Widget child;

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationSlow,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: SanbaoAnimations.smoothCurve,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: SanbaoAnimations.smoothCurve,
    ));

    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

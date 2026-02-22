/// Single onboarding step widget with animated content.
///
/// Displays a large illustration area at the top, followed by
/// a title and description. Animates in when the page becomes visible.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// A single page/step in the onboarding flow.
///
/// Contains an illustration [child] at the top (occupying ~55% of height),
/// a bold [title], and a descriptive [subtitle] below.
class OnboardingStep extends StatefulWidget {
  const OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  /// The main heading for this step.
  final String title;

  /// Descriptive text below the title.
  final String subtitle;

  /// Illustration widget (icons, animations, etc.).
  final Widget child;

  @override
  State<OnboardingStep> createState() => _OnboardingStepState();
}

class _OnboardingStepState extends State<OnboardingStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationSlow,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: SanbaoAnimations.smoothCurve,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: SanbaoAnimations.smoothCurve,
    ),);

    // Start animation after a brief delay for page transition
    Future<void>.delayed(const Duration(milliseconds: 100), () {
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
    final colors = context.sanbaoColors;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              // Illustration area -- flexible to fill available space
              Expanded(
                flex: 55,
                child: Center(child: widget.child),
              ),

              // Text area
              Expanded(
                flex: 45,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        widget.subtitle,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for image generation.
///
/// Shows a skeleton image area with animated shimmer effect
/// and a "generating" status message.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:shimmer/shimmer.dart';

/// Animated loading indicator shown while an image is being generated.
///
/// Displays a shimmer-animated placeholder box with a pulsing
/// sparkles icon and status text.
class ImageGenLoading extends StatefulWidget {
  const ImageGenLoading({super.key});

  @override
  State<ImageGenLoading> createState() => _ImageGenLoadingState();
}

class _ImageGenLoadingState extends State<ImageGenLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: SanbaoAnimations.smoothCurve,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final baseColor = colors.bgSurfaceAlt;
    final highlightColor = colors.bgSurfaceHover;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ГЕНЕРАЦИЯ',
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Shimmer placeholder
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: SanbaoRadius.md,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Status indicator
        Center(
          child: FadeTransition(
            opacity: _pulseAnimation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Генерация изображения...',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

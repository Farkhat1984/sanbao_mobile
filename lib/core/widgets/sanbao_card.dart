/// Sanbao card widget with shadow and 16px radius.
///
/// A surface container for grouping content with optional
/// border, shadow, and tap handler.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Elevation presets for the card.
enum SanbaoCardElevation {
  /// No shadow, border only.
  flat,

  /// Subtle shadow.
  low,

  /// Standard card shadow.
  medium,

  /// Modal/popup level shadow.
  high,
}

/// A styled card following the Sanbao design system.
class SanbaoCard extends StatelessWidget {
  const SanbaoCard({
    super.key,
    this.child,
    this.elevation = SanbaoCardElevation.flat,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.showBorder = true,
    this.onTap,
    this.onLongPress,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Card content.
  final Widget? child;

  /// Shadow elevation preset.
  final SanbaoCardElevation elevation;

  /// Inner padding. Defaults to 16px.
  final EdgeInsets? padding;

  /// Outer margin.
  final EdgeInsets? margin;

  /// Border radius. Defaults to 16px (SanbaoRadius.lg).
  final BorderRadius? borderRadius;

  /// Background color. Defaults to bgSurface.
  final Color? color;

  /// Border color override.
  final Color? borderColor;

  /// Whether to show the border.
  final bool showBorder;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long press callback.
  final VoidCallback? onLongPress;

  /// Fixed width.
  final double? width;

  /// Fixed height.
  final double? height;

  /// Clip behavior for the card.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final effectiveRadius = borderRadius ?? SanbaoRadius.lg;

    final shadows = switch (elevation) {
      SanbaoCardElevation.flat => SanbaoShadows.none,
      SanbaoCardElevation.low => SanbaoShadows.sm,
      SanbaoCardElevation.medium => SanbaoShadows.md,
      SanbaoCardElevation.high => SanbaoShadows.lg,
    };

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? colors.bgSurface,
        borderRadius: effectiveRadius,
        border: showBorder
            ? Border.all(
                color: borderColor ?? colors.border,
                width: 0.5,
              )
            : null,
        boxShadow: shadows,
      ),
      clipBehavior: clipBehavior,
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
    );

    if (onTap != null || onLongPress != null) {
      card = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: card,
      );
    }

    return card;
  }
}

/// Glassmorphism container widget.
///
/// Applies backdrop blur with a semi-transparent background,
/// matching the sidebar glass effect from the web design system.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// A container with glassmorphism (backdrop blur) effect.
///
/// Used for the sidebar, floating panels, and overlay containers.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    this.child,
    this.blur = 16.0,
    this.opacity = 0.75,
    this.borderRadius,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.showBorder = true,
    this.width,
    this.height,
  });

  /// Content inside the glass container.
  final Widget? child;

  /// Blur radius for the backdrop filter.
  final double blur;

  /// Opacity of the background color (0-1).
  final double opacity;

  /// Border radius. Defaults to 16px.
  final BorderRadius? borderRadius;

  /// Inner padding.
  final EdgeInsets? padding;

  /// Outer margin.
  final EdgeInsets? margin;

  /// Background color override. Defaults to bgSurfaceAlt with [opacity].
  final Color? color;

  /// Border color override.
  final Color? borderColor;

  /// Whether to show a border.
  final bool showBorder;

  /// Fixed width.
  final double? width;

  /// Fixed height.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final effectiveRadius = borderRadius ?? SanbaoRadius.lg;
    final bgColor =
        (color ?? colors.bgSurfaceAlt).withValues(alpha: opacity);

    return Container(
      width: width,
      height: height,
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: effectiveRadius,
            border: showBorder
                ? Border.all(
                    color: borderColor ??
                        colors.border.withValues(alpha: 0.5),
                    width: 0.5,
                  )
                : null,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

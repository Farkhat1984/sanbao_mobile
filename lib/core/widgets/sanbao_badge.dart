/// Sanbao status badge widget with 6 variants.
///
/// Used for status indicators, tags, and labels throughout the app.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Visual variant of the badge.
enum SanbaoBadgeVariant {
  /// Blue accent badge (default, active states).
  accent,

  /// Green success badge.
  success,

  /// Yellow warning badge.
  warning,

  /// Red error badge.
  error,

  /// Purple legal reference badge.
  legal,

  /// Grey neutral badge (muted, inactive).
  neutral,
}

/// A styled status badge following the Sanbao design system.
class SanbaoBadge extends StatelessWidget {
  const SanbaoBadge({
    required this.label,
    super.key,
    this.variant = SanbaoBadgeVariant.accent,
    this.icon,
    this.onTap,
    this.size = SanbaoBadgeSize.medium,
  });

  /// The badge label text.
  final String label;

  /// Visual variant.
  final SanbaoBadgeVariant variant;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Size preset.
  final SanbaoBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final (bgColor, fgColor) = _resolveColors(colors);
    final sizing = _resolveSizing();

    Widget badge = Container(
      padding: sizing.padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: SanbaoRadius.md,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: sizing.iconSize, color: fgColor),
            SizedBox(width: sizing.gap),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: sizing.fontSize,
              fontWeight: FontWeight.w500,
              color: fgColor,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      badge = GestureDetector(onTap: onTap, child: badge);
    }

    return badge;
  }

  (Color bg, Color fg) _resolveColors(SanbaoColorScheme colors) =>
      switch (variant) {
        SanbaoBadgeVariant.accent => (colors.accentLight, colors.accent),
        SanbaoBadgeVariant.success => (colors.successLight, colors.success),
        SanbaoBadgeVariant.warning => (colors.warningLight, colors.warning),
        SanbaoBadgeVariant.error => (colors.errorLight, colors.error),
        SanbaoBadgeVariant.legal => (colors.legalRefBg, colors.legalRef),
        SanbaoBadgeVariant.neutral => (colors.bgSurfaceAlt, colors.textMuted),
      };

  _BadgeSizing _resolveSizing() => switch (size) {
        SanbaoBadgeSize.small => const _BadgeSizing(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            fontSize: 11,
            iconSize: 12,
            gap: 4,
          ),
        SanbaoBadgeSize.medium => const _BadgeSizing(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            fontSize: 12,
            iconSize: 14,
            gap: 4,
          ),
        SanbaoBadgeSize.large => const _BadgeSizing(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            fontSize: 13,
            iconSize: 16,
            gap: 6,
          ),
      };
}

/// Size preset for the badge.
enum SanbaoBadgeSize {
  small,
  medium,
  large,
}

class _BadgeSizing {
  const _BadgeSizing({
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.gap,
  });

  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double gap;
}

/// A small dot indicator, used for unread counts or status.
class SanbaoDot extends StatelessWidget {
  const SanbaoDot({
    super.key,
    this.color,
    this.size = 8,
  });

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? context.sanbaoColors.accent,
          shape: BoxShape.circle,
        ),
      );
}

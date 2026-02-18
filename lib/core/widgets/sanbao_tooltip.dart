/// Sanbao tooltip wrapper with consistent styling.
///
/// Provides a themed tooltip that matches the design system.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// A themed tooltip wrapper following the Sanbao design system.
class SanbaoTooltip extends StatelessWidget {
  const SanbaoTooltip({
    required this.message,
    required this.child,
    super.key,
    this.preferBelow = true,
    this.showDuration,
    this.waitDuration,
  });

  /// The tooltip message text.
  final String message;

  /// The widget that triggers the tooltip.
  final Widget child;

  /// Whether to prefer showing the tooltip below the widget.
  final bool preferBelow;

  /// How long to show the tooltip.
  final Duration? showDuration;

  /// How long to wait before showing the tooltip.
  final Duration? waitDuration;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      showDuration: showDuration,
      waitDuration: waitDuration ?? const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: colors.textPrimary,
        borderRadius: SanbaoRadius.sm,
        boxShadow: SanbaoShadows.md,
      ),
      textStyle: context.textTheme.bodySmall?.copyWith(
        color: colors.textInverse,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }
}

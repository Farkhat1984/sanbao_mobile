/// Purple legal reference badge widget.
///
/// Displays a clickable badge for legal article references
/// (e.g., "ст. 188 УК РК") with the characteristic purple
/// color from the Sanbao design system.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/typography.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// A purple badge for legal article references.
///
/// Styled with the `legalRef` color from the design system,
/// it shows the article code in a monospaced font and
/// supports tap interaction for navigation.
class LegalRefBadge extends StatelessWidget {
  const LegalRefBadge({
    required this.displayText,
    super.key,
    this.codeName,
    this.article,
    this.onTap,
  });

  /// The display text (e.g., "ст. 188 УК РК").
  final String displayText;

  /// The code name (e.g., "criminal_code").
  final String? codeName;

  /// The article number (e.g., "188").
  final String? article;

  /// Callback when the badge is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.legalRefBg,
          borderRadius: SanbaoRadius.sm,
          border: Border.all(
            color: colors.legalRef.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gavel_rounded,
              size: 12,
              color: colors.legalRef,
            ),
            const SizedBox(width: 4),
            Text(
              displayText,
              style: SanbaoTypography.legalCodeStyle(
                color: colors.legalRef,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

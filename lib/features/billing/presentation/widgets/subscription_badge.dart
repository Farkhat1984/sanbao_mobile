/// Subscription status badge widget.
///
/// Displays the subscription status with color-coded styling:
/// active=green, canceled=red, past_due=orange, trialing=blue.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/subscription.dart';

/// A badge that displays the subscription status with semantic coloring.
class SubscriptionBadge extends StatelessWidget {
  const SubscriptionBadge({
    required this.status,
    super.key,
    this.size = SanbaoBadgeSize.medium,
  });

  /// The subscription status to display.
  final SubscriptionStatus status;

  /// Badge size preset.
  final SanbaoBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final (variant, icon) = _resolveStyle();

    return SanbaoBadge(
      label: status.displayLabel,
      variant: variant,
      icon: icon,
      size: size,
    );
  }

  (SanbaoBadgeVariant, IconData) _resolveStyle() => switch (status) {
        SubscriptionStatus.active => (
            SanbaoBadgeVariant.success,
            Icons.check_circle_outline,
          ),
        SubscriptionStatus.canceled => (
            SanbaoBadgeVariant.error,
            Icons.cancel_outlined,
          ),
        SubscriptionStatus.pastDue => (
            SanbaoBadgeVariant.warning,
            Icons.warning_amber_rounded,
          ),
        SubscriptionStatus.trialing => (
            SanbaoBadgeVariant.accent,
            Icons.science_outlined,
          ),
      };
}

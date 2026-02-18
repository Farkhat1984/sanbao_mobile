/// Data model for subscriptions.
///
/// Handles JSON serialization/deserialization for the Subscription entity.
library;

import 'package:sanbao_flutter/features/billing/data/models/plan_model.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/subscription.dart';

/// Data transfer model for [Subscription].
class SubscriptionModel {
  const SubscriptionModel._({required this.subscription});

  /// Parses a [SubscriptionModel] from a JSON map.
  factory SubscriptionModel.fromJson(Map<String, Object?> json) {
    final planJson = json['plan'] as Map<String, Object?>?;
    Plan? plan;
    if (planJson != null) {
      plan = PlanModel.fromJson(planJson).plan;
    }

    return SubscriptionModel._(
      subscription: Subscription(
        id: json['id'] as String? ?? '',
        planId: json['planId'] as String? ?? '',
        plan: plan,
        status: SubscriptionStatus.fromString(
          json['status'] as String? ?? 'active',
        ),
        currentPeriodStart: DateTime.tryParse(
              json['currentPeriodStart'] as String? ?? '',
            ) ??
            DateTime.now(),
        currentPeriodEnd: DateTime.tryParse(
              json['currentPeriodEnd'] as String? ?? '',
            ) ??
            DateTime.now().add(const Duration(days: 30)),
        cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool? ?? false,
      ),
    );
  }

  /// The deserialized subscription entity.
  final Subscription subscription;

  /// Serializes to JSON map.
  Map<String, Object?> toJson() => {
        'id': subscription.id,
        'planId': subscription.planId,
        'status': subscription.status.toJson(),
        'currentPeriodStart':
            subscription.currentPeriodStart.toIso8601String(),
        'currentPeriodEnd': subscription.currentPeriodEnd.toIso8601String(),
        'cancelAtPeriodEnd': subscription.cancelAtPeriodEnd,
      };
}

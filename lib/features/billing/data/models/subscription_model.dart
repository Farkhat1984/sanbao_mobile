/// Data model for subscriptions.
///
/// Handles JSON serialization/deserialization for the Subscription entity.
/// Supports both the legacy format (`{id, planId, status, currentPeriodStart}`)
/// and the backend /api/billing/current format (`{grantedAt, expiresAt, isTrial}`).
library;

import 'package:sanbao_flutter/features/billing/data/models/plan_model.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/subscription.dart';

/// Data transfer model for [Subscription].
class SubscriptionModel {
  const SubscriptionModel._({required this.subscription});

  /// Parses a [SubscriptionModel] from a JSON map.
  ///
  /// Backend /api/billing/current returns:
  /// `{grantedAt, expiresAt, trialEndsAt, isTrial}`
  factory SubscriptionModel.fromJson(Map<String, Object?> json) {
    final planJson = json['plan'] as Map<String, Object?>?;
    Plan? plan;
    if (planJson != null) {
      plan = PlanModel.fromJson(planJson).plan;
    }

    // Determine period dates: prefer legacy keys, fall back to backend keys
    final DateTime currentPeriodStart;
    if (json['currentPeriodStart'] is String) {
      currentPeriodStart =
          DateTime.tryParse(json['currentPeriodStart'] as String) ??
              DateTime.now();
    } else if (json['grantedAt'] is String) {
      currentPeriodStart =
          DateTime.tryParse(json['grantedAt'] as String) ?? DateTime.now();
    } else {
      currentPeriodStart = DateTime.now();
    }

    final DateTime currentPeriodEnd;
    if (json['currentPeriodEnd'] is String) {
      currentPeriodEnd =
          DateTime.tryParse(json['currentPeriodEnd'] as String) ??
              DateTime.now().add(const Duration(days: 30));
    } else if (json['expiresAt'] is String) {
      currentPeriodEnd =
          DateTime.tryParse(json['expiresAt'] as String) ??
              currentPeriodStart.add(const Duration(days: 30));
    } else {
      currentPeriodEnd = currentPeriodStart.add(const Duration(days: 30));
    }

    // Determine status from backend fields
    final SubscriptionStatus status;
    if (json['status'] is String) {
      status = SubscriptionStatus.fromString(json['status']! as String);
    } else {
      final isTrial = json['isTrial'] as bool? ?? false;
      final expired = json['expired'] as bool? ?? false;
      if (expired) {
        status = SubscriptionStatus.canceled;
      } else if (isTrial) {
        status = SubscriptionStatus.trialing;
      } else {
        status = SubscriptionStatus.active;
      }
    }

    return SubscriptionModel._(
      subscription: Subscription(
        id: json['id'] as String? ?? '',
        planId: json['planId'] as String? ?? '',
        plan: plan,
        status: status,
        currentPeriodStart: currentPeriodStart,
        currentPeriodEnd: currentPeriodEnd,
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

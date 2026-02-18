/// Subscription entity.
///
/// Represents the user's current subscription with status tracking,
/// period info, and cancellation state.
library;

import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';

/// Status of a subscription.
enum SubscriptionStatus {
  /// Subscription is active and in good standing.
  active,

  /// Subscription has been cancelled but still active until period end.
  canceled,

  /// Payment is overdue.
  pastDue,

  /// Subscription is in trial period.
  trialing;

  /// Parses a [SubscriptionStatus] from a string.
  static SubscriptionStatus fromString(String value) =>
      switch (value.toLowerCase().replaceAll('_', '')) {
        'active' => SubscriptionStatus.active,
        'canceled' || 'cancelled' => SubscriptionStatus.canceled,
        'pastdue' => SubscriptionStatus.pastDue,
        'trialing' || 'trial' => SubscriptionStatus.trialing,
        _ => SubscriptionStatus.active,
      };

  /// Returns the serialized string.
  String toJson() => switch (this) {
        SubscriptionStatus.active => 'active',
        SubscriptionStatus.canceled => 'canceled',
        SubscriptionStatus.pastDue => 'past_due',
        SubscriptionStatus.trialing => 'trialing',
      };

  /// Russian display label.
  String get displayLabel => switch (this) {
        SubscriptionStatus.active => 'Активна',
        SubscriptionStatus.canceled => 'Отменена',
        SubscriptionStatus.pastDue => 'Просрочена',
        SubscriptionStatus.trialing => 'Пробный период',
      };
}

/// Immutable representation of a user's subscription.
class Subscription {
  const Subscription({
    required this.id,
    required this.planId,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.plan,
    this.cancelAtPeriodEnd = false,
  });

  /// Unique subscription identifier.
  final String id;

  /// The plan this subscription is for.
  final String planId;

  /// Full plan details (may be null if not loaded).
  final Plan? plan;

  /// Current status of the subscription.
  final SubscriptionStatus status;

  /// Start of the current billing period.
  final DateTime currentPeriodStart;

  /// End of the current billing period.
  final DateTime currentPeriodEnd;

  /// Whether the subscription will be cancelled at the end of the period.
  final bool cancelAtPeriodEnd;

  /// Whether the subscription is currently usable.
  bool get isActive =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.trialing;

  /// Days remaining in the current period.
  int get daysRemaining {
    final now = DateTime.now();
    if (currentPeriodEnd.isBefore(now)) return 0;
    return currentPeriodEnd.difference(now).inDays;
  }

  /// Creates a copy with given fields replaced.
  Subscription copyWith({
    String? id,
    String? planId,
    Plan? plan,
    SubscriptionStatus? status,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    bool? cancelAtPeriodEnd,
  }) =>
      Subscription(
        id: id ?? this.id,
        planId: planId ?? this.planId,
        plan: plan ?? this.plan,
        status: status ?? this.status,
        currentPeriodStart: currentPeriodStart ?? this.currentPeriodStart,
        currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
        cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subscription && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Subscription(id=$id, planId=$planId, status=${status.name})';
}

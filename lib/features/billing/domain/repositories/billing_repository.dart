/// Abstract billing repository.
///
/// Defines the contract for all billing operations including
/// plan retrieval, subscription management, and payment history.
library;

import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/subscription.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/usage.dart';

/// Contract for billing data access.
abstract class BillingRepository {
  /// Fetches all available plans.
  Future<List<Plan>> getPlans();

  /// Fetches the current user's subscription.
  ///
  /// Returns null if the user is on the free tier with no subscription record.
  Future<Subscription?> getCurrentSubscription();

  /// Fetches the current user's usage for this billing period.
  Future<Usage> getUsage();

  /// Creates a Stripe checkout session URL for upgrading to [planId].
  ///
  /// The returned URL should be opened in the system browser.
  Future<String> createCheckoutUrl({required String planId});

  /// Cancels the current subscription.
  ///
  /// The subscription remains active until the end of the current period.
  Future<void> cancelSubscription();

  /// Fetches the user's payment history.
  Future<List<PaymentHistoryItem>> getPaymentHistory();
}

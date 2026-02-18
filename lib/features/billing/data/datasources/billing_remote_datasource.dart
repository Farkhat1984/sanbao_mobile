/// Remote data source for billing operations.
///
/// Handles all billing-related API calls to /api/billing endpoints.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/billing/data/models/plan_model.dart';
import 'package:sanbao_flutter/features/billing/data/models/subscription_model.dart';
import 'package:sanbao_flutter/features/billing/data/models/usage_model.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/subscription.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/usage.dart';

/// Remote data source for billing operations via the REST API.
class BillingRemoteDataSource {
  BillingRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  static String get _basePath => AppConfig.billingEndpoint;

  /// Fetches all available plans.
  ///
  /// GET /api/billing/plans
  Future<List<Plan>> getPlans() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '$_basePath/plans',
    );

    final plansJson = response['plans'] as List<Object?>? ??
        response['data'] as List<Object?>? ??
        [];

    return PlanModel.fromJsonList(plansJson);
  }

  /// Fetches the current user's subscription.
  ///
  /// GET /api/billing/subscription
  Future<Subscription?> getCurrentSubscription() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '$_basePath/subscription',
    );

    final subJson = response['subscription'] as Map<String, Object?>? ??
        (response.containsKey('id') ? response : null);

    if (subJson == null) return null;

    return SubscriptionModel.fromJson(subJson).subscription;
  }

  /// Fetches the current user's usage for this billing period.
  ///
  /// GET /api/billing/usage
  Future<Usage> getUsage() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '$_basePath/usage',
    );

    final usageJson = response['usage'] as Map<String, Object?>? ??
        (response.containsKey('messagesUsed') ? response : null) ??
        {};

    return UsageModel.fromJson(usageJson).usage;
  }

  /// Creates a Stripe checkout session URL.
  ///
  /// POST /api/billing/checkout
  Future<String> createCheckoutUrl({required String planId}) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '$_basePath/checkout',
      data: {'planId': planId},
    );

    return response['url'] as String? ??
        response['checkoutUrl'] as String? ??
        '';
  }

  /// Cancels the current subscription.
  ///
  /// POST /api/billing/cancel
  Future<void> cancelSubscription() async {
    await _dioClient.post<Map<String, Object?>>(
      '$_basePath/cancel',
    );
  }

  /// Fetches the user's payment history.
  ///
  /// GET /api/billing/history
  Future<List<PaymentHistoryItem>> getPaymentHistory() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '$_basePath/history',
    );

    final historyJson = response['payments'] as List<Object?>? ??
        response['history'] as List<Object?>? ??
        response['data'] as List<Object?>? ??
        [];

    return PaymentHistoryItemModel.fromJsonList(historyJson);
  }
}

/// Riverpod provider for [BillingRemoteDataSource].
final billingRemoteDataSourceProvider =
    Provider<BillingRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return BillingRemoteDataSource(dioClient: dioClient);
});

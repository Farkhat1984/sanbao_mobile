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
import 'package:sanbao_flutter/features/billing/domain/repositories/billing_repository.dart';

/// Remote data source for billing operations via the REST API.
class BillingRemoteDataSource {
  BillingRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  static String get _basePath => AppConfig.billingEndpoint;

  /// Fetches all available plans.
  ///
  /// GET /api/billing/plans → JSON array of plan objects.
  Future<List<Plan>> getPlans() async {
    final response = await _dioClient.get<List<dynamic>>(
      '$_basePath/plans',
    );

    return PlanModel.fromJsonList(response.cast<Object?>());
  }

  /// Fetches the current user's subscription from the combined endpoint.
  ///
  /// GET /api/billing/current → {plan, subscription, usage, monthlyUsage, expired}
  Future<Subscription?> getCurrentSubscription() async {
    final current = await _fetchCurrent();
    final subJson = current['subscription'] as Map<String, Object?>?;
    if (subJson == null) return null;
    return SubscriptionModel.fromJson(subJson).subscription;
  }

  /// Fetches the current user's usage from the combined endpoint.
  ///
  /// GET /api/billing/current → {plan, subscription, usage, monthlyUsage, expired}
  Future<Usage> getUsage() async {
    final current = await _fetchCurrent();
    final usageJson = current['usage'] as Map<String, Object?>? ?? {};
    final planJson = current['plan'] as Map<String, Object?>?;
    return UsageModel.fromCurrentJson(usageJson, planJson).usage;
  }

  /// Fetches the combined /api/billing/current endpoint.
  Future<Map<String, Object?>> _fetchCurrent() async => _dioClient.get<Map<String, Object?>>('$_basePath/current');

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

  /// Applies a promotional code.
  ///
  /// POST /api/billing/apply-promo
  /// Returns a map with `valid` (bool), `discount` (int), `message` (String).
  Future<PromoCodeResult> applyPromoCode(String code) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '$_basePath/apply-promo',
      data: {'code': code},
    );

    final valid = response['valid'] as bool? ?? false;
    final discount = response['discount'] as int? ?? 0;
    final message = response['message'] as String? ?? '';

    return PromoCodeResult(
      valid: valid,
      discount: discount,
      message: message,
    );
  }
}

/// Riverpod provider for [BillingRemoteDataSource].
final billingRemoteDataSourceProvider =
    Provider<BillingRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return BillingRemoteDataSource(dioClient: dioClient);
});

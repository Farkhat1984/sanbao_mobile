/// Riverpod providers for billing state management.
///
/// Provides reactive access to plans, subscription, usage, and
/// billing actions (checkout, cancel).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/subscription.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/usage.dart';
import 'package:sanbao_flutter/features/billing/domain/repositories/billing_repository.dart';

// ---- Plans Provider ----

/// Sealed state for plan list loading.
sealed class PlansState {
  const PlansState();
}

final class PlansLoading extends PlansState {
  const PlansLoading();
}

final class PlansLoaded extends PlansState {
  const PlansLoaded({required this.plans});
  final List<Plan> plans;
}

final class PlansError extends PlansState {
  const PlansError({required this.message});
  final String message;
}

/// Notifier that manages the available plans state.
class PlansNotifier extends StateNotifier<PlansState> {
  PlansNotifier({required BillingRepository repository})
      : _repository = repository,
        super(const PlansLoading()) {
    loadPlans();
  }

  final BillingRepository _repository;

  /// Loads the available plans from the API.
  Future<void> loadPlans() async {
    state = const PlansLoading();
    try {
      final plans = await _repository.getPlans();
      state = PlansLoaded(plans: plans);
    } on Failure catch (f) {
      state = PlansError(message: f.message);
    } catch (e) {
      debugPrint('[PlansNotifier] Error loading plans: $e');
      state = const PlansError(message: 'Не удалось загрузить тарифы');
    }
  }
}

/// Provider for the available billing plans.
final plansProvider = StateNotifierProvider<PlansNotifier, PlansState>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return PlansNotifier(repository: repository);
});

// ---- Subscription Provider ----

/// Sealed state for subscription loading.
sealed class SubscriptionState {
  const SubscriptionState();
}

final class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

final class SubscriptionLoaded extends SubscriptionState {
  const SubscriptionLoaded({this.subscription});
  final Subscription? subscription;
}

final class SubscriptionError extends SubscriptionState {
  const SubscriptionError({required this.message});
  final String message;
}

/// Notifier that manages the current subscription state.
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier({required BillingRepository repository})
      : _repository = repository,
        super(const SubscriptionLoading()) {
    loadSubscription();
  }

  final BillingRepository _repository;

  /// Loads the current subscription.
  Future<void> loadSubscription() async {
    state = const SubscriptionLoading();
    try {
      final subscription = await _repository.getCurrentSubscription();
      state = SubscriptionLoaded(subscription: subscription);
    } on Failure catch (f) {
      state = SubscriptionError(message: f.message);
    } catch (e) {
      debugPrint('[SubscriptionNotifier] Error: $e');
      state = const SubscriptionError(
        message: 'Не удалось загрузить подписку',
      );
    }
  }

  /// Cancels the current subscription.
  Future<void> cancelSubscription() async {
    try {
      await _repository.cancelSubscription();
      await loadSubscription();
    } on Failure catch (f) {
      state = SubscriptionError(message: f.message);
    }
  }
}

/// Provider for the current subscription.
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return SubscriptionNotifier(repository: repository);
});

// ---- Usage Provider ----

/// Sealed state for usage loading.
sealed class UsageState {
  const UsageState();
}

final class UsageLoading extends UsageState {
  const UsageLoading();
}

final class UsageLoaded extends UsageState {
  const UsageLoaded({required this.usage});
  final Usage usage;
}

final class UsageError extends UsageState {
  const UsageError({required this.message});
  final String message;
}

/// Notifier that manages usage data state.
class UsageNotifier extends StateNotifier<UsageState> {
  UsageNotifier({required BillingRepository repository})
      : _repository = repository,
        super(const UsageLoading()) {
    loadUsage();
  }

  final BillingRepository _repository;

  /// Loads usage data.
  Future<void> loadUsage() async {
    state = const UsageLoading();
    try {
      final usage = await _repository.getUsage();
      state = UsageLoaded(usage: usage);
    } on Failure catch (f) {
      state = UsageError(message: f.message);
    } catch (e) {
      debugPrint('[UsageNotifier] Error: $e');
      state = const UsageError(message: 'Не удалось загрузить данные');
    }
  }
}

/// Provider for usage data.
final usageProvider =
    StateNotifierProvider<UsageNotifier, UsageState>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return UsageNotifier(repository: repository);
});

// ---- Payment History Provider ----

/// Sealed state for payment history.
sealed class PaymentHistoryState {
  const PaymentHistoryState();
}

final class PaymentHistoryLoading extends PaymentHistoryState {
  const PaymentHistoryLoading();
}

final class PaymentHistoryLoaded extends PaymentHistoryState {
  const PaymentHistoryLoaded({required this.payments});
  final List<PaymentHistoryItem> payments;
}

final class PaymentHistoryError extends PaymentHistoryState {
  const PaymentHistoryError({required this.message});
  final String message;
}

/// Notifier for payment history state.
class PaymentHistoryNotifier extends StateNotifier<PaymentHistoryState> {
  PaymentHistoryNotifier({required BillingRepository repository})
      : _repository = repository,
        super(const PaymentHistoryLoading()) {
    loadHistory();
  }

  final BillingRepository _repository;

  /// Loads payment history.
  Future<void> loadHistory() async {
    state = const PaymentHistoryLoading();
    try {
      final payments = await _repository.getPaymentHistory();
      state = PaymentHistoryLoaded(payments: payments);
    } on Failure catch (f) {
      state = PaymentHistoryError(message: f.message);
    } catch (e) {
      debugPrint('[PaymentHistoryNotifier] Error: $e');
      state = const PaymentHistoryError(
        message: 'Не удалось загрузить историю',
      );
    }
  }
}

/// Provider for payment history.
final paymentHistoryProvider =
    StateNotifierProvider<PaymentHistoryNotifier, PaymentHistoryState>((ref) {
  final repository = ref.watch(billingRepositoryProvider);
  return PaymentHistoryNotifier(repository: repository);
});

// ---- Checkout Provider ----

/// Provider for creating checkout sessions.
///
/// Returns the checkout URL for opening in the browser.
final checkoutUrlProvider =
    FutureProvider.family<String, String>((ref, planId) async {
  final repository = ref.watch(billingRepositoryProvider);
  return repository.createCheckoutUrl(planId: planId);
});

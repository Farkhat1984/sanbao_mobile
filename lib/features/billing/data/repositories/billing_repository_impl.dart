/// Implementation of the billing repository.
///
/// Delegates to the remote data source for all operations and maps
/// API exceptions to domain failures.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/core/network/api_exceptions.dart';
import 'package:sanbao_flutter/features/billing/data/datasources/billing_remote_datasource.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/subscription.dart';
import 'package:sanbao_flutter/features/billing/domain/entities/usage.dart';
import 'package:sanbao_flutter/features/billing/domain/repositories/billing_repository.dart';

/// Concrete implementation of [BillingRepository].
class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl({
    required BillingRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final BillingRemoteDataSource _remoteDataSource;

  @override
  Future<List<Plan>> getPlans() async {
    try {
      return await _remoteDataSource.getPlans();
    } on ApiException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Subscription?> getCurrentSubscription() async {
    try {
      return await _remoteDataSource.getCurrentSubscription();
    } on ApiException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Usage> getUsage() async {
    try {
      return await _remoteDataSource.getUsage();
    } on ApiException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<String> createCheckoutUrl({required String planId}) async {
    try {
      return await _remoteDataSource.createCheckoutUrl(planId: planId);
    } on ApiException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> cancelSubscription() async {
    try {
      await _remoteDataSource.cancelSubscription();
    } on ApiException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<List<PaymentHistoryItem>> getPaymentHistory() async {
    try {
      return await _remoteDataSource.getPaymentHistory();
    } on ApiException catch (e) {
      throw _mapException(e);
    }
  }

  /// Maps API exceptions to domain failures.
  Failure _mapException(ApiException exception) => switch (exception) {
        UnauthorizedException() =>
          const AuthFailure(message: 'Сессия истекла. Войдите снова.'),
        ForbiddenException() =>
          const PermissionFailure(message: 'Доступ запрещён.'),
        NotFoundException() =>
          const NotFoundFailure(message: 'Подписка не найдена.'),
        NetworkException() => const NetworkFailure(),
        TimeoutException() => const TimeoutFailure(),
        ValidationException(:final message) =>
          ValidationFailure(message: message),
        RateLimitException() => const RateLimitFailure(),
        _ => ServerFailure(
            message: exception.message,
            statusCode: exception.statusCode,
          ),
      };
}

/// Riverpod provider for [BillingRepository].
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final remoteDataSource = ref.watch(billingRemoteDataSourceProvider);
  return BillingRepositoryImpl(remoteDataSource: remoteDataSource);
});

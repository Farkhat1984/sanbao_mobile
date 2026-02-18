/// Implementation of the notification repository.
///
/// Delegates to the remote data source for all operations
/// and maps API exceptions to domain [Failure] types.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/errors/error_handler.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:sanbao_flutter/features/notifications/domain/entities/notification.dart';
import 'package:sanbao_flutter/features/notifications/domain/repositories/notification_repository.dart';

/// Concrete implementation of [NotificationRepository].
///
/// Wraps remote data source calls with error handling, converting
/// API exceptions to domain failures via [ErrorHandler.toFailure].
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required NotificationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final NotificationRemoteDataSource _remoteDataSource;

  @override
  Future<List<AppNotification>> getAll() async {
    try {
      return await _remoteDataSource.getAll();
    } on Failure {
      rethrow;
    } on Object catch (e) {
      debugPrint('[NotificationRepo] getAll failed: $e');
      throw ErrorHandler.toFailure(e);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      return await _remoteDataSource.getUnreadCount();
    } on Failure {
      rethrow;
    } on Object catch (e) {
      debugPrint('[NotificationRepo] getUnreadCount failed: $e');
      throw ErrorHandler.toFailure(e);
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _remoteDataSource.markAsRead(id);
    } on Failure {
      rethrow;
    } on Object catch (e) {
      debugPrint('[NotificationRepo] markAsRead($id) failed: $e');
      throw ErrorHandler.toFailure(e);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _remoteDataSource.markAllAsRead();
    } on Failure {
      rethrow;
    } on Object catch (e) {
      debugPrint('[NotificationRepo] markAllAsRead failed: $e');
      throw ErrorHandler.toFailure(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _remoteDataSource.delete(id);
    } on Failure {
      rethrow;
    } on Object catch (e) {
      debugPrint('[NotificationRepo] delete($id) failed: $e');
      throw ErrorHandler.toFailure(e);
    }
  }
}

/// Riverpod provider for [NotificationRepository].
final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  final remoteDataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(remoteDataSource: remoteDataSource);
});

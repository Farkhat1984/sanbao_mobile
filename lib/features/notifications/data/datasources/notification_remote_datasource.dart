/// Remote data source for notification operations.
///
/// Handles GET/PUT calls to the notifications API endpoint.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/notifications/data/models/notification_model.dart';
import 'package:sanbao_flutter/features/notifications/domain/entities/notification.dart';

/// Remote data source for notification operations via the REST API.
class NotificationRemoteDataSource {
  NotificationRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Fetches all notifications for the current user.
  Future<List<AppNotification>> getAll() async {
    final response = await _dioClient
        .get<Object>(AppConfig.notificationsEndpoint);

    // API may return a plain list or a wrapped object
    final List<Object?> notificationsJson;
    if (response is List) {
      notificationsJson = response.cast<Object?>();
    } else if (response is Map<String, Object?>) {
      notificationsJson = response['notifications'] as List<Object?>? ??
          response['data'] as List<Object?>? ??
          [];
    } else {
      notificationsJson = [];
    }

    return NotificationModel.fromJsonList(notificationsJson);
  }

  /// Returns the count of unread notifications.
  ///
  /// Computes locally from the full list since the backend
  /// does not provide a dedicated unread-count endpoint.
  Future<int> getUnreadCount() async {
    final all = await getAll();
    return all.where((n) => !n.isRead).length;
  }

  /// Marks a single notification as read.
  ///
  /// Backend expects `PUT /api/notifications` with `{ ids: [id] }`.
  Future<void> markAsRead(String id) async {
    await _dioClient.put<Map<String, Object?>>(
      AppConfig.notificationsEndpoint,
      data: {'ids': [id]},
    );
  }

  /// Marks all notifications as read.
  ///
  /// Backend expects `PUT /api/notifications` with no ids (marks all).
  Future<void> markAllAsRead() async {
    await _dioClient.put<Map<String, Object?>>(
      AppConfig.notificationsEndpoint,
    );
  }

  /// Dismisses a notification by marking it as read.
  ///
  /// Backend does not support DELETE for notifications,
  /// so we mark it as read instead to hide it from unread list.
  Future<void> delete(String id) async {
    await markAsRead(id);
  }
}

/// Riverpod provider for [NotificationRemoteDataSource].
final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return NotificationRemoteDataSource(dioClient: dioClient);
});

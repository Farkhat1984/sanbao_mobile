/// Remote data source for notification operations.
///
/// Handles GET/PUT/DELETE calls to the notifications API endpoint.
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
  /// Calls `GET /api/notifications/unread-count`. If the endpoint
  /// does not exist, falls back to fetching all and counting locally.
  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.get<Map<String, Object?>>(
        '${AppConfig.notificationsEndpoint}/unread-count',
      );
      return (response['count'] as num?)?.toInt() ?? 0;
    } on Object {
      // Fallback: fetch all notifications and count unread
      final all = await getAll();
      return all.where((n) => !n.isRead).length;
    }
  }

  /// Marks a single notification as read.
  Future<void> markAsRead(String id) async {
    await _dioClient.put<Map<String, Object?>>(
      '${AppConfig.notificationsEndpoint}/$id',
      data: {'isRead': true},
    );
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    await _dioClient.put<Map<String, Object?>>(
      '${AppConfig.notificationsEndpoint}/read-all',
    );
  }

  /// Deletes a notification by [id].
  Future<void> delete(String id) async {
    await _dioClient.delete<Map<String, Object?>>(
      '${AppConfig.notificationsEndpoint}/$id',
    );
  }
}

/// Riverpod provider for [NotificationRemoteDataSource].
final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return NotificationRemoteDataSource(dioClient: dioClient);
});

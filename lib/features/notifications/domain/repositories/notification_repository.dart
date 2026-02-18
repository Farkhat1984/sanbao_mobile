/// Abstract notification repository contract.
///
/// Defines operations for fetching, reading, and deleting notifications.
library;

import 'package:sanbao_flutter/features/notifications/domain/entities/notification.dart';

/// Abstract repository for notification operations.
abstract class NotificationRepository {
  /// Fetches all notifications for the current user.
  Future<List<AppNotification>> getAll();

  /// Returns the count of unread notifications.
  ///
  /// This may call a dedicated lightweight endpoint or derive
  /// from the full list, depending on the API.
  Future<int> getUnreadCount();

  /// Marks a notification as read.
  Future<void> markAsRead(String id);

  /// Marks all notifications as read.
  Future<void> markAllAsRead();

  /// Deletes a notification by [id].
  Future<void> delete(String id);
}

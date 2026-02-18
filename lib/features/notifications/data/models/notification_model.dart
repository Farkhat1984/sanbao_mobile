/// Notification data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [AppNotification] entity.
library;

import 'package:sanbao_flutter/features/notifications/domain/entities/notification.dart';

/// Data model for [AppNotification] with JSON serialization support.
class NotificationModel {
  const NotificationModel._({required this.notification});

  /// Creates a model from an API JSON response.
  factory NotificationModel.fromJson(Map<String, Object?> json) {
    final typeStr = json['type'] as String? ?? 'system';
    final dataJson = json['data'] as Map<String, Object?>? ?? const {};

    // Extract conversationId from top-level or nested data
    final conversationId = json['conversationId'] as String? ??
        dataJson['conversationId'] as String?;

    return NotificationModel._(
      notification: AppNotification(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: _parseType(typeStr),
        isRead: json['isRead'] as bool? ?? false,
        data: dataJson,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
        conversationId: conversationId,
      ),
    );
  }

  /// The underlying domain entity.
  final AppNotification notification;

  /// Parses a list of notification JSON objects.
  static List<AppNotification> fromJsonList(List<Object?> jsonList) =>
      jsonList
          .whereType<Map<String, Object?>>()
          .map((json) => NotificationModel.fromJson(json).notification)
          .toList();

  static NotificationType _parseType(String type) =>
      switch (type.toLowerCase()) {
        'task' => NotificationType.task,
        'message' => NotificationType.message,
        'billing' => NotificationType.billing,
        _ => NotificationType.system,
      };
}

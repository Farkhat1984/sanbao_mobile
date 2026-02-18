/// App notification entity.
///
/// Represents an in-app notification with type, read status,
/// and optional navigation data.
library;

/// Type of notification.
enum NotificationType {
  /// Task completed or failed.
  task,

  /// New message in a conversation.
  message,

  /// System announcement or update.
  system,

  /// Billing or subscription event.
  billing;

  /// Returns a user-friendly label for display.
  String get label => switch (this) {
        task => 'Задача',
        message => 'Сообщение',
        system => 'Система',
        billing => 'Биллинг',
      };
}

/// An in-app notification item.
///
/// Notifications inform the user about events that happened
/// in the background (task completion, new messages, etc.).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data = const {},
    this.conversationId,
  });

  /// Unique notification identifier.
  final String id;

  /// Notification title.
  final String title;

  /// Notification body text.
  final String body;

  /// Notification type.
  final NotificationType type;

  /// Whether the notification has been read.
  final bool isRead;

  /// Additional data for navigation (e.g., conversationId, taskId).
  final Map<String, Object?> data;

  /// When the notification was created.
  final DateTime createdAt;

  /// Associated conversation ID for message-type notifications.
  ///
  /// When non-null, tapping the notification navigates to this conversation.
  final String? conversationId;

  /// Creates a copy with modified fields.
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    Map<String, Object?>? data,
    DateTime? createdAt,
    String? conversationId,
  }) =>
      AppNotification(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        isRead: isRead ?? this.isRead,
        data: data ?? this.data,
        createdAt: createdAt ?? this.createdAt,
        conversationId: conversationId ?? this.conversationId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AppNotification(id=$id, title=$title, type=$type, isRead=$isRead)';
}

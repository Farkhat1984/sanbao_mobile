/// Conversation data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [Conversation] entity.
library;

import 'package:sanbao_flutter/features/chat/domain/entities/conversation.dart';

/// Data model for [Conversation] with JSON serialization support.
class ConversationModel {
  const ConversationModel._({required this.conversation});

  /// Creates a [ConversationModel] from a domain [Conversation].
  factory ConversationModel.fromEntity(Conversation conversation) =>
      ConversationModel._(conversation: conversation);

  /// Creates a [ConversationModel] from a JSON map (API response).
  factory ConversationModel.fromJson(Map<String, Object?> json) {
    // Handle nested agent object if present
    final agentJson = json['agent'] as Map<String, Object?>?;

    return ConversationModel._(
      conversation: Conversation(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Новый чат',
        agentId: json['agentId'] as String? ?? agentJson?['id'] as String?,
        agentName: agentJson?['name'] as String?,
        agentIcon: agentJson?['icon'] as String?,
        agentColor: agentJson?['iconColor'] as String?,
        isPinned: json['pinned'] as bool? ??
            json['isPinned'] as bool? ??
            false,
        isArchived: json['archived'] as bool? ??
            json['isArchived'] as bool? ??
            false,
        lastMessagePreview: json['lastMessagePreview'] as String? ??
            json['lastMessage'] as String? ??
            _extractPreview(json),
        messageCount: (json['messageCount'] as num?)?.toInt() ??
            (json['_count'] as Map<String, Object?>?)?['messages'] as int? ??
            0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      ),
    );
  }

  /// The underlying domain entity.
  final Conversation conversation;

  /// Converts to a JSON map for API requests.
  Map<String, Object?> toJson() => {
        'id': conversation.id,
        'title': conversation.title,
        if (conversation.agentId != null) 'agentId': conversation.agentId,
        'isPinned': conversation.isPinned,
        'isArchived': conversation.isArchived,
        'createdAt': conversation.createdAt.toIso8601String(),
        'updatedAt': conversation.updatedAt.toIso8601String(),
      };

  /// Parses a list of conversation JSON objects.
  static List<Conversation> fromJsonList(List<Object?> jsonList) => jsonList
      .whereType<Map<String, Object?>>()
      .map((json) => ConversationModel.fromJson(json).conversation)
      .toList();
}

/// Extracts a preview string from the last message in the conversation JSON.
String? _extractPreview(Map<String, Object?> json) {
  final messages = json['messages'] as List<Object?>?;
  if (messages == null || messages.isEmpty) return null;
  final lastMessage = messages.last as Map<String, Object?>?;
  if (lastMessage == null) return null;
  final content = lastMessage['content'] as String?;
  if (content == null || content.isEmpty) return null;
  return content.length > 100 ? '${content.substring(0, 100)}...' : content;
}

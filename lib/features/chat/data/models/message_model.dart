/// Message data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [Message] entity.
library;

import 'package:sanbao_flutter/features/chat/domain/entities/artifact.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';

/// Data model for [Message] with JSON serialization support.
class MessageModel {
  const MessageModel._({required this.message});

  /// Creates a [MessageModel] from a domain [Message].
  factory MessageModel.fromEntity(Message message) =>
      MessageModel._(message: message);

  /// Creates a [MessageModel] from a JSON map (API response).
  factory MessageModel.fromJson(Map<String, Object?> json) {
    final attachmentsJson = json['attachments'] as List<Object?>?;
    final artifactsJson = json['artifacts'] as List<Object?>?;
    final toolsJson = json['toolsUsed'] as List<Object?>?;

    return MessageModel._(
      message: Message(
        id: json['id'] as String? ?? '',
        conversationId: json['conversationId'] as String? ?? '',
        role: MessageRole.fromString(json['role'] as String? ?? 'user'),
        content: json['content'] as String? ?? '',
        reasoningContent: json['reasoningContent'] as String?,
        planContent: json['planContent'] as String?,
        artifacts: artifactsJson
                ?.map((a) => _parseArtifact(a! as Map<String, Object?>))
                .toList() ??
            const [],
        attachments: attachmentsJson
                ?.map((a) => _parseAttachment(a! as Map<String, Object?>))
                .toList() ??
            const [],
        toolsUsed: toolsJson?.map((t) => t! as String).toList() ?? const [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        isError: json['isError'] as bool? ?? false,
        errorMessage: json['errorMessage'] as String?,
      ),
    );
  }

  /// The underlying domain entity.
  final Message message;

  /// Converts to a JSON map for API requests.
  Map<String, Object?> toJson() => {
        'id': message.id,
        'conversationId': message.conversationId,
        'role': message.role.name,
        'content': message.content,
        if (message.reasoningContent != null)
          'reasoningContent': message.reasoningContent,
        if (message.planContent != null) 'planContent': message.planContent,
        if (message.artifacts.isNotEmpty)
          'artifacts': message.artifacts.map(_artifactToJson).toList(),
        if (message.attachments.isNotEmpty)
          'attachments': message.attachments.map(_attachmentToJson).toList(),
        if (message.toolsUsed.isNotEmpty) 'toolsUsed': message.toolsUsed,
        'createdAt': message.createdAt.toIso8601String(),
      };

  /// Converts a message to the minimal format required by the chat API.
  ///
  /// The chat endpoint expects `{role, content}` for each message.
  Map<String, Object?> toChatApiFormat() => {
        'role': message.role.name,
        'content': message.content,
      };

  /// Converts a list of messages to the chat API format.
  static List<Map<String, Object?>> messagesToChatApi(
    List<Message> messages,
  ) =>
      messages
          .where((m) => m.role != MessageRole.system && m.content.isNotEmpty)
          .map((m) => MessageModel.fromEntity(m).toChatApiFormat())
          .toList();
}

// ---- Private Helpers ----

Artifact _parseArtifact(Map<String, Object?> json) => Artifact(
      id: json['id'] as String? ?? '',
      type: ArtifactType.fromString(json['type'] as String? ?? 'DOCUMENT'),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      language: json['language'] as String?,
    );

Map<String, Object?> _artifactToJson(Artifact artifact) => {
      'id': artifact.id,
      'type': artifact.type.name.toUpperCase(),
      'title': artifact.title,
      'content': artifact.content,
      if (artifact.language != null) 'language': artifact.language,
    };

MessageAttachment _parseAttachment(Map<String, Object?> json) =>
    MessageAttachment(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      url: json['url'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );

Map<String, Object?> _attachmentToJson(MessageAttachment attachment) => {
      'id': attachment.id,
      'name': attachment.name,
      'mimeType': attachment.mimeType,
      'sizeBytes': attachment.sizeBytes,
      if (attachment.url != null) 'url': attachment.url,
      if (attachment.thumbnailUrl != null)
        'thumbnailUrl': attachment.thumbnailUrl,
    };

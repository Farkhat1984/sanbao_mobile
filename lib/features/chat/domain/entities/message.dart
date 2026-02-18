/// Message entity for chat conversations.
///
/// Represents a single message in a conversation, supporting user,
/// assistant, and system roles with rich content including artifacts,
/// attachments, and reasoning traces.
library;

import 'package:sanbao_flutter/features/chat/domain/entities/artifact.dart';

/// The role of a message sender.
enum MessageRole {
  /// Message from the user.
  user,

  /// Message from the AI assistant.
  assistant,

  /// System-level message (e.g., context, instructions).
  system;

  /// Creates a [MessageRole] from its string representation.
  static MessageRole fromString(String value) => switch (value.toLowerCase()) {
        'user' => MessageRole.user,
        'assistant' => MessageRole.assistant,
        'system' => MessageRole.system,
        _ => MessageRole.user,
      };
}

/// A file attachment on a message.
class MessageAttachment {
  const MessageAttachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    this.url,
    this.thumbnailUrl,
  });

  /// Unique identifier.
  final String id;

  /// Original file name.
  final String name;

  /// MIME type (e.g., 'application/pdf').
  final String mimeType;

  /// File size in bytes.
  final int sizeBytes;

  /// Download URL (if available).
  final String? url;

  /// Thumbnail URL for images.
  final String? thumbnailUrl;

  /// Whether this attachment is an image.
  bool get isImage => mimeType.startsWith('image/');

  /// Whether this attachment is a PDF.
  bool get isPdf => mimeType == 'application/pdf';
}

/// A single message within a conversation.
///
/// Messages are immutable value objects. During streaming, the
/// [isStreaming] flag is true and [content] / [reasoningContent]
/// are updated progressively via [copyWith].
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.reasoningContent,
    this.planContent,
    this.artifacts = const [],
    this.attachments = const [],
    this.toolsUsed = const [],
    this.isStreaming = false,
    this.isError = false,
    this.errorMessage,
  });

  /// Creates an empty user message for sending.
  factory Message.user({
    required String id,
    required String conversationId,
    required String content,
    List<MessageAttachment> attachments = const [],
  }) =>
      Message(
        id: id,
        conversationId: conversationId,
        role: MessageRole.user,
        content: content,
        createdAt: DateTime.now(),
        attachments: attachments,
      );

  /// Creates an empty assistant message placeholder for streaming.
  factory Message.assistantPlaceholder({
    required String id,
    required String conversationId,
  }) =>
      Message(
        id: id,
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: '',
        createdAt: DateTime.now(),
        isStreaming: true,
      );

  /// Creates an error message from the assistant.
  factory Message.error({
    required String id,
    required String conversationId,
    required String errorMessage,
  }) =>
      Message(
        id: id,
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: '',
        createdAt: DateTime.now(),
        isError: true,
        errorMessage: errorMessage,
      );

  /// Unique message identifier.
  final String id;

  /// The conversation this message belongs to.
  final String conversationId;

  /// Who sent this message.
  final MessageRole role;

  /// The text content of the message (Markdown for assistant).
  final String content;

  /// The AI's reasoning/thinking trace (collapsible in UI).
  final String? reasoningContent;

  /// The AI's plan content.
  final String? planContent;

  /// Artifacts (documents, code) embedded in this message.
  final List<Artifact> artifacts;

  /// Files attached to this message.
  final List<MessageAttachment> attachments;

  /// When this message was created.
  final DateTime createdAt;

  /// Names of tools used during generation.
  final List<String> toolsUsed;

  /// Whether this message is currently being streamed.
  final bool isStreaming;

  /// Whether this message represents an error.
  final bool isError;

  /// Error message text (when [isError] is true).
  final String? errorMessage;

  /// Whether this is a user message.
  bool get isUser => role == MessageRole.user;

  /// Whether this is an assistant message.
  bool get isAssistant => role == MessageRole.assistant;

  /// Whether this message has any content to display.
  bool get hasContent => content.isNotEmpty || isError;

  /// Whether this message has reasoning content.
  bool get hasReasoning =>
      reasoningContent != null && reasoningContent!.isNotEmpty;

  /// Whether this message has a plan.
  bool get hasPlan => planContent != null && planContent!.isNotEmpty;

  /// Whether this message has artifacts.
  bool get hasArtifacts => artifacts.isNotEmpty;

  /// Whether this message has attachments.
  bool get hasAttachments => attachments.isNotEmpty;

  /// Creates a copy with modified fields.
  Message copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    String? reasoningContent,
    String? planContent,
    List<Artifact>? artifacts,
    List<MessageAttachment>? attachments,
    List<String>? toolsUsed,
    bool? isStreaming,
    bool? isError,
    String? errorMessage,
    DateTime? createdAt,
  }) =>
      Message(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        role: role ?? this.role,
        content: content ?? this.content,
        reasoningContent: reasoningContent ?? this.reasoningContent,
        planContent: planContent ?? this.planContent,
        artifacts: artifacts ?? this.artifacts,
        attachments: attachments ?? this.attachments,
        toolsUsed: toolsUsed ?? this.toolsUsed,
        isStreaming: isStreaming ?? this.isStreaming,
        isError: isError ?? this.isError,
        errorMessage: errorMessage ?? this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Message(id=$id, role=$role, content=${content.length} chars, streaming=$isStreaming)';
}

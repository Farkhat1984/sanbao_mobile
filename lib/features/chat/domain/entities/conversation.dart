/// Conversation entity representing a chat thread.
///
/// Conversations are the top-level container for message exchanges
/// between the user and the AI assistant.
library;

/// A conversation (chat thread) with metadata.
///
/// Conversations are identified by their [id] and can be associated
/// with a specific agent via [agentId]. They support pinning and
/// archiving for organization.
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.agentId,
    this.agentName,
    this.agentIcon,
    this.agentColor,
    this.isPinned = false,
    this.isArchived = false,
    this.lastMessagePreview,
    this.messageCount = 0,
  });

  /// Unique conversation identifier.
  final String id;

  /// Display title (auto-generated or user-set).
  final String title;

  /// ID of the associated agent (null for default Sanbao).
  final String? agentId;

  /// Display name of the agent.
  final String? agentName;

  /// Icon identifier for the agent.
  final String? agentIcon;

  /// Color hex string for the agent icon.
  final String? agentColor;

  /// Whether the conversation is pinned to the top.
  final bool isPinned;

  /// Whether the conversation is archived.
  final bool isArchived;

  /// Preview text of the last message.
  final String? lastMessagePreview;

  /// Total number of messages in the conversation.
  final int messageCount;

  /// When the conversation was created.
  final DateTime createdAt;

  /// When the conversation was last updated (last message).
  final DateTime updatedAt;

  /// Whether this conversation has an agent assigned.
  bool get hasAgent => agentId != null;

  /// Creates a copy with modified fields.
  Conversation copyWith({
    String? id,
    String? title,
    String? agentId,
    String? agentName,
    String? agentIcon,
    String? agentColor,
    bool? isPinned,
    bool? isArchived,
    String? lastMessagePreview,
    int? messageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Conversation(
        id: id ?? this.id,
        title: title ?? this.title,
        agentId: agentId ?? this.agentId,
        agentName: agentName ?? this.agentName,
        agentIcon: agentIcon ?? this.agentIcon,
        agentColor: agentColor ?? this.agentColor,
        isPinned: isPinned ?? this.isPinned,
        isArchived: isArchived ?? this.isArchived,
        lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
        messageCount: messageCount ?? this.messageCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Conversation(id=$id, title=$title)';
}

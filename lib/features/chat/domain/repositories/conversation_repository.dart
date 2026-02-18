/// Abstract conversation repository for CRUD operations.
///
/// Defines the contract for managing conversation metadata
/// (creating, listing, updating, deleting).
library;

import 'package:sanbao_flutter/features/chat/domain/entities/conversation.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';

/// Abstract repository for conversation CRUD operations.
///
/// Implementations handle network calls and local caching.
abstract class ConversationRepository {
  /// Fetches all conversations for the current user.
  ///
  /// Returns conversations sorted by [Conversation.updatedAt] descending.
  /// Supports optional [limit] and [offset] for pagination.
  Future<List<Conversation>> getConversations({
    int limit = 50,
    int offset = 0,
  });

  /// Fetches a single conversation by its [id].
  ///
  /// Returns `null` if the conversation does not exist.
  Future<Conversation?> getConversation(String id);

  /// Fetches all messages for a conversation.
  ///
  /// Returns messages sorted by [Message.createdAt] ascending.
  Future<List<Message>> getMessages(String conversationId);

  /// Creates a new conversation and returns it.
  Future<Conversation> createConversation({
    required String title,
    String? agentId,
  });

  /// Updates a conversation's metadata.
  Future<Conversation> updateConversation({
    required String id,
    String? title,
    bool? isPinned,
    bool? isArchived,
  });

  /// Permanently deletes a conversation and all its messages.
  Future<void> deleteConversation(String id);

  /// Saves a user message to the server after sending.
  ///
  /// This persists the message on the backend for conversation history.
  Future<void> saveMessage({
    required String conversationId,
    required Message message,
  });
}

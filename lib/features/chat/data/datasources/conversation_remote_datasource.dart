/// Remote data source for conversation CRUD operations.
///
/// Handles GET/POST/PUT/DELETE calls to /api/conversations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/chat/data/models/conversation_model.dart';
import 'package:sanbao_flutter/features/chat/data/models/message_model.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/conversation.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';

/// Remote data source for conversation operations via the REST API.
class ConversationRemoteDataSource {
  ConversationRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Fetches all conversations for the current user.
  Future<List<Conversation>> getConversations({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      AppConfig.conversationsEndpoint,
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final conversationsJson = response['conversations'] as List<Object?>? ??
        response['data'] as List<Object?>? ??
        [];

    return ConversationModel.fromJsonList(conversationsJson);
  }

  /// Fetches a single conversation by ID.
  Future<Conversation?> getConversation(String id) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '${AppConfig.conversationsEndpoint}/$id',
    );

    return ConversationModel.fromJson(response).conversation;
  }

  /// Fetches messages for a conversation.
  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '${AppConfig.conversationsEndpoint}/$conversationId/messages',
    );

    final messagesJson = response['messages'] as List<Object?>? ??
        response['data'] as List<Object?>? ??
        [];

    return messagesJson
        .whereType<Map<String, Object?>>()
        .map((json) => MessageModel.fromJson(json).message)
        .toList();
  }

  /// Creates a new conversation.
  Future<Conversation> createConversation({
    required String title,
    String? agentId,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      AppConfig.conversationsEndpoint,
      data: {
        'title': title,
        if (agentId != null) 'agentId': agentId,
      },
    );

    return ConversationModel.fromJson(response).conversation;
  }

  /// Updates a conversation's metadata.
  Future<Conversation> updateConversation({
    required String id,
    String? title,
    bool? isPinned,
    bool? isArchived,
  }) async {
    final response = await _dioClient.put<Map<String, Object?>>(
      '${AppConfig.conversationsEndpoint}/$id',
      data: {
        if (title != null) 'title': title,
        if (isPinned != null) 'isPinned': isPinned,
        if (isArchived != null) 'isArchived': isArchived,
      },
    );

    return ConversationModel.fromJson(response).conversation;
  }

  /// Deletes a conversation.
  Future<void> deleteConversation(String id) async {
    await _dioClient.delete<Map<String, Object?>>(
      '${AppConfig.conversationsEndpoint}/$id',
    );
  }

  /// Saves a message to the conversation on the server.
  Future<void> saveMessage({
    required String conversationId,
    required Message message,
  }) async {
    await _dioClient.post<Map<String, Object?>>(
      '${AppConfig.conversationsEndpoint}/$conversationId/messages',
      data: MessageModel.fromEntity(message).toJson(),
    );
  }
}

/// Riverpod provider for [ConversationRemoteDataSource].
final conversationRemoteDataSourceProvider =
    Provider<ConversationRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ConversationRemoteDataSource(dioClient: dioClient);
});

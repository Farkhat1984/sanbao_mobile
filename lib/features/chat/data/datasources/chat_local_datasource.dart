/// Local data source for caching conversations offline.
///
/// Uses the file-based [LocalDatabase] to cache recent
/// conversations and messages for offline access. TTLs are set
/// generously (24 hours) to ensure useful data availability
/// when the device goes offline.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/storage/local_db.dart';
import 'package:sanbao_flutter/features/chat/data/models/conversation_model.dart';
import 'package:sanbao_flutter/features/chat/data/models/message_model.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/conversation.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';

/// Cache namespace constants and configuration.
abstract final class _CacheKeys {
  static const String conversationsNamespace = 'conversations';
  static const String messagesNamespace = 'messages';
  static const String conversationListKey = 'list';

  /// Conversations list TTL -- 24 hours to ensure data is available
  /// during extended offline periods (commute, flights, etc.).
  static const Duration conversationTtl = Duration(hours: 24);

  /// Individual conversation messages TTL -- 24 hours.
  static const Duration messageTtl = Duration(hours: 24);
}

/// Local data source for offline conversation and message caching.
///
/// Caches the conversation list and individual conversation messages
/// using the [LocalDatabase] file-based storage. All cache operations
/// are resilient to corruption and format errors.
///
/// Cache strategy:
/// - Conversation list is stored as a single JSON array.
/// - Messages are stored per-conversation with the conversation ID as key.
/// - Both use 24-hour TTL for offline reliability.
class ChatLocalDataSource {
  ChatLocalDataSource({required LocalDatabase localDatabase})
      : _localDb = localDatabase;

  final LocalDatabase _localDb;

  /// Caches the conversation list for offline access.
  ///
  /// Serializes each conversation via [ConversationModel.toJson] and
  /// stores the resulting JSON array with a 24-hour TTL.
  Future<void> cacheConversations(List<Conversation> conversations) async {
    final jsonList = conversations
        .map((c) => ConversationModel.fromEntity(c).toJson())
        .toList();

    await _localDb.put(
      namespace: _CacheKeys.conversationsNamespace,
      key: _CacheKeys.conversationListKey,
      data: jsonList,
      ttl: _CacheKeys.conversationTtl,
    );
  }

  /// Retrieves cached conversations, or null if cache is empty/expired.
  ///
  /// Returns `null` rather than throwing on corruption to allow
  /// graceful fallback behavior in the repository layer.
  Future<List<Conversation>?> getCachedConversations() async {
    final cached = await _localDb.get<String>(
      namespace: _CacheKeys.conversationsNamespace,
      key: _CacheKeys.conversationListKey,
      fromJson: (json) {
        if (json is String) return json;
        return jsonEncode(json);
      },
    );

    if (cached == null) return null;

    try {
      final jsonList = jsonDecode(cached) as List<Object?>;
      return ConversationModel.fromJsonList(jsonList);
    } on FormatException {
      return null;
    }
  }

  /// Caches messages for a specific conversation.
  ///
  /// Each conversation's messages are stored under the conversation ID
  /// as the cache key within the messages namespace. This allows
  /// independent TTL and invalidation per conversation.
  Future<void> cacheMessages(
    String conversationId,
    List<Message> messages,
  ) async {
    final jsonList = messages
        .map((m) => MessageModel.fromEntity(m).toJson())
        .toList();

    await _localDb.put(
      namespace: _CacheKeys.messagesNamespace,
      key: conversationId,
      data: jsonList,
      ttl: _CacheKeys.messageTtl,
    );
  }

  /// Retrieves cached messages for a conversation.
  ///
  /// Returns `null` if no cached data exists, the cache has expired,
  /// or the stored data is corrupted.
  Future<List<Message>?> getCachedMessages(String conversationId) async {
    final cached = await _localDb.get<String>(
      namespace: _CacheKeys.messagesNamespace,
      key: conversationId,
      fromJson: (json) {
        if (json is String) return json;
        return jsonEncode(json);
      },
    );

    if (cached == null) return null;

    try {
      final jsonList = jsonDecode(cached) as List<Object?>;
      return jsonList
          .whereType<Map<String, Object?>>()
          .map((json) => MessageModel.fromJson(json).message)
          .toList();
    } on FormatException {
      return null;
    }
  }

  /// Removes cached messages for a specific conversation.
  Future<void> clearCachedMessages(String conversationId) async {
    await _localDb.delete(
      namespace: _CacheKeys.messagesNamespace,
      key: conversationId,
    );
  }

  /// Clears all cached conversation and message data.
  ///
  /// Useful for logout or manual cache clearing in settings.
  Future<void> clearAll() async {
    await _localDb.clearNamespace(_CacheKeys.conversationsNamespace);
    await _localDb.clearNamespace(_CacheKeys.messagesNamespace);
  }

  /// Removes expired entries from both namespaces.
  ///
  /// Can be called periodically or on app startup to reclaim disk space.
  Future<void> pruneExpired() async {
    await _localDb.pruneExpired(_CacheKeys.conversationsNamespace);
    await _localDb.pruneExpired(_CacheKeys.messagesNamespace);
  }
}

/// Riverpod provider for [ChatLocalDataSource].
final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  final localDb = ref.watch(localDatabaseProvider);
  return ChatLocalDataSource(localDatabase: localDb);
});

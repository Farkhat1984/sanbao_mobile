/// Implementation of the conversation repository.
///
/// Combines remote and local data sources with a network-aware
/// cache strategy. When online, fetches from the API and caches
/// results locally. When offline, returns cached data.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/network/connectivity_provider.dart';
import 'package:sanbao_flutter/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:sanbao_flutter/features/chat/data/datasources/conversation_remote_datasource.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/conversation.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';
import 'package:sanbao_flutter/features/chat/domain/repositories/conversation_repository.dart';

/// Concrete implementation of [ConversationRepository].
///
/// Uses a network-aware strategy:
/// - **Online**: Fetches from the API, caches the result locally, returns fresh data.
/// - **Offline**: Returns locally cached data if available, otherwise throws.
/// - **Network error while online**: Falls back to cached data gracefully.
///
/// This ensures the app remains usable even without internet connectivity,
/// showing the most recently cached conversations and messages.
class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl({
    required ConversationRemoteDataSource remoteDataSource,
    required ChatLocalDataSource localDataSource,
    required bool Function() isOnline,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _isOnline = isOnline;

  final ConversationRemoteDataSource _remoteDataSource;
  final ChatLocalDataSource _localDataSource;
  final bool Function() _isOnline;

  @override
  Future<List<Conversation>> getConversations({
    int limit = 50,
    int offset = 0,
  }) async {
    // If offline, go straight to cache
    if (!_isOnline()) {
      return _getCachedConversationsOrThrow();
    }

    // Online: try remote, cache on success, fall back to cache on failure
    try {
      final conversations = await _remoteDataSource.getConversations(
        limit: limit,
        offset: offset,
      );

      // Cache in background (fire-and-forget)
      unawaited(_localDataSource.cacheConversations(conversations));

      return conversations;
    } on Object {
      // Network error while technically online -- fall back to cache
      return _getCachedConversationsOrThrow();
    }
  }

  @override
  Future<Conversation?> getConversation(String id) async {
    if (!_isOnline()) {
      // In offline mode, try to find the conversation in the cached list
      final cached = await _localDataSource.getCachedConversations();
      return cached?.where((c) => c.id == id).firstOrNull;
    }

    try {
      return await _remoteDataSource.getConversation(id);
    } on Object {
      // Fall back to cached list lookup
      final cached = await _localDataSource.getCachedConversations();
      return cached?.where((c) => c.id == id).firstOrNull;
    }
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    // If offline, go straight to cache
    if (!_isOnline()) {
      return _getCachedMessagesOrThrow(conversationId);
    }

    // Online: try remote, cache on success, fall back to cache on failure
    try {
      final messages = await _remoteDataSource.getMessages(conversationId);

      // Cache in background (fire-and-forget)
      unawaited(_localDataSource.cacheMessages(conversationId, messages));

      return messages;
    } on Object {
      // Network error while technically online -- fall back to cache
      return _getCachedMessagesOrThrow(conversationId);
    }
  }

  @override
  Future<Conversation> createConversation({
    required String title,
    String? agentId,
  }) =>
      _remoteDataSource.createConversation(
        title: title,
        agentId: agentId,
      );

  @override
  Future<Conversation> updateConversation({
    required String id,
    String? title,
    bool? isPinned,
    bool? isArchived,
  }) async {
    final updated = await _remoteDataSource.updateConversation(
      id: id,
      title: title,
      isPinned: isPinned,
      isArchived: isArchived,
    );

    // Invalidate conversation list cache so it refetches on next access
    unawaited(_localDataSource.cacheConversations([]));

    return updated;
  }

  @override
  Future<void> deleteConversation(String id) async {
    await _remoteDataSource.deleteConversation(id);

    // Clear cached messages and invalidate list cache
    await _localDataSource.clearCachedMessages(id);
  }

  @override
  Future<void> saveMessage({
    required String conversationId,
    required Message message,
  }) =>
      _remoteDataSource.saveMessage(
        conversationId: conversationId,
        message: message,
      );

  // ---- Private Helpers ----

  /// Retrieves cached conversations, throwing if none are available.
  Future<List<Conversation>> _getCachedConversationsOrThrow() async {
    final cached = await _localDataSource.getCachedConversations();
    if (cached != null && cached.isNotEmpty) return cached;

    throw const OfflineDataUnavailableException(
      'Нет сохранённых данных для офлайн-режима',
    );
  }

  /// Retrieves cached messages, throwing if none are available.
  Future<List<Message>> _getCachedMessagesOrThrow(
    String conversationId,
  ) async {
    final cached = await _localDataSource.getCachedMessages(conversationId);
    if (cached != null && cached.isNotEmpty) return cached;

    throw OfflineDataUnavailableException(
      'Сообщения недоступны в офлайн-режиме (чат: $conversationId)',
    );
  }
}

/// Exception thrown when cached data is not available in offline mode.
///
/// This is a recoverable error -- the UI should display a friendly
/// message and offer a retry mechanism for when connectivity returns.
class OfflineDataUnavailableException implements Exception {
  const OfflineDataUnavailableException(this.message);

  /// User-facing error message in Russian.
  final String message;

  @override
  String toString() => 'OfflineDataUnavailableException: $message';
}

/// Riverpod provider for [ConversationRepository].
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final remoteDataSource = ref.watch(conversationRemoteDataSourceProvider);
  final localDataSource = ref.watch(chatLocalDataSourceProvider);

  // Provide a closure that reads the current connectivity state.
  // Using a closure avoids creating a dependency on the connectivity
  // provider at construction time, which would cause the repository
  // to be recreated on every connectivity change.
  bool isOnline() => ref.read(isOnlineProvider);

  return ConversationRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    isOnline: isOnline,
  );
});

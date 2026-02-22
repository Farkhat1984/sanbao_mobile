/// Implementation of the chat repository.
///
/// Bridges the domain [ChatRepository] contract with the
/// [ChatRemoteDataSource] for streaming chat communication.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/network/ndjson_parser.dart';
import 'package:sanbao_flutter/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';
import 'package:sanbao_flutter/features/chat/domain/repositories/chat_repository.dart';

/// Concrete implementation of [ChatRepository].
///
/// Delegates streaming to the remote data source and handles
/// attachment serialization.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required ChatRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final ChatRemoteDataSource _remoteDataSource;

  @override
  Stream<ChatEvent> sendMessage(SendMessageRequest request) =>
      _remoteDataSource.sendMessage(
        messages: request.messages,
        conversationId: request.conversationId,
        agentId: request.agentId,
        skillId: request.skillId,
        thinkingEnabled: request.thinkingEnabled,
        webSearchEnabled: request.webSearchEnabled,
        planningEnabled: request.planningEnabled,
        attachments: request.attachments
            .map(_serializeAttachment)
            .toList(),
      );

  @override
  void stopGeneration() => _remoteDataSource.stopGeneration();

  /// Serializes an attachment for the API request.
  Map<String, Object?> _serializeAttachment(MessageAttachment attachment) => {
        'id': attachment.id,
        'name': attachment.name,
        'mimeType': attachment.mimeType,
        'sizeBytes': attachment.sizeBytes,
        if (attachment.url != null) 'url': attachment.url,
      };
}

/// Riverpod provider for [ChatRepository].
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(remoteDataSource: remoteDataSource);
});

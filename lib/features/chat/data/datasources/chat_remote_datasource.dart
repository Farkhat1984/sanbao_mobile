/// Remote data source for chat message streaming.
///
/// Handles the POST /api/chat endpoint with NDJSON streaming
/// response parsing via [DioClient.postStream].
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/core/network/ndjson_parser.dart';
import 'package:sanbao_flutter/features/chat/data/models/message_model.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';

/// Remote data source for the chat streaming API.
///
/// Sends messages to `POST /api/chat` and returns a parsed
/// stream of [ChatEvent]s from the NDJSON response.
class ChatRemoteDataSource {
  ChatRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;
  CancelToken? _currentCancelToken;

  /// Whether a stream is currently active.
  bool get isStreaming => _currentCancelToken != null;

  /// Sends a chat message and returns a stream of [ChatEvent]s.
  ///
  /// The stream is backed by a Dio streaming response with NDJSON parsing.
  /// Call [stopGeneration] to cancel the stream.
  Stream<ChatEvent> sendMessage({
    required List<Message> messages,
    String? conversationId,
    String? agentId,
    String? skillId,
    bool thinkingEnabled = true,
    bool webSearchEnabled = false,
    bool planningEnabled = false,
    List<Map<String, Object?>> attachments = const [],
  }) async* {
    // Cancel any existing stream
    stopGeneration();

    _currentCancelToken = CancelToken();

    final apiMessages = MessageModel.messagesToChatApi(messages);

    final payload = <String, Object?>{
      'messages': apiMessages,
      if (conversationId != null) 'conversationId': conversationId,
      if (agentId != null) 'agentId': agentId,
      if (skillId != null) 'skillId': skillId,
      'thinkingEnabled': thinkingEnabled,
      'webSearchEnabled': webSearchEnabled,
      'planningEnabled': planningEnabled,
      if (attachments.isNotEmpty) 'attachments': attachments,
    };

    try {
      final response = await _dioClient.postStream(
        AppConfig.chatEndpoint,
        data: payload,
        cancelToken: _currentCancelToken,
      );

      final body = response.data;
      if (body == null) {
        yield const ErrorEvent('Пустой ответ от сервера');
        return;
      }

      final eventStream = parseChatStream(body.stream);

      await for (final event in eventStream) {
        yield event;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // User cancelled -- not an error
        return;
      }
      yield ErrorEvent(
        _mapDioErrorToMessage(e),
      );
    } on Object catch (e) {
      yield ErrorEvent('Ошибка: $e');
    } finally {
      _currentCancelToken = null;
    }
  }

  /// Cancels the current streaming response.
  void stopGeneration() {
    _currentCancelToken?.cancel('User stopped generation');
    _currentCancelToken = null;
  }

  /// Maps a Dio error to a user-friendly Russian message.
  String _mapDioErrorToMessage(DioException e) => switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'Превышено время ожидания ответа',
        DioExceptionType.connectionError => 'Нет подключения к серверу',
        _ => 'Ошибка соединения: ${e.message ?? 'Неизвестная ошибка'}',
      };
}

/// Riverpod provider for [ChatRemoteDataSource].
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRemoteDataSource(dioClient: dioClient);
});

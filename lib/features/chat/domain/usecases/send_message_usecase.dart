/// Use case for sending a chat message with streaming response.
///
/// Orchestrates the message send flow: validates input, delegates
/// to the chat repository, and returns the event stream.
library;

import 'package:sanbao_flutter/core/network/ndjson_parser.dart';
import 'package:sanbao_flutter/features/chat/domain/repositories/chat_repository.dart';

/// Sends a message and returns a stream of chat events.
///
/// This use case validates the request and delegates to the
/// [ChatRepository] for actual network communication.
class SendMessageUseCase {
  const SendMessageUseCase({required ChatRepository repository})
      : _repository = repository;

  final ChatRepository _repository;

  /// Executes the use case, returning a stream of [ChatEvent]s.
  ///
  /// The stream should be listened to immediately. Events arrive
  /// as they are parsed from the NDJSON response.
  Stream<ChatEvent> call(SendMessageRequest request) {
    // Validate that we have at least one message
    if (request.messages.isEmpty) {
      return Stream.error(
        ArgumentError('Необходимо хотя бы одно сообщение'),
      );
    }

    // Validate message content length
    final lastMessage = request.messages.last;
    if (lastMessage.content.isEmpty) {
      return Stream.error(
        ArgumentError('Сообщение не может быть пустым'),
      );
    }

    return _repository.sendMessage(request);
  }

  /// Cancels any in-progress streaming response.
  void stopGeneration() => _repository.stopGeneration();
}

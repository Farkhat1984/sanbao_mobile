/// Abstract chat repository for message streaming.
///
/// Defines the contract for sending messages and receiving
/// streaming responses from the AI backend.
library;

import 'package:sanbao_flutter/core/network/ndjson_parser.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';

/// Request parameters for sending a chat message.
class SendMessageRequest {
  const SendMessageRequest({
    required this.messages,
    this.conversationId,
    this.agentId,
    this.skillId,
    this.thinkingEnabled = true,
    this.webSearchEnabled = false,
    this.planningEnabled = false,
    this.attachments = const [],
  });

  /// The message history to include in the request.
  final List<Message> messages;

  /// The conversation ID (null for new conversations).
  final String? conversationId;

  /// The agent to use for this message.
  final String? agentId;

  /// The skill to activate for this message.
  final String? skillId;

  /// Whether to enable reasoning/thinking mode.
  final bool thinkingEnabled;

  /// Whether to enable web search.
  final bool webSearchEnabled;

  /// Whether to enable planning mode.
  final bool planningEnabled;

  /// File attachments for this message.
  final List<MessageAttachment> attachments;
}

/// Abstract repository for chat message operations.
///
/// Implementations handle the actual network communication
/// and stream parsing.
abstract class ChatRepository {
  /// Sends a message and returns a stream of [ChatEvent]s.
  ///
  /// The stream emits events as they arrive from the NDJSON
  /// response. The caller is responsible for accumulating
  /// content and updating the UI.
  ///
  /// Throws [Failure] on network or server errors.
  Stream<ChatEvent> sendMessage(SendMessageRequest request);

  /// Cancels any in-progress streaming response.
  ///
  /// This is a best-effort operation; the stream may still
  /// emit a few more events after cancellation.
  void stopGeneration();
}

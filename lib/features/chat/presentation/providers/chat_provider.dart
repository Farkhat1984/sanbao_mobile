/// Chat state providers using Riverpod.
///
/// Manages the core chat state: current conversation, messages,
/// streaming state, and the send message flow with NDJSON parsing.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/network/ndjson_parser.dart';
import 'package:sanbao_flutter/features/chat/data/models/chat_event_model.dart';
import 'package:sanbao_flutter/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:sanbao_flutter/features/chat/data/repositories/conversation_repository_impl.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/artifact.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/chat_event.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/conversation.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';
import 'package:sanbao_flutter/features/chat/domain/repositories/chat_repository.dart';
import 'package:sanbao_flutter/features/chat/domain/usecases/send_message_usecase.dart';

// ---- ID Generation ----

int _idCounter = 0;

/// Generates a locally-unique ID for messages.
String _generateId() {
  _idCounter++;
  return 'local_${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
}

// ---- Current Conversation ----

/// The currently active conversation ID (null for new chat).
final currentConversationIdProvider = StateProvider<String?>((ref) => null);

/// The currently active agent ID.
final currentAgentIdProvider = StateProvider<String?>((ref) => null);

/// The current conversation entity, loaded when the ID changes.
final currentConversationProvider =
    FutureProvider.autoDispose<Conversation?>((ref) async {
  final id = ref.watch(currentConversationIdProvider);
  if (id == null) return null;

  final repo = ref.watch(conversationRepositoryProvider);
  return repo.getConversation(id);
});

// ---- Messages ----

/// The message list for the current conversation.
final messagesProvider =
    StateNotifierProvider<MessagesNotifier, List<Message>>((ref) {
  return MessagesNotifier(ref);
});

/// State notifier for managing the message list.
class MessagesNotifier extends StateNotifier<List<Message>> {
  MessagesNotifier(this._ref) : super(const []) {
    // Load messages when conversation changes
    _ref.listen(currentConversationIdProvider, (previous, next) {
      if (next != previous) {
        if (next != null) {
          loadMessages(next);
        } else {
          state = const [];
        }
      }
    });
  }

  final Ref _ref;

  /// Loads messages for a conversation from the repository.
  Future<void> loadMessages(String conversationId) async {
    try {
      final repo = _ref.read(conversationRepositoryProvider);
      final messages = await repo.getMessages(conversationId);
      state = messages;
    } on Object {
      // Keep current state on error
    }
  }

  /// Adds a message to the list.
  void addMessage(Message message) {
    state = [...state, message];
  }

  /// Updates the last assistant message during streaming.
  void updateLastAssistantMessage({
    String? appendContent,
    String? appendReasoning,
    String? appendPlan,
    List<Artifact>? artifacts,
    List<String>? toolsUsed,
    bool? isStreaming,
  }) {
    if (state.isEmpty) return;

    final lastIndex = state.length - 1;
    final lastMessage = state[lastIndex];

    if (!lastMessage.isAssistant) return;

    final updated = lastMessage.copyWith(
      content: appendContent != null
          ? '${lastMessage.content}$appendContent'
          : null,
      reasoningContent: appendReasoning != null
          ? '${lastMessage.reasoningContent ?? ''}$appendReasoning'
          : null,
      planContent: appendPlan != null
          ? '${lastMessage.planContent ?? ''}$appendPlan'
          : null,
      artifacts: artifacts ?? lastMessage.artifacts,
      toolsUsed: toolsUsed ?? lastMessage.toolsUsed,
      isStreaming: isStreaming,
    );

    state = [...state.sublist(0, lastIndex), updated];
  }

  /// Marks the last assistant message as finished (no longer streaming).
  void finishStreaming() {
    if (state.isEmpty) return;

    final lastIndex = state.length - 1;
    final lastMessage = state[lastIndex];

    if (!lastMessage.isAssistant) return;

    // Extract artifacts from the final content
    final result = SanbaoTagParser.extractArtifacts(lastMessage.content);

    final updated = lastMessage.copyWith(
      isStreaming: false,
      content: result.cleanContent,
      artifacts: result.artifacts.isNotEmpty
          ? result.artifacts
          : lastMessage.artifacts,
    );

    state = [...state.sublist(0, lastIndex), updated];
  }

  /// Sets an error on the last assistant message.
  void setError(String errorMessage) {
    if (state.isEmpty) return;

    final lastIndex = state.length - 1;
    final lastMessage = state[lastIndex];

    if (!lastMessage.isAssistant) return;

    final updated = lastMessage.copyWith(
      isStreaming: false,
      isError: true,
      errorMessage: errorMessage,
    );

    state = [...state.sublist(0, lastIndex), updated];
  }

  /// Clears all messages.
  void clear() {
    state = const [];
  }
}

// ---- Streaming State ----

/// Whether the AI is currently streaming a response.
final isStreamingProvider = StateProvider<bool>((ref) => false);

/// The current streaming phase.
final streamingPhaseProvider = StateProvider<StreamingPhase?>((ref) => null);

/// The current tool name being used (if any).
final streamingToolNameProvider = StateProvider<String?>((ref) => null);

/// Context usage information from the stream.
final contextUsageProvider = StateProvider<ContextEvent?>((ref) => null);

// ---- AI Feature Toggles ----

/// Whether reasoning/thinking mode is enabled.
final thinkingEnabledProvider = StateProvider<bool>((ref) => true);

/// Whether web search is enabled.
final webSearchEnabledProvider = StateProvider<bool>((ref) => false);

/// Whether planning mode is enabled.
final planningEnabledProvider = StateProvider<bool>((ref) => false);

// ---- Send Message ----

/// Provider for the send message use case.
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return SendMessageUseCase(repository: repository);
});

/// Controller provider for sending messages.
///
/// This is the main entry point for the chat interaction flow.
/// It handles:
/// 1. Creating the user message
/// 2. Adding a placeholder assistant message
/// 3. Starting the stream
/// 4. Accumulating content from events
/// 5. Extracting artifacts on completion
final chatControllerProvider = Provider<ChatController>((ref) {
  return ChatController(ref);
});

/// Controls the chat message send flow and stream handling.
class ChatController {
  ChatController(this._ref);

  final Ref _ref;
  StreamSubscription<ChatEvent>? _streamSubscription;

  /// Sends a user message and starts streaming the response.
  ///
  /// Optionally includes file [attachments] as API payload maps.
  /// Each attachment map should contain `id`, `name`, `mimeType`,
  /// `size`, and optionally `parsedText`.
  Future<void> sendMessage(
    String content, {
    List<MessageAttachment> messageAttachments = const [],
    List<Map<String, Object?>> apiAttachments = const [],
  }) async {
    final conversationId = _ref.read(currentConversationIdProvider);
    final agentId = _ref.read(currentAgentIdProvider);
    final messages = _ref.read(messagesProvider);
    final thinkingEnabled = _ref.read(thinkingEnabledProvider);
    final webSearchEnabled = _ref.read(webSearchEnabledProvider);
    final planningEnabled = _ref.read(planningEnabledProvider);

    // Create user message (with optional attachments for UI display)
    final userMessage = Message.user(
      id: _generateId(),
      conversationId: conversationId ?? '',
      content: content,
      attachments: messageAttachments,
    );

    // Create placeholder assistant message
    final assistantMessage = Message.assistantPlaceholder(
      id: _generateId(),
      conversationId: conversationId ?? '',
    );

    // Add both messages to state
    final messagesNotifier = _ref.read(messagesProvider.notifier);
    messagesNotifier.addMessage(userMessage);
    messagesNotifier.addMessage(assistantMessage);

    // Set streaming state
    _ref.read(isStreamingProvider.notifier).state = true;
    _ref.read(streamingPhaseProvider.notifier).state =
        StreamingPhase.thinking;
    _ref.read(streamingToolNameProvider.notifier).state = null;

    // Build all messages for the API (include history)
    final allMessages = [...messages, userMessage];

    // Start streaming
    final useCase = _ref.read(sendMessageUseCaseProvider);
    final request = SendMessageRequest(
      messages: allMessages,
      conversationId: conversationId,
      agentId: agentId,
      thinkingEnabled: thinkingEnabled,
      webSearchEnabled: webSearchEnabled,
      planningEnabled: planningEnabled,
      attachments: messageAttachments,
    );

    final stream = useCase.call(request);

    _streamSubscription = stream.listen(
      (event) => _handleEvent(event),
      onError: (Object error) {
        messagesNotifier.setError(error.toString());
        _finishStream();
      },
      onDone: () {
        messagesNotifier.finishStreaming();
        _finishStream();
      },
    );
  }

  /// Handles a single chat event from the stream.
  void _handleEvent(ChatEvent event) {
    final messagesNotifier = _ref.read(messagesProvider.notifier);

    switch (event) {
      case ContentEvent(:final text):
        _ref.read(streamingPhaseProvider.notifier).state =
            StreamingPhase.answering;
        messagesNotifier.updateLastAssistantMessage(
          appendContent: text,
        );

      case ReasoningEvent(:final text):
        _ref.read(streamingPhaseProvider.notifier).state =
            StreamingPhase.thinking;
        messagesNotifier.updateLastAssistantMessage(
          appendReasoning: text,
        );

      case PlanEvent(:final text):
        _ref.read(streamingPhaseProvider.notifier).state =
            StreamingPhase.planning;
        messagesNotifier.updateLastAssistantMessage(
          appendPlan: text,
        );

      case StatusEvent(:final status):
        final phase = switch (status) {
          'searching' => StreamingPhase.searching,
          'using_tool' => StreamingPhase.usingTool,
          _ => null,
        };
        if (phase != null) {
          _ref.read(streamingPhaseProvider.notifier).state = phase;
          if (status == 'using_tool') {
            // Extract tool name if provided as "using_tool:tool_name"
            final parts = status.split(':');
            if (parts.length > 1) {
              _ref.read(streamingToolNameProvider.notifier).state = parts[1];
            }
          }
        }

      case ContextEvent():
        _ref.read(contextUsageProvider.notifier).state = event;

      case ErrorEvent(:final message):
        messagesNotifier.setError(message);
        _finishStream();
    }
  }

  /// Stops the current generation.
  void stopGeneration() {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    final useCase = _ref.read(sendMessageUseCaseProvider);
    useCase.stopGeneration();

    _ref.read(messagesProvider.notifier).finishStreaming();
    _finishStream();
  }

  /// Cleans up streaming state.
  void _finishStream() {
    _ref.read(isStreamingProvider.notifier).state = false;
    _ref.read(streamingPhaseProvider.notifier).state = null;
    _ref.read(streamingToolNameProvider.notifier).state = null;
    _streamSubscription = null;
  }

  /// Starts a new conversation.
  void startNewConversation() {
    _ref.read(currentConversationIdProvider.notifier).state = null;
    _ref.read(messagesProvider.notifier).clear();
    _ref.read(contextUsageProvider.notifier).state = null;
  }

  /// Loads an existing conversation.
  Future<void> loadConversation(String conversationId) async {
    _ref.read(currentConversationIdProvider.notifier).state = conversationId;
  }
}

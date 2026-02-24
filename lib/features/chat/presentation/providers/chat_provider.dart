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
    StateNotifierProvider<MessagesNotifier, List<Message>>(MessagesNotifier.new);

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

  /// Replaces the entire message list.
  // ignore: use_setters_to_change_properties
  void setMessages(List<Message> messages) => state = messages;

  /// Marks the last assistant message as finished (no longer streaming).
  ///
  /// Extracts artifacts from `<sanbao-doc>` tags, applies edits from
  /// `<sanbao-edit>` tags to existing artifacts, and performs title-based
  /// deduplication (same title → update content + bump version).
  void finishStreaming() {
    if (state.isEmpty) return;

    final lastIndex = state.length - 1;
    final lastMessage = state[lastIndex];

    if (!lastMessage.isAssistant) return;

    // 1. Extract artifacts from <sanbao-doc> tags
    final artifactResult =
        SanbaoTagParser.extractArtifacts(lastMessage.content);

    // 2. Extract edits from <sanbao-edit> tags
    final editResult = SanbaoTagParser.extractEdits(lastMessage.content);

    // 3. Clean content: remove both artifact and edit tags
    var cleanContent = artifactResult.cleanContent;
    if (editResult.edits.isNotEmpty) {
      cleanContent = SanbaoTagParser.editPattern
          .allMatches(cleanContent)
          .isNotEmpty
          ? cleanContent.replaceAll(SanbaoTagParser.editPattern, '').trim()
          : cleanContent;
    }

    // 4. Collect new artifacts (with title-based dedup against older messages)
    final newArtifacts = artifactResult.artifacts.isNotEmpty
        ? _deduplicateArtifacts(artifactResult.artifacts)
        : lastMessage.artifacts;

    // 5. Apply edits to existing artifacts across all messages
    final appliedEdits = <ArtifactEdit>[];
    if (editResult.edits.isNotEmpty) {
      for (final edit in editResult.edits) {
        final applied = _applyEditToArtifacts(edit);
        if (applied) {
          appliedEdits.add(edit);
        }
      }
    }

    final updated = lastMessage.copyWith(
      isStreaming: false,
      content: cleanContent,
      artifacts: newArtifacts,
      appliedEdits: appliedEdits.isNotEmpty ? appliedEdits : null,
    );

    state = [...state.sublist(0, lastIndex), updated];
  }

  /// Applies a single edit operation to artifacts found across all messages.
  ///
  /// Searches for the target artifact by title (case-insensitive) and
  /// applies all search/replace operations to its content.
  bool _applyEditToArtifacts(ArtifactEdit edit) {
    final messages = [...state];
    var applied = false;

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (!message.isAssistant || message.artifacts.isEmpty) continue;

      final artifactIndex = message.artifacts.indexWhere(
        (a) => a.title.toLowerCase() == edit.target.toLowerCase(),
      );
      if (artifactIndex == -1) continue;

      final artifact = message.artifacts[artifactIndex];
      var newContent = artifact.content;

      for (final replacement in edit.replacements) {
        newContent = newContent.replaceAll(
          replacement.oldText,
          replacement.newText,
        );
      }

      if (newContent != artifact.content) {
        final updatedArtifacts = [...message.artifacts];
        updatedArtifacts[artifactIndex] = artifact.copyWith(
          content: newContent,
        );
        messages[i] = message.copyWith(artifacts: updatedArtifacts);
        applied = true;
        break; // Apply to first matching artifact only
      }
    }

    if (applied) {
      state = messages;
    }
    return applied;
  }

  /// Deduplicates new artifacts against existing ones by title.
  ///
  /// If an artifact with the same title already exists in a previous
  /// message, updates the existing one instead of creating a duplicate.
  List<Artifact> _deduplicateArtifacts(List<Artifact> newArtifacts) {
    final messages = [...state];
    final result = <Artifact>[];
    var stateChanged = false;

    for (final artifact in newArtifacts) {
      var deduplicated = false;

      // Search older messages for same-title artifact
      for (var i = 0; i < messages.length - 1; i++) {
        final msg = messages[i];
        if (!msg.isAssistant || msg.artifacts.isEmpty) continue;

        final existingIndex = msg.artifacts.indexWhere(
          (a) => a.title.toLowerCase() == artifact.title.toLowerCase(),
        );
        if (existingIndex == -1) continue;

        final existing = msg.artifacts[existingIndex];
        if (existing.content != artifact.content) {
          // Update existing artifact with new content
          final updatedArtifacts = [...msg.artifacts];
          updatedArtifacts[existingIndex] = existing.copyWith(
            content: artifact.content,
          );
          messages[i] = msg.copyWith(artifacts: updatedArtifacts);
          stateChanged = true;
        }
        deduplicated = true;
        break;
      }

      if (!deduplicated) {
        result.add(artifact);
      }
    }

    if (stateChanged) {
      state = messages;
    }
    return result.isNotEmpty ? result : const [];
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

// ---- Pending Input (for regenerate) ----

/// Text to pre-fill in the message input (e.g. when regenerating).
final pendingInputProvider = StateProvider<String?>((ref) => null);

/// Clarification questions from the AI (from `<sanbao-clarify>` tags).
final clarifyQuestionsProvider =
    StateProvider<List<ClarifyQuestion>?>((ref) => null);

// ---- AI Feature Toggles ----

/// Whether reasoning/thinking mode is enabled.
final thinkingEnabledProvider = StateProvider<bool>((ref) => true);

/// Whether web search is enabled.
final webSearchEnabledProvider = StateProvider<bool>((ref) => false);

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
final chatControllerProvider = Provider<ChatController>(ChatController.new);

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
    final messagesNotifier = _ref.read(messagesProvider.notifier)
      ..addMessage(userMessage)
      ..addMessage(assistantMessage);

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
      attachments: messageAttachments,
    );

    final stream = useCase.call(request);

    _streamSubscription = stream.listen(
      _handleEvent,
      onError: (Object error) {
        messagesNotifier.setError(error.toString());
        _finishStream();
      },
      onDone: () {
        messagesNotifier.finishStreaming();
        _extractClarifyQuestions();
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
            StreamingPhase.answering;
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

    _ref.read(sendMessageUseCaseProvider).stopGeneration();

    _ref.read(messagesProvider.notifier).finishStreaming();
    _finishStream();
  }

  /// Extracts clarify questions from the last assistant message.
  void _extractClarifyQuestions() {
    final messages = _ref.read(messagesProvider);
    if (messages.isEmpty) return;

    final lastMessage = messages.last;
    if (!lastMessage.isAssistant) return;

    final result =
        SanbaoTagParser.extractClarifyQuestions(lastMessage.content);
    if (result.questions.isNotEmpty) {
      // Update message content to remove clarify tags
      final messagesNotifier = _ref.read(messagesProvider.notifier);
      final updated = [...messages];
      updated[updated.length - 1] = lastMessage.copyWith(
        content: result.cleanContent,
      );
      messagesNotifier.setMessages(updated);

      // Set clarify questions for the UI
      _ref.read(clarifyQuestionsProvider.notifier).state = result.questions;
    }
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

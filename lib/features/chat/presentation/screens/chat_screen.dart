/// Main chat screen with message list and floating input.
///
/// This is the CORE screen of the Sanbao app. It displays the
/// conversation messages, handles streaming with auto-scroll,
/// and shows the welcome screen when the conversation is empty.
/// On mobile, includes a hamburger menu to open the sidebar drawer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_compass.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact.dart'
    as full;
import 'package:sanbao_flutter/features/artifacts/presentation/screens/artifact_view_screen.dart';
import 'package:sanbao_flutter/features/chat/data/models/chat_event_model.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/chat_event.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';
import 'package:sanbao_flutter/features/chat/presentation/providers/chat_provider.dart';
import 'package:sanbao_flutter/features/chat/presentation/providers/file_provider.dart';
import 'package:sanbao_flutter/features/chat/presentation/screens/main_layout.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/clarify_bottom_sheet.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/message_bubble.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/message_input.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/thinking_indicator.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/welcome_screen.dart';
import 'package:sanbao_flutter/features/legal/presentation/widgets/legal_article_sheet.dart';
import 'package:sanbao_flutter/features/notifications/presentation/widgets/notification_bell.dart';

/// The main chat screen displaying messages and input.
///
/// Manages auto-scrolling during streaming, keyboard avoidance,
/// and transitions between empty state (welcome) and active chat.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  bool _userHasScrolledUp = false;
  bool _shouldAutoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    const threshold = 100.0;

    // User scrolled up -- stop auto-scrolling
    _userHasScrolledUp = maxScroll - currentScroll > threshold;
    _shouldAutoScroll = !_userHasScrolledUp;
  }

  /// Scrolls to the bottom of the message list.
  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: SanbaoAnimations.durationNormal,
          curve: SanbaoAnimations.smoothCurve,
        );
      } else {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  /// Shows the clarification questions bottom sheet.
  Future<void> _showClarifyQuestions(List<ClarifyQuestion> questions) async {
    // Clear the provider first to prevent re-triggering
    ref.read(clarifyQuestionsProvider.notifier).state = null;

    final answer = await showClarifySheet(context, questions);
    if (answer != null && answer.isNotEmpty) {
      ref.read(pendingInputProvider.notifier).state = answer;
    }
  }

  /// Handles regenerate: finds the user message before the given assistant
  /// message index and sets it as pending input.
  void _handleRegenerate(List<Message> messages, int assistantIndex) {
    for (var i = assistantIndex - 1; i >= 0; i--) {
      if (messages[i].isUser && messages[i].content.trim().isNotEmpty) {
        ref.read(pendingInputProvider.notifier).state = messages[i].content;
        break;
      }
    }
  }

  void _handleSendMessage(String content) {
    _shouldAutoScroll = true;
    _userHasScrolledUp = false;

    ref.read(chatControllerProvider).sendMessage(content);

    // Scroll to bottom after sending
    _scrollToBottom();
  }

  void _handleSendWithAttachments(
    String content,
    List<Map<String, Object?>> apiAttachments,
  ) {
    _shouldAutoScroll = true;
    _userHasScrolledUp = false;

    // Build MessageAttachment list for UI display from file provider
    final fileNotifier = ref.read(fileAttachmentsProvider.notifier);
    final messageAttachments = fileNotifier.toMessageAttachments();

    ref.read(chatControllerProvider).sendMessage(
      content,
      messageAttachments: messageAttachments,
      apiAttachments: apiAttachments,
    );

    // Scroll to bottom after sending
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final isStreaming = ref.watch(isStreamingProvider);
    final streamingPhase = ref.watch(streamingPhaseProvider);
    final toolName = ref.watch(streamingToolNameProvider);
    final colors = context.sanbaoColors;

    // Listen for clarification questions from AI
    ref.listen(clarifyQuestionsProvider, (previous, next) {
      if (next != null && next.isNotEmpty && mounted) {
        _showClarifyQuestions(next);
      }
    });

    // Auto-scroll when streaming and user hasn't scrolled up
    if (isStreaming && _shouldAutoScroll) {
      _scrollToBottom();
    }

    final isEmpty = messages.isEmpty;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: _buildAppBar(context, isStreaming),
      body: Column(
        children: [
          // Message list or welcome screen
          Expanded(
            child: isEmpty
                ? WelcomeScreen(
                    onPromptSelected: _handleSendMessage,
                  )
                : _buildMessageList(
                    context,
                    messages,
                    isStreaming,
                    streamingPhase,
                    toolName,
                  ),
          ),

          // Floating input
          MessageInput(
            onSend: _handleSendMessage,
            onSendWithAttachments: _handleSendWithAttachments,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isStreaming) {
    final colors = context.sanbaoColors;
    final conversationAsync = ref.watch(currentConversationProvider);
    final isMobile = context.isMobile;

    final title = conversationAsync.whenOrNull(
          data: (conversation) => conversation?.title,
        ) ??
        'Новый чат';

    return AppBar(
      leading: isMobile
          ? IconButton(
              onPressed: () => context.openMainDrawer(),
              icon: Icon(
                Icons.menu_rounded,
                color: colors.textSecondary,
              ),
              tooltip: 'Меню',
            )
          : null,
      automaticallyImplyLeading: false,
      titleSpacing: isMobile ? 0 : 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated compass during streaming
          if (isStreaming)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SanbaoCompass(
                state: CompassState.thinking,
                size: 20,
                color: colors.accent,
              ),
            ),

          Flexible(
            child: Text(
              title,
              style: context.textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell
        const NotificationBell(),
        // New chat button
        IconButton(
          onPressed: () {
            ref.read(chatControllerProvider).startNewConversation();
          },
          icon: Icon(
            Icons.edit_square,
            size: 20,
            color: colors.textSecondary,
          ),
          tooltip: 'Новый чат',
        ),
      ],
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    List<Message> messages,
    bool isStreaming,
    StreamingPhase? streamingPhase,
    String? toolName,
  ) => ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: messages.length + (isStreaming && streamingPhase != null ? 1 : 0),
      itemBuilder: (context, index) {
        // Thinking indicator at the bottom during streaming
        if (index == messages.length) {
          return Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ThinkingIndicator(
              phase: streamingPhase!,
              toolName: toolName,
            ),
          );
        }

        final message = messages[index];

        // Skip showing the thinking indicator row if the last assistant
        // message is streaming and has no content yet
        if (message.isAssistant &&
            message.isStreaming &&
            !message.hasContent &&
            !message.hasReasoning) {
          return const SizedBox.shrink();
        }

        return MessageBubble(
          key: ValueKey(message.id),
          message: message,
          showTimestamp: _shouldShowTimestamp(messages, index),
          animate: index >= messages.length - 2,
          onArtifactOpen: (artifactId) {
            final artifact = message.artifacts
                .where((a) => a.id == artifactId)
                .firstOrNull;
            if (artifact == null) return;

            openArtifactViewer(
              context: context,
              ref: ref,
              artifact: full.FullArtifact(
                id: artifact.id,
                type: full.ArtifactType.fromString(artifact.type.name),
                title: artifact.title,
                content: artifact.content,
                language: artifact.language,
                conversationId:
                    ref.read(currentConversationIdProvider),
                messageId: message.id,
              ),
            );
          },
          onLegalReferenceTap: (codeName, article) {
            showLegalArticleSheet(
              context,
              codeName: codeName,
              articleNum: article,
            );
          },
          onRetry: message.isError
              ? () {
                  // Retry: remove error message and resend the last user message
                  final lastUserMessage = messages
                      .where((m) => m.isUser)
                      .lastOrNull;
                  if (lastUserMessage != null) {
                    _handleSendMessage(lastUserMessage.content);
                  }
                }
              : null,
          onRegenerate: message.isAssistant && !message.isError
              ? () => _handleRegenerate(messages, index)
              : null,
        );
      },
    );

  /// Determines whether to show a timestamp for a message.
  ///
  /// Shows timestamp when:
  /// - It's the last message
  /// - More than 5 minutes have passed since the previous message
  /// - The previous message is from a different role
  bool _shouldShowTimestamp(List<Message> messages, int index) {
    if (index == messages.length - 1) return true;

    final current = messages[index];
    final next = messages[index + 1];

    // Different role
    if (current.role != next.role) return true;

    // More than 5 minutes gap
    final gap = next.createdAt.difference(current.createdAt);
    return gap.inMinutes >= 5;
  }
}

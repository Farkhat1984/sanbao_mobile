/// Message bubble widget for user and assistant messages.
///
/// User messages: right-aligned with blue gradient background.
/// Assistant messages: left-aligned with markdown rendering,
/// collapsible reasoning section, and inline artifact cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/utils/formatters.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/message.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/artifact_card.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/file_attachment.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/markdown_renderer.dart';

/// A chat message bubble with different styles for user and assistant.
///
/// User messages are right-aligned with a blue gradient.
/// Assistant messages are left-aligned with full markdown rendering,
/// collapsible reasoning, and artifact cards.
class MessageBubble extends StatefulWidget {
  const MessageBubble({
    required this.message,
    super.key,
    this.showTimestamp = false,
    this.onArtifactOpen,
    this.onLegalReferenceTap,
    this.onCopy,
    this.onRetry,
    this.animate = true,
  });

  /// The message to display.
  final Message message;

  /// Whether to show the timestamp below the bubble.
  final bool showTimestamp;

  /// Callback when an artifact's "Open" button is tapped.
  final void Function(String artifactId)? onArtifactOpen;

  /// Callback when a legal reference link is tapped.
  final void Function(String codeName, String article)? onLegalReferenceTap;

  /// Callback when the copy action is triggered.
  final VoidCallback? onCopy;

  /// Callback when the retry action is triggered (for error messages).
  final VoidCallback? onRetry;

  /// Whether to animate the bubble entrance.
  final bool animate;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterController;
  bool _reasoningExpanded = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationNormal,
    );
    if (widget.animate) {
      _enterController.forward();
    } else {
      _enterController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;

    return FadeTransition(
      opacity: _enterController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, SanbaoAnimations.messageAppearOffset / 100),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _enterController,
          curve: SanbaoAnimations.smoothCurve,
        )),
        child: Padding(
          padding: EdgeInsets.only(
            left: isUser ? 48 : 16,
            right: isUser ? 16 : 48,
            top: 4,
            bottom: 4,
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              isUser ? _buildUserBubble(context) : _buildAssistantBubble(context),
              if (widget.showTimestamp) _buildTimestamp(context),
            ],
          ),
        ),
      ),
    );
  }

  // ---- User Bubble ----

  Widget _buildUserBubble(BuildContext context) {
    final colors = context.sanbaoColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Attachments above the message
        if (widget.message.hasAttachments)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: FileAttachmentGrid(
              attachments: widget.message.attachments,
            ),
          ),

        // Message bubble
        GestureDetector(
          onLongPress: () => _showCopyMenu(context),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: context.screenWidth * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SanbaoColors.accent, SanbaoColors.accentHover],
              ),
              borderRadius: SanbaoRadius.userMessage,
              boxShadow: SanbaoShadows.sm,
            ),
            child: SelectableText(
              widget.message.content,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textInverse,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---- Assistant Bubble ----

  Widget _buildAssistantBubble(BuildContext context) {
    final colors = context.sanbaoColors;

    // Error state
    if (widget.message.isError) {
      return _buildErrorBubble(context);
    }

    // Empty streaming placeholder
    if (widget.message.isStreaming && !widget.message.hasContent) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onLongPress: () => _showCopyMenu(context),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: context.screenWidth * 0.85,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: SanbaoRadius.assistantMessage,
          border: Border.all(
            color: colors.border,
            width: 0.5,
          ),
          boxShadow: SanbaoShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collapsible reasoning section
            if (widget.message.hasReasoning)
              _buildReasoningSection(context),

            // Plan section
            if (widget.message.hasPlan)
              _buildPlanSection(context),

            // Main content (Markdown)
            if (widget.message.hasContent)
              MarkdownRenderer(
                content: widget.message.content,
                onLegalReferenceTap: widget.onLegalReferenceTap,
              ),

            // Streaming cursor
            if (widget.message.isStreaming && widget.message.hasContent)
              _buildStreamingCursor(colors),

            // Artifact cards
            if (widget.message.hasArtifacts)
              ...widget.message.artifacts.map(
                (artifact) => ArtifactCard(
                  artifact: artifact,
                  onOpen: () => widget.onArtifactOpen?.call(artifact.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- Reasoning Section ----

  Widget _buildReasoningSection(BuildContext context) {
    final colors = context.sanbaoColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle button
          GestureDetector(
            onTap: () => setState(() {
              _reasoningExpanded = !_reasoningExpanded;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                borderRadius: SanbaoRadius.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: 14,
                    color: colors.legalRef,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Рассуждения',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.legalRef,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _reasoningExpanded ? 0.5 : 0,
                    duration: SanbaoAnimations.durationFast,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: colors.legalRef,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceAlt,
                  borderRadius: SanbaoRadius.sm,
                  border: Border.all(
                    color: colors.border,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  widget.message.reasoningContent!,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            crossFadeState: _reasoningExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: SanbaoAnimations.durationNormal,
          ),
        ],
      ),
    );
  }

  // ---- Plan Section ----

  Widget _buildPlanSection(BuildContext context) {
    final colors = context.sanbaoColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
          borderRadius: SanbaoRadius.sm,
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.checklist_rounded,
                  size: 14,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 6),
                Text(
                  'План',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            MarkdownRenderer(
              content: widget.message.planContent!,
              selectable: false,
            ),
          ],
        ),
      ),
    );
  }

  // ---- Error Bubble ----

  Widget _buildErrorBubble(BuildContext context) {
    final colors = context.sanbaoColors;

    return Container(
      constraints: BoxConstraints(
        maxWidth: context.screenWidth * 0.85,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorLight,
        borderRadius: SanbaoRadius.assistantMessage,
        border: Border.all(
          color: colors.error.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: colors.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.message.errorMessage ?? 'Произошла ошибка',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.error,
                  ),
                ),
              ),
            ],
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.onRetry,
              child: Text(
                'Попробовать снова',
                style: context.textTheme.labelMedium?.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Streaming Cursor ----

  Widget _buildStreamingCursor(SanbaoColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: _BlinkingCursor(color: colors.accent),
    );
  }

  // ---- Timestamp ----

  Widget _buildTimestamp(BuildContext context) {
    final colors = context.sanbaoColors;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        Formatters.formatTime(widget.message.createdAt),
        style: context.textTheme.labelSmall?.copyWith(
          color: colors.textMuted,
          fontSize: 10,
        ),
      ),
    );
  }

  // ---- Copy Menu ----

  void _showCopyMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    final content = widget.message.content;
    if (content.isEmpty) return;

    Clipboard.setData(ClipboardData(text: content));
    context.showSnackBar('Скопировано в буфер обмена');
    widget.onCopy?.call();
  }
}

/// A blinking text cursor for the streaming state.
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});

  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _controller.value,
        child: child,
      ),
      child: Container(
        width: 2,
        height: 16,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

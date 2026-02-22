/// Floating pill-shaped chat input widget.
///
/// Features auto-resizing text field, animated send button,
/// stop button during streaming, file attach button with picker,
/// file preview grid, voice button with speech-to-text,
/// feature toggle badges, and gradient border animation on focus.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/gradient_border.dart';
import 'package:sanbao_flutter/features/chat/presentation/providers/chat_provider.dart';
import 'package:sanbao_flutter/features/chat/presentation/providers/file_provider.dart';
import 'package:sanbao_flutter/features/chat/presentation/providers/voice_provider.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/feature_badges.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/file_attachment.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/file_picker_sheet.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/voice_button.dart';

/// The floating chat input field at the bottom of the chat screen.
///
/// Wraps a [TextFormField] in a pill shape with animated gradient border
/// on focus. Includes send, stop, attach, and voice buttons. Displays
/// feature toggle badges above the input and a file preview grid when
/// files are attached.
class MessageInput extends ConsumerStatefulWidget {
  const MessageInput({
    super.key,
    this.onSend,
    this.onSendWithAttachments,
    this.enabled = true,
  });

  /// Callback when the user sends a text-only message.
  final void Function(String message)? onSend;

  /// Callback when the user sends a message with file attachments.
  final void Function(
    String message,
    List<Map<String, Object?>> attachments,
  )? onSendWithAttachments;

  /// Whether the input is enabled.
  final bool enabled;

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasText = false;
  bool _isVoiceRecording = false;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(_onFocusChange);
    _textController.addListener(_onTextChange);

    _sendButtonController = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationFast,
    );
    _sendButtonScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sendButtonController,
        curve: SanbaoAnimations.springCurve,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _onTextChange() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      _updateSendButton();
    }
  }

  /// Updates the send button animation based on text and attachment state.
  void _updateSendButton() {
    final hasAttachments = ref.read(hasFileAttachmentsProvider);
    final shouldShow = _hasText || hasAttachments;

    if (shouldShow) {
      _sendButtonController.forward();
    } else {
      _sendButtonController.reverse();
    }
  }

  void _handleSend() {
    final text = _textController.text.trim();
    final hasAttachments = ref.read(hasFileAttachmentsProvider);
    final allUploaded = ref.read(allFilesUploadedProvider);

    // Must have text or attachments
    if (text.isEmpty && !hasAttachments) return;

    // Check message size limit
    if (text.length > AppConfig.maxMessageSizeBytes) {
      context.showErrorSnackBar('Сообщение слишком длинное');
      return;
    }

    // Wait for uploads to finish
    if (hasAttachments && !allUploaded) {
      context.showSnackBar('Подождите, файлы загружаются...');
      return;
    }

    unawaited(HapticFeedback.lightImpact());

    if (hasAttachments) {
      final fileNotifier = ref.read(fileAttachmentsProvider.notifier);
      final apiAttachments = fileNotifier.toApiAttachments();
      widget.onSendWithAttachments?.call(text, apiAttachments);
      fileNotifier.clearAll();
    } else {
      widget.onSend?.call(text);
    }

    _textController.clear();
    _focusNode.requestFocus();
  }

  void _handleStop() {
    unawaited(HapticFeedback.mediumImpact());
    ref.read(chatControllerProvider).stopGeneration();
  }

  Future<void> _handleAttachFile() async {
    unawaited(HapticFeedback.lightImpact());

    final results = await showFilePickerSheet(context);
    if (results == null || results.isEmpty) return;

    final notifier = ref.read(fileAttachmentsProvider.notifier);

    for (final file in results) {
      final error = notifier.addFile(
        name: file.name,
        sizeBytes: file.sizeBytes,
        mimeType: file.mimeType,
        bytes: file.bytes,
        localPath: file.path,
      );

      if (error != null && mounted) {
        context.showErrorSnackBar(error);
        break;
      }
    }

    // Update send button visibility
    _updateSendButton();
  }

  void _onVoiceResult(String recognizedText) {
    if (recognizedText.isEmpty) return;

    // Append recognized text to the input field
    final currentText = _textController.text;
    final separator =
        currentText.isNotEmpty && !currentText.endsWith(' ') ? ' ' : '';
    _textController.text = '$currentText$separator$recognizedText';
    _textController.selection = TextSelection.collapsed(
      offset: _textController.text.length,
    );
  }

  void _onVoicePartialResult(String partialText) {
    // Update the partial recognition provider for potential UI preview
    ref.read(partialRecognitionProvider.notifier).state =
        partialText.isNotEmpty ? partialText : null;
  }

  void _onVoiceRecordingStateChanged({required bool isRecording}) {
    setState(() => _isVoiceRecording = isRecording);
    // Sync recording state to the voice provider for cross-widget access
    ref.read(isVoiceRecordingProvider.notifier).state = isRecording;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final isStreaming = ref.watch(isStreamingProvider);
    final hasAttachments = ref.watch(hasFileAttachmentsProvider);
    final isUploading = ref.watch(isUploadingFilesProvider);
    final bottomPadding = context.bottomPadding;

    // Listen for pending input (from regenerate)
    ref.listen(pendingInputProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        _textController.text = next;
        _textController.selection = TextSelection.collapsed(
          offset: next.length,
        );
        _focusNode.requestFocus();
        ref.read(pendingInputProvider.notifier).state = null;
      }
    });

    // Keep send button in sync with attachment changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSendButton();
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Feature toggle badges
        if (!isStreaming)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: FeatureBadges(),
          ),

        // Main input container
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: hasAttachments ? 4 : 8,
            bottom: bottomPadding > 0 ? bottomPadding + 4 : 12,
          ),
          decoration: BoxDecoration(
            color: colors.bg,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pending file attachments preview
                if (hasAttachments) const PendingAttachmentGrid(),

                // Input field
                GradientBorder(
                  isActive: _isFocused,
                  borderRadius: SanbaoRadius.input,
                  opacity: 0.0,
                  activeOpacity: 0.6,
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      maxHeight: 200,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: SanbaoRadius.input,
                      border: Border.all(
                        color:
                            _isFocused ? colors.borderFocus : colors.border,
                        width: _isFocused ? 0 : 0.5,
                      ),
                      boxShadow: _isFocused
                          ? SanbaoShadows.inputFocus
                          : SanbaoShadows.input,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Attach button
                        if (AppConfig.enableFileAttachments)
                          _buildAttachButton(colors, isUploading),

                        // Text input
                        Expanded(child: _buildTextField(colors)),

                        // Voice button (when no text and not streaming)
                        if (AppConfig.enableVoiceInput &&
                            !_hasText &&
                            !isStreaming &&
                            !hasAttachments)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: VoiceButton(
                              size: 40,
                              onResult: _onVoiceResult,
                              onPartialResult: _onVoicePartialResult,
                              onRecordingStateChanged:
                                  _onVoiceRecordingStateChanged,
                            ),
                          ),

                        // Send / Stop button
                        Padding(
                          padding: const EdgeInsets.only(right: 4, bottom: 4),
                          child: isStreaming
                              ? _buildStopButton(colors)
                              : _buildSendButton(colors),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- Attach Button ----

  Widget _buildAttachButton(SanbaoColorScheme colors, bool isUploading) =>
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Stack(
          children: [
            IconButton(
              onPressed: _handleAttachFile,
              icon: Icon(
                Icons.attach_file_rounded,
                color: colors.textMuted,
                size: 22,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              splashRadius: 20,
            ),

            // Upload progress indicator dot
            if (isUploading)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: SanbaoColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      );

  // ---- Text Field ----

  Widget _buildTextField(SanbaoColorScheme colors) {
    final hintText = _isVoiceRecording ? 'Говорите...' : 'Сообщение...';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: widget.enabled,
        maxLines: null,
        minLines: 1,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        style: context.textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: context.textTheme.bodyMedium?.copyWith(
            color: _isVoiceRecording ? colors.error : colors.textMuted,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          fillColor: Colors.transparent,
          filled: true,
          isDense: true,
        ),
        onFieldSubmitted: (_) {
          if (_hasText) _handleSend();
        },
      ),
    );
  }

  // ---- Send Button ----

  Widget _buildSendButton(SanbaoColorScheme colors) => AnimatedBuilder(
        animation: _sendButtonScale,
        builder: (context, child) {
          final scale = _sendButtonScale.value;
          if (scale < 0.01) return const SizedBox(width: 40, height: 40);

          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: (_hasText || ref.read(hasFileAttachmentsProvider))
              ? _handleSend
              : null,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [SanbaoColors.accent, SanbaoColors.accentHover],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );

  // ---- Stop Button ----

  Widget _buildStopButton(SanbaoColorScheme colors) => GestureDetector(
        onTap: _handleStop,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.error.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.stop_rounded,
            color: colors.error,
            size: 20,
          ),
        ),
      );
}

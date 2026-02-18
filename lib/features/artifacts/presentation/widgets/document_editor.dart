/// Rich document editor with live preview and formatting toolbar.
///
/// Composes [MarkdownEditor] (the editing surface) with
/// [EditorToolbar] (formatting buttons) and an optional
/// [DocumentPreview] pane for live Markdown rendering.
///
/// Layout adapts to screen size:
/// - Mobile: Tabs to switch between Edit and Preview modes
/// - Tablet/Desktop: Side-by-side split view (editor | preview)
///
/// Features:
/// - Full markdown formatting toolbar (bold, italic, headings,
///   code, lists, links, quotes)
/// - Undo/redo support
/// - Auto-save with debounce and visual unsaved indicator
/// - Optional line numbers toggle
/// - Live preview rendering via [DocumentPreview]
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/widgets/document_preview.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/widgets/editor_toolbar.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/widgets/markdown_editor.dart';

/// The two sub-tabs available inside the editor on mobile.
enum _EditorSubTab {
  edit,
  preview;

  String get label => switch (this) {
        _EditorSubTab.edit => 'Редактор',
        _EditorSubTab.preview => 'Просмотр',
      };
}

/// A Markdown-aware document editor with formatting toolbar.
///
/// Provides:
/// - Bold, Italic, Inline Code, Code Block toggle buttons
/// - Heading level selector (H1-H3)
/// - Bulleted and numbered list toggles
/// - Blockquote and link insertion
/// - Undo/Redo via system undo controller
/// - Auto-save with configurable debounce delay
/// - Mobile: tab switch between editor and preview
/// - Tablet: side-by-side split view
class DocumentEditor extends StatefulWidget {
  const DocumentEditor({
    required this.content,
    required this.onContentChanged,
    super.key,
    this.readOnly = false,
    this.autosaveDelay = const Duration(seconds: 2),
  });

  /// The initial Markdown content.
  final String content;

  /// Callback when content changes (debounced for auto-save).
  final ValueChanged<String> onContentChanged;

  /// Whether the editor is read-only.
  final bool readOnly;

  /// Delay before auto-save triggers after the last keystroke.
  final Duration autosaveDelay;

  @override
  State<DocumentEditor> createState() => _DocumentEditorState();
}

class _DocumentEditorState extends State<DocumentEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final UndoHistoryController _undoController;
  final GlobalKey<MarkdownEditorState> _editorKey = GlobalKey();

  Timer? _saveTimer;
  bool _hasUnsavedChanges = false;
  bool _showLineNumbers = false;
  _EditorSubTab _mobileTab = _EditorSubTab.edit;

  /// Tracks the current formatting state at the cursor position.
  MarkdownFormatState _formatState = const MarkdownFormatState();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content)
      ..addListener(_onSelectionOrTextChanged);
    _focusNode = FocusNode();
    _undoController = UndoHistoryController();
  }

  @override
  void didUpdateWidget(DocumentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // External content update (e.g., version restore) -- sync if different
    if (widget.content != oldWidget.content &&
        widget.content != _controller.text) {
      _controller.text = widget.content;
      _hasUnsavedChanges = false;
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _controller
      ..removeListener(_onSelectionOrTextChanged)
      ..dispose();
    _focusNode.dispose();
    _undoController.dispose();
    super.dispose();
  }

  // ---- Event handlers ----

  /// Called on every text change or cursor movement to update
  /// the formatting state and schedule auto-save.
  void _onSelectionOrTextChanged() {
    // Detect formatting at cursor
    final editorState = _editorKey.currentState;
    if (editorState != null) {
      final newState = editorState.detectFormatState();
      if (_formatState != newState) {
        setState(() => _formatState = newState);
      }
    }
  }

  /// Called by the MarkdownEditor's onChanged callback.
  void _onTextChanged(String text) {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(widget.autosaveDelay, _autoSave);
  }

  void _autoSave() {
    if (_hasUnsavedChanges && mounted) {
      widget.onContentChanged(_controller.text);
      setState(() => _hasUnsavedChanges = false);
    }
  }

  /// Triggers an immediate save (used by the save button).
  void _saveNow() {
    _saveTimer?.cancel();
    widget.onContentChanged(_controller.text);
    setState(() => _hasUnsavedChanges = false);
  }

  // ---- Toolbar building ----

  /// Builds the list of toolbar items with the current format state.
  List<ToolbarItem> _buildToolbarItems() => [
        // Undo / Redo
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'undo',
            icon: Icons.undo_rounded,
            tooltip: 'Отменить (Ctrl+Z)',
            onTap: () => _undoController.undo(),
          ),
        ),
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'redo',
            icon: Icons.redo_rounded,
            tooltip: 'Повторить (Ctrl+Y)',
            onTap: () => _undoController.redo(),
          ),
        ),

        const ToolbarDividerItem(),

        // Text formatting
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'bold',
            icon: Icons.format_bold_rounded,
            tooltip: 'Жирный (Ctrl+B)',
            isActive: _formatState.isBold,
            onTap: () => _editorKey.currentState?.toggleBold(),
          ),
        ),
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'italic',
            icon: Icons.format_italic_rounded,
            tooltip: 'Курсив (Ctrl+I)',
            isActive: _formatState.isItalic,
            onTap: () => _editorKey.currentState?.toggleItalic(),
          ),
        ),

        const ToolbarDividerItem(),

        // Headings
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'h1',
            label: 'H1',
            tooltip: 'Заголовок 1',
            isActive: _formatState.headingLevel == 1,
            onTap: () => _editorKey.currentState?.toggleHeading(1),
          ),
        ),
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'h2',
            label: 'H2',
            tooltip: 'Заголовок 2',
            isActive: _formatState.headingLevel == 2,
            onTap: () => _editorKey.currentState?.toggleHeading(2),
          ),
        ),
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'h3',
            label: 'H3',
            tooltip: 'Заголовок 3',
            isActive: _formatState.headingLevel == 3,
            onTap: () => _editorKey.currentState?.toggleHeading(3),
          ),
        ),

        const ToolbarDividerItem(),

        // Inline code
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'inline_code',
            icon: Icons.code_rounded,
            tooltip: 'Код (Ctrl+`)',
            isActive: _formatState.isInlineCode,
            onTap: () => _editorKey.currentState?.toggleInlineCode(),
          ),
        ),

        // Code block
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'code_block',
            icon: Icons.data_object_rounded,
            tooltip: 'Блок кода',
            isActive: _formatState.isCodeBlock,
            onTap: () => _editorKey.currentState?.insertCodeBlock(),
          ),
        ),

        const ToolbarDividerItem(),

        // Lists
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'bullet_list',
            icon: Icons.format_list_bulleted_rounded,
            tooltip: 'Маркированный список',
            isActive: _formatState.isBulletList,
            onTap: () => _editorKey.currentState?.toggleBulletList(),
          ),
        ),
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'numbered_list',
            icon: Icons.format_list_numbered_rounded,
            tooltip: 'Нумерованный список',
            isActive: _formatState.isNumberedList,
            onTap: () => _editorKey.currentState?.toggleNumberedList(),
          ),
        ),

        const ToolbarDividerItem(),

        // Block quote
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'quote',
            icon: Icons.format_quote_rounded,
            tooltip: 'Цитата',
            isActive: _formatState.isBlockquote,
            onTap: () => _editorKey.currentState?.toggleBlockquote(),
          ),
        ),

        // Link
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'link',
            icon: Icons.link_rounded,
            tooltip: 'Ссылка',
            onTap: () => _editorKey.currentState?.insertLink(),
          ),
        ),

        const ToolbarDividerItem(),

        // Line numbers toggle
        ToolbarCommandItem(
          ToolbarCommand(
            id: 'line_numbers',
            icon: Icons.format_list_numbered_rtl_rounded,
            tooltip: _showLineNumbers ? 'Скрыть номера строк' : 'Номера строк',
            isActive: _showLineNumbers,
            onTap: () => setState(() => _showLineNumbers = !_showLineNumbers),
          ),
        ),
      ];

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final isWide = !context.isMobile;
    final colors = context.sanbaoColors;

    return Column(
      children: [
        // Formatting toolbar (shared between mobile and tablet)
        EditorToolbar(
          items: _buildToolbarItems(),
          visible: !widget.readOnly,
        ),

        // Mobile sub-tab bar (edit/preview toggle)
        if (!isWide) _buildMobileTabBar(colors),

        // Main content area
        Expanded(
          child: isWide ? _buildSplitView(colors) : _buildMobileContent(colors),
        ),

        // Unsaved changes indicator
        _UnsavedBanner(
          visible: _hasUnsavedChanges,
          onSave: _saveNow,
        ),
      ],
    );
  }

  /// Builds the mobile tab bar for switching between edit and preview.
  Widget _buildMobileTabBar(SanbaoColorScheme colors) => DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgSurfaceAlt,
          border: Border(
            bottom: BorderSide(color: colors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: _EditorSubTab.values.map((tab) {
            final isActive = tab == _mobileTab;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _mobileTab = tab),
                child: AnimatedContainer(
                  duration: SanbaoAnimations.durationFast,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? colors.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    tab.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? colors.accent : colors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  /// Builds the mobile content: either the editor or the preview.
  Widget _buildMobileContent(SanbaoColorScheme colors) => AnimatedSwitcher(
        duration: SanbaoAnimations.durationFast,
        child: _mobileTab == _EditorSubTab.edit
            ? _buildEditorPane()
            : _buildPreviewPane(),
      );

  /// Builds the tablet split view: editor on the left, preview on the right.
  Widget _buildSplitView(SanbaoColorScheme colors) => Row(
        children: [
          // Editor pane
          Expanded(child: _buildEditorPane()),

          // Divider
          ColoredBox(
            color: colors.border,
            child: const SizedBox(width: 1),
          ),

          // Preview pane with header
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PreviewHeader(colors: colors),
                Expanded(child: _buildPreviewPane()),
              ],
            ),
          ),
        ],
      );

  /// Builds the markdown editor pane.
  Widget _buildEditorPane() => MarkdownEditor(
        key: _editorKey,
        controller: _controller,
        undoController: _undoController,
        focusNode: _focusNode,
        readOnly: widget.readOnly,
        showLineNumbers: _showLineNumbers,
        onChanged: _onTextChanged,
      );

  /// Builds the live preview pane.
  Widget _buildPreviewPane() => ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          if (value.text.isEmpty) {
            return const _EmptyPreview();
          }
          return DocumentPreview(
            content: value.text,
          );
        },
      );
}

/// Small header above the preview pane in split view.
class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.colors});

  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colors.bgSurfaceAlt,
          border: Border(
            bottom: BorderSide(color: colors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.visibility_rounded,
              size: 14,
              color: colors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              'Предпросмотр',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      );
}

/// Empty state shown in the preview when there is no content.
class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: colors.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Предпросмотр появится здесь',
            style: TextStyle(
              fontSize: 14,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated banner at the bottom indicating unsaved changes.
///
/// Shows a warning-colored bar with text and a save button.
/// Animates in/out based on [visible].
class _UnsavedBanner extends StatelessWidget {
  const _UnsavedBanner({
    required this.visible,
    required this.onSave,
  });

  final bool visible;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return AnimatedContainer(
      duration: SanbaoAnimations.durationFast,
      height: visible ? 32 : 0,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.warningLight,
        border: visible
            ? Border(
                top: BorderSide(
                  color: colors.warning.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              )
            : null,
      ),
      child: visible
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: colors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  'Несохраненные изменения',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.warning.withValues(alpha: 0.15),
                      borderRadius: SanbaoRadius.sm,
                    ),
                    child: Text(
                      'Сохранить',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.warning,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Low-level markdown editing surface with formatting support.
///
/// Provides a [TextEditingController]-based editor that understands
/// markdown syntax. Features include:
/// - Toolbar-driven formatting (bold, italic, headings, etc.)
/// - Code block and inline code insertion
/// - List (bullet, numbered) insertion with auto-continuation
/// - Link and blockquote insertion
/// - Optional line numbers in a gutter
/// - Undo/redo via [UndoHistoryController]
/// - Auto-indent on newline after list items
/// - Monospaced font (JetBrains Mono) for the editing surface
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/typography.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/widgets/editor_toolbar.dart';

/// Describes which markdown formatting is active at the cursor position.
///
/// Used by the toolbar to show active state on buttons.
class MarkdownFormatState {
  const MarkdownFormatState({
    this.isBold = false,
    this.isItalic = false,
    this.isInlineCode = false,
    this.isCodeBlock = false,
    this.isBulletList = false,
    this.isNumberedList = false,
    this.isBlockquote = false,
    this.headingLevel = 0,
  });

  /// Whether the cursor is inside bold markers (**...**).
  final bool isBold;

  /// Whether the cursor is inside italic markers (*...*).
  final bool isItalic;

  /// Whether the cursor is inside inline code markers (`...`).
  final bool isInlineCode;

  /// Whether the cursor is inside a fenced code block.
  final bool isCodeBlock;

  /// Whether the current line starts with a bullet list marker.
  final bool isBulletList;

  /// Whether the current line starts with a numbered list marker.
  final bool isNumberedList;

  /// Whether the current line starts with a blockquote marker.
  final bool isBlockquote;

  /// Current heading level (0 = none, 1-3 = H1-H3).
  final int headingLevel;
}

/// A markdown-aware text editing surface.
///
/// This is the core editing component. It manages:
/// - The text controller and focus node
/// - Markdown formatting operations (wrap/prefix)
/// - Format detection at cursor position
/// - Auto-indent behavior for lists
/// - Line number gutter rendering
///
/// Does NOT include the toolbar -- that is composed externally
/// via [EditorToolbar] to allow flexible layout (e.g., toolbar
/// inside a split view header).
class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({
    required this.controller,
    required this.undoController,
    required this.focusNode,
    super.key,
    this.readOnly = false,
    this.showLineNumbers = false,
    this.onChanged,
    this.hintText = 'Введите текст...',
  });

  /// The text editing controller (managed externally for sharing state).
  final TextEditingController controller;

  /// The undo history controller.
  final UndoHistoryController undoController;

  /// The focus node (managed externally for sharing state).
  final FocusNode focusNode;

  /// Whether the editor is read-only.
  final bool readOnly;

  /// Whether to show line numbers in a gutter.
  final bool showLineNumbers;

  /// Called on every text change.
  final ValueChanged<String>? onChanged;

  /// Placeholder hint text.
  final String hintText;

  @override
  State<MarkdownEditor> createState() => MarkdownEditorState();
}

/// Public state for [MarkdownEditor] so parent widgets can call
/// formatting methods via a GlobalKey.
class MarkdownEditorState extends State<MarkdownEditor> {
  /// Regex patterns for detecting current-line formatting.
  static final RegExp _bulletPattern = RegExp(r'^(\s*)[-*+]\s');
  static final RegExp _numberedPattern = RegExp(r'^(\s*)(\d+)\.\s');
  static final RegExp _headingPattern = RegExp(r'^(#{1,6})\s');
  static final RegExp _blockquotePattern = RegExp('^>\\s?');
  static final RegExp _codeBlockFencePattern = RegExp(r'^```');

  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  // ---- Public formatting API ----

  /// Detects the markdown formatting state at the current cursor position.
  MarkdownFormatState detectFormatState() {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    if (!sel.isValid || text.isEmpty) return const MarkdownFormatState();

    final currentLine = _getCurrentLine(text, sel.start);
    final headingMatch = _headingPattern.firstMatch(currentLine);

    return MarkdownFormatState(
      isBold: _isWrappedWith(text, sel, '**'),
      isItalic: _isWrappedWithSingle(text, sel, '*'),
      isInlineCode: _isWrappedWith(text, sel, '`'),
      isCodeBlock: _isInsideCodeBlock(text, sel.start),
      isBulletList: _bulletPattern.hasMatch(currentLine),
      isNumberedList: _numberedPattern.hasMatch(currentLine),
      isBlockquote: _blockquotePattern.hasMatch(currentLine),
      headingLevel: headingMatch != null ? headingMatch.group(1)!.length : 0,
    );
  }

  /// Toggles bold formatting (**text**) around the selection.
  void toggleBold() => _wrapSelection('**');

  /// Toggles italic formatting (*text*) around the selection.
  void toggleItalic() => _wrapSelection('*');

  /// Toggles inline code formatting (`code`) around the selection.
  void toggleInlineCode() => _wrapSelection('`');

  /// Inserts or toggles a heading prefix at the given [level] (1-3).
  void toggleHeading(int level) {
    assert(level >= 1 && level <= 3, 'Heading level must be 1-3');
    final prefix = '${'#' * level} ';
    _toggleLinePrefix(prefix, clearOtherHeadings: true);
  }

  /// Toggles a bullet list prefix (- ) on the current line.
  void toggleBulletList() => _toggleLinePrefix('- ');

  /// Toggles a numbered list prefix (1. ) on the current line.
  void toggleNumberedList() => _toggleLinePrefix('1. ');

  /// Toggles a blockquote prefix (> ) on the current line.
  void toggleBlockquote() => _toggleLinePrefix('> ');

  /// Inserts a fenced code block at the cursor position.
  void insertCodeBlock() {
    final sel = widget.controller.selection;
    if (!sel.isValid) return;

    final text = widget.controller.text;
    final selectedText = sel.textInside(text);

    String insertion;
    int cursorOffset;

    if (selectedText.isNotEmpty) {
      insertion = '```\n$selectedText\n```';
      cursorOffset = sel.start + 4; // after ```\n
    } else {
      insertion = '```\n\n```';
      cursorOffset = sel.start + 4; // between the fences
    }

    final newText =
        text.substring(0, sel.start) + insertion + text.substring(sel.end);

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
    _notifyChanged();
  }

  /// Inserts a markdown link template at the cursor or wraps selection.
  void insertLink() {
    final sel = widget.controller.selection;
    if (!sel.isValid) return;

    final text = widget.controller.text;
    final selectedText = sel.textInside(text);

    String insertion;
    int selStart;
    int selEnd;

    if (selectedText.isNotEmpty) {
      insertion = '[$selectedText](url)';
      // Select "url" for easy replacement
      selStart = sel.start + selectedText.length + 3;
      selEnd = selStart + 3;
    } else {
      insertion = '[текст](url)';
      // Select "текст" for easy replacement
      selStart = sel.start + 1;
      selEnd = selStart + 5; // length of "текст" in UTF-16
    }

    final newText =
        text.substring(0, sel.start) + insertion + text.substring(sel.end);

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: selStart, extentOffset: selEnd),
    );
    _notifyChanged();
  }

  /// Inserts a horizontal rule (---) below the current line.
  void insertHorizontalRule() {
    final sel = widget.controller.selection;
    if (!sel.isValid) return;

    final text = widget.controller.text;
    final lineEnd = text.indexOf('\n', sel.start);
    final insertPos = lineEnd == -1 ? text.length : lineEnd;

    final newText =
        '${text.substring(0, insertPos)}\n\n---\n\n${text.substring(insertPos)}';

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertPos + 6),
    );
    _notifyChanged();
  }

  // ---- Internal formatting helpers ----

  /// Wraps the current selection with symmetric markers (e.g., ** for bold).
  ///
  /// If the selection is already wrapped, unwraps it (toggle behavior).
  /// If nothing is selected, inserts the markers with placeholder text.
  void _wrapSelection(String marker) {
    final sel = widget.controller.selection;
    if (!sel.isValid) return;

    final text = widget.controller.text;
    final selectedText = sel.textInside(text);

    // Check if already wrapped -- toggle off
    final beforeStart = sel.start - marker.length;
    final afterEnd = sel.end + marker.length;

    if (beforeStart >= 0 && afterEnd <= text.length) {
      final before = text.substring(beforeStart, sel.start);
      final after = text.substring(sel.end, afterEnd);

      if (before == marker && after == marker) {
        // Unwrap
        widget.controller.value = TextEditingValue(
          text: text.substring(0, beforeStart) +
              selectedText +
              text.substring(afterEnd),
          selection: TextSelection(
            baseOffset: beforeStart,
            extentOffset: beforeStart + selectedText.length,
          ),
        );
        _notifyChanged();
        return;
      }
    }

    // Wrap selection or insert placeholder
    if (selectedText.isEmpty) {
      final placeholder = _placeholderForMarker(marker);
      final insertion = '$marker$placeholder$marker';
      final newText =
          text.substring(0, sel.start) + insertion + text.substring(sel.end);

      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: sel.start + marker.length,
          extentOffset: sel.start + marker.length + placeholder.length,
        ),
      );
    } else {
      final newText = text.substring(0, sel.start) +
          marker +
          selectedText +
          marker +
          text.substring(sel.end);

      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: sel.start + marker.length,
          extentOffset: sel.end + marker.length,
        ),
      );
    }
    _notifyChanged();
  }

  /// Returns placeholder text for a given marker when nothing is selected.
  String _placeholderForMarker(String marker) => switch (marker) {
        '**' => 'жирный текст',
        '*' => 'курсивный текст',
        '`' => 'код',
        _ => 'текст',
      };

  /// Toggles a line prefix (e.g., '# ', '- ', '> ') on the current line.
  ///
  /// When [clearOtherHeadings] is true, any existing heading prefix
  /// is removed before applying the new one (so H1 -> H2 works correctly).
  void _toggleLinePrefix(
    String prefix, {
    bool clearOtherHeadings = false,
  }) {
    final sel = widget.controller.selection;
    if (!sel.isValid) return;

    final text = widget.controller.text;
    final lineStart = _findLineStart(text, sel.start);
    final lineEnd = _findLineEnd(text, sel.start);
    final currentLine = text.substring(lineStart, lineEnd);

    String newLine;
    int cursorDelta;

    if (currentLine.startsWith(prefix)) {
      // Already has this prefix -- remove it (toggle off)
      newLine = currentLine.substring(prefix.length);
      cursorDelta = -prefix.length;
    } else if (clearOtherHeadings) {
      // Remove any existing heading prefix first
      final headingMatch = _headingPattern.firstMatch(currentLine);
      if (headingMatch != null) {
        final existing = '${headingMatch.group(0)}';
        newLine = prefix + currentLine.substring(existing.length);
        cursorDelta = prefix.length - existing.length;
      } else {
        newLine = prefix + currentLine;
        cursorDelta = prefix.length;
      }
    } else {
      // Add prefix
      newLine = prefix + currentLine;
      cursorDelta = prefix.length;
    }

    final newText =
        text.substring(0, lineStart) + newLine + text.substring(lineEnd);
    final newOffset = (sel.start + cursorDelta).clamp(0, newText.length);

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    _notifyChanged();
  }

  /// Handles a newline insertion with smart list continuation.
  ///
  /// Called by the [KeyboardListener] wrapper. If the current line
  /// is a list item, the new line continues the list. If the current
  /// line is an empty list item, the prefix is removed.
  bool handleNewline() {
    final sel = widget.controller.selection;
    if (!sel.isValid || !sel.isCollapsed) return false;

    final text = widget.controller.text;
    final currentLine = _getCurrentLine(text, sel.start);

    // Check bullet list continuation
    final bulletMatch = _bulletPattern.firstMatch(currentLine);
    if (bulletMatch != null) {
      return _continueLine(
        text: text,
        sel: sel,
        lineContent: currentLine,
        prefix: '${bulletMatch.group(1)}${'- '}',
        fullMatch: bulletMatch.group(0)!,
      );
    }

    // Check numbered list continuation
    final numberedMatch = _numberedPattern.firstMatch(currentLine);
    if (numberedMatch != null) {
      final indent = numberedMatch.group(1)!;
      final currentNumber = int.parse(numberedMatch.group(2)!);
      return _continueLine(
        text: text,
        sel: sel,
        lineContent: currentLine,
        prefix: '$indent${currentNumber + 1}. ',
        fullMatch: numberedMatch.group(0)!,
      );
    }

    // Check blockquote continuation
    final quoteMatch = _blockquotePattern.firstMatch(currentLine);
    if (quoteMatch != null) {
      return _continueLine(
        text: text,
        sel: sel,
        lineContent: currentLine,
        prefix: '> ',
        fullMatch: quoteMatch.group(0)!,
      );
    }

    return false; // Let the default newline behavior handle it
  }

  /// Inserts a new line with the given [prefix], or removes the
  /// current prefix if the line contains only the prefix.
  bool _continueLine({
    required String text,
    required TextSelection sel,
    required String lineContent,
    required String prefix,
    required String fullMatch,
  }) {
    // If the line only contains the prefix, remove it instead
    if (lineContent.trimRight() == fullMatch.trimRight()) {
      final lineStart = _findLineStart(text, sel.start);
      final lineEnd = _findLineEnd(text, sel.start);
      final newText = text.substring(0, lineStart) + text.substring(lineEnd);
      final newOffset = lineStart.clamp(0, newText.length);

      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
      _notifyChanged();
      return true;
    }

    // Insert new line with prefix
    final insertion = '\n$prefix';
    final newText =
        text.substring(0, sel.start) + insertion + text.substring(sel.end);
    final newOffset = sel.start + insertion.length;

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    _notifyChanged();
    return true;
  }

  // ---- Text analysis helpers ----

  /// Returns the content of the line containing [offset].
  String _getCurrentLine(String text, int offset) {
    final start = _findLineStart(text, offset);
    final end = _findLineEnd(text, offset);
    return text.substring(start, end);
  }

  /// Finds the start index of the line containing [offset].
  int _findLineStart(String text, int offset) {
    if (offset <= 0) return 0;
    var i = offset - 1;
    while (i >= 0 && text[i] != '\n') {
      i--;
    }
    return i + 1;
  }

  /// Finds the end index of the line containing [offset].
  int _findLineEnd(String text, int offset) {
    var i = offset;
    while (i < text.length && text[i] != '\n') {
      i++;
    }
    return i;
  }

  /// Checks if the selection is wrapped with a symmetric [marker].
  bool _isWrappedWith(String text, TextSelection sel, String marker) {
    final start = sel.start - marker.length;
    final end = sel.end + marker.length;
    if (start < 0 || end > text.length) return false;
    return text.substring(start, sel.start) == marker &&
        text.substring(sel.end, end) == marker;
  }

  /// Special check for single-character markers like * (italic)
  /// that should not match ** (bold).
  bool _isWrappedWithSingle(String text, TextSelection sel, String marker) {
    if (marker.length != 1) return _isWrappedWith(text, sel, marker);

    final start = sel.start - 1;
    final end = sel.end + 1;
    if (start < 0 || end > text.length) return false;

    final hasSingleBefore = text[start] == marker;
    final hasSingleAfter = text[sel.end] == marker;

    if (!hasSingleBefore || !hasSingleAfter) return false;

    // Ensure it is not ** (bold)
    final hasDoubleBefore = start > 0 && text[start - 1] == marker;
    final hasDoubleAfter = end < text.length && text[end] == marker;

    return !hasDoubleBefore && !hasDoubleAfter;
  }

  /// Whether [offset] is inside a fenced code block (```...```).
  bool _isInsideCodeBlock(String text, int offset) {
    final lines = text.substring(0, offset).split('\n');
    var insideBlock = false;
    for (final line in lines) {
      if (_codeBlockFencePattern.hasMatch(line.trim())) {
        insideBlock = !insideBlock;
      }
    }
    return insideBlock;
  }

  /// Notifies the parent of a text change.
  void _notifyChanged() {
    widget.onChanged?.call(widget.controller.text);
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return KeyboardListener(
      focusNode: FocusNode(), // Separate listener node
      onKeyEvent: _handleKeyEvent,
      child: widget.showLineNumbers
          ? _buildWithLineNumbers(colors)
          : _buildPlainEditor(colors),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      // Try smart list continuation; if not handled, default behavior
      if (handleNewline()) {
        // Consumed by our handler
      }
    }
  }

  /// Builds the editor without line numbers.
  Widget _buildPlainEditor(SanbaoColorScheme colors) => ColoredBox(
        color: colors.bgSurface,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          undoController: widget.undoController,
          readOnly: widget.readOnly,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          onChanged: (value) => widget.onChanged?.call(value),
          style: SanbaoTypography.codeStyle(
            color: colors.textPrimary,
            fontSize: 14,
          ).copyWith(height: 1.7),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            hintText: widget.hintText,
            hintStyle: SanbaoTypography.codeStyle(
              color: colors.textMuted,
              fontSize: 14,
            ).copyWith(height: 1.7),
          ),
        ),
      );

  /// Builds the editor with a line number gutter.
  Widget _buildWithLineNumbers(SanbaoColorScheme colors) => ColoredBox(
        color: colors.bgSurface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line number gutter
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) => _LineNumberGutter(
                lineCount: '\n'.allMatches(value.text).length + 1,
                scrollController: _scrollController,
                colors: colors,
              ),
            ),

            // Divider
            ColoredBox(
              color: colors.border,
              child: const SizedBox(width: 0.5),
            ),

            // Editor
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                undoController: widget.undoController,
                scrollController: _scrollController,
                readOnly: widget.readOnly,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (value) => widget.onChanged?.call(value),
                style: SanbaoTypography.codeStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                ).copyWith(height: 1.7),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: widget.hintText,
                  hintStyle: SanbaoTypography.codeStyle(
                    color: colors.textMuted,
                    fontSize: 14,
                  ).copyWith(height: 1.7),
                ),
              ),
            ),
          ],
        ),
      );
}

/// Line number gutter that syncs its scroll position with the editor.
class _LineNumberGutter extends StatelessWidget {
  const _LineNumberGutter({
    required this.lineCount,
    required this.colors,
    this.scrollController,
  });

  final int lineCount;
  final ScrollController? scrollController;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) {
    // Gutter width adapts to the number of digits
    final gutterWidth = lineCount.toString().length * 10.0 + 28;

    return Container(
      width: gutterWidth,
      color: colors.bgSurfaceAlt,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(lineCount, (index) {
          return SizedBox(
            // Match the line height: 14px font * 1.7 height = 23.8
            height: 14 * 1.7,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.right,
                style: SanbaoTypography.codeStyle(
                  color: colors.textMuted.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

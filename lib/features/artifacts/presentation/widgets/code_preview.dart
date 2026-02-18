/// Syntax-highlighted code viewer with line numbers.
///
/// Displays code artifacts with a monospaced font, line numbers,
/// language indicator badge, and a copy-to-clipboard button.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/typography.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';

/// A code viewer widget with line numbers and syntax indicators.
///
/// Provides:
/// - Monospaced font rendering (JetBrains Mono)
/// - Line numbers in a fixed gutter
/// - Language badge in the top-right corner
/// - Copy-to-clipboard button with confirmation feedback
/// - Horizontal scrolling for long lines
class CodePreview extends StatelessWidget {
  const CodePreview({
    required this.code,
    super.key,
    this.language,
    this.showLineNumbers = true,
    this.fontSize = 13.0,
    this.onCopy,
  });

  /// The source code to display.
  final String code;

  /// Programming language for the badge (e.g., "python", "dart").
  final String? language;

  /// Whether to show line numbers in the gutter.
  final bool showLineNumbers;

  /// Font size for the code text.
  final double fontSize;

  /// Optional callback after copying.
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final lines = code.split('\n');

    return Container(
      color: colors.bgSurfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar with language badge and copy button
          _CodeHeader(
            language: language,
            code: code,
            colors: colors,
            onCopy: onCopy,
          ),

          // Code body with line numbers
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(lines.length, (index) {
                        return _CodeLine(
                          lineNumber: index + 1,
                          text: lines[index],
                          totalLines: lines.length,
                          showLineNumbers: showLineNumbers,
                          fontSize: fontSize,
                          colors: colors,
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header bar with language badge and copy button.
class _CodeHeader extends StatefulWidget {
  const _CodeHeader({
    required this.language,
    required this.code,
    required this.colors,
    this.onCopy,
  });

  final String? language;
  final String code;
  final SanbaoColorScheme colors;
  final VoidCallback? onCopy;

  @override
  State<_CodeHeader> createState() => _CodeHeaderState();
}

class _CodeHeaderState extends State<_CodeHeader> {
  bool _copied = false;

  Future<void> _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    widget.onCopy?.call();
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.colors.bgSurfaceHover,
        border: Border(
          bottom: BorderSide(
            color: widget.colors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Language badge
          if (widget.language != null && widget.language!.isNotEmpty)
            SanbaoBadge(
              label: _formatLanguage(widget.language!),
              variant: SanbaoBadgeVariant.accent,
              size: SanbaoBadgeSize.small,
              icon: Icons.code_rounded,
            ),

          const Spacer(),

          // Line count
          Text(
            '${widget.code.split('\n').length} строк',
            style: context.textTheme.labelSmall?.copyWith(
              color: widget.colors.textMuted,
            ),
          ),
          const SizedBox(width: 12),

          // Copy button
          GestureDetector(
            onTap: _handleCopy,
            child: AnimatedSwitcher(
              duration: SanbaoAnimations.durationFast,
              child: _copied
                  ? Row(
                      key: const ValueKey('copied'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: widget.colors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Скопировано',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.colors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('copy'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: widget.colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Копировать',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.colors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a language identifier for display.
  String _formatLanguage(String lang) => switch (lang.toLowerCase()) {
        'javascript' || 'js' => 'JavaScript',
        'typescript' || 'ts' => 'TypeScript',
        'python' || 'py' => 'Python',
        'dart' => 'Dart',
        'html' => 'HTML',
        'css' => 'CSS',
        'json' => 'JSON',
        'jsx' => 'JSX',
        'tsx' => 'TSX',
        'go' => 'Go',
        'rust' || 'rs' => 'Rust',
        'sql' => 'SQL',
        'yaml' || 'yml' => 'YAML',
        'bash' || 'sh' => 'Shell',
        'markdown' || 'md' => 'Markdown',
        _ => lang.toUpperCase(),
      };
}

/// A single line of code with optional line number.
class _CodeLine extends StatelessWidget {
  const _CodeLine({
    required this.lineNumber,
    required this.text,
    required this.totalLines,
    required this.showLineNumbers,
    required this.fontSize,
    required this.colors,
  });

  final int lineNumber;
  final String text;
  final int totalLines;
  final bool showLineNumbers;
  final double fontSize;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) {
    // Calculate gutter width based on the total number of lines
    final gutterWidth =
        showLineNumbers ? (totalLines.toString().length * 10.0 + 24) : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line number gutter
        if (showLineNumbers)
          SizedBox(
            width: gutterWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '$lineNumber',
                textAlign: TextAlign.right,
                style: SanbaoTypography.codeStyle(
                  color: colors.textMuted.withValues(alpha: 0.5),
                  fontSize: fontSize,
                ),
              ),
            ),
          ),

        // Code text
        Padding(
          padding: EdgeInsets.only(
            left: showLineNumbers ? 0 : 16,
            right: 16,
          ),
          child: SelectableText(
            text.isEmpty ? ' ' : text,
            style: SanbaoTypography.codeStyle(
              color: colors.textPrimary,
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  }
}

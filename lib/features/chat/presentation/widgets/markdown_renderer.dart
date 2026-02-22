/// Markdown renderer widget wrapping flutter_markdown.
///
/// Provides syntax highlighting for code blocks, table rendering,
/// legal reference link handling, and consistent styling with
/// the Sanbao design system.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/typography.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:url_launcher/url_launcher.dart';

/// A Markdown renderer configured for the Sanbao design system.
///
/// Renders assistant message content with:
/// - Syntax-highlighted code blocks with copy button
/// - Styled tables with alternating row colors
/// - Legal reference links (article://) handling
/// - Consistent typography from the theme
class MarkdownRenderer extends StatelessWidget {
  const MarkdownRenderer({
    required this.content,
    super.key,
    this.selectable = false,
    this.shrinkWrap = true,
    this.maxLines,
    this.onLegalReferenceTap,
  });

  /// The Markdown content to render.
  final String content;

  /// Whether the text is selectable.
  final bool selectable;

  /// Whether to shrink-wrap the content.
  final bool shrinkWrap;

  /// Maximum number of lines (null for unlimited).
  final int? maxLines;

  /// Callback when a legal reference link is tapped.
  final void Function(String codeName, String article)? onLegalReferenceTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final textTheme = context.textTheme;

    return MarkdownBody(
      data: content,
      selectable: selectable,
      shrinkWrap: shrinkWrap,
      onTapLink: (text, href, title) => _handleLinkTap(context, href),
      styleSheet: _buildStyleSheet(colors, textTheme),
      builders: {
        'code': _CodeBlockBuilder(colors: colors),
      },
    );
  }

  /// Handles link taps, routing legal references specially.
  void _handleLinkTap(BuildContext context, String? href) {
    if (href == null) return;

    // Handle legal reference links: article://code_name/article_number
    if (href.startsWith('article://')) {
      final parts = href.replaceFirst('article://', '').split('/');
      if (parts.length >= 2) {
        onLegalReferenceTap?.call(parts[0], parts[1]);
      }
      return;
    }

    // Open regular URLs
    final uri = Uri.tryParse(href);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Builds the markdown style sheet matching Sanbao design.
  MarkdownStyleSheet _buildStyleSheet(
    SanbaoColorScheme colors,
    TextTheme textTheme,
  ) =>
      MarkdownStyleSheet(
        // Body
        p: textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
          height: 1.6,
        ),
        pPadding: const EdgeInsets.only(bottom: 8),

        // Headers
        h1: textTheme.headlineMedium?.copyWith(
          color: colors.textPrimary,
        ),
        h1Padding: const EdgeInsets.only(top: 16, bottom: 8),
        h2: textTheme.headlineSmall?.copyWith(
          color: colors.textPrimary,
        ),
        h2Padding: const EdgeInsets.only(top: 14, bottom: 6),
        h3: textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
        ),
        h3Padding: const EdgeInsets.only(top: 12, bottom: 4),
        h4: textTheme.titleMedium?.copyWith(
          color: colors.textPrimary,
        ),
        h5: textTheme.titleSmall?.copyWith(
          color: colors.textPrimary,
        ),
        h6: textTheme.labelLarge?.copyWith(
          color: colors.textSecondary,
        ),

        // Strong & emphasis
        strong: const TextStyle(fontWeight: FontWeight.w600),
        em: const TextStyle(fontStyle: FontStyle.italic),

        // Links
        a: TextStyle(
          color: colors.accent,
          decoration: TextDecoration.none,
        ),

        // Inline code
        code: SanbaoTypography.codeStyle(
          color: colors.accent,
        ).copyWith(
          backgroundColor: colors.bgSurfaceAlt,
        ),
        codeblockPadding: const EdgeInsets.all(16),
        codeblockDecoration: BoxDecoration(
          color: colors.bgSurfaceAlt,
          borderRadius: SanbaoRadius.md,
          border: Border.all(color: colors.border, width: 0.5),
        ),

        // Block quote
        blockquote: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: colors.accent, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),

        // Lists
        listBullet: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
        listBulletPadding: const EdgeInsets.only(right: 8),
        listIndent: 24,

        // Table
        tableHead: textTheme.labelLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        tableBody: textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
        ),
        tableBorder: TableBorder.all(
          color: colors.border,
          width: 0.5,
        ),
        tableHeadAlign: TextAlign.left,
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),

        // Horizontal rule
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.border, width: 0.5),
          ),
        ),
      );
}

/// Custom builder for code blocks with copy button and language label.
class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder({required this.colors});

  final SanbaoColorScheme colors;

  @override
  Widget? visitElementAfter(
    md.Element element,
    TextStyle? preferredStyle,
  ) {
    final textContent = element.textContent;
    // Try to detect language from the class attribute
    String? language;
    if (element.attributes.containsKey('class')) {
      final className = element.attributes['class'] ?? '';
      if (className.startsWith('language-')) {
        language = className.replaceFirst('language-', '');
      }
    }

    return _CodeBlock(
      code: textContent,
      language: language,
      colors: colors,
    );
  }
}

/// A styled code block with language label and copy button.
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.code,
    required this.colors,
    this.language,
  });

  final String code;
  final String? language;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSurfaceAlt,
        borderRadius: SanbaoRadius.md,
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with language label and copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bgSurfaceHover,
              borderRadius: const BorderRadius.vertical(
                top: SanbaoRadius.circularMd,
              ),
            ),
            child: Row(
              children: [
                if (language != null)
                  Text(
                    language!,
                    style: SanbaoTypography.codeStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                const Spacer(),
                _CopyButton(
                  text: code,
                  colors: colors,
                ),
              ],
            ),
          ),

          // Code content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              code,
              style: SanbaoTypography.codeStyle(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
}

/// Copy-to-clipboard button with feedback animation.
class _CopyButton extends StatefulWidget {
  const _CopyButton({
    required this.text,
    required this.colors,
  });

  final String text;
  final SanbaoColorScheme colors;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: _copy,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _copied
            ? Icon(
                Icons.check,
                key: const ValueKey('check'),
                size: 14,
                color: widget.colors.success,
              )
            : Icon(
                Icons.copy_rounded,
                key: const ValueKey('copy'),
                size: 14,
                color: widget.colors.textMuted,
              ),
      ),
    );
}

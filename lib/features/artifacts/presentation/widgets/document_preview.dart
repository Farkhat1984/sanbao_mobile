/// Document preview widget with prose styling.
///
/// Renders Markdown content with professional typography suitable
/// for legal documents: indented paragraphs, numbered articles,
/// proper heading hierarchy, and print-ready layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/typography.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:url_launcher/url_launcher.dart';

/// A preview widget that renders Markdown with professional
/// document styling.
///
/// Designed for legal and business documents with:
/// - Wider line height for readability
/// - Proper heading hierarchy with spacing
/// - Indented blockquotes for legal citations
/// - Numbered list styling matching legal document conventions
/// - Table formatting with alternating rows
class DocumentPreview extends StatelessWidget {
  const DocumentPreview({
    required this.content,
    super.key,
    this.onLegalReferenceTap,
    this.padding,
  });

  /// The Markdown content to render.
  final String content;

  /// Callback when a legal reference link is tapped.
  final void Function(String codeName, String article)? onLegalReferenceTap;

  /// Override padding. Defaults to 24px horizontal, 20px vertical.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final textTheme = context.textTheme;

    return SingleChildScrollView(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: MarkdownBody(
        data: content,
        selectable: true,
        shrinkWrap: true,
        onTapLink: (text, href, title) => _handleLink(href),
        styleSheet: _buildProseStyleSheet(colors, textTheme),
        builders: {
          'code': _ProseCodeBlockBuilder(colors: colors),
        },
      ),
    );
  }

  /// Routes link taps to either legal reference handler or URL launcher.
  void _handleLink(String? href) {
    if (href == null) return;

    if (href.startsWith('article://')) {
      final parts = href.replaceFirst('article://', '').split('/');
      if (parts.length >= 2) {
        onLegalReferenceTap?.call(parts[0], parts[1]);
      }
      return;
    }

    final uri = Uri.tryParse(href);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Builds a prose-optimized stylesheet for document preview.
  MarkdownStyleSheet _buildProseStyleSheet(
    SanbaoColorScheme colors,
    TextTheme textTheme,
  ) =>
      MarkdownStyleSheet(
        // Body -- generous line height for legal readability
        p: textTheme.bodyLarge?.copyWith(
          color: colors.textPrimary,
          height: 1.8,
          fontSize: 15,
        ),
        pPadding: const EdgeInsets.only(bottom: 12),

        // Headings -- clear hierarchy
        h1: textTheme.headlineLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        h1Padding: const EdgeInsets.only(top: 24, bottom: 12),
        h2: textTheme.headlineMedium?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        h2Padding: const EdgeInsets.only(top: 20, bottom: 10),
        h3: textTheme.headlineSmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        h3Padding: const EdgeInsets.only(top: 16, bottom: 8),
        h4: textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
        ),
        h5: textTheme.titleMedium?.copyWith(
          color: colors.textPrimary,
        ),
        h6: textTheme.titleSmall?.copyWith(
          color: colors.textSecondary,
        ),

        // Emphasis
        strong: const TextStyle(fontWeight: FontWeight.w600),
        em: const TextStyle(fontStyle: FontStyle.italic),

        // Links -- accent or legal ref color
        a: TextStyle(
          color: colors.accent,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w500,
        ),

        // Inline code
        code: SanbaoTypography.codeStyle(
          color: colors.accent,
          fontSize: 13,
        ).copyWith(
          backgroundColor: colors.bgSurfaceAlt,
        ),
        codeblockPadding: const EdgeInsets.all(16),
        codeblockDecoration: BoxDecoration(
          color: colors.bgSurfaceAlt,
          borderRadius: SanbaoRadius.md,
          border: Border.all(color: colors.border, width: 0.5),
        ),

        // Blockquotes -- styled for legal citations
        blockquote: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
          fontStyle: FontStyle.italic,
          height: 1.7,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: colors.legalRef, width: 3),
          ),
          color: colors.legalRefBg.withValues(alpha: 0.3),
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),

        // Lists -- generous spacing for numbered articles
        listBullet: textTheme.bodyLarge?.copyWith(
          color: colors.textSecondary,
          height: 1.8,
        ),
        listBulletPadding: const EdgeInsets.only(right: 8),
        listIndent: 28,

        // Tables
        tableHead: textTheme.labelLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        tableBody: textTheme.bodyMedium?.copyWith(
          color: colors.textPrimary,
          height: 1.5,
        ),
        tableBorder: TableBorder.all(
          color: colors.border,
          width: 0.5,
        ),
        tableHeadAlign: TextAlign.left,
        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        // Horizontal rule
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.border,
              width: 1,
            ),
          ),
        ),
      );
}

/// Custom code block builder for document preview.
class _ProseCodeBlockBuilder extends MarkdownElementBuilder {
  _ProseCodeBlockBuilder({required this.colors});

  final SanbaoColorScheme colors;

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final textContent = element.textContent;
    String? language;
    if (element.attributes.containsKey('class')) {
      final className = element.attributes['class'] ?? '';
      if (className.startsWith('language-')) {
        language = className.replaceFirst('language-', '');
      }
    }

    return Container(
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
          if (language != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgSurfaceHover,
                borderRadius: const BorderRadius.vertical(
                  top: SanbaoRadius.circularMd,
                ),
              ),
              child: Text(
                language,
                style: SanbaoTypography.codeStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              textContent,
              style: SanbaoTypography.codeStyle(
                color: colors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

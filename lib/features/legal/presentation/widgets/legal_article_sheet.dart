/// Legal article bottom sheet widget.
///
/// A modal bottom sheet that displays the full text of a legal article
/// with header, validity badge, content, annotation, and a source link.
/// Includes loading skeleton and error states with retry.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/theme/typography.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/legal/domain/entities/legal_article.dart';
import 'package:sanbao_flutter/features/legal/presentation/providers/legal_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the legal article detail bottom sheet.
///
/// This is the primary entry point for showing legal article details.
/// Call this from the `onLegalReferenceTap` callback in [ChatScreen].
///
/// Parameters:
/// - [context]: Build context for showing the modal.
/// - [codeName]: Internal code name (e.g., "criminal_code").
/// - [articleNum]: Article number (e.g., "188").
void showLegalArticleSheet(
  BuildContext context, {
  required String codeName,
  required String articleNum,
}) {
  HapticFeedback.lightImpact();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: SanbaoColors.mobileOverlay,
    builder: (_) => _LegalArticleSheet(
      codeName: codeName,
      articleNum: articleNum,
    ),
  );
}

/// Internal widget for the legal article bottom sheet content.
///
/// Wrapped in a [DraggableScrollableSheet] to allow the user to expand
/// the sheet to full height when reading long articles.
class _LegalArticleSheet extends ConsumerWidget {
  const _LegalArticleSheet({
    required this.codeName,
    required this.articleNum,
  });

  final String codeName;
  final String articleNum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final articleKey = LegalArticleKey(
      codeName: codeName,
      articleNum: articleNum,
    );
    final articleAsync = ref.watch(legalArticleProvider(articleKey));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(SanbaoRadius.lgValue),
          ),
          boxShadow: SanbaoShadows.xl,
        ),
        child: Column(
          children: [
            _DragHandle(colors: colors),
            Expanded(
              child: articleAsync.when(
                loading: () => _ArticleSkeleton(colors: colors),
                error: (error, _) => _ArticleError(
                  message: _userFriendlyError(error),
                  colors: colors,
                  onRetry: () =>
                      ref.invalidate(legalArticleProvider(articleKey)),
                ),
                data: (article) => _ArticleContent(
                  article: article,
                  colors: colors,
                  scrollController: scrollController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Converts an error to a user-friendly Russian message.
  String _userFriendlyError(Object error) {
    final message = error.toString();
    if (message.contains('NotFoundException') || message.contains('404')) {
      return 'Статья не найдена';
    }
    if (message.contains('NetworkFailure') ||
        message.contains('NetworkException')) {
      return 'Нет подключения к интернету';
    }
    if (message.contains('TimeoutFailure') ||
        message.contains('TimeoutException')) {
      return 'Превышено время ожидания';
    }
    return 'Не удалось загрузить статью';
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// The small drag indicator at the top of the sheet.
class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.colors});

  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: SanbaoRadius.full,
            ),
            child: const SizedBox(width: 36, height: 4),
          ),
        ),
      );
}

/// Skeleton loading state for the article content.
class _ArticleSkeleton extends StatelessWidget {
  const _ArticleSkeleton({required this.colors});

  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header skeleton
            Row(
              children: [
                SanbaoSkeleton.line(
                  width: MediaQuery.sizeOf(context).width * 0.35,
                  height: 16,
                ),
                const Spacer(),
                const SanbaoSkeleton.line(width: 80, height: 20),
              ],
            ),
            const SizedBox(height: 8),
            const SanbaoSkeleton.line(height: 12),
            const SizedBox(height: 20),

            // Divider
            ColoredBox(
              color: colors.border,
              child: const SizedBox(height: 0.5, width: double.infinity),
            ),
            const SizedBox(height: 20),

            // Title skeleton
            SanbaoSkeleton.line(
              width: MediaQuery.sizeOf(context).width * 0.7,
              height: 18,
            ),
            const SizedBox(height: 16),

            // Content lines skeleton
            const SanbaoSkeleton.line(),
            const SizedBox(height: 10),
            const SanbaoSkeleton.line(),
            const SizedBox(height: 10),
            SanbaoSkeleton.line(
              width: MediaQuery.sizeOf(context).width * 0.8,
            ),
            const SizedBox(height: 10),
            const SanbaoSkeleton.line(),
            const SizedBox(height: 10),
            SanbaoSkeleton.line(
              width: MediaQuery.sizeOf(context).width * 0.6,
            ),
          ],
        ),
      );
}

/// Error state with retry button.
class _ArticleError extends StatelessWidget {
  const _ArticleError({
    required this.message,
    required this.colors,
    required this.onRetry,
  });

  final String message;
  final SanbaoColorScheme colors;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.errorLight,
                  borderRadius: SanbaoRadius.md,
                ),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 28,
                    color: colors.error,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Error message
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Retry button
              TextButton.icon(
                onPressed: onRetry,
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: colors.accent,
                ),
                label: Text(
                  'Повторить',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: colors.accent,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: colors.bgSurfaceAlt,
                  shape: RoundedRectangleBorder(
                    borderRadius: SanbaoRadius.md,
                    side: BorderSide(color: colors.border, width: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// The article content: header, body text, annotation, and source link.
class _ArticleContent extends StatelessWidget {
  const _ArticleContent({
    required this.article,
    required this.colors,
    required this.scrollController,
  });

  final LegalArticle article;
  final SanbaoColorScheme colors;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // Header section
          _ArticleHeader(article: article, colors: colors),

          // Divider
          _HorizontalDivider(colors: colors),

          // Article body
          _ArticleBody(article: article, colors: colors),

          // Annotation section (if present)
          if (article.annotation != null && article.annotation!.isNotEmpty)
            _ArticleAnnotation(
              annotation: article.annotation!,
              colors: colors,
            ),

          // Source link (if present)
          if (article.sourceUrl != null && article.sourceUrl!.isNotEmpty)
            _SourceLink(url: article.sourceUrl!, colors: colors),

          // Bottom safe area
          SizedBox(height: context.bottomPadding + 16),
        ],
      );
}

/// Reusable thin horizontal divider with horizontal margin.
class _HorizontalDivider extends StatelessWidget {
  const _HorizontalDivider({required this.colors});

  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ColoredBox(
          color: colors.border,
          child: const SizedBox(height: 0.5, width: double.infinity),
        ),
      );
}

/// Sticky-like header with code label, article number, and validity badge.
class _ArticleHeader extends StatelessWidget {
  const _ArticleHeader({
    required this.article,
    required this.colors,
  });

  final LegalArticle article;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code label + validity badge row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and code reference
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: colors.legalRef,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          article.headerLabel,
                          style: context.textTheme.titleLarge?.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Validity badge
                _ValidityBadge(
                  isValid: article.isValid,
                  colors: colors,
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Code monospace identifier
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                article.codeName,
                style: SanbaoTypography.codeStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Green/amber badge indicating article validity status.
class _ValidityBadge extends StatelessWidget {
  const _ValidityBadge({
    required this.isValid,
    required this.colors,
  });

  final bool isValid;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final bgColor = isValid ? colors.successLight : colors.warningLight;
    final fgColor = isValid ? colors.success : colors.warning;
    final label = isValid ? 'Актуальна' : 'Не актуальна';
    final icon = isValid ? Icons.check_circle_rounded : Icons.warning_rounded;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: SanbaoRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fgColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: SanbaoTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The main article text content.
class _ArticleBody extends StatelessWidget {
  const _ArticleBody({
    required this.article,
    required this.colors,
  });

  final LegalArticle article;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article title
            if (article.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  article.title,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Full article text with preserved whitespace
            SelectableText(
              article.content,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                height: 1.7,
              ),
            ),
          ],
        ),
      );
}

/// Annotation/footnote section with visual separator.
class _ArticleAnnotation extends StatelessWidget {
  const _ArticleAnnotation({
    required this.annotation,
    required this.colors,
  });

  final String annotation;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HorizontalDivider(colors: colors),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Примечание: ',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: annotation,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

/// Footer link to open the official article source in an external browser.
class _SourceLink extends StatelessWidget {
  const _SourceLink({
    required this.url,
    required this.colors,
  });

  final String url;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _HorizontalDivider(colors: colors),
          InkWell(
            onTap: () => _openSource(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: colors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Открыть источник',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Future<void> _openSource(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      context.showSnackBar('Не удалось открыть ссылку');
    }
  }
}

/// A convenience function to copy the full article text to the clipboard.
///
/// This is exposed for potential use in a toolbar action or context menu.
Future<void> copyArticleText(
  BuildContext context,
  LegalArticle article,
) async {
  final fullText = [
    article.title,
    '',
    article.content,
    if (article.annotation != null && article.annotation!.isNotEmpty)
      '\nПримечание: ${article.annotation}',
  ].join('\n');

  await Clipboard.setData(ClipboardData(text: fullText));
  if (context.mounted) {
    context.showSuccessSnackBar('Текст скопирован');
  }
}

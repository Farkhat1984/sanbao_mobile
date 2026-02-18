/// Export options bottom sheet for artifacts.
///
/// Presents available export formats (PDF, DOCX, TXT, MD, Copy)
/// with icons and descriptions in a modal bottom sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact.dart';
import 'package:sanbao_flutter/features/artifacts/domain/repositories/artifact_repository.dart';
import 'package:sanbao_flutter/features/artifacts/presentation/providers/artifact_provider.dart';

/// Shows the export options bottom sheet.
///
/// Returns the selected [ExportFormat] or null if dismissed.
Future<ExportFormat?> showExportMenu({
  required BuildContext context,
  required ArtifactType artifactType,
}) =>
    showSanbaoBottomSheet<ExportFormat>(
      context: context,
      builder: (context) => _ExportMenuContent(
        artifactType: artifactType,
      ),
    );

/// Content of the export options bottom sheet.
class _ExportMenuContent extends StatelessWidget {
  const _ExportMenuContent({required this.artifactType});

  final ArtifactType artifactType;

  /// Returns the list of available formats for the artifact type.
  List<ExportFormat> _availableFormats() {
    if (artifactType == ArtifactType.code) {
      return [
        ExportFormat.copy,
        ExportFormat.txt,
        ExportFormat.markdown,
      ];
    }
    return [
      ExportFormat.docx,
      ExportFormat.pdf,
      ExportFormat.txt,
      ExportFormat.markdown,
      ExportFormat.html,
      ExportFormat.copy,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final formats = _availableFormats();

    return SanbaoBottomSheetContent(
      title: 'Экспорт',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...formats.map((format) {
            final index = formats.indexOf(format);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: SanbaoAnimations.durationNormal +
                  Duration(
                    milliseconds:
                        index * SanbaoAnimations.staggerDelay.inMilliseconds,
                  ),
              curve: SanbaoAnimations.smoothCurve,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - value)),
                  child: child,
                ),
              ),
              child: _ExportFormatTile(
                format: format,
                colors: colors,
                onTap: () => Navigator.of(context).pop(format),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// A single export format option tile.
class _ExportFormatTile extends StatelessWidget {
  const _ExportFormatTile({
    required this.format,
    required this.colors,
    required this.onTap,
  });

  final ExportFormat format;
  final SanbaoColorScheme colors;
  final VoidCallback onTap;

  IconData _formatIcon() => switch (format) {
        ExportFormat.pdf => Icons.picture_as_pdf_rounded,
        ExportFormat.docx => Icons.description_rounded,
        ExportFormat.txt => Icons.text_snippet_rounded,
        ExportFormat.markdown => Icons.code_rounded,
        ExportFormat.html => Icons.language_rounded,
        ExportFormat.copy => Icons.copy_rounded,
      };

  Color _formatColor() => switch (format) {
        ExportFormat.pdf => const Color(0xFFEF4444),
        ExportFormat.docx => const Color(0xFF2563EB),
        ExportFormat.txt => SanbaoColors.textSecondary,
        ExportFormat.markdown => const Color(0xFF22C55E),
        ExportFormat.html => const Color(0xFFF59E0B),
        ExportFormat.copy => SanbaoColors.accent,
      };

  @override
  Widget build(BuildContext context) {
    final iconColor = _formatColor();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            // Format icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: SanbaoRadius.sm,
              ),
              child: Icon(
                _formatIcon(),
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),

            // Label and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.shortLabel,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    format.description,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline export action bar that appears in the artifact header.
///
/// Shows the currently selected format with a dropdown trigger
/// and a download button.
class ExportActionBar extends ConsumerWidget {
  const ExportActionBar({
    required this.artifactId,
    required this.artifactType,
    super.key,
  });

  final String artifactId;
  final ArtifactType artifactType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final selectedFormat = ref.watch(selectedExportFormatProvider);
    final exportState = ref.watch(exportProvider);
    final isExporting = exportState is ExportInProgress;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Format selector
        GestureDetector(
          onTap: () async {
            final format = await showExportMenu(
              context: context,
              artifactType: artifactType,
            );
            if (format != null) {
              ref.read(selectedExportFormatProvider.notifier).state = format;
              // Execute export immediately
              await ref.read(exportProvider.notifier).exportArtifact(
                    artifactId: artifactId,
                    format: format,
                  );
              if (context.mounted) {
                if (format == ExportFormat.copy) {
                  context.showSuccessSnackBar('Скопировано в буфер обмена');
                } else {
                  context.showSuccessSnackBar(
                    'Экспорт в ${format.shortLabel} завершен',
                  );
                }
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bgSurfaceAlt,
              borderRadius: const BorderRadius.horizontal(
                left: SanbaoRadius.circularSm,
              ),
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isExporting)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: colors.accent,
                    ),
                  )
                else
                  Icon(
                    Icons.download_rounded,
                    size: 14,
                    color: colors.textMuted,
                  ),
                const SizedBox(width: 4),
                Text(
                  selectedFormat.shortLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

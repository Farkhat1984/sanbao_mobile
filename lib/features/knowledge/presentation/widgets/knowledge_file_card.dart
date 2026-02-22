/// Knowledge file card widget for the knowledge list.
///
/// Displays the file name, description preview, size, and date.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/features/knowledge/domain/entities/knowledge_file.dart';

/// A card displaying a knowledge file's metadata.
///
/// Shows the file icon, name, description (truncated), size badge,
/// and formatted date.
class KnowledgeFileCard extends StatelessWidget {
  const KnowledgeFileCard({
    required this.file,
    super.key,
    this.onTap,
  });

  /// The knowledge file to display.
  final KnowledgeFile file;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: SanbaoRadius.lg,
          border: Border.all(color: colors.border, width: 0.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File type icon
            _FileTypeIcon(fileType: file.fileType),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File name
                  Text(
                    file.name,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description preview
                  if (file.description != null &&
                      file.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      file.description!,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Footer: size badge + date
                  Row(
                    children: [
                      SanbaoBadge(
                        label: file.formattedSize,
                        variant: SanbaoBadgeVariant.neutral,
                        size: SanbaoBadgeSize.small,
                      ),
                      const SizedBox(width: 8),
                      SanbaoBadge(
                        label: file.fileType.toUpperCase(),
                        size: SanbaoBadgeSize.small,
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(file.updatedAt),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    if (date.isToday) return 'Сегодня ${date.timeString}';
    if (date.isYesterday) return 'Вчера ${date.timeString}';
    final daysAgo = date.daysAgo;
    if (daysAgo < 7) return '$daysAgo дн. назад';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Icon widget that displays an appropriate icon based on file type.
class _FileTypeIcon extends StatelessWidget {
  const _FileTypeIcon({required this.fileType});

  final String fileType;

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = _resolveIcon();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: SanbaoRadius.sm,
      ),
      child: Icon(
        icon,
        size: 20,
        color: iconColor,
      ),
    );
  }

  (IconData, Color) _resolveIcon() => switch (fileType.toLowerCase()) {
        'md' || 'markdown' => (Icons.description_rounded, const Color(0xFF4F6EF7)),
        'txt' || 'text' => (Icons.article_rounded, const Color(0xFF5C6B82)),
        'pdf' => (Icons.picture_as_pdf_rounded, const Color(0xFFEF4444)),
        'doc' || 'docx' => (Icons.description_rounded, const Color(0xFF2563EB)),
        'csv' || 'xls' || 'xlsx' => (Icons.table_chart_rounded, const Color(0xFF10B981)),
        'html' || 'htm' => (Icons.code_rounded, const Color(0xFFF59E0B)),
        'json' => (Icons.data_object_rounded, const Color(0xFF7C3AED)),
        _ => (Icons.insert_drive_file_rounded, const Color(0xFF5C6B82)),
      };
}

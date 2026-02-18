/// Memory card widget for the memories list.
///
/// Displays the memory content preview, category badge, and date.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/features/memory/domain/entities/memory.dart';

/// A card displaying a memory's content and metadata.
///
/// Shows the memory content (truncated), category badge,
/// and creation date.
class MemoryCard extends StatelessWidget {
  const MemoryCard({
    required this.memory,
    super.key,
    this.onTap,
  });

  /// The memory to display.
  final Memory memory;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content preview
            Text(
              memory.content,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Footer: category badge + date
            Row(
              children: [
                if (memory.category != null)
                  SanbaoBadge(
                    label: MemoryCategory.labelFor(memory.category),
                    variant: _variantForCategory(memory.category),
                    size: SanbaoBadgeSize.small,
                  ),
                const Spacer(),
                Text(
                  _formatDate(memory.createdAt),
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
    );
  }

  static SanbaoBadgeVariant _variantForCategory(String? category) =>
      switch (category) {
        'preference' => SanbaoBadgeVariant.accent,
        'fact' => SanbaoBadgeVariant.success,
        'instruction' => SanbaoBadgeVariant.warning,
        'context' => SanbaoBadgeVariant.legal,
        _ => SanbaoBadgeVariant.neutral,
      };

  String _formatDate(DateTime date) {
    if (date.isToday) return 'Сегодня ${date.timeString}';
    if (date.isYesterday) return 'Вчера ${date.timeString}';
    final daysAgo = date.daysAgo;
    if (daysAgo < 7) return '$daysAgo дн. назад';
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Knowledge file detail screen.
///
/// Displays the full file content, metadata, and provides
/// edit and delete actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/empty_state.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_card.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/knowledge/domain/entities/knowledge_file.dart';
import 'package:sanbao_flutter/features/knowledge/presentation/providers/knowledge_provider.dart';
import 'package:sanbao_flutter/features/knowledge/presentation/widgets/knowledge_file_form.dart';

/// Detail screen for a single knowledge file.
///
/// Shows the file name, description, metadata, and the full
/// extracted text content in a scrollable view.
class KnowledgeDetailScreen extends ConsumerWidget {
  const KnowledgeDetailScreen({
    required this.fileId,
    super.key,
  });

  /// The ID of the knowledge file to display.
  final String fileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileAsync = ref.watch(knowledgeDetailProvider(fileId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Файл знаний'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          fileAsync.whenOrNull(
                data: (file) => _DetailActions(
                  file: file,
                  fileId: fileId,
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: fileAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (error, _) => EmptyState.error(
          message: 'Не удалось загрузить файл',
          onRetry: () => ref.invalidate(knowledgeDetailProvider(fileId)),
        ),
        data: (file) => _DetailContent(
          file: file,
          fileId: fileId,
        ),
      ),
    );
  }
}

/// Action buttons in the app bar.
class _DetailActions extends ConsumerWidget {
  const _DetailActions({
    required this.file,
    required this.fileId,
  });

  final KnowledgeFile file;
  final String fileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit button
        IconButton(
          onPressed: () => _editFile(context, ref),
          icon: Icon(
            Icons.edit_outlined,
            size: 20,
            color: colors.accent,
          ),
          tooltip: 'Редактировать',
        ),
        // More actions menu
        PopupMenuButton<_DetailAction>(
          icon: Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: colors.textSecondary,
          ),
          onSelected: (action) =>
              _handleAction(context, ref, action),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _DetailAction.copyContent,
              child: ListTile(
                leading: Icon(Icons.copy_rounded, size: 20),
                title: Text('Копировать текст'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: _DetailAction.delete,
              child: ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: colors.error,
                ),
                title: Text(
                  'Удалить',
                  style: TextStyle(color: colors.error),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editFile(BuildContext context, WidgetRef ref) async {
    final result = await showKnowledgeFileForm(
      context: context,
      existingFile: file,
    );
    if (result != null) {
      try {
        await ref.read(knowledgeListProvider.notifier).updateFile(
              file.id,
              name: result.name,
              description: result.description,
              content: result.content,
            );
        ref.invalidate(knowledgeDetailProvider(fileId));
        if (context.mounted) {
          context.showSuccessSnackBar('Файл обновлен');
        }
      } on Object catch (e) {
        if (context.mounted) {
          context.showErrorSnackBar('Ошибка: $e');
        }
      }
    }
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    _DetailAction action,
  ) {
    switch (action) {
      case _DetailAction.copyContent:
        final content = file.content ?? '';
        if (content.isEmpty) {
          context.showSnackBar('Нет содержимого для копирования');
          return;
        }
        Clipboard.setData(ClipboardData(text: content));
        context.showSuccessSnackBar('Текст скопирован');

      case _DetailAction.delete:
        _confirmAndDelete(context, ref);
    }
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: Text(
          'Файл "${file.name}" будет удален из базы знаний. '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Удалить',
              style: TextStyle(color: context.sanbaoColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await ref.read(knowledgeListProvider.notifier).deleteFile(file.id);
        if (context.mounted) {
          context.showSuccessSnackBar('Файл удален');
          Navigator.of(context).pop();
        }
      } on Object catch (e) {
        if (context.mounted) {
          context.showErrorSnackBar('Ошибка: $e');
        }
      }
    }
  }
}

/// Available actions in the more menu.
enum _DetailAction {
  copyContent,
  delete,
}

/// Main content of the detail screen.
class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.file,
    required this.fileId,
  });

  final KnowledgeFile file;
  final String fileId;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // File header
          _FileHeader(file: file),
          const SizedBox(height: 16),

          // Metadata card
          _MetadataCard(file: file),
          const SizedBox(height: 16),

          // Content card
          _ContentCard(file: file),

          const SizedBox(height: 32),
        ],
      );
}

/// Header section with file icon, name, and description.
class _FileHeader extends StatelessWidget {
  const _FileHeader({required this.file});

  final KnowledgeFile file;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SanbaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // File icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.accentLight,
                  borderRadius: SanbaoRadius.md,
                ),
                child: Icon(
                  Icons.description_rounded,
                  size: 24,
                  color: colors.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SanbaoBadge(
                          label: file.fileType.toUpperCase(),
                          size: SanbaoBadgeSize.small,
                        ),
                        const SizedBox(width: 8),
                        SanbaoBadge(
                          label: file.formattedSize,
                          variant: SanbaoBadgeVariant.neutral,
                          size: SanbaoBadgeSize.small,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (file.description != null && file.description!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgSurfaceAlt,
                borderRadius: SanbaoRadius.sm,
              ),
              child: Text(
                file.description!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card displaying file metadata (dates, size).
class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.file});

  final KnowledgeFile file;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SanbaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _MetadataRow(
            icon: Icons.calendar_today_outlined,
            label: 'Создан',
            value: _formatFullDate(file.createdAt),
          ),
          const SizedBox(height: 10),
          _MetadataRow(
            icon: Icons.update_rounded,
            label: 'Обновлен',
            value: _formatFullDate(file.updatedAt),
          ),
          const SizedBox(height: 10),
          _MetadataRow(
            icon: Icons.straighten_rounded,
            label: 'Размер',
            value: file.formattedSize,
          ),
          if (file.content != null) ...[
            const SizedBox(height: 10),
            _MetadataRow(
              icon: Icons.text_snippet_outlined,
              label: 'Символов',
              value: _formatNumber(file.content!.length),
            ),
          ],
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final time = date.timeString;
    return '$day.$month.$year $time';
  }

  String _formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
}

/// A single metadata row with icon, label, and value.
class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textMuted),
        const SizedBox(width: 10),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Card displaying the file's text content.
class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.file});

  final KnowledgeFile file;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final content = file.content;

    return SanbaoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Содержимое',
                style: context.textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (content != null && content.isNotEmpty)
                SanbaoButton(
                  label: 'Копировать',
                  variant: SanbaoButtonVariant.ghost,
                  size: SanbaoButtonSize.small,
                  leadingIcon: Icons.copy_rounded,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    context.showSuccessSnackBar('Текст скопирован');
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (content == null || content.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgSurfaceAlt,
                borderRadius: SanbaoRadius.sm,
              ),
              child: Text(
                'Содержимое недоступно',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 500),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgSurfaceAlt,
                borderRadius: SanbaoRadius.sm,
                border: Border.all(
                  color: colors.border,
                  width: 0.5,
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  content,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontFamily: 'JetBrains Mono',
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loading skeleton for the detail screen.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SanbaoSkeleton.box(),
          SizedBox(height: 16),
          SanbaoSkeleton.box(height: 160),
          SizedBox(height: 16),
          SanbaoSkeleton.box(height: 300),
        ],
      );
}

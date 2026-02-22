/// Knowledge base list screen with search, FAB upload, and swipe-to-delete.
///
/// Displays all user knowledge files with search filtering.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanbao_flutter/core/config/routes.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/empty_state.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/knowledge/domain/entities/knowledge_file.dart';
import 'package:sanbao_flutter/features/knowledge/presentation/providers/knowledge_provider.dart';
import 'package:sanbao_flutter/features/knowledge/presentation/widgets/knowledge_file_card.dart';
import 'package:sanbao_flutter/features/knowledge/presentation/widgets/knowledge_file_form.dart';

/// Screen displaying all knowledge base files with search and management.
///
/// Shows files in a list with search filtering, swipe-to-delete,
/// and a FAB to add new files.
class KnowledgeListScreen extends ConsumerStatefulWidget {
  const KnowledgeListScreen({super.key});

  @override
  ConsumerState<KnowledgeListScreen> createState() =>
      _KnowledgeListScreenState();
}

class _KnowledgeListScreenState extends ConsumerState<KnowledgeListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ignore: use_setters_to_change_properties
  void _onSearchChanged(String query) {
    ref.read(knowledgeSearchQueryProvider.notifier).state = query;
  }

  Future<void> _addFile() async {
    final result = await showKnowledgeFileForm(context: context);
    if (result != null) {
      try {
        await ref.read(knowledgeListProvider.notifier).createFile(
              name: result.name,
              content: result.content,
              description: result.description,
            );
        if (mounted) context.showSuccessSnackBar('Файл добавлен');
      } on Object catch (e) {
        if (mounted) context.showErrorSnackBar('Ошибка: $e');
      }
    }
  }

  Future<void> _deleteFile(KnowledgeFile file) async {
    await ref.read(knowledgeListProvider.notifier).deleteFile(file.id);
    if (mounted) {
      context.showSnackBar(
        'Файл удален',
        action: SnackBarAction(
          label: 'Отмена',
          onPressed: () {
            ref.read(knowledgeListProvider.notifier).createFile(
                  name: file.name,
                  content: file.content ?? '',
                  description: file.description,
                );
          },
        ),
      );
    }
  }

  void _openDetail(KnowledgeFile file) {
    context.push('${RoutePaths.knowledge}/${file.id}');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final filteredFiles = ref.watch(filteredKnowledgeFilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('База знаний'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFile,
        backgroundColor: colors.accent,
        foregroundColor: colors.textInverse,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(knowledgeListProvider.notifier).refresh(),
        color: colors.accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchField(colors)),
            SliverToBoxAdapter(child: _buildFileCount(colors)),
            filteredFiles.when(
              loading: () =>
                  SliverToBoxAdapter(child: _KnowledgeListSkeleton()),
              error: (_, __) => SliverToBoxAdapter(
                child: EmptyState.error(
                  message: 'Не удалось загрузить файлы',
                  onRetry: () =>
                      ref.read(knowledgeListProvider.notifier).refresh(),
                ),
              ),
              data: (files) {
                if (files.isEmpty) {
                  final hasSearchQuery =
                      ref.read(knowledgeSearchQueryProvider).isNotEmpty;

                  if (hasSearchQuery) {
                    return const SliverToBoxAdapter(
                      child: EmptyState.noResults(),
                    );
                  }

                  return SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.menu_book_rounded,
                      title: 'База знаний пуста',
                      message:
                          'Добавьте файлы, чтобы AI использовал их\n'
                          'для более точных ответов',
                      actionLabel: 'Добавить файл',
                      onAction: _addFile,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: files.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return Dismissible(
                        key: ValueKey(file.id),
                        direction: DismissDirection.endToStart,
                        background: _buildDismissBackground(colors),
                        confirmDismiss: (_) => _confirmDelete(context),
                        onDismissed: (_) => _deleteFile(file),
                        child: KnowledgeFileCard(
                          file: file,
                          onTap: () => _openDetail(file),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            // Bottom padding for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(SanbaoColorScheme colors) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Поиск файлов...',
            hintStyle: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
            prefixIcon:
                Icon(Icons.search, size: 18, color: colors.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    icon:
                        Icon(Icons.close, size: 16, color: colors.textMuted),
                  )
                : null,
            filled: true,
            fillColor: colors.bgSurfaceAlt,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: SanbaoRadius.md,
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: SanbaoRadius.md,
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: SanbaoRadius.md,
              borderSide: BorderSide(color: colors.borderFocus, width: 1.5),
            ),
            isDense: true,
          ),
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textPrimary,
          ),
        ),
      );

  Widget _buildFileCount(SanbaoColorScheme colors) {
    final files = ref.watch(knowledgeListProvider);
    final count = files.valueOrNull?.length;

    if (count == null || count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: 14,
            color: colors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            _pluralFiles(count),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground(SanbaoColorScheme colors) => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.errorLight,
          borderRadius: SanbaoRadius.lg,
        ),
        child: Icon(Icons.delete_outline, color: colors.error),
      );

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить файл?'),
        content: const Text(
          'Файл будет удален из базы знаний. '
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
    return confirmed ?? false;
  }

  /// Returns the correct Russian plural for file count.
  String _pluralFiles(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;

    if (mod100 >= 11 && mod100 <= 19) return '$count файлов';
    if (mod10 == 1) return '$count файл';
    if (mod10 >= 2 && mod10 <= 4) return '$count файла';
    return '$count файлов';
  }
}

class _KnowledgeListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SanbaoSkeleton.box(height: 100),
            ),
          ),
        ),
      );
}

/// Memory list screen with search, add FAB, and swipe-to-delete.
///
/// Displays all memories with search filtering and category badges.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/empty_state.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/memory/domain/entities/memory.dart';
import 'package:sanbao_flutter/features/memory/presentation/providers/memory_provider.dart';
import 'package:sanbao_flutter/features/memory/presentation/widgets/memory_card.dart';
import 'package:sanbao_flutter/features/memory/presentation/widgets/memory_form.dart';

/// Screen displaying all AI memories with search and management.
///
/// Shows memories in a list with search filtering, swipe-to-delete,
/// and a FAB to add new memories.
class MemoryListScreen extends ConsumerStatefulWidget {
  const MemoryListScreen({super.key});

  @override
  ConsumerState<MemoryListScreen> createState() => _MemoryListScreenState();
}

class _MemoryListScreenState extends ConsumerState<MemoryListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ignore: use_setters_to_change_properties
  void _onSearchChanged(String query) {
    ref.read(memorySearchQueryProvider.notifier).state = query;
  }

  Future<void> _addMemory() async {
    final result = await showMemoryForm(context: context);
    if (result != null) {
      try {
        await ref.read(memoryListProvider.notifier).createMemory(
              content: result.content,
              category: result.category,
            );
        if (mounted) context.showSuccessSnackBar('Запись добавлена');
      } on Object catch (e) {
        if (mounted) context.showErrorSnackBar('Ошибка: $e');
      }
    }
  }

  Future<void> _editMemory(Memory memory) async {
    final result = await showMemoryForm(
      context: context,
      existingMemory: memory,
    );
    if (result != null) {
      try {
        await ref.read(memoryListProvider.notifier).updateMemory(
              id: memory.id,
              content: result.content,
              category: result.category,
            );
        if (mounted) context.showSuccessSnackBar('Запись обновлена');
      } on Object catch (e) {
        if (mounted) context.showErrorSnackBar('Ошибка: $e');
      }
    }
  }

  Future<void> _deleteMemory(Memory memory) async {
    await ref.read(memoryListProvider.notifier).deleteMemory(memory.id);
    if (mounted) {
      context.showSnackBar(
        'Запись удалена',
        action: SnackBarAction(
          label: 'Отмена',
          onPressed: () {
            // Re-create from deleted memory data
            ref.read(memoryListProvider.notifier).createMemory(
                  content: memory.content,
                  category: memory.category,
                );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final filteredMemories = ref.watch(filteredMemoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Память'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMemory,
        backgroundColor: colors.accent,
        foregroundColor: colors.textInverse,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(memoryListProvider.notifier).refresh(),
        color: colors.accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchField(colors)),
            SliverToBoxAdapter(child: _buildCategoryFilters(colors)),
            filteredMemories.when(
              loading: () =>
                  SliverToBoxAdapter(child: _MemoryListSkeleton()),
              error: (_, __) => SliverToBoxAdapter(
                child: EmptyState.error(
                  message: 'Не удалось загрузить записи',
                  onRetry: () =>
                      ref.read(memoryListProvider.notifier).refresh(),
                ),
              ),
              data: (memories) {
                if (memories.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.psychology_outlined,
                      title: 'Нет записей',
                      message:
                          'Добавьте записи, чтобы AI запомнил важную информацию',
                      actionLabel: 'Добавить запись',
                      onAction: _addMemory,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: memories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final memory = memories[index];
                      return Dismissible(
                        key: ValueKey(memory.id),
                        direction: DismissDirection.endToStart,
                        background: _buildDismissBackground(colors),
                        onDismissed: (_) => _deleteMemory(memory),
                        child: MemoryCard(
                          memory: memory,
                          onTap: () => _editMemory(memory),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
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
            hintText: 'Поиск записей...',
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

  Widget _buildCategoryFilters(SanbaoColorScheme colors) {
    final selectedCategory = ref.watch(memoryCategoryFilterProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            label: 'Все',
            isSelected: selectedCategory == null,
            onTap: () => ref
                .read(memoryCategoryFilterProvider.notifier)
                .state = null,
            colors: colors,
          ),
          ...MemoryCategory.labels.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _CategoryChip(
                label: entry.value,
                isSelected: selectedCategory == entry.key,
                onTap: () => ref
                    .read(memoryCategoryFilterProvider.notifier)
                    .state = entry.key,
                colors: colors,
              ),
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
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final SanbaoColorScheme colors;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentLight : colors.bgSurfaceAlt,
            borderRadius: SanbaoRadius.md,
            border: Border.all(
              color: isSelected ? colors.accent : colors.border,
              width: isSelected ? 1 : 0.5,
            ),
          ),
          child: Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: isSelected ? colors.accent : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
}

class _MemoryListSkeleton extends StatelessWidget {
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

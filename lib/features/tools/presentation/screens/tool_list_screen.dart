/// Tool list screen with type filter tabs.
///
/// Displays all tools in a list with tab-based type filtering,
/// search, and enabled toggle per tool.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/empty_state.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/tools/domain/entities/tool.dart';
import 'package:sanbao_flutter/features/tools/presentation/providers/tools_provider.dart';
import 'package:sanbao_flutter/features/tools/presentation/screens/tool_form_screen.dart';
import 'package:sanbao_flutter/features/tools/presentation/widgets/tool_card.dart';

/// Screen displaying all tools with type filter tabs.
///
/// Provides search, type-based filtering via tabs, and the ability
/// to toggle tools on/off inline.
class ToolListScreen extends ConsumerStatefulWidget {
  const ToolListScreen({super.key});

  @override
  ConsumerState<ToolListScreen> createState() => _ToolListScreenState();
}

class _ToolListScreenState extends ConsumerState<ToolListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  static const _tabs = <(String label, ToolType? type)>[
    ('Все', null),
    ('Шаблоны', ToolType.promptTemplate),
    ('Вебхуки', ToolType.webhook),
    ('URL', ToolType.url),
    ('Функции', ToolType.function_),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(toolsTypeFilterProvider.notifier).state =
          _tabs[_tabController.index].$2;
    }
  }

  // ignore: use_setters_to_change_properties
  void _onSearchChanged(String query) {
    ref.read(toolsSearchQueryProvider.notifier).state = query;
  }

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ToolFormScreen()),
    );
  }

  void _navigateToEdit(Tool tool) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ToolFormScreen(tool: tool)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final filteredTools = ref.watch(filteredToolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Инструменты'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((tab) => Tab(text: tab.$1)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        backgroundColor: colors.accent,
        foregroundColor: colors.textInverse,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(toolsListProvider.notifier).refresh(),
        color: colors.accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchField(colors)),
            filteredTools.when(
              loading: () => SliverToBoxAdapter(child: _ToolListSkeleton()),
              error: (error, _) => SliverToBoxAdapter(
                child: EmptyState.error(
                  message: 'Не удалось загрузить инструменты',
                  onRetry: () =>
                      ref.read(toolsListProvider.notifier).refresh(),
                ),
              ),
              data: (tools) {
                if (tools.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.build_outlined,
                      title: 'Нет инструментов',
                      message:
                          'Создайте инструмент для расширения возможностей агентов',
                      actionLabel: 'Создать инструмент',
                      onAction: _navigateToCreate,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: tools.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tool = tools[index];
                      return ToolCard(
                        tool: tool,
                        onTap: () => _navigateToEdit(tool),
                        onToggleEnabled: () => ref
                            .read(toolsListProvider.notifier)
                            .toggleEnabled(tool.id),
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
            hintText: 'Поиск инструментов...',
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
}

class _ToolListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            4,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SanbaoSkeleton.box(height: 80),
            ),
          ),
        ),
      );
}

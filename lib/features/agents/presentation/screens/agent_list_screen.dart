/// Agent list screen with system and user agent sections.
///
/// Displays agents in a grid layout with a search filter and
/// a FAB to create new agents.
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
import 'package:sanbao_flutter/features/agents/domain/entities/agent.dart';
import 'package:sanbao_flutter/features/agents/presentation/providers/agents_provider.dart';
import 'package:sanbao_flutter/features/agents/presentation/screens/agent_form_screen.dart';
import 'package:sanbao_flutter/features/agents/presentation/widgets/agent_card.dart';
import 'package:sanbao_flutter/features/agents/presentation/widgets/agent_generate_sheet.dart';

/// Screen displaying all available agents organized by type.
///
/// Shows two sections: "System agents" (built-in) and "Your agents"
/// (user-created). Includes a search field and a FAB to create
/// new agents.
class AgentListScreen extends ConsumerStatefulWidget {
  const AgentListScreen({super.key});

  @override
  ConsumerState<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends ConsumerState<AgentListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(agentsSearchQueryProvider.notifier).state = query;
  }

  void _navigateToDetail(Agent agent) {
    context.pushNamed(
      RouteNames.agentDetail,
      pathParameters: {'id': agent.id},
    );
  }

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AgentFormScreen(),
      ),
    );
  }

  void _showGenerateSheet() {
    showAgentGenerateSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Агенты'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'agent_generate',
            onPressed: _showGenerateSheet,
            backgroundColor: colors.bgSurface,
            foregroundColor: colors.accent,
            child: const Icon(Icons.auto_awesome_rounded),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'agent_create',
            onPressed: _navigateToCreate,
            backgroundColor: colors.accent,
            foregroundColor: colors.textInverse,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(agentsListProvider.notifier).refresh(),
        color: colors.accent,
        child: CustomScrollView(
          slivers: [
            // Search
            SliverToBoxAdapter(child: _buildSearchField(colors)),
            // System agents section
            _SystemAgentsSection(onAgentTap: _navigateToDetail),
            // User agents section
            _UserAgentsSection(onAgentTap: _navigateToDetail),
            // Bottom spacing
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
            hintText: 'Поиск агентов...',
            hintStyle: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: colors.textMuted,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: colors.textMuted,
                    ),
                  )
                : null,
            filled: true,
            fillColor: colors.bgSurfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
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
              borderSide:
                  BorderSide(color: colors.borderFocus, width: 1.5),
            ),
            isDense: true,
          ),
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textPrimary,
          ),
        ),
      );
}

/// Section displaying system (built-in) agents.
class _SystemAgentsSection extends ConsumerWidget {
  const _SystemAgentsSection({required this.onAgentTap});

  final ValueChanged<Agent> onAgentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemAgents = ref.watch(systemAgentsProvider);

    return systemAgents.when(
      loading: () => SliverToBoxAdapter(
        child: _AgentGridSkeleton(),
      ),
      error: (error, _) => SliverToBoxAdapter(
        child: EmptyState.error(
          message: 'Не удалось загрузить системных агентов',
          onRetry: () => ref.read(agentsListProvider.notifier).refresh(),
        ),
      ),
      data: (agents) {
        if (agents.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Системные агенты',
                  count: agents.length,
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => AgentCard(
                    agent: agents[index],
                    onTap: () => onAgentTap(agents[index]),
                  ),
                  childCount: agents.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Section displaying user-created agents.
class _UserAgentsSection extends ConsumerWidget {
  const _UserAgentsSection({required this.onAgentTap});

  final ValueChanged<Agent> onAgentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAgents = ref.watch(userAgentsProvider);

    return userAgents.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (agents) {
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Ваши агенты',
                  count: agents.length,
                ),
              ),
              if (agents.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.smart_toy_outlined,
                    title: 'Нет пользовательских агентов',
                    message:
                        'Создайте своего агента с уникальными настройками',
                  ),
                )
              else
                SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => AgentCard(
                      agent: agents[index],
                      onTap: () => onAgentTap(agents[index]),
                    ),
                    childCount: agents.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Section header with title and count badge.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.bgSurfaceAlt,
              borderRadius: SanbaoRadius.sm,
            ),
            child: Text(
              '$count',
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading state for the agent grid.
class _AgentGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: 4,
          itemBuilder: (context, _) => const SanbaoSkeleton.box(height: 180),
        ),
      );
}


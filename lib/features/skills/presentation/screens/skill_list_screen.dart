/// Skill list screen with "My Skills" and "Marketplace" tabs.
///
/// Displays skills in a grid layout with search filtering,
/// tab-based navigation, and a FAB to create new skills.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/empty_state.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/skills/domain/entities/skill.dart';
import 'package:sanbao_flutter/features/skills/presentation/providers/skills_provider.dart';
import 'package:sanbao_flutter/features/skills/presentation/screens/skill_detail_screen.dart';
import 'package:sanbao_flutter/features/skills/presentation/screens/skill_form_screen.dart';
import 'package:sanbao_flutter/features/skills/presentation/widgets/skill_card.dart';
import 'package:sanbao_flutter/features/skills/presentation/widgets/skill_generate_sheet.dart';

// ignore_for_file: use_build_context_synchronously

/// Screen displaying skills in two tabs: personal and marketplace.
class SkillListScreen extends ConsumerStatefulWidget {
  const SkillListScreen({super.key});

  @override
  ConsumerState<SkillListScreen> createState() => _SkillListScreenState();
}

class _SkillListScreenState extends ConsumerState<SkillListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ignore: use_setters_to_change_properties
  void _onSearchChanged(String query) {
    ref.read(skillsSearchQueryProvider.notifier).state = query;
  }

  void _navigateToDetail(Skill skill) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SkillDetailScreen(skillId: skill.id),
      ),
    );
  }

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SkillFormScreen(),
      ),
    );
  }

  void _showGenerateSheet() {
    showSkillGenerateSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Навыки'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Мои скиллы'),
            Tab(text: 'Маркетплейс'),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'skill_generate',
            onPressed: _showGenerateSheet,
            backgroundColor: colors.bgSurface,
            foregroundColor: colors.accent,
            child: const Icon(Icons.auto_awesome_rounded),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'skill_create',
            onPressed: _navigateToCreate,
            backgroundColor: colors.accent,
            foregroundColor: colors.textInverse,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(colors),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MySkillsTab(onSkillTap: _navigateToDetail),
                _MarketplaceTab(onSkillTap: _navigateToDetail),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(SanbaoColorScheme colors) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Поиск навыков...',
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

/// Tab displaying the user's personal skills.
class _MySkillsTab extends ConsumerWidget {
  const _MySkillsTab({required this.onSkillTap});

  final ValueChanged<Skill> onSkillTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(filteredSkillsProvider);

    return skillsAsync.when(
      loading: _SkillGridSkeleton.new,
      error: (error, _) => EmptyState.error(
        message: 'Не удалось загрузить навыки',
        onRetry: () => ref.read(skillsListProvider.notifier).refresh(),
      ),
      data: (skills) {
        if (skills.isEmpty) {
          return const EmptyState(
            icon: Icons.psychology_outlined,
            title: 'Нет навыков',
            message: 'Создайте свой навык или клонируйте из маркетплейса',
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(skillsListProvider.notifier).refresh(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: skills.length,
            itemBuilder: (context, index) => SkillCard(
              skill: skills[index],
              onTap: () => onSkillTap(skills[index]),
            ),
          ),
        );
      },
    );
  }
}

/// Tab displaying the public marketplace skills.
class _MarketplaceTab extends ConsumerWidget {
  const _MarketplaceTab({required this.onSkillTap});

  final ValueChanged<Skill> onSkillTap;

  Future<void> _cloneSkill(BuildContext context, WidgetRef ref, Skill skill) async {
    try {
      await ref.read(skillsListProvider.notifier).cloneSkill(skill.id);
      context.showSuccessSnackBar('Навык "${skill.name}" клонирован');
    } on Object catch (e) {
      context.showErrorSnackBar(
        'Ошибка клонирования: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(filteredPublicSkillsProvider);

    return skillsAsync.when(
      loading: _SkillGridSkeleton.new,
      error: (error, _) => EmptyState.error(
        message: 'Не удалось загрузить маркетплейс',
        onRetry: () => ref.read(publicSkillsProvider.notifier).refresh(),
      ),
      data: (skills) {
        if (skills.isEmpty) {
          return const EmptyState(
            icon: Icons.store_outlined,
            title: 'Маркетплейс пуст',
            message: 'Пока нет публичных навыков',
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(publicSkillsProvider.notifier).refresh(),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: skills.length,
            itemBuilder: (context, index) => SkillCard(
              skill: skills[index],
              onTap: () => onSkillTap(skills[index]),
              showCloneCount: true,
              onClone: () => _cloneSkill(context, ref, skills[index]),
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton loading state for the skill grid.
class _SkillGridSkeleton extends StatelessWidget {
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

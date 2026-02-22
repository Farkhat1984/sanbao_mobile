/// Plugin list screen with enable/disable toggles.
///
/// Displays all plugins with inline toggle switches and search.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/empty_state.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/plugins/domain/entities/plugin.dart';
import 'package:sanbao_flutter/features/plugins/presentation/providers/plugins_provider.dart';
import 'package:sanbao_flutter/features/plugins/presentation/screens/plugin_form_screen.dart';

/// Screen displaying all plugins with enable/disable toggles.
class PluginListScreen extends ConsumerStatefulWidget {
  const PluginListScreen({super.key});

  @override
  ConsumerState<PluginListScreen> createState() => _PluginListScreenState();
}

class _PluginListScreenState extends ConsumerState<PluginListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ignore: use_setters_to_change_properties
  void _onSearchChanged(String query) {
    ref.read(pluginsSearchQueryProvider.notifier).state = query;
  }

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PluginFormScreen()),
    );
  }

  void _navigateToEdit(Plugin plugin) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PluginFormScreen(plugin: plugin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final filteredPlugins = ref.watch(filteredPluginsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Плагины'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        backgroundColor: colors.accent,
        foregroundColor: colors.textInverse,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(pluginsListProvider.notifier).refresh(),
        color: colors.accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchField(colors)),
            filteredPlugins.when(
              loading: () => SliverToBoxAdapter(
                child: _PluginListSkeleton(),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: EmptyState.error(
                  message: 'Не удалось загрузить плагины',
                  onRetry: () =>
                      ref.read(pluginsListProvider.notifier).refresh(),
                ),
              ),
              data: (plugins) {
                if (plugins.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.extension_outlined,
                      title: 'Нет плагинов',
                      message:
                          'Создайте плагин, объединив инструменты и скиллы',
                      actionLabel: 'Создать плагин',
                      onAction: _navigateToCreate,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: plugins.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final plugin = plugins[index];
                      return _PluginCard(
                        plugin: plugin,
                        onTap: () => _navigateToEdit(plugin),
                        onToggle: () => ref
                            .read(pluginsListProvider.notifier)
                            .toggleEnabled(plugin.id),
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
            hintText: 'Поиск плагинов...',
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

/// Card for a single plugin in the list.
class _PluginCard extends StatelessWidget {
  const _PluginCard({
    required this.plugin,
    required this.onTap,
    required this.onToggle,
  });

  final Plugin plugin;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: plugin.isEnabled ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: SanbaoRadius.lg,
            border: Border.all(color: colors.border, width: 0.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.legalRefBg,
                  borderRadius: SanbaoRadius.md,
                ),
                child: Icon(
                  Icons.extension_outlined,
                  color: colors.legalRef,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plugin.name,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (plugin.description != null &&
                        plugin.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        plugin.description!,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (plugin.tools.isNotEmpty)
                          SanbaoBadge(
                            label: '${plugin.tools.length} инстр.',
                            icon: Icons.build_outlined,
                            size: SanbaoBadgeSize.small,
                          ),
                        if (plugin.skills.isNotEmpty)
                          SanbaoBadge(
                            label: '${plugin.skills.length} скилл.',
                            variant: SanbaoBadgeVariant.legal,
                            icon: Icons.psychology_outlined,
                            size: SanbaoBadgeSize.small,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: plugin.isEnabled,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PluginListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SanbaoSkeleton.box(height: 100),
            ),
          ),
        ),
      );
}

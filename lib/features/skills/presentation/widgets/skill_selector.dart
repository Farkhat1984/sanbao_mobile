/// Multi-select skills picker bottom sheet.
///
/// Shows a searchable list of skills with checkboxes for
/// multi-selection. Used when configuring agent skills.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/agents/presentation/widgets/agent_icon.dart';
import 'package:sanbao_flutter/features/skills/domain/entities/skill.dart';
import 'package:sanbao_flutter/features/skills/presentation/providers/skills_provider.dart';

/// Shows a multi-select skill picker bottom sheet.
///
/// Returns the selected skill IDs when confirmed, or `null` if dismissed.
Future<List<String>?> showSkillSelector({
  required BuildContext context,
  List<String> initialSelected = const [],
}) =>
    showSanbaoBottomSheet<List<String>>(
      context: context,
      builder: (context) => _SkillSelectorContent(
        initialSelected: initialSelected,
      ),
      maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    );

class _SkillSelectorContent extends ConsumerStatefulWidget {
  const _SkillSelectorContent({
    required this.initialSelected,
  });

  final List<String> initialSelected;

  @override
  ConsumerState<_SkillSelectorContent> createState() =>
      _SkillSelectorContentState();
}

class _SkillSelectorContentState extends ConsumerState<_SkillSelectorContent> {
  late Set<String> _selected;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = Set.of(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSkill(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _confirm() {
    Navigator.of(context).pop(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final skillsAsync = ref.watch(skillsListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Выберите скиллы',
                  style: context.textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close,
                  color: colors.textMuted,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Поиск скиллов...',
              hintStyle: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color: colors.textMuted,
              ),
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
          const SizedBox(height: 12),
          // Skills list
          Flexible(
            child: skillsAsync.when(
              loading: () => const SanbaoSkeletonList(itemCount: 4),
              error: (error, _) => Center(
                child: Text(
                  'Ошибка загрузки скиллов',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              data: (skills) {
                final filtered = _filterSkills(skills);
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Скиллы не найдены',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    color: colors.border,
                    height: 1,
                  ),
                  itemBuilder: (context, index) =>
                      _buildSkillTile(filtered[index], colors),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Confirm button
          SanbaoButton(
            label: 'Выбрать (${_selected.length})',
            onPressed: _confirm,
            isExpanded: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Skill> _filterSkills(List<Skill> skills) {
    if (_searchQuery.isEmpty) return skills;

    final query = _searchQuery.toLowerCase();
    return skills
        .where((s) =>
            s.name.toLowerCase().contains(query) ||
            (s.description?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  Widget _buildSkillTile(Skill skill, SanbaoColorScheme colors) {
    final isSelected = _selected.contains(skill.id);

    return ListTile(
      onTap: () => _toggleSkill(skill.id),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: AgentIcon(
        icon: skill.icon,
        color: skill.iconColor,
        size: AgentIconSize.sm,
      ),
      title: Text(
        skill.name,
        style: context.textTheme.titleSmall?.copyWith(
          color: colors.textPrimary,
        ),
      ),
      subtitle: skill.description != null
          ? Text(
              skill.description!,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Checkbox(
        value: isSelected,
        onChanged: (_) => _toggleSkill(skill.id),
        activeColor: colors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

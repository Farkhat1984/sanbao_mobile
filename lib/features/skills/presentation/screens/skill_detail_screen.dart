/// Skill detail screen showing full skill information.
///
/// Displays the skill's icon, name, description, jurisdiction,
/// system prompt preview, and action buttons (Clone/Edit/Delete).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/empty_state.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_card.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/agents/presentation/widgets/agent_icon.dart';
import 'package:sanbao_flutter/features/skills/domain/entities/skill.dart';
import 'package:sanbao_flutter/features/skills/presentation/providers/skills_provider.dart';
import 'package:sanbao_flutter/features/skills/presentation/screens/skill_form_screen.dart';

/// Screen displaying full details for a single skill.
class SkillDetailScreen extends ConsumerStatefulWidget {
  const SkillDetailScreen({
    required this.skillId,
    super.key,
  });

  /// The skill ID to display.
  final String skillId;

  @override
  ConsumerState<SkillDetailScreen> createState() =>
      _SkillDetailScreenState();
}

class _SkillDetailScreenState extends ConsumerState<SkillDetailScreen> {
  bool _isCloning = false;

  @override
  Widget build(BuildContext context) {
    final skillAsync = ref.watch(currentSkillProvider(widget.skillId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Навык'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          skillAsync.whenOrNull(
                data: (skill) {
                  if (skill == null || skill.isBuiltIn) return null;
                  return PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenuAction(value, skill),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Редактировать'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Удалить', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: skillAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (error, _) => EmptyState.error(
          message: 'Не удалось загрузить навык',
          onRetry: () => ref.invalidate(currentSkillProvider(widget.skillId)),
        ),
        data: (skill) {
          if (skill == null) {
            return const EmptyState(
              icon: Icons.psychology_outlined,
              title: 'Навык не найден',
              message: 'Навык был удален или не существует',
            );
          }
          return _SkillDetailContent(
            skill: skill,
            isCloning: _isCloning,
            onClone: () => _cloneSkill(skill),
            onEdit: () => _editSkill(skill),
          );
        },
      ),
    );
  }

  void _handleMenuAction(String action, Skill skill) {
    switch (action) {
      case 'edit':
        _editSkill(skill);
      case 'delete':
        _confirmDelete(skill);
    }
  }

  void _editSkill(Skill skill) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SkillFormScreen(existingSkill: skill),
      ),
    );
  }

  Future<void> _confirmDelete(Skill skill) async {
    final confirmed = await showSanbaoConfirmDialog(
      context: context,
      title: 'Удалить навык?',
      message: 'Навык "${skill.name}" будет удален безвозвратно.',
      confirmLabel: 'Удалить',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      await ref.read(skillsListProvider.notifier).deleteSkill(skill.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _cloneSkill(Skill skill) async {
    setState(() => _isCloning = true);

    try {
      await ref.read(skillsListProvider.notifier).cloneSkill(skill.id);
      if (mounted) {
        context.showSuccessSnackBar('Навык клонирован в вашу библиотеку');
      }
    } on Object catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          'Ошибка клонирования: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isCloning = false);
    }
  }
}

/// Content widget for the skill detail scroll view.
class _SkillDetailContent extends StatelessWidget {
  const _SkillDetailContent({
    required this.skill,
    required this.isCloning,
    required this.onClone,
    required this.onEdit,
  });

  final Skill skill;
  final bool isCloning;
  final VoidCallback onClone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, colors),
          const SizedBox(height: 24),
          // Action buttons
          _buildActionButtons(context, colors),
          const SizedBox(height: 24),
          // Info section
          _buildInfoSection(context, colors),
          // System prompt preview
          const SizedBox(height: 20),
          _buildSystemPromptSection(context, colors),
          // Citation rules (if legal skill)
          if (skill.citationRules != null &&
              skill.citationRules!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildCitationRulesSection(context, colors),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SanbaoColorScheme colors) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgentIcon(
            icon: skill.icon,
            color: skill.iconColor,
            size: AgentIconSize.xxl,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  skill.name,
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                // Badges row
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (skill.isBuiltIn)
                      const SanbaoBadge(
                        label: 'Встроенный',
                        variant: SanbaoBadgeVariant.neutral,
                        size: SanbaoBadgeSize.small,
                      ),
                    if (skill.isPublic)
                      const SanbaoBadge(
                        label: 'Публичный',
                        size: SanbaoBadgeSize.small,
                      ),
                    if (skill.isLegal && skill.jurisdictionLabel != null)
                      SanbaoBadge(
                        label: skill.jurisdictionLabel!,
                        variant: SanbaoBadgeVariant.legal,
                        icon: Icons.gavel_outlined,
                        size: SanbaoBadgeSize.small,
                      ),
                  ],
                ),
                if (skill.description != null &&
                    skill.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    skill.description!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );

  Widget _buildActionButtons(
    BuildContext context,
    SanbaoColorScheme colors,
  ) {
    // For non-owned skills (e.g., marketplace), show clone button.
    // For own skills, show edit button.
    if (skill.isBuiltIn) {
      return SanbaoButton(
        label: 'Клонировать',
        onPressed: onClone,
        isLoading: isCloning,
        leadingIcon: Icons.copy_outlined,
        isExpanded: true,
        variant: SanbaoButtonVariant.secondary,
      );
    }

    return Row(
      children: [
        Expanded(
          child: SanbaoButton(
            label: 'Редактировать',
            onPressed: onEdit,
            leadingIcon: Icons.edit_outlined,
            variant: SanbaoButtonVariant.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SanbaoButton(
            label: 'Клонировать',
            onPressed: onClone,
            isLoading: isCloning,
            leadingIcon: Icons.copy_outlined,
            variant: SanbaoButtonVariant.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    SanbaoColorScheme colors,
  ) =>
      SanbaoCard(
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
            _InfoRow(
              label: 'Тип',
              value: skill.isBuiltIn ? 'Встроенный' : 'Пользовательский',
              icon: Icons.category_outlined,
            ),
            if (skill.isLegal) ...[
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Юрисдикция',
                value: skill.jurisdictionLabel ?? skill.jurisdiction ?? '',
                icon: Icons.gavel_outlined,
              ),
            ],
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Видимость',
              value: skill.isPublic ? 'Публичный' : 'Приватный',
              icon: skill.isPublic
                  ? Icons.public_outlined
                  : Icons.lock_outlined,
            ),
            if (skill.cloneCount > 0) ...[
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Клонов',
                value: '${skill.cloneCount}',
                icon: Icons.copy_outlined,
              ),
            ],
          ],
        ),
      );

  Widget _buildSystemPromptSection(
    BuildContext context,
    SanbaoColorScheme colors,
  ) =>
      SanbaoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Системный промпт',
              style: context.textTheme.titleSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgSurfaceAlt,
                borderRadius: SanbaoRadius.sm,
              ),
              child: Text(
                skill.systemPrompt.length > 500
                    ? '${skill.systemPrompt.substring(0, 500)}...'
                    : skill.systemPrompt,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontFamily: 'JetBrainsMono',
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildCitationRulesSection(
    BuildContext context,
    SanbaoColorScheme colors,
  ) =>
      SanbaoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Правила цитирования',
              style: context.textTheme.titleSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgSurfaceAlt,
                borderRadius: SanbaoRadius.sm,
              ),
              child: Text(
                skill.citationRules!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontFamily: 'JetBrainsMono',
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
}

/// A key-value info row with icon.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Skeleton loading state for the detail screen.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SanbaoSkeleton.circle(size: 80),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SanbaoSkeleton.line(
                        width: MediaQuery.sizeOf(context).width * 0.4,
                        height: 20,
                      ),
                      const SizedBox(height: 8),
                      const SanbaoSkeleton.line(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SanbaoSkeleton.box(height: 48),
            const SizedBox(height: 24),
            const SanbaoSkeleton.box(height: 160),
          ],
        ),
      );
}

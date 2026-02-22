/// Agent detail screen showing full agent information.
///
/// Displays the agent's icon, name, description, tools, skills,
/// starter prompts, and model info. Provides "Start Chat",
/// "Edit", and "Delete" actions for user agents.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanbao_flutter/core/config/routes.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/empty_state.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_card.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/agents/domain/entities/agent.dart';
import 'package:sanbao_flutter/features/agents/presentation/providers/agents_provider.dart';
import 'package:sanbao_flutter/features/agents/presentation/screens/agent_form_screen.dart';
import 'package:sanbao_flutter/features/agents/presentation/widgets/agent_icon.dart';
import 'package:sanbao_flutter/features/agents/presentation/widgets/starter_prompts.dart';

/// Screen displaying full details for a single agent.
class AgentDetailScreen extends ConsumerWidget {
  const AgentDetailScreen({
    required this.agentId,
    super.key,
  });

  /// The agent ID to display.
  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentAsync = ref.watch(currentAgentProvider(agentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Агент'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          agentAsync.whenOrNull(
                data: (agent) {
                  if (agent == null || agent.isSystem) return null;
                  return PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenuAction(context, ref, value, agent),
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
      body: agentAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (error, _) => EmptyState.error(
          message: 'Не удалось загрузить агента',
          onRetry: () => ref.invalidate(currentAgentProvider(agentId)),
        ),
        data: (agent) {
          if (agent == null) {
            return const EmptyState(
              icon: Icons.smart_toy_outlined,
              title: 'Агент не найден',
              message: 'Агент был удален или не существует',
            );
          }
          return _AgentDetailContent(agent: agent);
        },
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    Agent agent,
  ) {
    switch (action) {
      case 'edit':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AgentFormScreen(existingAgent: agent),
          ),
        );
      case 'delete':
        _confirmDelete(context, ref, agent);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Agent agent,
  ) async {
    final confirmed = await showSanbaoConfirmDialog(
      context: context,
      title: 'Удалить агента?',
      message: 'Агент "${agent.name}" будет удален безвозвратно.',
      confirmLabel: 'Удалить',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      await ref.read(agentsListProvider.notifier).deleteAgent(agent.id);
      if (context.mounted) context.pop();
    }
  }
}

/// Content widget for the agent detail scroll view.
class _AgentDetailContent extends StatelessWidget {
  const _AgentDetailContent({required this.agent});

  final Agent agent;

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
          // Start Chat button
          SanbaoButton(
            label: 'Начать чат',
            onPressed: () => _startChat(context),
            leadingIcon: Icons.chat_outlined,
            isExpanded: true,
          ),
          const SizedBox(height: 24),
          // Model info
          _buildInfoSection(context, colors),
          // Tools
          if (agent.tools.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildToolsSection(context, colors),
          ],
          // Skills
          if (agent.skills.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSkillsSection(context, colors),
          ],
          // Starter prompts
          if (agent.starterPrompts.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildStarterPromptsSection(context, colors),
          ],
          // System prompt preview
          const SizedBox(height: 20),
          _buildSystemPromptSection(context, colors),
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
            icon: agent.icon,
            color: agent.iconColor,
            size: AgentIconSize.xxl,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        agent.name,
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (agent.isSystem)
                      const SanbaoBadge(
                        label: 'Системный',
                        variant: SanbaoBadgeVariant.neutral,
                        size: SanbaoBadgeSize.small,
                      ),
                  ],
                ),
                if (agent.description != null &&
                    agent.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    agent.description!,
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

  Widget _buildInfoSection(BuildContext context, SanbaoColorScheme colors) =>
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
              label: 'Модель',
              value: agent.model,
              icon: Icons.memory_outlined,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Инструменты',
              value: '${agent.tools.length}',
              icon: Icons.build_outlined,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Навыки',
              value: '${agent.skills.length}',
              icon: Icons.psychology_outlined,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Файлы',
              value: '${agent.files.length}',
              icon: Icons.attach_file_outlined,
            ),
          ],
        ),
      );

  Widget _buildToolsSection(
    BuildContext context,
    SanbaoColorScheme colors,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Инструменты',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: agent.tools.map((tool) => SanbaoBadge(
                label: tool.toolName,
                icon: Icons.build_outlined,
              ),).toList(),
          ),
        ],
      );

  Widget _buildSkillsSection(
    BuildContext context,
    SanbaoColorScheme colors,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Навыки',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: agent.skills.map((skill) => SanbaoBadge(
                label: skill.skillName,
                variant: SanbaoBadgeVariant.legal,
                icon: Icons.psychology_outlined,
              ),).toList(),
          ),
        ],
      );

  Widget _buildStarterPromptsSection(
    BuildContext context,
    SanbaoColorScheme colors,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Стартовые промпты',
            style: context.textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          StarterPrompts(
            prompts: agent.starterPrompts,
            onPromptTap: (prompt) => _startChatWithPrompt(context, prompt),
          ),
        ],
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
                agent.instructions.length > 500
                    ? '${agent.instructions.substring(0, 500)}...'
                    : agent.instructions,
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

  void _startChat(BuildContext context) {
    // Navigate to chat with this agent selected
    context.go('${RoutePaths.chat}?agentId=${agent.id}');
  }

  void _startChatWithPrompt(BuildContext context, String prompt) {
    context.go(
      '${RoutePaths.chat}?agentId=${agent.id}&prompt=${Uri.encodeComponent(prompt)}',
    );
  }
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

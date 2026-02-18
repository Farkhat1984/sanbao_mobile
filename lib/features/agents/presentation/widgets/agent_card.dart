/// Agent card widget for the agents list grid.
///
/// Displays the agent's icon, name, description, and tool/skill
/// count badges. Supports tap to navigate to the detail screen.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/features/agents/domain/entities/agent.dart';
import 'package:sanbao_flutter/features/agents/presentation/widgets/agent_icon.dart';

/// A card displaying an agent's summary information.
///
/// Used in the agent list grid. Shows the icon, name, description
/// preview, and badges for tools/skills count.
class AgentCard extends StatefulWidget {
  const AgentCard({
    required this.agent,
    required this.onTap,
    super.key,
  });

  /// The agent to display.
  final Agent agent;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  @override
  State<AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<AgentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationFast,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: SanbaoAnimations.buttonPressScale,
    ).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final agent = widget.agent;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: SanbaoRadius.lg,
            border: Border.all(color: colors.border, width: 0.5),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(agent, colors),
              const SizedBox(height: 12),
              _buildName(agent, colors),
              if (agent.description != null &&
                  agent.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildDescription(agent, colors),
              ],
              const Spacer(),
              _buildBadges(agent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Agent agent, SanbaoColorScheme colors) => Row(
        children: [
          AgentIcon(
            icon: agent.icon,
            color: agent.iconColor,
            size: AgentIconSize.lg,
          ),
          const Spacer(),
          if (agent.isSystem)
            SanbaoBadge(
              label: 'Системный',
              variant: SanbaoBadgeVariant.neutral,
              size: SanbaoBadgeSize.small,
            ),
        ],
      );

  Widget _buildName(Agent agent, SanbaoColorScheme colors) => Text(
        agent.name,
        style: context.textTheme.titleSmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildDescription(Agent agent, SanbaoColorScheme colors) => Text(
        agent.description!,
        style: context.textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildBadges(Agent agent) => Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (agent.tools.isNotEmpty)
            SanbaoBadge(
              label: '${agent.tools.length} инстр.',
              variant: SanbaoBadgeVariant.accent,
              icon: Icons.build_outlined,
              size: SanbaoBadgeSize.small,
            ),
          if (agent.skills.isNotEmpty)
            SanbaoBadge(
              label: '${agent.skills.length} скилл.',
              variant: SanbaoBadgeVariant.legal,
              icon: Icons.psychology_outlined,
              size: SanbaoBadgeSize.small,
            ),
        ],
      );
}

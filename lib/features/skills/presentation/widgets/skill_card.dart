/// Skill card widget for the skills list grid.
///
/// Displays the skill's icon, name, description, jurisdiction
/// badge, and clone count. Supports tap to navigate to detail.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/features/agents/presentation/widgets/agent_icon.dart';
import 'package:sanbao_flutter/features/skills/domain/entities/skill.dart';

/// A card displaying a skill's summary information.
///
/// Used in both the personal skills list and marketplace grid.
/// Shows the icon, name, description, jurisdiction badge, and
/// clone count for public skills.
class SkillCard extends StatefulWidget {
  const SkillCard({
    required this.skill,
    required this.onTap,
    super.key,
    this.showCloneCount = false,
    this.onClone,
  });

  /// The skill to display.
  final Skill skill;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Whether to show the clone count (for marketplace view).
  final bool showCloneCount;

  /// Callback when the clone button is tapped (marketplace only).
  final VoidCallback? onClone;

  @override
  State<SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<SkillCard>
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
    final skill = widget.skill;

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
              _buildHeader(skill, colors),
              const SizedBox(height: 12),
              _buildName(skill, colors),
              if (skill.description != null &&
                  skill.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildDescription(skill, colors),
              ],
              const Spacer(),
              _buildFooter(skill, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Skill skill, SanbaoColorScheme colors) => Row(
        children: [
          AgentIcon(
            icon: skill.icon,
            color: skill.iconColor,
            size: AgentIconSize.lg,
          ),
          const Spacer(),
          if (skill.isBuiltIn)
            const SanbaoBadge(
              label: 'Встроенный',
              variant: SanbaoBadgeVariant.neutral,
              size: SanbaoBadgeSize.small,
            ),
          if (!skill.isBuiltIn && skill.isPublic)
            const SanbaoBadge(
              label: 'Публичный',
              size: SanbaoBadgeSize.small,
            ),
        ],
      );

  Widget _buildName(Skill skill, SanbaoColorScheme colors) => Text(
        skill.name,
        style: context.textTheme.titleSmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildDescription(Skill skill, SanbaoColorScheme colors) => Text(
        skill.description!,
        style: context.textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

  Widget _buildFooter(Skill skill, SanbaoColorScheme colors) => Row(
        children: [
          if (skill.isLegal && skill.jurisdictionLabel != null)
            SanbaoBadge(
              label: skill.jurisdictionLabel!,
              variant: SanbaoBadgeVariant.legal,
              icon: Icons.gavel_outlined,
              size: SanbaoBadgeSize.small,
            ),
          const Spacer(),
          if (widget.onClone != null)
            GestureDetector(
              onTap: () {
                // Stop event from propagating to parent onTap
                widget.onClone!();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.copy_outlined,
                  size: 16,
                  color: colors.accent,
                ),
              ),
            )
          else if (widget.showCloneCount && skill.cloneCount > 0) ...[
            Icon(
              Icons.copy_outlined,
              size: 12,
              color: colors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              '${skill.cloneCount}',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      );
}

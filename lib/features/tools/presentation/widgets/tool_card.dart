/// Tool card widget for the tools list.
///
/// Displays the tool type icon, name, description, and an
/// enabled toggle switch.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/features/tools/domain/entities/tool.dart';

/// A card displaying a tool's summary information.
///
/// Shows the tool type icon, name, description preview,
/// and a toggle switch to enable/disable.
class ToolCard extends StatefulWidget {
  const ToolCard({
    required this.tool,
    required this.onTap,
    super.key,
    this.onToggleEnabled,
  });

  /// The tool to display.
  final Tool tool;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  /// Callback when the enabled toggle is changed.
  final VoidCallback? onToggleEnabled;

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard>
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
    final tool = widget.tool;

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
        child: AnimatedOpacity(
          opacity: tool.isEnabled ? 1.0 : 0.6,
          duration: SanbaoAnimations.durationFast,
          child: Container(
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: SanbaoRadius.lg,
              border: Border.all(color: colors.border, width: 0.5),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildIcon(tool, colors),
                const SizedBox(width: 12),
                Expanded(child: _buildContent(tool, colors)),
                if (widget.onToggleEnabled != null)
                  Switch.adaptive(
                    value: tool.isEnabled,
                    onChanged: (_) => widget.onToggleEnabled?.call(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Tool tool, SanbaoColorScheme colors) {
    final iconData = _iconForType(tool.type);
    final iconColor = _colorForType(tool.type, colors);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: SanbaoRadius.md,
      ),
      child: Icon(iconData, color: iconColor, size: 22),
    );
  }

  Widget _buildContent(Tool tool, SanbaoColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tool.name,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SanbaoBadge(
                label: tool.typeLabel,
                variant: SanbaoBadgeVariant.neutral,
                size: SanbaoBadgeSize.small,
              ),
            ],
          ),
          if (tool.description != null && tool.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              tool.description!,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );

  static IconData _iconForType(ToolType type) => switch (type) {
        ToolType.promptTemplate => Icons.description_outlined,
        ToolType.webhook => Icons.webhook_outlined,
        ToolType.url => Icons.link_outlined,
        ToolType.function_ => Icons.code_outlined,
      };

  static Color _colorForType(ToolType type, SanbaoColorScheme colors) =>
      switch (type) {
        ToolType.promptTemplate => colors.accent,
        ToolType.webhook => colors.success,
        ToolType.url => colors.info,
        ToolType.function_ => colors.legalRef,
      };
}

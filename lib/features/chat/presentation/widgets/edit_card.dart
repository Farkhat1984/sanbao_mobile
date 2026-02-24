/// Inline card displayed when an artifact edit has been applied.
///
/// Shows a green-themed card with pencil icon, target artifact title,
/// and the number of changes applied. Tapping opens the edited artifact.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/chat/data/models/chat_event_model.dart';

/// A card that shows an applied edit operation within a message bubble.
class EditCard extends StatefulWidget {
  const EditCard({
    required this.edit,
    super.key,
    this.onTap,
  });

  /// The edit operation that was applied.
  final ArtifactEdit edit;

  /// Callback when the card is tapped (opens the edited artifact).
  final VoidCallback? onTap;

  @override
  State<EditCard> createState() => _EditCardState();
}

class _EditCardState extends State<EditCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationNormal,
    )..forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    const editColor = Color(0xFF10B981); // emerald-500

    final editCount = widget.edit.editCount;
    final label = switch (editCount) {
      1 => '1 изменение',
      _ when editCount < 5 => '$editCount изменения',
      _ => '$editCount изменений',
    };

    return FadeTransition(
      opacity: _enterController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _enterController,
          curve: SanbaoAnimations.smoothCurve,
        ),),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: editColor.withValues(alpha: 0.06),
              borderRadius: SanbaoRadius.md,
              border: Border.all(
                color: editColor.withValues(alpha: 0.25),
                width: 0.5,
              ),
              boxShadow: SanbaoShadows.sm,
            ),
            child: Row(
              children: [
                // Pencil icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: editColor.withValues(alpha: 0.12),
                    borderRadius: SanbaoRadius.sm,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 20,
                    color: editColor,
                  ),
                ),

                const SizedBox(width: 12),

                // Title and edit count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.edit.target,
                        style: context.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: editColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Open button
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

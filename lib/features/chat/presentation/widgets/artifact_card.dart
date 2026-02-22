/// Inline artifact preview card displayed within messages.
///
/// Shows the artifact type, title, and a preview with an
/// "Open" button to view the full content.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/artifact.dart';

/// A card that previews an artifact within a message bubble.
///
/// Displays the artifact type icon, title, content preview,
/// and an action button to open the full artifact viewer.
class ArtifactCard extends StatefulWidget {
  const ArtifactCard({
    required this.artifact,
    super.key,
    this.onOpen,
  });

  /// The artifact to preview.
  final Artifact artifact;

  /// Callback when the "Open" button is tapped.
  final VoidCallback? onOpen;

  @override
  State<ArtifactCard> createState() => _ArtifactCardState();
}

class _ArtifactCardState extends State<ArtifactCard>
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

  IconData _typeIcon() => switch (widget.artifact.type) {
        ArtifactType.document => Icons.description_rounded,
        ArtifactType.code => Icons.code_rounded,
        ArtifactType.analysis => Icons.analytics_rounded,
        ArtifactType.image => Icons.image_rounded,
      };

  Color _typeColor() => switch (widget.artifact.type) {
        ArtifactType.document => SanbaoColors.accent,
        ArtifactType.code => const Color(0xFF22C55E),
        ArtifactType.analysis => SanbaoColors.legalRef,
        ArtifactType.image => const Color(0xFFF59E0B),
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final typeColor = _typeColor();

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
          onTap: widget.onOpen,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: SanbaoRadius.md,
              border: Border.all(
                color: typeColor.withValues(alpha: 0.3),
                width: 0.5,
              ),
              boxShadow: SanbaoShadows.sm,
            ),
            child: Row(
              children: [
                // Type icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: SanbaoRadius.sm,
                  ),
                  child: Icon(
                    _typeIcon(),
                    size: 20,
                    color: typeColor,
                  ),
                ),

                const SizedBox(width: 12),

                // Title and type label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.artifact.title,
                        style: context.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.artifact.type.label,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Open button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: SanbaoRadius.sm,
                  ),
                  child: Text(
                    'Открыть',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

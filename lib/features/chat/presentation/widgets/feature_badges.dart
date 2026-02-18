/// Feature toggle badges shown above the message input.
///
/// Displays a horizontal row of tappable pills for toggling
/// AI features like Thinking, Web Search, and Planning.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/chat/presentation/providers/chat_provider.dart';

/// A row of toggleable feature pills shown above the message input.
///
/// Each badge represents an AI feature that can be enabled or disabled
/// by tapping. Active badges use the accent color; inactive use neutral.
class FeatureBadges extends ConsumerWidget {
  const FeatureBadges({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thinkingEnabled = ref.watch(thinkingEnabledProvider);
    final webSearchEnabled = ref.watch(webSearchEnabledProvider);
    final planningEnabled = ref.watch(planningEnabledProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FeatureBadge(
            icon: Icons.psychology_rounded,
            label: 'Думать',
            isActive: thinkingEnabled,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(thinkingEnabledProvider.notifier).state =
                  !thinkingEnabled;
            },
          ),
          const SizedBox(width: 8),
          _FeatureBadge(
            icon: Icons.travel_explore_rounded,
            label: 'Веб-поиск',
            isActive: webSearchEnabled,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(webSearchEnabledProvider.notifier).state =
                  !webSearchEnabled;
            },
          ),
          const SizedBox(width: 8),
          _FeatureBadge(
            icon: Icons.account_tree_rounded,
            label: 'План',
            isActive: planningEnabled,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(planningEnabledProvider.notifier).state =
                  !planningEnabled;
            },
          ),
        ],
      ),
    );
  }
}

/// A single toggleable feature badge.
class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    final bgColor = isActive
        ? colors.accentLight
        : colors.bgSurfaceAlt;

    final fgColor = isActive
        ? colors.accent
        : colors.textMuted;

    final borderColor = isActive
        ? colors.accent.withValues(alpha: 0.25)
        : colors.border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: SanbaoAnimations.durationFast,
        curve: SanbaoAnimations.smoothCurve,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: SanbaoRadius.full,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: SanbaoAnimations.durationFast,
              child: Icon(
                icon,
                key: ValueKey('$label-$isActive'),
                size: 14,
                color: fgColor,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: SanbaoAnimations.durationFast,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: fgColor,
                height: 1.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

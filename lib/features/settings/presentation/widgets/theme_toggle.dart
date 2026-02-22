/// Segmented control for selecting the theme mode.
///
/// Provides three options: System, Light, and Dark with
/// a sliding indicator following the selected segment.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Theme mode option with label and icon.
class _ThemeOption {
  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.icon,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
}

const _options = [
  _ThemeOption(
    mode: ThemeMode.system,
    label: 'Система',
    icon: Icons.phone_android_rounded,
  ),
  _ThemeOption(
    mode: ThemeMode.light,
    label: 'Светлая',
    icon: Icons.light_mode_outlined,
  ),
  _ThemeOption(
    mode: ThemeMode.dark,
    label: 'Тёмная',
    icon: Icons.dark_mode_outlined,
  ),
];

/// A segmented control for choosing between System, Light, and Dark themes.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({
    required this.currentMode,
    required this.onModeChanged,
    super.key,
  });

  /// The currently selected theme mode.
  final ThemeMode currentMode;

  /// Called when the user selects a new theme mode.
  final ValueChanged<ThemeMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final selectedIndex = _options.indexWhere((o) => o.mode == currentMode);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.bgSurfaceAlt,
        borderRadius: SanbaoRadius.md,
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / _options.length;

          return Stack(
            children: [
              // Sliding indicator
              AnimatedPositioned(
                duration: SanbaoAnimations.durationNormal,
                curve: SanbaoAnimations.smoothCurve,
                left: selectedIndex * segmentWidth + 3,
                top: 3,
                width: segmentWidth - 6,
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: SanbaoRadius.sm,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A1A2138),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              // Segments
              Row(
                children: _options.map((option) {
                  final isSelected = option.mode == currentMode;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onModeChanged(option.mode),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              option.icon,
                              size: 16,
                              color: isSelected
                                  ? colors.accent
                                  : colors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              option.label,
                              style: context.textTheme.labelMedium?.copyWith(
                                color: isSelected
                                    ? colors.accent
                                    : colors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

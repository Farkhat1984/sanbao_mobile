/// Reusable horizontal option selector for image generation parameters.
///
/// Used for selecting style (vivid/natural) and size (square/landscape/portrait).
/// Renders as a row of tappable pills following the Sanbao design system.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// A single selectable option item.
class OptionItem<T> {
  const OptionItem({
    required this.value,
    required this.label,
    this.icon,
  });

  /// The underlying value.
  final T value;

  /// Display label.
  final String label;

  /// Optional leading icon.
  final IconData? icon;
}

/// A horizontal row of selectable pill-shaped options.
///
/// Exactly one option is always selected. Tapping an option
/// triggers [onChanged] with the new value.
class ImageGenOptionSelector<T> extends StatelessWidget {
  const ImageGenOptionSelector({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    super.key,
  });

  /// Section label shown above the options.
  final String label;

  /// Available options.
  final List<OptionItem<T>> options;

  /// Currently selected value.
  final T selectedValue;

  /// Callback when a different option is selected.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option.value == selectedValue;

            return GestureDetector(
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  onChanged(option.value);
                }
              },
              child: AnimatedContainer(
                duration: SanbaoAnimations.durationFast,
                curve: SanbaoAnimations.smoothCurve,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accentLight
                      : colors.bgSurfaceAlt,
                  borderRadius: SanbaoRadius.sm,
                  border: Border.all(
                    color: isSelected
                        ? colors.accent.withValues(alpha: 0.3)
                        : colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (option.icon != null) ...[
                      Icon(
                        option.icon,
                        size: 14,
                        color: isSelected
                            ? colors.accent
                            : colors.textMuted,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? colors.accent
                            : colors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

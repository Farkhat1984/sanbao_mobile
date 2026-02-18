/// Language dropdown selector widget.
///
/// Provides a choice between Русский (ru) and English (en).
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Supported locale option.
class LocaleOption {
  const LocaleOption({
    required this.code,
    required this.label,
    required this.flag,
  });

  /// Locale code (e.g., "ru", "en").
  final String code;

  /// Display label.
  final String label;

  /// Flag emoji for visual identification.
  final String flag;
}

/// Available locale options.
const _localeOptions = [
  LocaleOption(code: 'ru', label: 'Русский', flag: '🇷🇺'),
  LocaleOption(code: 'en', label: 'English', flag: '🇬🇧'),
];

/// A dropdown selector for choosing the app language.
class LocaleSelector extends StatelessWidget {
  const LocaleSelector({
    required this.currentLocale,
    required this.onLocaleChanged,
    super.key,
    this.label,
  });

  /// The currently selected locale code.
  final String currentLocale;

  /// Called when the user selects a new locale.
  final ValueChanged<String> onLocaleChanged;

  /// Optional label above the dropdown.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: context.textTheme.labelLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: colors.bgSurfaceAlt,
            borderRadius: SanbaoRadius.md,
            border: Border.all(color: colors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentLocale,
              isExpanded: true,
              borderRadius: SanbaoRadius.md,
              dropdownColor: colors.bgSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.textMuted,
              ),
              items: _localeOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option.code,
                  child: Row(
                    children: [
                      Text(
                        option.flag,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        option.label,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onLocaleChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

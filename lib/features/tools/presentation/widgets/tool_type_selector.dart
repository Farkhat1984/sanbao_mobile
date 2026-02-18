/// Tool type selector widget with 4 type options.
///
/// Displays the four tool types as selectable cards with icons
/// and descriptions in Russian.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/features/tools/domain/entities/tool.dart';

/// A selector for choosing a tool type.
///
/// Shows four options as cards with icons and descriptions.
/// Used in the tool creation/edit form.
class ToolTypeSelector extends StatelessWidget {
  const ToolTypeSelector({
    required this.selectedType,
    required this.onTypeSelected,
    super.key,
  });

  /// The currently selected tool type.
  final ToolType selectedType;

  /// Callback when a type is selected.
  final ValueChanged<ToolType> onTypeSelected;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Тип инструмента',
            style: context.textTheme.labelLarge?.copyWith(
              color: context.sanbaoColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...ToolType.values.map(
            (type) => _ToolTypeOption(
              type: type,
              isSelected: type == selectedType,
              onTap: () => onTypeSelected(type),
            ),
          ),
        ],
      );
}

class _ToolTypeOption extends StatelessWidget {
  const _ToolTypeOption({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final ToolType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentLight : colors.bgSurface,
            borderRadius: SanbaoRadius.md,
            border: Border.all(
              color: isSelected ? colors.accent : colors.border,
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accent.withValues(alpha: 0.15)
                      : colors.bgSurfaceAlt,
                  borderRadius: SanbaoRadius.sm,
                ),
                child: Icon(
                  _iconForType(type),
                  size: 20,
                  color: isSelected ? colors.accent : colors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labelForType(type),
                      style: context.textTheme.titleSmall?.copyWith(
                        color: isSelected
                            ? colors.accent
                            : colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _descriptionForType(type),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colors.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForType(ToolType type) => switch (type) {
        ToolType.promptTemplate => Icons.description_outlined,
        ToolType.webhook => Icons.webhook_outlined,
        ToolType.url => Icons.link_outlined,
        ToolType.function_ => Icons.code_outlined,
      };

  static String _labelForType(ToolType type) => switch (type) {
        ToolType.promptTemplate => 'Шаблон промпта',
        ToolType.webhook => 'Вебхук',
        ToolType.url => 'URL',
        ToolType.function_ => 'Функция',
      };

  static String _descriptionForType(ToolType type) => switch (type) {
        ToolType.promptTemplate =>
          'Структурированный шаблон для генерации промптов',
        ToolType.webhook =>
          'Вызов внешнего HTTP-эндпоинта при активации',
        ToolType.url => 'Получение содержимого по веб-адресу',
        ToolType.function_ =>
          'Выполнение пользовательской логики',
      };
}

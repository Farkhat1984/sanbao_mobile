/// Memory form widget shown as a bottom sheet.
///
/// Provides a content text field and category dropdown for
/// creating or editing memories.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_input.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/features/memory/domain/entities/memory.dart';

/// Result of the memory form submission.
class MemoryFormResult {
  const MemoryFormResult({
    required this.content,
    this.category,
  });

  final String content;
  final String? category;
}

/// Shows a bottom sheet with the memory form.
///
/// Returns a [MemoryFormResult] if submitted, or null if dismissed.
Future<MemoryFormResult?> showMemoryForm({
  required BuildContext context,
  Memory? existingMemory,
}) =>
    showSanbaoBottomSheet<MemoryFormResult>(
      context: context,
      builder: (context) => _MemoryFormContent(
        existingMemory: existingMemory,
      ),
    );

class _MemoryFormContent extends StatefulWidget {
  const _MemoryFormContent({this.existingMemory});

  final Memory? existingMemory;

  @override
  State<_MemoryFormContent> createState() => _MemoryFormContentState();
}

class _MemoryFormContentState extends State<_MemoryFormContent> {
  late final TextEditingController _contentController;
  String? _selectedCategory;

  bool get _isEditing => widget.existingMemory != null;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.existingMemory?.content ?? '',
    );
    _selectedCategory = widget.existingMemory?.category;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    Navigator.of(context).pop(
      MemoryFormResult(
        content: content,
        category: _selectedCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SanbaoBottomSheetContent(
      title: _isEditing ? 'Редактировать память' : 'Новая запись',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          SanbaoInput(
            controller: _contentController,
            hint: 'Что нужно запомнить...',
            maxLines: 5,
            minLines: 3,
            autofocus: true,
            textInputAction: TextInputAction.newline,
          ),

          const SizedBox(height: 16),

          // Category dropdown
          Text(
            'Категория',
            style: context.textTheme.labelLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: colors.bgSurfaceAlt,
              borderRadius: SanbaoRadius.md,
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedCategory,
                isExpanded: true,
                hint: Text(
                  'Выберите категорию',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
                icon: Icon(
                  Icons.expand_more,
                  color: colors.textMuted,
                ),
                dropdownColor: colors.bgSurface,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                ),
                items: [
                  DropdownMenuItem<String?>(
                    child: Text(
                      'Без категории',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                  ...MemoryCategory.labels.entries.map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Submit
          SanbaoButton(
            label: _isEditing ? 'Сохранить' : 'Добавить',
            onPressed: _submit,
            isExpanded: true,
            leadingIcon: _isEditing ? Icons.save_outlined : Icons.add,
          ),
        ],
      ),
    );
  }
}

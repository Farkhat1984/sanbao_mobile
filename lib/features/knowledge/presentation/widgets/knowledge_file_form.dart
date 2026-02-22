/// Form dialog for creating and editing knowledge files.
///
/// Shows a bottom sheet with name, description, and content fields.
/// Returns [KnowledgeFileFormResult] on save.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/features/knowledge/domain/entities/knowledge_file.dart';

/// Maximum allowed lengths matching the web API validation.
const int _maxNameLength = 100;
const int _maxDescriptionLength = 500;
const int _maxContentLength = 100000; // 100KB

/// Result from the knowledge file form.
class KnowledgeFileFormResult {
  const KnowledgeFileFormResult({
    required this.name,
    required this.content,
    this.description,
  });

  /// File name.
  final String name;

  /// File content.
  final String content;

  /// Optional description.
  final String? description;
}

/// Shows a bottom sheet form for creating or editing a knowledge file.
///
/// Returns a [KnowledgeFileFormResult] when the user saves, or null
/// if they dismiss the form.
Future<KnowledgeFileFormResult?> showKnowledgeFileForm({
  required BuildContext context,
  KnowledgeFile? existingFile,
}) =>
    showModalBottomSheet<KnowledgeFileFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _KnowledgeFileFormSheet(
        existingFile: existingFile,
      ),
    );

/// The form sheet widget.
class _KnowledgeFileFormSheet extends StatefulWidget {
  const _KnowledgeFileFormSheet({this.existingFile});

  final KnowledgeFile? existingFile;

  @override
  State<_KnowledgeFileFormSheet> createState() =>
      _KnowledgeFileFormSheetState();
}

class _KnowledgeFileFormSheetState extends State<_KnowledgeFileFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.existingFile != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingFile?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingFile?.description ?? '');
    _contentController =
        TextEditingController(text: widget.existingFile?.content ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final result = KnowledgeFileFormResult(
      name: _nameController.text.trim(),
      content: _contentController.text.trim(),
      description: _descriptionController.text.trim().nullIfEmpty,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SanbaoRadius.lgValue),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Form(
            key: _formKey,
            child: Column(
              children: [
                // Drag handle
                _buildDragHandle(colors),

                // Header
                _buildHeader(colors),

                const Divider(height: 1),

                // Form fields
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildNameField(colors),
                      const SizedBox(height: 16),
                      _buildDescriptionField(colors),
                      const SizedBox(height: 16),
                      _buildContentField(colors),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Save button
                _buildActions(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(SanbaoColorScheme colors) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: colors.textMuted.withValues(alpha: 0.3),
            borderRadius: SanbaoRadius.full,
          ),
        ),
      );

  Widget _buildHeader(SanbaoColorScheme colors) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.accentLight,
                borderRadius: SanbaoRadius.sm,
              ),
              child: Icon(
                _isEditing
                    ? Icons.edit_document
                    : Icons.note_add_rounded,
                size: 18,
                color: colors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isEditing ? 'Редактировать файл' : 'Новый файл знаний',
              style: context.textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close_rounded, color: colors.textMuted),
              iconSize: 20,
            ),
          ],
        ),
      );

  Widget _buildNameField(SanbaoColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel(label: 'Название', isRequired: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            maxLength: _maxNameLength,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              colors,
              hintText: 'Введите название файла',
            ),
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Название обязательно';
              }
              if (value.length > _maxNameLength) {
                return 'Максимум $_maxNameLength символов';
              }
              return null;
            },
          ),
        ],
      );

  Widget _buildDescriptionField(SanbaoColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel(label: 'Описание'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLength: _maxDescriptionLength,
            maxLines: 3,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              colors,
              hintText: 'Краткое описание содержимого файла',
            ),
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
            ),
            validator: (value) {
              if (value != null && value.length > _maxDescriptionLength) {
                return 'Максимум $_maxDescriptionLength символов';
              }
              return null;
            },
          ),
        ],
      );

  Widget _buildContentField(SanbaoColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _FieldLabel(label: 'Содержимое', isRequired: true),
              const Spacer(),
              Text(
                'Markdown поддерживается',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contentController,
            maxLines: 12,
            minLines: 6,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            decoration: _inputDecoration(
              colors,
              hintText: 'Вставьте текст файла...',
            ),
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontFamily: 'JetBrains Mono',
              fontSize: 13,
              height: 1.5,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Содержимое обязательно';
              }
              if (value.length > _maxContentLength) {
                return 'Файл слишком большой (макс. 100 KB)';
              }
              return null;
            },
          ),
        ],
      );

  Widget _buildActions(SanbaoColorScheme colors) => Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12 + context.bottomPadding,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: SanbaoButton(
                label: 'Отмена',
                variant: SanbaoButtonVariant.secondary,
                isExpanded: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SanbaoButton(
                label: _isEditing ? 'Сохранить' : 'Создать',
                isExpanded: true,
                leadingIcon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                onPressed: _save,
              ),
            ),
          ],
        ),
      );

  InputDecoration _inputDecoration(
    SanbaoColorScheme colors, {
    required String hintText,
  }) =>
      InputDecoration(
        hintText: hintText,
        hintStyle: context.textTheme.bodySmall?.copyWith(
          color: colors.textMuted,
        ),
        filled: true,
        fillColor: colors.bgSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: SanbaoRadius.md,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.md,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.md,
          borderSide: BorderSide(color: colors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.md,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.md,
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        counterStyle: context.textTheme.bodySmall?.copyWith(
          color: colors.textMuted,
          fontSize: 11,
        ),
      );
}

/// Styled field label with optional required indicator.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: colors.error,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet for selecting and filling document templates.
///
/// Templates are attached to agent tools and contain fields
/// that users fill in. The filled template generates a prompt
/// that is auto-sent to the chat.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';

/// A field definition within a document template.
class TemplateField {
  const TemplateField({
    required this.id,
    required this.label,
    this.placeholder,
    this.type = 'text',
    this.options,
    this.required = false,
  });

  factory TemplateField.fromJson(Map<String, dynamic> json) => TemplateField(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      placeholder: json['placeholder'] as String?,
      type: json['type'] as String? ?? 'text',
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      required: json['required'] as bool? ?? false,
    );

  final String id;
  final String label;
  final String? placeholder;
  final String type; // text, date, number, textarea, select
  final List<String>? options;
  final bool required;
}

/// A document template definition.
class DocumentTemplate {
  const DocumentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.fields,
    required this.promptTemplate,
  });

  factory DocumentTemplate.fromJson(Map<String, dynamic> json) => DocumentTemplate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) => TemplateField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      promptTemplate: json['promptTemplate'] as String? ?? '',
    );

  final String id;
  final String name;
  final String description;
  final List<TemplateField> fields;
  final String promptTemplate;

  /// Fills the prompt template with provided values.
  String fillTemplate(Map<String, String> values) {
    var result = promptTemplate;
    for (final entry in values.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }
}

/// Shows the template bottom sheet for filling a document template.
///
/// Returns the filled prompt text if submitted, or `null` if dismissed.
Future<String?> showTemplateSheet(
  BuildContext context,
  DocumentTemplate template,
) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TemplateSheet(template: template),
  );

/// Shows a template list selector bottom sheet.
///
/// Returns the selected template's filled prompt, or `null`.
Future<String?> showTemplateListSheet(
  BuildContext context,
  List<DocumentTemplate> templates,
) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _TemplateListSheet(templates: templates),
  );

// ---- Template List Sheet ----

class _TemplateListSheet extends StatelessWidget {
  const _TemplateListSheet({required this.templates});

  final List<DocumentTemplate> templates;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: colors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Шаблоны документов',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Template list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final template = templates[index];
                return _TemplateListItem(
                  template: template,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final result = await showTemplateSheet(context, template);
                    if (result != null && context.mounted) {
                      Navigator.of(context).pop(result);
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TemplateListItem extends StatelessWidget {
  const _TemplateListItem({
    required this.template,
    required this.onTap,
  });

  final DocumentTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Material(
      color: colors.bgSurfaceAlt,
      borderRadius: SanbaoRadius.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: SanbaoRadius.md,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                Icons.article_outlined,
                color: colors.accent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (template.description.isNotEmpty)
                      Text(
                        template.description,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Template Form Sheet ----

class _TemplateSheet extends StatefulWidget {
  const _TemplateSheet({required this.template});

  final DocumentTemplate template;

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  final _values = <String, String>{};
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final field in widget.template.fields) {
      _controllers[field.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isValid {
    for (final field in widget.template.fields) {
      if (field.required && (_values[field.id] ?? '').trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  void _submit() {
    if (!_isValid) return;
    HapticFeedback.lightImpact();
    final filledPrompt = widget.template.fillTemplate(_values);
    Navigator.of(context).pop(filledPrompt);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.template.name,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.template.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.template.description,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Form fields
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.template.fields.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (ctx, index) =>
                  _buildField(ctx, widget.template.fields[index]),
            ),
          ),

          // Submit button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SanbaoButton(
              label: 'Создать документ',
              onPressed: _isValid ? _submit : null,
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, TemplateField field) {
    final colors = context.sanbaoColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              field.label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (field.required)
              Text(
                ' *',
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Input based on type
        if (field.type == 'select' && field.options != null)
          _buildSelectField(field)
        else if (field.type == 'textarea')
          _buildTextAreaField(field)
        else
          _buildTextField(field),
      ],
    );
  }

  Widget _buildTextField(TemplateField field) {
    final colors = context.sanbaoColors;

    return TextField(
      controller: _controllers[field.id],
      keyboardType: field.type == 'number'
          ? TextInputType.number
          : field.type == 'date'
              ? TextInputType.datetime
              : TextInputType.text,
      onChanged: (v) => setState(() => _values[field.id] = v),
      style: context.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: field.placeholder ?? 'Введите ${field.label.toLowerCase()}',
        hintStyle: context.textTheme.bodyMedium?.copyWith(
          color: colors.textMuted,
        ),
        filled: true,
        fillColor: colors.bgSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: SanbaoRadius.sm,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.sm,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.sm,
          borderSide: BorderSide(color: colors.accent),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildTextAreaField(TemplateField field) {
    final colors = context.sanbaoColors;

    return TextField(
      controller: _controllers[field.id],
      maxLines: 3,
      onChanged: (v) => setState(() => _values[field.id] = v),
      style: context.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: field.placeholder ?? 'Введите текст...',
        hintStyle: context.textTheme.bodyMedium?.copyWith(
          color: colors.textMuted,
        ),
        filled: true,
        fillColor: colors.bgSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: SanbaoRadius.sm,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.sm,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.sm,
          borderSide: BorderSide(color: colors.accent),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildSelectField(TemplateField field) {
    final colors = context.sanbaoColors;
    final current = _values[field.id] ?? '';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: field.options!.map((option) {
        final isSelected = current == option;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _values[field.id] = option);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colors.accent : colors.bgSurfaceAlt,
              borderRadius: SanbaoRadius.sm,
              border: Border.all(
                color: isSelected ? colors.accent : colors.border,
              ),
            ),
            child: Text(
              option,
              style: context.textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

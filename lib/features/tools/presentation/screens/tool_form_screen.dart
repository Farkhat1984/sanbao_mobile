/// Tool create/edit form screen.
///
/// Provides type-specific configuration fields based on the
/// selected tool type.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_input.dart';
import 'package:sanbao_flutter/features/tools/domain/entities/tool.dart';
import 'package:sanbao_flutter/features/tools/presentation/providers/tools_provider.dart';
import 'package:sanbao_flutter/features/tools/presentation/widgets/tool_type_selector.dart';

/// Screen for creating or editing a custom tool.
///
/// Shows common fields (name, description) and type-specific
/// configuration fields that change based on the selected tool type.
class ToolFormScreen extends ConsumerStatefulWidget {
  const ToolFormScreen({super.key, this.tool});

  /// If provided, edits this existing tool. Otherwise creates a new one.
  final Tool? tool;

  @override
  ConsumerState<ToolFormScreen> createState() => _ToolFormScreenState();
}

class _ToolFormScreenState extends ConsumerState<ToolFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  // Type-specific config controllers
  late final TextEditingController _templateController;
  late final TextEditingController _webhookUrlController;
  late final TextEditingController _urlController;
  late final TextEditingController _functionBodyController;

  bool get _isEditing => widget.tool != null;

  @override
  void initState() {
    super.initState();
    final tool = widget.tool;
    _nameController = TextEditingController(text: tool?.name ?? '');
    _descriptionController =
        TextEditingController(text: tool?.description ?? '');

    final config = tool?.config ?? {};
    _templateController =
        TextEditingController(text: config['template'] as String? ?? '');
    _webhookUrlController =
        TextEditingController(text: config['webhookUrl'] as String? ?? '');
    _urlController =
        TextEditingController(text: config['url'] as String? ?? '');
    _functionBodyController =
        TextEditingController(text: config['body'] as String? ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(toolFormProvider.notifier).initialize(tool: widget.tool);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _templateController.dispose();
    _webhookUrlController.dispose();
    _urlController.dispose();
    _functionBodyController.dispose();
    super.dispose();
  }

  Map<String, Object?> _buildConfig(ToolType type) => switch (type) {
        ToolType.promptTemplate => {
            'template': _templateController.text.trim(),
          },
        ToolType.webhook => {
            'webhookUrl': _webhookUrlController.text.trim(),
          },
        ToolType.url => {
            'url': _urlController.text.trim(),
          },
        ToolType.function_ => {
            'body': _functionBodyController.text.trim(),
          },
      };

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref.read(toolFormSubmittingProvider.notifier).state = true;
    final formData = ref.read(toolFormProvider);

    try {
      final notifier = ref.read(toolsListProvider.notifier);
      final config = _buildConfig(formData.type);

      if (_isEditing) {
        await notifier.updateTool(
          id: widget.tool!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().nullIfEmpty,
          type: formData.type,
          config: config,
        );
        if (mounted) context.showSuccessSnackBar('Инструмент обновлен');
      } else {
        await notifier.createTool(
          name: _nameController.text.trim(),
          type: formData.type,
          description: _descriptionController.text.trim().nullIfEmpty,
          config: config,
        );
        if (mounted) context.showSuccessSnackBar('Инструмент создан');
      }

      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) context.showErrorSnackBar('Ошибка: $e');
    } finally {
      ref.read(toolFormSubmittingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(toolFormSubmittingProvider);
    final formData = ref.watch(toolFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Редактировать инструмент' : 'Новый инструмент',
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            SanbaoInput(
              controller: _nameController,
              label: 'Название',
              hint: 'Мой инструмент',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
              onChanged: (v) =>
                  ref.read(toolFormProvider.notifier).updateName(v),
            ),

            const SizedBox(height: 16),

            // Description
            SanbaoInput(
              controller: _descriptionController,
              label: 'Описание (необязательно)',
              hint: 'Краткое описание инструмента',
              maxLines: 3,
              textInputAction: TextInputAction.next,
              onChanged: (v) =>
                  ref.read(toolFormProvider.notifier).updateDescription(v),
            ),

            const SizedBox(height: 24),

            // Type selector
            ToolTypeSelector(
              selectedType: formData.type,
              onTypeSelected: (type) =>
                  ref.read(toolFormProvider.notifier).updateType(type),
            ),

            const SizedBox(height: 24),

            // Type-specific config fields
            _buildConfigFields(formData.type),

            const SizedBox(height: 32),

            // Submit
            SanbaoButton(
              label: _isEditing ? 'Сохранить' : 'Создать',
              onPressed: isSubmitting ? null : _submit,
              isLoading: isSubmitting,
              isExpanded: true,
              leadingIcon: _isEditing ? Icons.save_outlined : Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigFields(ToolType type) => switch (type) {
        ToolType.promptTemplate => SanbaoInput(
            controller: _templateController,
            label: 'Шаблон промпта',
            hint:
                'Используй {{переменная}} для подстановок...',
            maxLines: 8,
            minLines: 4,
          ),
        ToolType.webhook => SanbaoInput(
            controller: _webhookUrlController,
            label: 'URL вебхука',
            hint: 'https://api.example.com/webhook',
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value != null && value.isNotEmpty && !value.isValidUrl) {
                return 'Введите корректный URL';
              }
              return null;
            },
          ),
        ToolType.url => SanbaoInput(
            controller: _urlController,
            label: 'URL ресурса',
            hint: 'https://example.com/data',
            keyboardType: TextInputType.url,
            validator: (value) {
              if (value != null && value.isNotEmpty && !value.isValidUrl) {
                return 'Введите корректный URL';
              }
              return null;
            },
          ),
        ToolType.function_ => SanbaoInput(
            controller: _functionBodyController,
            label: 'Тело функции',
            hint: '// JavaScript или JSON описание...',
            maxLines: 8,
            minLines: 4,
            keyboardType: TextInputType.multiline,
          ),
      };
}

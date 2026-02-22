/// Plugin create/edit form screen.
///
/// Provides fields for name, description, tool selection,
/// and skill selection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_badge.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_input.dart';
import 'package:sanbao_flutter/features/plugins/domain/entities/plugin.dart';
import 'package:sanbao_flutter/features/plugins/presentation/providers/plugins_provider.dart';
import 'package:sanbao_flutter/features/tools/domain/entities/tool.dart';
import 'package:sanbao_flutter/features/tools/presentation/providers/tools_provider.dart';

/// Screen for creating or editing a plugin.
///
/// Shows fields for name and description, plus multi-select
/// lists for tools and skills.
class PluginFormScreen extends ConsumerStatefulWidget {
  const PluginFormScreen({super.key, this.plugin});

  /// If provided, edits this existing plugin.
  final Plugin? plugin;

  @override
  ConsumerState<PluginFormScreen> createState() => _PluginFormScreenState();
}

class _PluginFormScreenState extends ConsumerState<PluginFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  bool get _isEditing => widget.plugin != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.plugin?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.plugin?.description ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(pluginFormProvider.notifier)
          .initialize(plugin: widget.plugin);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref.read(pluginFormSubmittingProvider.notifier).state = true;
    final formData = ref.read(pluginFormProvider);

    try {
      final notifier = ref.read(pluginsListProvider.notifier);

      if (_isEditing) {
        await notifier.updatePlugin(
          id: widget.plugin!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().nullIfEmpty,
          tools: formData.tools,
          skills: formData.skills,
        );
        if (mounted) context.showSuccessSnackBar('Плагин обновлен');
      } else {
        await notifier.createPlugin(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().nullIfEmpty,
          tools: formData.tools,
          skills: formData.skills,
        );
        if (mounted) context.showSuccessSnackBar('Плагин создан');
      }

      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) context.showErrorSnackBar('Ошибка: $e');
    } finally {
      ref.read(pluginFormSubmittingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final isSubmitting = ref.watch(pluginFormSubmittingProvider);
    final formData = ref.watch(pluginFormProvider);
    final toolsAsync = ref.watch(toolsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать плагин' : 'Новый плагин'),
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
              hint: 'Мой плагин',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
              onChanged: (v) =>
                  ref.read(pluginFormProvider.notifier).updateName(v),
            ),

            const SizedBox(height: 16),

            // Description
            SanbaoInput(
              controller: _descriptionController,
              label: 'Описание (необязательно)',
              hint: 'Описание плагина',
              maxLines: 3,
              onChanged: (v) =>
                  ref.read(pluginFormProvider.notifier).updateDescription(v),
            ),

            const SizedBox(height: 24),

            // Tools selection
            _buildSectionHeader(
              'Инструменты',
              formData.tools.length,
              colors,
            ),
            const SizedBox(height: 8),
            toolsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => Text(
                'Не удалось загрузить инструменты',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.error,
                ),
              ),
              data: (tools) => _buildToolSelector(tools, formData, colors),
            ),

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

  Widget _buildSectionHeader(
    String title,
    int count,
    SanbaoColorScheme colors,
  ) =>
      Row(
        children: [
          Text(
            title,
            style: context.textTheme.labelLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          if (count > 0)
            SanbaoBadge(
              label: '$count',
              size: SanbaoBadgeSize.small,
            ),
        ],
      );

  Widget _buildToolSelector(
    List<Tool> tools,
    PluginFormData formData,
    SanbaoColorScheme colors,
  ) {
    if (tools.isEmpty) {
      return Text(
        'Нет доступных инструментов',
        style: context.textTheme.bodySmall?.copyWith(
          color: colors.textMuted,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tools.map((tool) {
        final isSelected = formData.tools.contains(tool.id);
        return FilterChip(
          label: Text(tool.name),
          selected: isSelected,
          showCheckmark: true,
          onSelected: (selected) {
            final current = List<String>.of(formData.tools);
            if (selected) {
              current.add(tool.id);
            } else {
              current.remove(tool.id);
            }
            ref.read(pluginFormProvider.notifier).updateTools(current);
          },
          backgroundColor: colors.bgSurfaceAlt,
          selectedColor: colors.accentLight,
          labelStyle: context.textTheme.labelMedium?.copyWith(
            color: isSelected ? colors.accent : colors.textPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: SanbaoRadius.sm,
            side: BorderSide(
              color: isSelected ? colors.accent : colors.border,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Agent create/edit form screen.
///
/// Full-featured form for creating or editing an agent with:
/// name, description, icon picker, color picker, system prompt,
/// model selector, starter prompts, and skill/tool multi-select.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_card.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_input.dart';
import 'package:sanbao_flutter/features/agents/domain/entities/agent.dart';
import 'package:sanbao_flutter/features/agents/presentation/providers/agents_provider.dart';
import 'package:sanbao_flutter/features/agents/presentation/widgets/agent_icon.dart';
import 'package:sanbao_flutter/features/agents/presentation/widgets/starter_prompts.dart';
import 'package:sanbao_flutter/features/skills/presentation/widgets/skill_selector.dart';

/// Available AI model options for the agent.
const List<({String id, String label})> _modelOptions = [
  (id: 'gpt-4o', label: 'GPT-4o'),
  (id: 'gpt-4o-mini', label: 'GPT-4o Mini'),
  (id: 'claude-3-5-sonnet', label: 'Claude 3.5 Sonnet'),
  (id: 'claude-3-opus', label: 'Claude 3 Opus'),
  (id: 'moonshot-v1', label: 'Kimi K2.5'),
];

/// Screen for creating or editing an agent.
///
/// Pre-fills the form when [existingAgent] is provided (edit mode).
/// Otherwise starts with a blank form (create mode).
class AgentFormScreen extends ConsumerStatefulWidget {
  const AgentFormScreen({
    super.key,
    this.existingAgent,
  });

  /// The agent to edit. If null, creating a new agent.
  final Agent? existingAgent;

  @override
  ConsumerState<AgentFormScreen> createState() => _AgentFormScreenState();
}

class _AgentFormScreenState extends ConsumerState<AgentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();

  bool get _isEditing => widget.existingAgent != null;

  @override
  void initState() {
    super.initState();
    // Initialize form data after the first frame so the provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formNotifier = ref.read(agentFormProvider.notifier);
      formNotifier.initialize(agent: widget.existingAgent);

      final form = ref.read(agentFormProvider);
      _nameController.text = form.name;
      _descriptionController.text = form.description;
      _instructionsController.text = form.instructions;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final form = ref.read(agentFormProvider);
    if (!form.isValid) {
      context.showErrorSnackBar('Заполните обязательные поля');
      return;
    }

    ref.read(agentFormSubmittingProvider.notifier).state = true;

    try {
      if (_isEditing) {
        await ref.read(agentsListProvider.notifier).updateAgent(
              id: widget.existingAgent!.id,
              name: form.name,
              description: form.description.isEmpty ? null : form.description,
              instructions: form.instructions,
              model: form.model,
              icon: form.icon,
              iconColor: form.iconColor,
              avatar: form.avatar,
              starterPrompts: form.starterPrompts,
              skillIds: form.skillIds,
              toolIds: form.toolIds,
            );
        if (mounted) {
          context.showSuccessSnackBar('Агент обновлен');
        }
      } else {
        await ref.read(agentsListProvider.notifier).createAgent(
              name: form.name,
              description: form.description.isEmpty ? null : form.description,
              instructions: form.instructions,
              model: form.model,
              icon: form.icon,
              iconColor: form.iconColor,
              avatar: form.avatar,
              starterPrompts: form.starterPrompts,
              skillIds: form.skillIds,
              toolIds: form.toolIds,
            );
        if (mounted) {
          context.showSuccessSnackBar('Агент создан');
        }
      }

      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          'Ошибка: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        ref.read(agentFormSubmittingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final form = ref.watch(agentFormProvider);
    final isSubmitting = ref.watch(agentFormSubmittingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать агента' : 'Новый агент'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SanbaoButton(
              label: _isEditing ? 'Сохранить' : 'Создать',
              onPressed: _submit,
              isLoading: isSubmitting,
              isDisabled: !form.isValid,
              size: SanbaoButtonSize.small,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon & Color picker
              _buildIconColorPicker(colors, form),
              const SizedBox(height: 20),
              // Name
              SanbaoInput(
                controller: _nameController,
                label: 'Название',
                hint: 'Введите название агента',
                onChanged: (v) =>
                    ref.read(agentFormProvider.notifier).updateName(v),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              // Description
              SanbaoInput(
                controller: _descriptionController,
                label: 'Описание',
                hint: 'Краткое описание агента (необязательно)',
                onChanged: (v) =>
                    ref.read(agentFormProvider.notifier).updateDescription(v),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Model selector
              _buildModelSelector(colors, form),
              const SizedBox(height: 16),
              // System prompt
              SanbaoInput(
                controller: _instructionsController,
                label: 'Системный промпт',
                hint: 'Инструкции для AI модели...',
                onChanged: (v) =>
                    ref.read(agentFormProvider.notifier).updateInstructions(v),
                maxLines: 8,
                minLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 20),
              // Skills multi-select
              _buildSkillsSelector(colors, form),
              const SizedBox(height: 20),
              // Starter prompts editor
              StarterPromptsEditor(
                prompts: form.starterPrompts,
                onAdd: (p) =>
                    ref.read(agentFormProvider.notifier).addStarterPrompt(p),
                onRemove: (i) =>
                    ref.read(agentFormProvider.notifier).removeStarterPrompt(i),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconColorPicker(
    SanbaoColorScheme colors,
    AgentFormData form,
  ) =>
      SanbaoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Иконка и цвет',
              style: context.textTheme.labelLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            // Preview
            Center(
              child: AgentIcon(
                icon: form.icon,
                color: form.iconColor,
                size: AgentIconSize.xxl,
              ),
            ),
            const SizedBox(height: 16),
            // Icon grid
            Text(
              'Иконка',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AgentIcon.availableIcons.map((iconName) {
                final isSelected = form.icon == iconName;
                return GestureDetector(
                  onTap: () =>
                      ref.read(agentFormProvider.notifier).updateIcon(iconName),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.accentLight
                          : colors.bgSurfaceAlt,
                      borderRadius: SanbaoRadius.sm,
                      border: Border.all(
                        color:
                            isSelected ? colors.accent : colors.border,
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Icon(
                      AgentIcon.iconDataFor(iconName),
                      size: 18,
                      color: isSelected
                          ? colors.accent
                          : colors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Color grid
            Text(
              'Цвет',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConfig.validColors.map((colorHex) {
                final isSelected = form.iconColor == colorHex;
                final bgColor = colorHex.toColor() ?? colors.accent;
                return GestureDetector(
                  onTap: () => ref
                      .read(agentFormProvider.notifier)
                      .updateIconColor(colorHex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: colors.textPrimary, width: 2.5)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _buildModelSelector(
    SanbaoColorScheme colors,
    AgentFormData form,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Модель AI',
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
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _modelOptions.any((m) => m.id == form.model)
                    ? form.model
                    : _modelOptions.first.id,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                borderRadius: SanbaoRadius.md,
                dropdownColor: colors.bgSurface,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: colors.textMuted,
                ),
                items: _modelOptions.map((model) {
                  return DropdownMenuItem(
                    value: model.id,
                    child: Text(model.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(agentFormProvider.notifier).updateModel(value);
                  }
                },
              ),
            ),
          ),
        ],
      );

  Widget _buildSkillsSelector(
    SanbaoColorScheme colors,
    AgentFormData form,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Навыки',
                style: context.textTheme.labelLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (form.skillIds.isNotEmpty)
                Text(
                  '${form.skillIds.length} выбрано',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final result = await showSkillSelector(
                context: context,
                initialSelected: form.skillIds,
              );
              if (result != null) {
                ref.read(agentFormProvider.notifier).updateSkillIds(result);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.bgSurfaceAlt,
                borderRadius: SanbaoRadius.md,
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 18,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      form.skillIds.isEmpty
                          ? 'Выберите навыки...'
                          : '${form.skillIds.length} навыков выбрано',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: form.skillIds.isEmpty
                            ? colors.textMuted
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

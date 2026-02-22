/// Skill create/edit form screen.
///
/// Full-featured form for creating or editing a skill with:
/// name, description, icon/color picker, category, jurisdiction,
/// system prompt editor, and public toggle.
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
import 'package:sanbao_flutter/features/agents/presentation/widgets/agent_icon.dart';
import 'package:sanbao_flutter/features/skills/domain/entities/skill.dart';
import 'package:sanbao_flutter/features/skills/presentation/providers/skills_provider.dart';

/// Available jurisdiction options for legal skills.
const List<({String? code, String label})> _jurisdictionOptions = [
  (code: null, label: 'Не указана'),
  (code: 'RF', label: 'Россия'),
  (code: 'US', label: 'США'),
  (code: 'UK', label: 'Великобритания'),
  (code: 'EU', label: 'Евросоюз'),
  (code: 'KZ', label: 'Казахстан'),
  (code: 'BY', label: 'Беларусь'),
  (code: 'UZ', label: 'Узбекистан'),
];

/// Screen for creating or editing a skill.
///
/// Pre-fills the form when [existingSkill] is provided (edit mode).
/// Otherwise starts with a blank form (create mode).
class SkillFormScreen extends ConsumerStatefulWidget {
  const SkillFormScreen({
    super.key,
    this.existingSkill,
  });

  /// The skill to edit. If null, creating a new skill.
  final Skill? existingSkill;

  @override
  ConsumerState<SkillFormScreen> createState() => _SkillFormScreenState();
}

class _SkillFormScreenState extends ConsumerState<SkillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _systemPromptController = TextEditingController();
  final _citationRulesController = TextEditingController();

  bool get _isEditing => widget.existingSkill != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(skillFormProvider.notifier)
        .initialize(skill: widget.existingSkill);

      final form = ref.read(skillFormProvider);
      _nameController.text = form.name;
      _descriptionController.text = form.description;
      _systemPromptController.text = form.systemPrompt;
      _citationRulesController.text = form.citationRules;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _systemPromptController.dispose();
    _citationRulesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final form = ref.read(skillFormProvider);
    if (!form.isValid) {
      context.showErrorSnackBar('Заполните обязательные поля');
      return;
    }

    ref.read(skillFormSubmittingProvider.notifier).state = true;

    try {
      if (_isEditing) {
        await ref.read(skillsListProvider.notifier).updateSkill(
              id: widget.existingSkill!.id,
              name: form.name,
              description: form.description.isEmpty ? null : form.description,
              systemPrompt: form.systemPrompt,
              citationRules:
                  form.citationRules.isEmpty ? null : form.citationRules,
              jurisdiction: form.jurisdiction,
              icon: form.icon,
              iconColor: form.iconColor,
              isPublic: form.isPublic,
            );
        if (mounted) {
          context.showSuccessSnackBar('Навык обновлен');
        }
      } else {
        await ref.read(skillsListProvider.notifier).createSkill(
              name: form.name,
              description: form.description.isEmpty ? null : form.description,
              systemPrompt: form.systemPrompt,
              citationRules:
                  form.citationRules.isEmpty ? null : form.citationRules,
              jurisdiction: form.jurisdiction,
              icon: form.icon,
              iconColor: form.iconColor,
              isPublic: form.isPublic,
            );
        if (mounted) {
          context.showSuccessSnackBar('Навык создан');
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
        ref.read(skillFormSubmittingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final form = ref.watch(skillFormProvider);
    final isSubmitting = ref.watch(skillFormSubmittingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать навык' : 'Новый навык'),
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
                hint: 'Введите название навыка',
                onChanged: (v) =>
                    ref.read(skillFormProvider.notifier).updateName(v),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              // Description
              SanbaoInput(
                controller: _descriptionController,
                label: 'Описание',
                hint: 'Краткое описание навыка (необязательно)',
                onChanged: (v) =>
                    ref.read(skillFormProvider.notifier).updateDescription(v),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Jurisdiction dropdown
              _buildJurisdictionSelector(colors, form),
              const SizedBox(height: 16),
              // System prompt
              SanbaoInput(
                controller: _systemPromptController,
                label: 'Системный промпт',
                hint: 'Инструкции и контекст для AI...',
                onChanged: (v) =>
                    ref.read(skillFormProvider.notifier).updateSystemPrompt(v),
                maxLines: 10,
                minLines: 5,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Обязательное поле' : null,
              ),
              const SizedBox(height: 16),
              // Citation rules (optional)
              SanbaoInput(
                controller: _citationRulesController,
                label: 'Правила цитирования',
                hint: 'Формат ссылок на источники (необязательно)',
                onChanged: (v) =>
                    ref.read(skillFormProvider.notifier).updateCitationRules(v),
                maxLines: 4,
                minLines: 2,
              ),
              const SizedBox(height: 20),
              // Public toggle
              _buildPublicToggle(colors, form),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconColorPicker(
    SanbaoColorScheme colors,
    SkillFormData form,
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
                      ref.read(skillFormProvider.notifier).updateIcon(iconName),
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
                      .read(skillFormProvider.notifier)
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

  Widget _buildJurisdictionSelector(
    SanbaoColorScheme colors,
    SkillFormData form,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Юрисдикция',
            style: context.textTheme.labelLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Для юридических навыков (необязательно)',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.bgSurfaceAlt,
              borderRadius: SanbaoRadius.md,
              border: Border.all(color: colors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: form.jurisdiction,
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
                items: _jurisdictionOptions.map((option) => DropdownMenuItem(
                    value: option.code,
                    child: Text(option.label),
                  ),).toList(),
                onChanged: (value) {
                  ref.read(skillFormProvider.notifier).updateJurisdiction(value);
                },
              ),
            ),
          ),
        ],
      );

  Widget _buildPublicToggle(
    SanbaoColorScheme colors,
    SkillFormData form,
  ) =>
      SanbaoCard(
        child: Row(
          children: [
            Icon(
              form.isPublic ? Icons.public_outlined : Icons.lock_outlined,
              size: 20,
              color: form.isPublic ? colors.accent : colors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Публичный навык',
                    style: context.textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Доступен другим пользователям в маркетплейсе',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: form.isPublic,
              onChanged: (_) =>
                  ref.read(skillFormProvider.notifier).togglePublic(),
            ),
          ],
        ),
      );
}

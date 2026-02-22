/// Skill AI generation bottom sheet.
///
/// Modal bottom sheet with description input, jurisdiction dropdown,
/// generate button, loading state, and on success pre-fills the
/// skill form and navigates to the skill form screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/features/skills/presentation/providers/skills_provider.dart';
import 'package:sanbao_flutter/features/skills/presentation/screens/skill_form_screen.dart';

/// Jurisdiction options for skill generation.
const _jurisdictions = <String, String>{
  'RF': 'Россия',
  'KZ': 'Казахстан',
  'BY': 'Беларусь',
  'EU': 'Европейский Союз',
  'EU/RF': 'ЕС / Россия',
  'International': 'Международное',
};

/// Shows the skill AI generation bottom sheet.
Future<void> showSkillGenerateSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _SkillGenerateSheet(),
    );

/// The skill generation modal bottom sheet content.
class _SkillGenerateSheet extends ConsumerStatefulWidget {
  const _SkillGenerateSheet();

  @override
  ConsumerState<_SkillGenerateSheet> createState() =>
      _SkillGenerateSheetState();
}

class _SkillGenerateSheetState extends ConsumerState<_SkillGenerateSheet> {
  final _descController = TextEditingController();
  final _descFocusNode = FocusNode();
  String? _selectedJurisdiction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(skillGenProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _descFocusNode.dispose();
    super.dispose();
  }

  void _handleGenerate() {
    final description = _descController.text.trim();
    if (description.isEmpty) return;

    HapticFeedback.lightImpact();
    _descFocusNode.unfocus();
    ref.read(skillGenProvider.notifier).generate(
          description: description,
          jurisdiction: _selectedJurisdiction,
        );
  }

  void _handleSuccess(Map<String, Object?> data) {
    // Pre-fill the skill form
    final formNotifier = ref.read(skillFormProvider.notifier)
      ..initialize();

    final name = data['name'] as String?;
    final description = data['description'] as String?;
    final systemPrompt = data['systemPrompt'] as String?;
    final citationRules = data['citationRules'] as String?;
    final jurisdiction = data['jurisdiction'] as String?;
    final icon = data['icon'] as String?;
    final iconColor = data['iconColor'] as String?;

    if (name != null) formNotifier.updateName(name);
    if (description != null) formNotifier.updateDescription(description);
    if (systemPrompt != null) formNotifier.updateSystemPrompt(systemPrompt);
    if (citationRules != null) formNotifier.updateCitationRules(citationRules);
    if (jurisdiction != null) formNotifier.updateJurisdiction(jurisdiction);
    if (icon != null) formNotifier.updateIcon(icon);
    if (iconColor != null) formNotifier.updateIconColor(iconColor);

    // Close sheet and navigate to form
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SkillFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final genState = ref.watch(skillGenProvider);
    final isGenerating = genState is SkillGenLoading;
    final hasText = _descController.text.trim().isNotEmpty;

    // Listen for success to navigate
    ref.listen<SkillGenState>(skillGenProvider, (previous, next) {
      if (next is SkillGenSuccess) {
        _handleSuccess(next.data);
      }
    });

    final maxHeight = context.screenHeight * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.only(
          topLeft: SanbaoRadius.circularLg,
          topRight: SanbaoRadius.circularLg,
        ),
        boxShadow: SanbaoShadows.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(colors),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),

                  // Loading
                  if (isGenerating) _buildLoading(colors),

                  // Description input
                  _buildDescriptionInput(colors),
                  const SizedBox(height: 12),

                  // Jurisdiction dropdown
                  _buildJurisdictionDropdown(colors),

                  // Error message
                  if (genState case SkillGenError(:final message)) ...[
                    const SizedBox(height: 12),
                    _buildErrorBanner(colors, message),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildFooter(colors, isGenerating, hasText),
        ],
      ),
    );
  }

  // ---- Header ----

  Widget _buildHeader(SanbaoColorScheme colors) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: SanbaoRadius.full,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0FFF4),
                    borderRadius: SanbaoRadius.sm,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Генерация навыка',
                        style: context.textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Опишите — AI создаст навык',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.bgSurfaceAlt,
                      borderRadius: SanbaoRadius.sm,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // ---- Description Input ----

  Widget _buildDescriptionInput(SanbaoColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Опишите навык',
            style: context.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descController,
            focusNode: _descFocusNode,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleGenerate(),
            onChanged: (_) => setState(() {}),
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'Например: "Анализ нормативно-правовых актов '
                  'Республики Казахстан, проверка на соответствие"...',
              hintStyle: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
              filled: true,
              fillColor: colors.bgSurfaceAlt,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: SanbaoRadius.md,
                borderSide: BorderSide(color: colors.border, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: SanbaoRadius.md,
                borderSide: BorderSide(color: colors.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: SanbaoRadius.md,
                borderSide: BorderSide(
                  color: colors.accent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      );

  // ---- Jurisdiction Dropdown ----

  Widget _buildJurisdictionDropdown(SanbaoColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Юрисдикция (опционально)',
            style: context.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedJurisdiction,
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.bgSurfaceAlt,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: SanbaoRadius.md,
                borderSide: BorderSide(color: colors.border, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: SanbaoRadius.md,
                borderSide: BorderSide(color: colors.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: SanbaoRadius.md,
                borderSide: BorderSide(
                  color: colors.accent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
            hint: Text(
              'Выберите юрисдикцию',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
            ),
            dropdownColor: colors.bgSurface,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
            ),
            items: [
              DropdownMenuItem<String>(
                child: Text(
                  'Не указана',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
              ..._jurisdictions.entries.map(
                (e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                ),
              ),
            ],
            onChanged: (value) => setState(() {
              _selectedJurisdiction = value;
            }),
          ),
        ],
      );

  // ---- Loading ----

  Widget _buildLoading(SanbaoColorScheme colors) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.bgSurfaceAlt,
            borderRadius: SanbaoRadius.md,
          ),
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Генерируем навык...',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      );

  // ---- Error Banner ----

  Widget _buildErrorBanner(SanbaoColorScheme colors, String message) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.errorLight,
          borderRadius: SanbaoRadius.sm,
          border: Border.all(
            color: colors.error.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: colors.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.error,
                ),
              ),
            ),
          ],
        ),
      );

  // ---- Footer ----

  Widget _buildFooter(
    SanbaoColorScheme colors,
    bool isGenerating,
    bool hasText,
  ) =>
      Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom:
              context.bottomPadding > 0 ? context.bottomPadding + 4 : 16,
        ),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          border: Border(
            top: BorderSide(color: colors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            if (hasText)
              Text(
                '${_descController.text.trim().length} / 5000',
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            const Spacer(),
            SanbaoButton(
              label: isGenerating ? 'Генерация...' : 'Сгенерировать',
              leadingIcon:
                  isGenerating ? null : Icons.auto_awesome_rounded,
              onPressed: _handleGenerate,
              size: SanbaoButtonSize.small,
              isLoading: isGenerating,
              isDisabled: !hasText || isGenerating,
            ),
          ],
        ),
      );
}

/// Agent AI generation bottom sheet.
///
/// Modal bottom sheet with a description input, generate button,
/// loading state, and on success pre-fills the agent form and
/// navigates to the agent form screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/features/agents/presentation/providers/agents_provider.dart';
import 'package:sanbao_flutter/features/agents/presentation/screens/agent_form_screen.dart';

/// Shows the agent AI generation bottom sheet.
Future<void> showAgentGenerateSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _AgentGenerateSheet(),
    );

/// The agent generation modal bottom sheet content.
class _AgentGenerateSheet extends ConsumerStatefulWidget {
  const _AgentGenerateSheet();

  @override
  ConsumerState<_AgentGenerateSheet> createState() =>
      _AgentGenerateSheetState();
}

class _AgentGenerateSheetState extends ConsumerState<_AgentGenerateSheet> {
  final _descController = TextEditingController();
  final _descFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(agentGenProvider.notifier).reset();
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
    ref.read(agentGenProvider.notifier).generate(description: description);
  }

  void _handleSuccess(Map<String, Object?> data) {
    // Pre-fill the agent form
    final formNotifier = ref.read(agentFormProvider.notifier)
      ..initialize();

    final name = data['name'] as String?;
    final description = data['description'] as String?;
    final instructions = data['instructions'] as String?;
    final icon = data['icon'] as String?;
    final iconColor = data['iconColor'] as String?;

    if (name != null) formNotifier.updateName(name);
    if (description != null) formNotifier.updateDescription(description);
    if (instructions != null) formNotifier.updateInstructions(instructions);
    if (icon != null) formNotifier.updateIcon(icon);
    if (iconColor != null) formNotifier.updateIconColor(iconColor);

    // Close sheet and navigate to form
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AgentFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final genState = ref.watch(agentGenProvider);
    final isGenerating = genState is AgentGenLoading;
    final hasText = _descController.text.trim().isNotEmpty;

    // Listen for success to navigate
    ref.listen<AgentGenState>(agentGenProvider, (previous, next) {
      if (next is AgentGenSuccess) {
        _handleSuccess(next.data);
      }
    });

    final maxHeight = context.screenHeight * 0.7;

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

                  // Error message
                  if (genState case AgentGenError(:final message)) ...[
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
                    color: Color(0xFFF0F0FF),
                    borderRadius: SanbaoRadius.sm,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Генерация агента',
                        style: context.textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Опишите — AI создаст настройки',
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
            'Опишите агента',
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
                  'Например: "Юрист по договорам, специализируется на '
                  'гражданском праве РФ, проверяет документы на риски"...',
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
                'Генерируем агента...',
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

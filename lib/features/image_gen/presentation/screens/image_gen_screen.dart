/// Image generation screen displayed as a modal bottom sheet.
///
/// Features a prompt input, style/size selectors, generate button,
/// loading shimmer, and result display with share/save actions.
/// Follows the same bottom sheet pattern as [FilePickerSheet].
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/features/image_gen/domain/entities/image_gen_result.dart';
import 'package:sanbao_flutter/features/image_gen/presentation/providers/image_gen_provider.dart';
import 'package:sanbao_flutter/features/image_gen/presentation/widgets/image_gen_loading.dart';
import 'package:sanbao_flutter/features/image_gen/presentation/widgets/image_gen_option_selector.dart';
import 'package:sanbao_flutter/features/image_gen/presentation/widgets/image_gen_result_view.dart';

/// Shows the image generation bottom sheet.
///
/// Returns the [ImageGenResult] if an image was generated, or null
/// if the sheet was dismissed without generating.
Future<ImageGenResult?> showImageGenSheet(BuildContext context) =>
    showModalBottomSheet<ImageGenResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _ImageGenSheet(),
    );

/// The image generation modal bottom sheet content.
class _ImageGenSheet extends ConsumerStatefulWidget {
  const _ImageGenSheet();

  @override
  ConsumerState<_ImageGenSheet> createState() => _ImageGenSheetState();
}

class _ImageGenSheetState extends ConsumerState<_ImageGenSheet> {
  final _promptController = TextEditingController();
  final _promptFocusNode = FocusNode();
  bool _showOptions = false;

  @override
  void initState() {
    super.initState();
    // Reset the generation state when the sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(imageGenProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _promptFocusNode.dispose();
    super.dispose();
  }

  void _handleGenerate() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    HapticFeedback.lightImpact();
    _promptFocusNode.unfocus();
    ref.read(imageGenProvider.notifier).generate(prompt: prompt);
  }

  void _handleReset() {
    _promptController.clear();
    ref.read(imageGenProvider.notifier).reset();
    _promptFocusNode.requestFocus();
  }

  void _handleClose() {
    final genState = ref.read(imageGenProvider);
    if (genState is ImageGenStateSuccess) {
      Navigator.of(context).pop(genState.result);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final genState = ref.watch(imageGenProvider);
    final isGenerating = genState is ImageGenStateLoading;
    final hasResult = genState is ImageGenStateSuccess;
    final hasText = _promptController.text.trim().isNotEmpty;

    // Calculate max height: 90% of screen height
    final maxHeight = context.screenHeight * 0.9;

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
          // Header
          _buildHeader(colors),

          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),

                  // Result (shown above prompt when available)
                  if (genState case ImageGenStateSuccess(:final result))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ImageGenResultView(
                        result: result,
                        onReset: _handleReset,
                      ),
                    ),

                  // Loading state
                  if (isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ImageGenLoading(),
                    ),

                  // Prompt input
                  _buildPromptInput(colors),

                  const SizedBox(height: 12),

                  // Options toggle & selectors
                  _buildOptionsSection(colors),

                  // Error message
                  if (genState case ImageGenStateError(:final message)) ...[
                    const SizedBox(height: 12),
                    _buildError(colors, message),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Footer with generate button
          _buildFooter(colors, isGenerating, hasResult, hasText),
        ],
      ),
    );
  }

  // ---- Header ----

  Widget _buildHeader(SanbaoColorScheme colors) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Drag handle
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
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1F2), // Rose-50
                    borderRadius: SanbaoRadius.sm,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Color(0xFFF43F5E), // Rose-500
                  ),
                ),
                const SizedBox(width: 12),

                // Title & subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Генерация изображения',
                        style: context.textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'AI генератор изображений',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Close button
                GestureDetector(
                  onTap: _handleClose,
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

  // ---- Prompt Input ----

  Widget _buildPromptInput(SanbaoColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Опишите изображение',
            style: context.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _promptController,
            focusNode: _promptFocusNode,
            maxLines: 3,
            minLines: 2,
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
                  'Например: "Горный пейзаж на закате с озером", '
                  '"Логотип в минималистичном стиле"...',
              hintStyle: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
              ),
              filled: true,
              fillColor: colors.bgSurfaceAlt,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: SanbaoRadius.md,
                borderSide: BorderSide(
                  color: colors.border,
                  width: 0.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: SanbaoRadius.md,
                borderSide: BorderSide(
                  color: colors.border,
                  width: 0.5,
                ),
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

  // ---- Options Section ----

  Widget _buildOptionsSection(SanbaoColorScheme colors) {
    final style = ref.watch(imageGenStyleProvider);
    final size = ref.watch(imageGenSizeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _showOptions = !_showOptions);
          },
          child: Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 16,
                color: colors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Параметры',
                style: context.textTheme.labelMedium?.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _showOptions ? 0.5 : 0.0,
                duration: SanbaoAnimations.durationFast,
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),

        // Expandable options
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                // Style selector
                ImageGenOptionSelector<ImageGenStyle>(
                  label: 'Стиль',
                  options: ImageGenStyle.values
                      .map(
                        (s) => OptionItem(
                          value: s,
                          label: s.label,
                          icon: s == ImageGenStyle.vivid
                              ? Icons.palette_rounded
                              : Icons.nature_rounded,
                        ),
                      )
                      .toList(),
                  selectedValue: style,
                  onChanged: (value) =>
                      ref.read(imageGenStyleProvider.notifier).state =
                          value,
                ),
                const SizedBox(height: 12),

                // Size selector
                ImageGenOptionSelector<ImageGenSize>(
                  label: 'Размер',
                  options: ImageGenSize.values
                      .map(
                        (s) => OptionItem(
                          value: s,
                          label: s.label,
                          icon: switch (s) {
                            ImageGenSize.square =>
                              Icons.crop_square_rounded,
                            ImageGenSize.landscape =>
                              Icons.crop_landscape_rounded,
                            ImageGenSize.portrait =>
                              Icons.crop_portrait_rounded,
                          },
                        ),
                      )
                      .toList(),
                  selectedValue: size,
                  onChanged: (value) =>
                      ref.read(imageGenSizeProvider.notifier).state =
                          value,
                ),
              ],
            ),
          ),
          crossFadeState: _showOptions
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: SanbaoAnimations.durationNormal,
          sizeCurve: SanbaoAnimations.smoothCurve,
        ),
      ],
    );
  }

  // ---- Error ----

  Widget _buildError(SanbaoColorScheme colors, String message) => Container(
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
    bool hasResult,
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
            // Prompt character count
            if (hasText)
              Text(
                '${_promptController.text.trim().length} / 2000',
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),

            const Spacer(),

            // Generate button
            SanbaoButton(
              label: isGenerating
                  ? 'Генерация...'
                  : hasResult
                      ? 'Сгенерировать ещё'
                      : 'Сгенерировать',
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

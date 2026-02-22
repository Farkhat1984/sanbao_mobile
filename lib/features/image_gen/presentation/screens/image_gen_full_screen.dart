/// Full-screen image generation page for route-based navigation.
///
/// Wraps the image generation UI in a Scaffold with an app bar,
/// providing a full-screen alternative to the bottom sheet modal.
/// Used when navigating via [RoutePaths.imageGen].
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Full-screen image generation page.
///
/// Provides the same functionality as the bottom sheet but as a
/// standalone routed screen. Accessible via `/image-gen` route.
class ImageGenFullScreen extends ConsumerStatefulWidget {
  const ImageGenFullScreen({super.key});

  @override
  ConsumerState<ImageGenFullScreen> createState() =>
      _ImageGenFullScreenState();
}

class _ImageGenFullScreenState extends ConsumerState<ImageGenFullScreen> {
  final _promptController = TextEditingController();
  final _promptFocusNode = FocusNode();
  bool _showOptions = false;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final genState = ref.watch(imageGenProvider);
    final isGenerating = genState is ImageGenStateLoading;
    final hasResult = genState is ImageGenStateSuccess;
    final hasText = _promptController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colors.textPrimary,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2),
                borderRadius: SanbaoRadius.sm,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: Color(0xFFF43F5E),
              ),
            ),
            const SizedBox(width: 10),
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
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Result
                  if (genState case ImageGenStateSuccess(:final result))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ImageGenResultView(
                        result: result,
                        onReset: _handleReset,
                      ),
                    ),

                  // Loading
                  if (isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: ImageGenLoading(),
                    ),

                  // Prompt
                  _buildPromptInput(colors),
                  const SizedBox(height: 16),

                  // Options
                  _buildOptionsSection(colors),

                  // Error
                  if (genState case ImageGenStateError(:final message)) ...[
                    const SizedBox(height: 16),
                    _buildError(colors, message),
                  ],
                ],
              ),
            ),
          ),

          // Footer
          _buildFooter(colors, isGenerating, hasResult, hasText),
        ],
      ),
    );
  }

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

  Widget _buildOptionsSection(SanbaoColorScheme colors) {
    final style = ref.watch(imageGenStyleProvider);
    final size = ref.watch(imageGenSizeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
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
          boxShadow: SanbaoShadows.sm,
        ),
        child: Row(
          children: [
            if (hasText)
              Text(
                '${_promptController.text.trim().length} / 2000',
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                ),
              ),
            const Spacer(),
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

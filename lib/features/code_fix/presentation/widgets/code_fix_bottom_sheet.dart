/// Code fix bottom sheet UI.
///
/// Modal bottom sheet with code and error input fields,
/// a fix button, loading state, and result display with copy action.
/// Follows the same pattern as [ImageGenScreen].
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/features/code_fix/presentation/providers/code_fix_provider.dart';

/// Shows the code fix bottom sheet.
///
/// Returns the fixed code [String] if successful, or null if dismissed.
Future<String?> showCodeFixSheet(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _CodeFixSheet(),
    );

/// The code fix modal bottom sheet content.
class _CodeFixSheet extends ConsumerStatefulWidget {
  const _CodeFixSheet();

  @override
  ConsumerState<_CodeFixSheet> createState() => _CodeFixSheetState();
}

class _CodeFixSheetState extends ConsumerState<_CodeFixSheet> {
  final _codeController = TextEditingController();
  final _errorController = TextEditingController();
  final _codeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(codeFixProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _errorController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  void _handleFix() {
    final code = _codeController.text.trim();
    final error = _errorController.text.trim();
    if (code.isEmpty || error.isEmpty) return;

    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    ref.read(codeFixProvider.notifier).fix(code: code, error: error);
  }

  void _handleReset() {
    _codeController.clear();
    _errorController.clear();
    ref.read(codeFixProvider.notifier).reset();
    _codeFocusNode.requestFocus();
  }

  void _handleCopy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    context.showSuccessSnackBar('Код скопирован');
  }

  void _handleClose() {
    final fixState = ref.read(codeFixProvider);
    if (fixState is CodeFixSuccess) {
      Navigator.of(context).pop(fixState.fixedCode);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final fixState = ref.watch(codeFixProvider);
    final isFixing = fixState is CodeFixLoading;
    final hasCode = _codeController.text.trim().isNotEmpty;
    final hasError = _errorController.text.trim().isNotEmpty;

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
          _buildHeader(colors),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),

                  // Result
                  if (fixState case CodeFixSuccess(:final fixedCode))
                    _buildResult(colors, fixedCode),

                  // Loading
                  if (isFixing) _buildLoading(colors),

                  // Code input
                  _buildCodeInput(colors),
                  const SizedBox(height: 12),

                  // Error input
                  _buildErrorInput(colors),

                  // Error message
                  if (fixState case CodeFixError(:final message)) ...[
                    const SizedBox(height: 12),
                    _buildErrorBanner(colors, message),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildFooter(colors, isFixing, hasCode && hasError),
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
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: SanbaoRadius.sm,
                  ),
                  child: Icon(
                    Icons.build_rounded,
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
                        'Исправление кода',
                        style: context.textTheme.titleSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'AI исправит ошибки в коде',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
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

  // ---- Code Input ----

  Widget _buildCodeInput(SanbaoColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Код',
            style: context.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _codeController,
            focusNode: _codeFocusNode,
            maxLines: 6,
            minLines: 3,
            onChanged: (_) => setState(() {}),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
              fontFamily: 'JetBrainsMono',
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Вставьте код с ошибкой...',
              hintStyle: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
                fontFamily: 'JetBrainsMono',
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

  // ---- Error Input ----

  Widget _buildErrorInput(SanbaoColorScheme colors) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ошибка',
            style: context.textTheme.labelMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _errorController,
            maxLines: 3,
            minLines: 2,
            onChanged: (_) => setState(() {}),
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Опишите ошибку или вставьте текст ошибки...',
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

  // ---- Result ----

  Widget _buildResult(SanbaoColorScheme colors, String fixedCode) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                  color: colors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Исправленный код',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: colors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _handleCopy(fixedCode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bgSurfaceAlt,
                      borderRadius: SanbaoRadius.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Копировать',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgSurfaceAlt,
                borderRadius: SanbaoRadius.sm,
                border: Border.all(
                  color: colors.success.withValues(alpha: 0.2),
                ),
              ),
              child: SelectableText(
                fixedCode,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                  fontFamily: 'JetBrainsMono',
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SanbaoButton(
              label: 'Исправить другой код',
              onPressed: _handleReset,
              leadingIcon: Icons.refresh_rounded,
              size: SanbaoButtonSize.small,
              variant: SanbaoButtonVariant.ghost,
            ),
          ],
        ),
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
                'Исправляем код...',
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
    bool isFixing,
    bool canSubmit,
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
            const Spacer(),
            SanbaoButton(
              label: isFixing ? 'Исправление...' : 'Исправить',
              leadingIcon: isFixing ? null : Icons.build_rounded,
              onPressed: _handleFix,
              size: SanbaoButtonSize.small,
              isLoading: isFixing,
              isDisabled: !canSubmit || isFixing,
            ),
          ],
        ),
      );
}

/// Sanbao modal widget -- bottom sheet and dialog helpers.
///
/// Provides consistent styling for bottom sheets and dialogs
/// with proper safe area handling and animations.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Shows a Sanbao-styled modal bottom sheet.
///
/// Returns the value passed to [Navigator.pop] when the sheet is dismissed.
Future<T?> showSanbaoBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  double? maxHeight,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: Colors.transparent,
      barrierColor: SanbaoColors.mobileOverlay,
      constraints: maxHeight != null
          ? BoxConstraints(maxHeight: maxHeight)
          : null,
      builder: (context) => _BottomSheetWrapper(
        child: builder(context),
      ),
    );

/// Shows a Sanbao-styled dialog.
///
/// Returns the value passed to [Navigator.pop] when the dialog is dismissed.
Future<T?> showSanbaoDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool useRootNavigator = true,
}) =>
    showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierColor: SanbaoColors.mobileOverlay,
      useRootNavigator: useRootNavigator,
      builder: builder,
    );

/// Shows a confirmation dialog with title, message, and action buttons.
Future<bool> showSanbaoConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Подтвердить',
  String cancelLabel = 'Отмена',
  bool isDestructive = false,
}) async {
  final result = await showSanbaoDialog<bool>(
    context: context,
    builder: (context) => SanbaoDialogContent(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
    ),
  );
  return result ?? false;
}

/// Internal wrapper for bottom sheet content.
class _BottomSheetWrapper extends StatelessWidget {
  const _BottomSheetWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SanbaoRadius.lgValue),
        ),
        boxShadow: SanbaoShadows.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Drag handle
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderHover,
              borderRadius: SanbaoRadius.full,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(child: child),
          SizedBox(height: context.bottomPadding),
        ],
      ),
    );
  }
}

/// Content widget for a standard confirmation dialog.
class SanbaoDialogContent extends StatelessWidget {
  const SanbaoDialogContent({
    required this.title,
    required this.message,
    super.key,
    this.confirmLabel = 'Подтвердить',
    this.cancelLabel = 'Отмена',
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return AlertDialog(
      title: Text(title),
      content: Text(
        message,
        style: context.textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
      ),
      shape: const RoundedRectangleBorder(borderRadius: SanbaoRadius.lg),
      backgroundColor: colors.bgSurface,
      surfaceTintColor: Colors.transparent,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: isDestructive ? colors.error : colors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// A reusable bottom sheet with title and optional close button.
class SanbaoBottomSheetContent extends StatelessWidget {
  const SanbaoBottomSheetContent({
    required this.title,
    required this.child,
    super.key,
    this.showCloseButton = true,
    this.padding,
  });

  final String title;
  final Widget child;
  final bool showCloseButton;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.headlineSmall,
                ),
              ),
              if (showCloseButton)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: colors.textMuted,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Report dialog for flagging inappropriate assistant messages.
///
/// Shows a modal bottom sheet with reason selection (radio buttons),
/// optional details text field, and submit/cancel actions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_input.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/features/chat/data/datasources/report_datasource.dart';

/// Shows the report bottom sheet for a specific message.
///
/// Returns `true` if the report was submitted successfully,
/// `false` or `null` if cancelled.
Future<bool?> showReportDialog({
  required BuildContext context,
  required String messageId,
}) =>
    showSanbaoBottomSheet<bool>(
      context: context,
      builder: (context) => _ReportSheetContent(messageId: messageId),
    );

/// Internal content of the report bottom sheet.
class _ReportSheetContent extends ConsumerStatefulWidget {
  const _ReportSheetContent({required this.messageId});

  final String messageId;

  @override
  ConsumerState<_ReportSheetContent> createState() =>
      _ReportSheetContentState();
}

class _ReportSheetContentState extends ConsumerState<_ReportSheetContent> {
  ReportReason? _selectedReason;
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SanbaoBottomSheetContent(
      title: 'Пожаловаться',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Выберите причину жалобы',
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Reason radio buttons
          ...ReportReason.values.map(
            (reason) => _ReasonRadioTile(
              reason: reason,
              isSelected: _selectedReason == reason,
              onTap: _isSubmitting
                  ? null
                  : () => setState(() => _selectedReason = reason),
            ),
          ),

          const SizedBox(height: 16),

          // Optional details
          SanbaoInput(
            controller: _detailsController,
            label: 'Подробности (необязательно)',
            hint: 'Опишите проблему...',
            maxLines: 3,
            minLines: 2,
            maxLength: 500,
            enabled: !_isSubmitting,
            textCapitalization: TextCapitalization.sentences,
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SanbaoButton(
                  label: 'Отмена',
                  variant: SanbaoButtonVariant.ghost,
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SanbaoButton(
                  label: 'Отправить',
                  isLoading: _isSubmitting,
                  isDisabled: _selectedReason == null || _isSubmitting,
                  leadingIcon: Icons.send_rounded,
                  onPressed: _selectedReason == null ? null : _submitReport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    unawaited(HapticFeedback.lightImpact());

    try {
      final reportDataSource = ref.read(reportRemoteDataSourceProvider);
      await reportDataSource.submitReport(
        messageId: widget.messageId,
        reason: _selectedReason!,
        details: _detailsController.text.nullIfEmpty,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        context.showErrorSnackBar('Не удалось отправить жалобу');
      }
    }
  }
}

/// A single radio option tile for selecting a report reason.
class _ReasonRadioTile extends StatelessWidget {
  const _ReasonRadioTile({
    required this.reason,
    required this.isSelected,
    this.onTap,
  });

  final ReportReason reason;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: SanbaoRadius.sm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? colors.accent : colors.border,
                      width: isSelected ? 2 : 1.5,
                    ),
                    color: isSelected
                        ? colors.accent
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.textInverse,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reason.displayLabel,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w500 : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

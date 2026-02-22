/// Bottom sheet for AI clarification questions.
///
/// Shown when the AI needs more context before generating a document.
/// Parses `<sanbao-clarify>` tags from the response and presents
/// questions with multi-select options or text inputs.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_button.dart';
import 'package:sanbao_flutter/features/chat/data/models/chat_event_model.dart';

/// Shows the clarification questions bottom sheet.
///
/// Returns the formatted answer text if the user submits,
/// or `null` if dismissed.
Future<String?> showClarifySheet(
  BuildContext context,
  List<ClarifyQuestion> questions,
) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ClarifySheet(questions: questions),
  );

class _ClarifySheet extends StatefulWidget {
  const _ClarifySheet({required this.questions});

  final List<ClarifyQuestion> questions;

  @override
  State<_ClarifySheet> createState() => _ClarifySheetState();
}

class _ClarifySheetState extends State<_ClarifySheet> {
  final _answers = <String, String>{};
  final _textControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final q in widget.questions) {
      if (q.isTextInput) {
        _textControllers[q.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasAnyAnswer =>
      _answers.values.any((v) => v.trim().isNotEmpty);

  void _toggleOption(String questionId, String option) {
    HapticFeedback.selectionClick();
    setState(() {
      final current = _answers[questionId] ?? '';
      final selected = current.split(', ').where((s) => s.isNotEmpty).toList();

      if (selected.contains(option)) {
        selected.remove(option);
      } else {
        selected.add(option);
      }

      _answers[questionId] = selected.join(', ');
    });
  }

  void _submit() {
    final lines = <String>[];
    for (final q in widget.questions) {
      final answer = q.isTextInput
          ? _textControllers[q.id]?.text.trim() ?? ''
          : (_answers[q.id] ?? '').trim();
      if (answer.isEmpty) continue;
      lines.add('${q.question}\n→ $answer');
    }

    if (lines.isEmpty) return;

    final text =
        'Мои ответы на уточняющие вопросы:\n\n${lines.join('\n\n')}';
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 20,
                  color: colors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Уточняющие вопросы',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Questions list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (ctx, index) =>
                  _buildQuestion(ctx, widget.questions[index], index + 1),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: SanbaoButton(
                    label: 'Пропустить',
                    variant: SanbaoButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SanbaoButton(
                    label: 'Отправить ответы',
                    onPressed: _hasAnyAnswer ? _submit : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    ClarifyQuestion question,
    int number,
  ) {
    final colors = context.sanbaoColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question with number badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                question.question,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Answer input
        if (question.isTextInput)
          _buildTextInput(question)
        else if (question.isSelect)
          _buildSelectOptions(question),
      ],
    );
  }

  Widget _buildTextInput(ClarifyQuestion question) {
    final colors = context.sanbaoColors;

    return TextField(
      controller: _textControllers[question.id],
      maxLines: 2,
      onChanged: (value) => setState(() {
        _answers[question.id] = value;
      }),
      style: context.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: question.placeholder ?? 'Введите ответ...',
        hintStyle: context.textTheme.bodyMedium?.copyWith(
          color: colors.textMuted,
        ),
        filled: true,
        fillColor: colors.bgSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: SanbaoRadius.sm,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.sm,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.sm,
          borderSide: BorderSide(color: colors.accent),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildSelectOptions(ClarifyQuestion question) {
    final colors = context.sanbaoColors;
    final selected =
        (_answers[question.id] ?? '').split(', ').where((s) => s.isNotEmpty);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: question.options!.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => _toggleOption(question.id, option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.accent
                  : colors.bgSurfaceAlt,
              borderRadius: SanbaoRadius.sm,
              border: Border.all(
                color: isSelected
                    ? colors.accent
                    : colors.border,
              ),
            ),
            child: Text(
              option,
              style: context.textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

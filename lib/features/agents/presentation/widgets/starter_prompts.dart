/// Starter prompts display and editor widgets.
///
/// Shows a list of suggested prompts as tappable chips (display mode)
/// or an editable list with add/remove (form mode).
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Displays starter prompts as tappable chips.
///
/// Used on the agent detail screen and welcome screen to show
/// suggested conversation starters.
class StarterPrompts extends StatelessWidget {
  const StarterPrompts({
    required this.prompts,
    super.key,
    this.onPromptTap,
    this.maxDisplay = 4,
  });

  /// List of prompt strings to display.
  final List<String> prompts;

  /// Callback when a prompt chip is tapped.
  final ValueChanged<String>? onPromptTap;

  /// Maximum number of prompts to show.
  final int maxDisplay;

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();

    final colors = context.sanbaoColors;
    final displayPrompts = prompts.take(maxDisplay).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: displayPrompts.map((prompt) {
        return GestureDetector(
          onTap: onPromptTap != null ? () => onPromptTap!(prompt) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.bgSurfaceAlt,
              borderRadius: SanbaoRadius.md,
              border: Border.all(color: colors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 14,
                  color: colors.accent,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    prompt,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Editable list of starter prompts for the agent form.
///
/// Allows adding and removing starter prompts with an inline
/// text field and remove buttons.
class StarterPromptsEditor extends StatefulWidget {
  const StarterPromptsEditor({
    required this.prompts,
    required this.onAdd,
    required this.onRemove,
    super.key,
    this.maxPrompts = 6,
  });

  /// Current list of prompts.
  final List<String> prompts;

  /// Callback to add a new prompt.
  final ValueChanged<String> onAdd;

  /// Callback to remove a prompt at the given index.
  final ValueChanged<int> onRemove;

  /// Maximum number of prompts allowed.
  final int maxPrompts;

  @override
  State<StarterPromptsEditor> createState() => _StarterPromptsEditorState();
}

class _StarterPromptsEditorState extends State<StarterPromptsEditor> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addPrompt() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (widget.prompts.length >= widget.maxPrompts) return;

    widget.onAdd(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final canAdd = widget.prompts.length < widget.maxPrompts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Стартовые промпты',
          style: context.textTheme.labelLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Подсказки для начала разговора (до ${widget.maxPrompts})',
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        // Existing prompts
        ...widget.prompts.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _PromptItem(
              prompt: entry.value,
              onRemove: () => widget.onRemove(entry.key),
            ),
          );
        }),
        // Add new prompt field
        if (canAdd) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Введите промпт...',
                    hintStyle: context.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                    filled: true,
                    fillColor: colors.bgSurfaceAlt,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: SanbaoRadius.md,
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: SanbaoRadius.md,
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: SanbaoRadius.md,
                      borderSide:
                          BorderSide(color: colors.borderFocus, width: 1.5),
                    ),
                    isDense: true,
                  ),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textPrimary,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addPrompt(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addPrompt,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: SanbaoRadius.md,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A single prompt item with remove button.
class _PromptItem extends StatelessWidget {
  const _PromptItem({
    required this.prompt,
    required this.onRemove,
  });

  final String prompt;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return AnimatedContainer(
      duration: SanbaoAnimations.durationFast,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSurfaceAlt,
        borderRadius: SanbaoRadius.sm,
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 14,
            color: colors.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              prompt,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

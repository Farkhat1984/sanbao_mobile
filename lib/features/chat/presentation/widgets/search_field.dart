/// Search input for filtering conversations in the sidebar.
///
/// A compact text field with a search icon that matches
/// the web sidebar's search input styling.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// A compact search field for filtering the conversation list.
///
/// Provides a search icon prefix and a clear button suffix
/// when the query is not empty. Matches the web sidebar's
/// search field (h-8, pl-8, rounded-lg, bg-surface-alt).
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.hint = 'Поиск чатов...',
  });

  /// External text controller. If null, an internal one is created.
  final TextEditingController? controller;

  /// Called when the search query changes.
  final ValueChanged<String>? onChanged;

  /// Placeholder text.
  final String hint;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    // Only dispose the controller if we created it internally.
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged?.call(_controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 32,
        child: TextField(
          controller: _controller,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textPrimary,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontSize: 13,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 10, right: 6),
              child: Icon(
                Icons.search_rounded,
                size: 14,
                color: colors.textMuted,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 32,
            ),
            suffixIcon: _hasText
                ? GestureDetector(
                    onTap: _clearSearch,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: colors.textMuted,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 32,
            ),
            filled: true,
            fillColor: colors.bgSurfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 0,
            ),
            border: OutlineInputBorder(
              borderRadius: SanbaoRadius.sm,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: SanbaoRadius.sm,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: SanbaoRadius.sm,
              borderSide: BorderSide(
                color: colors.borderHover,
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

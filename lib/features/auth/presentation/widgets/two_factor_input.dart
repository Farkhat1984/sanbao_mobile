/// Two-factor authentication OTP input widget.
///
/// Provides a 6-digit PIN-style input with individual cells,
/// auto-advance, and paste support.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Number of digits in the OTP code.
const _otpLength = 6;

/// A 6-digit OTP input for two-factor authentication.
///
/// Features:
/// - Individual cells for each digit
/// - Auto-advance on input
/// - Backspace to go back
/// - Clipboard paste support
/// - Error state display
/// - Auto-submit callback when all digits entered
class TwoFactorInput extends StatefulWidget {
  const TwoFactorInput({
    required this.onCompleted,
    super.key,
    this.errorText,
    this.isLoading = false,
    this.isDisabled = false,
    this.autoFocus = true,
  });

  /// Called when all 6 digits have been entered.
  final ValueChanged<String> onCompleted;

  /// Error text to display below the input.
  final String? errorText;

  /// Whether to show a loading indicator.
  final bool isLoading;

  /// Whether the input is disabled.
  final bool isDisabled;

  /// Whether to auto-focus the first cell.
  final bool autoFocus;

  @override
  State<TwoFactorInput> createState() => _TwoFactorInputState();
}

class _TwoFactorInputState extends State<TwoFactorInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _otpLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());

    if (widget.autoFocus) {
      // Request focus after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _currentCode =>
      _controllers.map((c) => c.text).join();

  bool get _isComplete =>
      _controllers.every((c) => c.text.isNotEmpty);

  void _onChanged(int index, String value) {
    if (widget.isDisabled || widget.isLoading) return;

    // Handle paste (multiple characters)
    if (value.length > 1) {
      _handlePaste(value);
      return;
    }

    // Single character entered - advance to next cell
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    // Check if all digits entered
    if (_isComplete) {
      widget.onCompleted(_currentCode);
    }
  }

  void _handlePaste(String value) {
    // Extract only digits
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;

    for (int i = 0; i < _otpLength && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }

    // Focus the last filled cell or the next empty one
    final lastIndex = (digits.length < _otpLength)
        ? digits.length
        : _otpLength - 1;
    _focusNodes[lastIndex].requestFocus();

    if (_isComplete) {
      widget.onCompleted(_currentCode);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Handle backspace: clear current and move back
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  /// Clears all cells and focuses the first one.
  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final hasError = widget.errorText != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_otpLength, (index) {
            // Add a gap between the 3rd and 4th digit
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index == 3)
                  const SizedBox(width: 16),
                _OtpCell(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  isDisabled: widget.isDisabled || widget.isLoading,
                  hasError: hasError,
                  onChanged: (value) => _onChanged(index, value),
                  onKeyEvent: (event) => _onKeyEvent(index, event),
                ),
                if (index < _otpLength - 1 && index != 2)
                  const SizedBox(width: 8),
              ],
            );
          }),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (widget.isLoading) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.accent,
            ),
          ),
        ],
      ],
    );
  }
}

/// Individual cell in the OTP input.
class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.isDisabled,
    required this.hasError,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDisabled;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(), // Separate listener node
        onKeyEvent: onKeyEvent,
        child: AnimatedContainer(
          duration: SanbaoAnimations.durationFast,
          decoration: BoxDecoration(
            color: isDisabled
                ? colors.bgSurfaceAlt.withValues(alpha: 0.5)
                : colors.bgSurfaceAlt,
            borderRadius: SanbaoRadius.md,
            border: Border.all(
              color: hasError
                  ? colors.error
                  : focusNode.hasFocus
                      ? colors.borderFocus
                      : colors.border,
              width: focusNode.hasFocus ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !isDisabled,
            onChanged: onChanged,
            textAlign: TextAlign.center,
            maxLength: 1,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: context.textTheme.headlineSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}

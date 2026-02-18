/// Accent-colored "New Chat" button for the sidebar drawer.
///
/// Creates a new conversation when pressed and provides
/// haptic feedback with a press-scale animation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// A full-width accent button to start a new conversation.
///
/// Matches the web sidebar's "Новый чат" button with Plus icon,
/// accent background, active:scale-[0.98], and hover-to-pressed transition.
class NewChatButton extends StatefulWidget {
  const NewChatButton({
    super.key,
    this.onPressed,
  });

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  @override
  State<NewChatButton> createState() => _NewChatButtonState();
}

class _NewChatButtonState extends State<NewChatButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: SanbaoAnimations.durationFast,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: SanbaoAnimations.buttonPressScale,
    ).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.forward();

  void _onTapUp(TapUpDetails _) => _scaleController.reverse();

  void _onTapCancel() => _scaleController.reverse();

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Container(
            width: double.infinity,
            height: 36,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: SanbaoRadius.md,
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: colors.textInverse,
                ),
                const SizedBox(width: 8),
                Text(
                  'Новый чат',
                  style: context.textTheme.labelLarge?.copyWith(
                    color: colors.textInverse,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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

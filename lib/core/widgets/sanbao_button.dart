/// Sanbao button widget with Primary, Secondary, Ghost, and Gradient variants.
///
/// All buttons include:
/// - Active press scale (0.98) for tactile feedback
/// - Loading state with spinner
/// - Disabled state with reduced opacity
/// - Icon support (leading and trailing)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/animations.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Visual variant of the button.
enum SanbaoButtonVariant {
  /// Filled accent background, white text.
  primary,

  /// Surface-alt background with border.
  secondary,

  /// Transparent background, text changes on hover.
  ghost,

  /// Gradient background (accent -> legal-ref) for main CTAs.
  gradient,
}

/// Size preset for the button.
enum SanbaoButtonSize {
  /// Compact button (height ~36).
  small,

  /// Default button (height ~44).
  medium,

  /// Large button (height ~52).
  large,
}

/// A styled button following the Sanbao design system.
class SanbaoButton extends StatefulWidget {
  const SanbaoButton({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = SanbaoButtonVariant.primary,
    this.size = SanbaoButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.leadingIcon,
    this.trailingIcon,
    this.isExpanded = false,
  });

  /// The button label text.
  final String label;

  /// Callback when the button is pressed. Null disables the button.
  final VoidCallback? onPressed;

  /// Visual variant of the button.
  final SanbaoButtonVariant variant;

  /// Size preset.
  final SanbaoButtonSize size;

  /// Whether to show a loading spinner.
  final bool isLoading;

  /// Whether the button is disabled.
  final bool isDisabled;

  /// Optional icon before the label.
  final IconData? leadingIcon;

  /// Optional icon after the label.
  final IconData? trailingIcon;

  /// Whether the button expands to fill available width.
  final bool isExpanded;

  @override
  State<SanbaoButton> createState() => _SanbaoButtonState();
}

class _SanbaoButtonState extends State<SanbaoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  bool get _isEnabled =>
      !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

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

  void _onTapDown(TapDownDetails _) {
    if (_isEnabled) _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  void _onTap() {
    if (_isEnabled) {
      HapticFeedback.lightImpact();
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final sizing = _resolveSizing();

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: _buildButton(colors, sizing),
    );

    if (widget.isExpanded) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return AnimatedOpacity(
      opacity: _isEnabled ? 1.0 : 0.5,
      duration: SanbaoAnimations.durationFast,
      child: button,
    );
  }

  Widget _buildButton(SanbaoColorScheme colors, _ButtonSizing sizing) {
    final child = _buildContent(colors, sizing);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      child: switch (widget.variant) {
        SanbaoButtonVariant.primary => _primaryContainer(colors, sizing, child),
        SanbaoButtonVariant.secondary =>
          _secondaryContainer(colors, sizing, child),
        SanbaoButtonVariant.ghost => _ghostContainer(colors, sizing, child),
        SanbaoButtonVariant.gradient =>
          _gradientContainer(colors, sizing, child),
      },
    );
  }

  Widget _primaryContainer(
    SanbaoColorScheme colors,
    _ButtonSizing sizing,
    Widget child,
  ) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: SanbaoRadius.md,
        ),
        child: Padding(
          padding: sizing.padding,
          child: child,
        ),
      );

  Widget _secondaryContainer(
    SanbaoColorScheme colors,
    _ButtonSizing sizing,
    Widget child,
  ) =>
      DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgSurfaceAlt,
          borderRadius: SanbaoRadius.md,
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: sizing.padding,
          child: child,
        ),
      );

  Widget _ghostContainer(
    SanbaoColorScheme colors,
    _ButtonSizing sizing,
    Widget child,
  ) =>
      Padding(
        padding: sizing.padding,
        child: child,
      );

  Widget _gradientContainer(
    SanbaoColorScheme colors,
    _ButtonSizing sizing,
    Widget child,
  ) =>
      DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SanbaoColors.gradientStart, SanbaoColors.gradientEnd],
          ),
          borderRadius: SanbaoRadius.md,
        ),
        child: Padding(
          padding: sizing.padding,
          child: child,
        ),
      );

  Widget _buildContent(SanbaoColorScheme colors, _ButtonSizing sizing) {
    final foreground = _foregroundColor(colors);

    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: sizing.iconSize,
          height: sizing.iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: foreground,
          ),
        ),
      );
    }

    final children = <Widget>[
      if (widget.leadingIcon != null) ...[
        Icon(widget.leadingIcon, size: sizing.iconSize, color: foreground),
        SizedBox(width: sizing.iconGap),
      ],
      Text(
        widget.label,
        style: TextStyle(
          fontSize: sizing.fontSize,
          fontWeight: FontWeight.w600,
          color: foreground,
          height: 1.2,
        ),
      ),
      if (widget.trailingIcon != null) ...[
        SizedBox(width: sizing.iconGap),
        Icon(widget.trailingIcon, size: sizing.iconSize, color: foreground),
      ],
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  Color _foregroundColor(SanbaoColorScheme colors) => switch (widget.variant) {
        SanbaoButtonVariant.primary => colors.textInverse,
        SanbaoButtonVariant.secondary => colors.textPrimary,
        SanbaoButtonVariant.ghost => colors.accent,
        SanbaoButtonVariant.gradient => colors.textInverse,
      };

  _ButtonSizing _resolveSizing() => switch (widget.size) {
        SanbaoButtonSize.small => const _ButtonSizing(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            fontSize: 13,
            iconSize: 16,
            iconGap: 6,
          ),
        SanbaoButtonSize.medium => const _ButtonSizing(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            fontSize: 14,
            iconSize: 18,
            iconGap: 8,
          ),
        SanbaoButtonSize.large => const _ButtonSizing(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            fontSize: 16,
            iconSize: 20,
            iconGap: 10,
          ),
      };
}

class _ButtonSizing {
  const _ButtonSizing({
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.iconGap,
  });

  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double iconGap;
}

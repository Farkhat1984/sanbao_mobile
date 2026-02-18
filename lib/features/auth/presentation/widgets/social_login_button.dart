/// Social login button widget.
///
/// A styled button for Google Sign-In following the Sanbao design system.
/// Uses the secondary button variant with the Google icon.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Type of social login provider.
enum SocialProvider {
  /// Google Sign-In.
  google,
}

/// A styled social login button matching the Sanbao design system.
///
/// Renders with the provider's icon, name, and appropriate colors.
/// Supports loading and disabled states.
class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    required this.provider,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.isDisabled = false,
    this.label,
  });

  /// The social login provider.
  final SocialProvider provider;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is in a loading state.
  final bool isLoading;

  /// Whether the button is disabled.
  final bool isDisabled;

  /// Custom label override. Defaults to provider-specific text.
  final String? label;

  bool get _isEnabled => !isDisabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    final buttonLabel = label ?? _defaultLabel;

    return AnimatedOpacity(
      opacity: _isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 150),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isEnabled ? onPressed : null,
            borderRadius: SanbaoRadius.md,
            child: Ink(
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: SanbaoRadius.md,
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 14,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.textSecondary,
                      ),
                    ),
                  ] else ...[
                    _buildProviderIcon(),
                  ],
                  const SizedBox(width: 12),
                  Text(
                    buttonLabel,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _defaultLabel => switch (provider) {
        SocialProvider.google => 'Google',
      };

  Widget _buildProviderIcon() => switch (provider) {
        SocialProvider.google => _GoogleIcon(),
      };
}

/// Custom Google "G" icon rendered with branded colors.
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

/// Paints the Google "G" logo with the official brand colors.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    // Draw the four colored arcs
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    const strokeWidth = 3.5;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Blue (top-right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.8, 1.2, false, paint);

    // Green (bottom-right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.4, 1.2, false, paint);

    // Yellow (bottom-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 1.6, 1.0, false, paint);

    // Red (top-left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 2.6, 1.0, false, paint);

    // Horizontal bar
    paint
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, cy),
      Offset(w - 1, cy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

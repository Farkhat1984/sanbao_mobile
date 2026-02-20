/// Social login button widget.
///
/// Styled buttons for Google, Apple, and WhatsApp Sign-In following the
/// Sanbao design system with each provider's brand colors and icons.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Type of social login provider.
enum SocialProvider {
  /// Google Sign-In.
  google,

  /// Apple Sign-In.
  apple,

  /// WhatsApp Sign-In (phone + OTP).
  whatsapp,
}

/// A styled social login button matching each provider's brand guidelines.
///
/// - **Google**: white background, multicolor "G" icon
/// - **Apple**: black background, white Apple icon (Apple HIG)
/// - **WhatsApp**: #25D366 green background, white phone icon
///
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
    final buttonLabel = label ?? _defaultLabel;
    final style = _providerStyle(context);

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
                color: style.bgColor,
                borderRadius: SanbaoRadius.md,
                border: Border.all(color: style.borderColor),
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
                        color: style.spinnerColor,
                      ),
                    ),
                  ] else ...[
                    _buildProviderIcon(),
                  ],
                  const SizedBox(width: 12),
                  Text(
                    buttonLabel,
                    style: context.textTheme.labelLarge?.copyWith(
                      color: style.textColor,
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
        SocialProvider.apple => 'Apple',
        SocialProvider.whatsapp => 'WhatsApp',
      };

  Widget _buildProviderIcon() => switch (provider) {
        SocialProvider.google => _GoogleIcon(),
        SocialProvider.apple => const _AppleIcon(),
        SocialProvider.whatsapp => const _WhatsAppIcon(),
      };

  _ProviderStyle _providerStyle(BuildContext context) {
    final colors = context.sanbaoColors;

    return switch (provider) {
      SocialProvider.google => _ProviderStyle(
          bgColor: colors.bgSurface,
          borderColor: colors.border,
          textColor: colors.textPrimary,
          spinnerColor: colors.textSecondary,
        ),
      SocialProvider.apple => const _ProviderStyle(
          bgColor: Colors.black,
          borderColor: Colors.black,
          textColor: Colors.white,
          spinnerColor: Colors.white70,
        ),
      SocialProvider.whatsapp => const _ProviderStyle(
          bgColor: Color(0xFF25D366),
          borderColor: Color(0xFF25D366),
          textColor: Colors.white,
          spinnerColor: Colors.white70,
        ),
    };
  }

  /// Whether Apple Sign-In is available on the current platform.
  static bool get isAppleSignInAvailable {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}

/// Style data for a provider button.
class _ProviderStyle {
  const _ProviderStyle({
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.spinnerColor,
  });

  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Color spinnerColor;
}

// ---------------------------------------------------------------------------
// Provider icons
// ---------------------------------------------------------------------------

/// Custom Google "G" icon rendered with branded colors.
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

/// Apple logo icon (white on dark background).
class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: Icon(Icons.apple, size: 22, color: Colors.white),
      ),
    );
  }
}

/// WhatsApp phone icon (white on green background).
class _WhatsAppIcon extends StatelessWidget {
  const _WhatsAppIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _WhatsAppLogoPainter()),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painters
// ---------------------------------------------------------------------------

/// Paints the Google "G" logo with the official brand colors.
///
/// Insets the arcs by half the stroke width so nothing overflows
/// the bounding box.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    const double strokeWidth = 3.0;
    // Inset radius so the stroke stays inside bounds
    final double r = (w - strokeWidth) / 2;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Blue (right, from ~-45° sweeping ~70°)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.75, 1.15, false, paint);

    // Green (bottom-right, ~20° sweeping ~70°)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.4, 1.15, false, paint);

    // Yellow (bottom-left, ~90° sweeping ~55°)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 1.55, 1.0, false, paint);

    // Red (top-left, ~145° sweeping ~60°)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 2.55, 1.05, false, paint);

    // Horizontal bar (the Google "G" notch)
    paint
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx + 0.5, cy),
      Offset(cx + r, cy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints a simplified WhatsApp phone-in-bubble logo in white.
class _WhatsAppLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer speech bubble circle
    final center = Offset(w / 2, h / 2 - 0.5);
    final radius = w * 0.42;
    canvas.drawCircle(center, radius, paint);

    // Small tail at bottom-left of the bubble
    final tailPath = Path()
      ..moveTo(w * 0.22, h * 0.68)
      ..quadraticBezierTo(w * 0.14, h * 0.85, w * 0.10, h * 0.92)
      ..quadraticBezierTo(w * 0.22, h * 0.82, w * 0.32, h * 0.76);
    canvas.drawPath(tailPath, paint);

    // Phone handset inside the bubble
    final phonePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Receiver: curved line from bottom-left to top-right
    final phonePath = Path();
    final pcx = w / 2;
    final pcy = h / 2 - 0.5;
    final pr = w * 0.18;

    // Draw a phone handset shape (rotated slightly)
    // Left earpiece
    phonePath.moveTo(pcx - pr * 0.9, pcy + pr * 0.5);
    phonePath.quadraticBezierTo(
      pcx - pr * 1.0, pcy - pr * 0.2,
      pcx - pr * 0.5, pcy - pr * 0.8,
    );
    // Curved body connecting earpieces
    phonePath.quadraticBezierTo(
      pcx, pcy - pr * 0.3,
      pcx + pr * 0.5, pcy - pr * 0.8,
    );
    // Right earpiece
    phonePath.quadraticBezierTo(
      pcx + pr * 1.0, pcy - pr * 0.2,
      pcx + pr * 0.9, pcy + pr * 0.5,
    );

    // Rotate the phone path 135 degrees for the WhatsApp style angle
    final rotatedPath = phonePath.transform(
      (Matrix4.identity()
            ..translate(pcx, pcy)
            ..rotateZ(math.pi * 0.75)
            ..translate(-pcx, -pcy))
          .storage,
    );

    canvas.drawPath(rotatedPath, phonePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

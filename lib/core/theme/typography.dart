/// Sanbao typography definitions.
///
/// Uses Inter as the primary font family and JetBrains Mono for
/// monospaced content (code blocks, legal article codes).
/// Base size: 14px (logical), line height: 1.6
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';

/// Typography constants for the Sanbao design system.
abstract final class SanbaoTypography {
  /// Primary font family for the entire interface.
  static const String fontFamily = 'Inter';

  /// Monospaced font family for code and legal article codes.
  static const String monoFontFamily = 'JetBrainsMono';

  /// Base font size in logical pixels.
  static const double baseFontSize = 14.0;

  /// Default line height multiplier.
  static const double baseLineHeight = 1.6;

  /// Creates the light mode text theme.
  static TextTheme get lightTextTheme => _buildTextTheme(
        primaryColor: SanbaoColors.textPrimary,
        secondaryColor: SanbaoColors.textSecondary,
      );

  /// Creates the dark mode text theme.
  static TextTheme get darkTextTheme => _buildTextTheme(
        primaryColor: SanbaoColors.textPrimaryDark,
        secondaryColor: SanbaoColors.textSecondaryDark,
      );

  static TextTheme _buildTextTheme({
    required Color primaryColor,
    required Color secondaryColor,
  }) =>
      TextTheme(
        // Display styles
        displayLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: primaryColor,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: primaryColor,
          letterSpacing: -0.3,
        ),
        displaySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: primaryColor,
        ),

        // Headline styles
        headlineLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: primaryColor,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: primaryColor,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: primaryColor,
        ),

        // Title styles
        titleLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
          color: primaryColor,
        ),
        titleMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: primaryColor,
        ),
        titleSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: primaryColor,
        ),

        // Body styles
        bodyLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: baseLineHeight,
          color: primaryColor,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: baseFontSize,
          fontWeight: FontWeight.w400,
          height: baseLineHeight,
          color: primaryColor,
        ),
        bodySmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: secondaryColor,
        ),

        // Label styles
        labelLarge: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: primaryColor,
        ),
        labelMedium: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: secondaryColor,
        ),
        labelSmall: TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: secondaryColor,
          letterSpacing: 0.3,
        ),
      );

  /// Monospaced text style for code blocks.
  static TextStyle codeStyle({
    Color? color,
    double fontSize = 13,
  }) =>
      TextStyle(
        fontFamily: monoFontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  /// Monospaced text style for legal article codes.
  static TextStyle legalCodeStyle({
    Color? color,
    double fontSize = 12,
  }) =>
      TextStyle(
        fontFamily: monoFontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: color ?? SanbaoColors.legalRef,
      );
}

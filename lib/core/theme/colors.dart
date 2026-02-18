/// Sanbao design system color tokens.
///
/// All colors are derived from the web styleguide (STYLEGUIDE.md)
/// and CSS variables (globals.css). Never hardcode colors in widgets --
/// always reference [SanbaoColors] or theme extensions.
library;

import 'package:flutter/material.dart';

/// Complete color palette for the Sanbao design system.
///
/// Organized by semantic purpose, matching the CSS variable naming
/// convention from the web project.
abstract final class SanbaoColors {
  // ---- Background ----

  /// Page background (light). Never pure white -- slight blue tint.
  static const Color bg = Color(0xFFFAFBFD);

  /// Card, panel surface (light).
  static const Color bgSurface = Color(0xFFFFFFFF);

  /// Sidebar, input fields, alternate surface (light).
  static const Color bgSurfaceAlt = Color(0xFFF3F5F9);

  /// Hover state for surface elements.
  static const Color bgSurfaceHover = Color(0xFFEDF0F5);

  /// Overlay background with transparency.
  static const Color bgOverlay = Color(0xD9FAFBFD); // ~85% opacity

  /// Page background (dark). Never pure black -- slight blue tint.
  static const Color bgDark = Color(0xFF0F1219);

  /// Card, panel surface (dark).
  static const Color bgSurfaceDark = Color(0xFF181D27);

  /// Sidebar, input fields, alternate surface (dark).
  static const Color bgSurfaceAltDark = Color(0xFF1E2433);

  /// Hover state for surface elements (dark).
  static const Color bgSurfaceHoverDark = Color(0xFF2A3144);

  /// Overlay background with transparency (dark).
  static const Color bgOverlayDark = Color(0xD90F1219);

  // ---- Text ----

  /// Primary text: headings, body text (light).
  static const Color textPrimary = Color(0xFF1A2138);

  /// Secondary text: captions, subtitles (light).
  static const Color textSecondary = Color(0xFF5C6B82);

  /// Muted text: placeholders, hints (light).
  static const Color textMuted = Color(0xFF8E99AB);

  /// Inverse text: on accent backgrounds.
  static const Color textInverse = Color(0xFFFFFFFF);

  /// Primary text (dark).
  static const Color textPrimaryDark = Color(0xFFE8ECF2);

  /// Secondary text (dark).
  static const Color textSecondaryDark = Color(0xFF8E99AB);

  /// Muted text (dark).
  static const Color textMutedDark = Color(0xFF5C6B82);

  // ---- Accent (Indigo Blue) ----

  /// Primary accent: buttons, links, active elements.
  static const Color accent = Color(0xFF4F6EF7);

  /// Accent hover state.
  static const Color accentHover = Color(0xFF3B57D9);

  /// Light accent background (for badges, highlights).
  static const Color accentLight = Color(0xFFEEF1FE);

  /// Accent for dark mode.
  static const Color accentDark = Color(0xFF6B8AFF);

  // ---- Legal Reference (Purple) ----

  /// Legal reference links and badges.
  static const Color legalRef = Color(0xFF7C3AED);

  /// Light background for legal reference badges.
  static const Color legalRefBg = Color(0xFFF5F0FF);

  /// Legal reference hover state.
  static const Color legalRefHover = Color(0xFF6D28D9);

  /// Legal reference for dark mode.
  static const Color legalRefDark = Color(0xFFA78BFA);

  // ---- Borders ----

  /// Default border (light).
  static const Color border = Color(0xFFE8ECF2);

  /// Border hover state.
  static const Color borderHover = Color(0xFFD0D7E2);

  /// Border focus state (accent).
  static const Color borderFocus = Color(0xFF4F6EF7);

  /// Default border (dark).
  static const Color borderDark = Color(0xFF2A3144);

  // ---- Status ----

  /// Success color.
  static const Color success = Color(0xFF22C55E);

  /// Success light background.
  static const Color successLight = Color(0xFFF0FDF4);

  /// Warning color.
  static const Color warning = Color(0xFFF59E0B);

  /// Warning light background.
  static const Color warningLight = Color(0xFFFFFBEB);

  /// Error color.
  static const Color error = Color(0xFFEF4444);

  /// Error light background.
  static const Color errorLight = Color(0xFFFEF2F2);

  /// Info color.
  static const Color info = Color(0xFF3B82F6);

  /// Info light background.
  static const Color infoLight = Color(0xFFEFF6FF);

  // ---- Gradient Colors ----

  /// Gradient start color (accent).
  static const Color gradientStart = accent;

  /// Gradient end color (legal-ref purple).
  static const Color gradientEnd = legalRef;

  /// Animated border gradient colors.
  static const List<Color> animatedBorderColors = [
    accent,       // Indigo
    Color(0xFFA78BFA), // Lavender
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF22C55E), // Green
    Color(0xFF3B82F6), // Blue
    accent,       // Back to Indigo
  ];

  // ---- Sidebar ----

  /// Sidebar background with transparency for glassmorphism.
  static const Color sidebarBg = Color(0xBFF3F5F9); // ~75% opacity

  // ---- Avatar Palette ----

  /// Deterministic color palette for avatar backgrounds.
  static const List<Color> avatarPalette = [
    Color(0xFF4F6EF7), // Indigo
    Color(0xFF7C3AED), // Purple
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF6366F1), // Violet
  ];

  /// Mobile overlay backdrop color.
  static const Color mobileOverlay = Color(0x66000000); // 40% black
}

/// Theme extension that provides Sanbao colors through [Theme.of(context)].
///
/// Usage:
/// ```dart
/// final colors = Theme.of(context).extension<SanbaoColorScheme>()!;
/// Container(color: colors.bgSurface);
/// ```
@immutable
class SanbaoColorScheme extends ThemeExtension<SanbaoColorScheme> {
  const SanbaoColorScheme({
    required this.bg,
    required this.bgSurface,
    required this.bgSurfaceAlt,
    required this.bgSurfaceHover,
    required this.bgOverlay,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textInverse,
    required this.accent,
    required this.accentHover,
    required this.accentLight,
    required this.legalRef,
    required this.legalRefBg,
    required this.legalRefHover,
    required this.border,
    required this.borderHover,
    required this.borderFocus,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.error,
    required this.errorLight,
    required this.info,
    required this.infoLight,
    required this.sidebarBg,
  });

  final Color bg;
  final Color bgSurface;
  final Color bgSurfaceAlt;
  final Color bgSurfaceHover;
  final Color bgOverlay;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textInverse;
  final Color accent;
  final Color accentHover;
  final Color accentLight;
  final Color legalRef;
  final Color legalRefBg;
  final Color legalRefHover;
  final Color border;
  final Color borderHover;
  final Color borderFocus;
  final Color success;
  final Color successLight;
  final Color warning;
  final Color warningLight;
  final Color error;
  final Color errorLight;
  final Color info;
  final Color infoLight;
  final Color sidebarBg;

  /// Light mode color scheme.
  static const light = SanbaoColorScheme(
    bg: SanbaoColors.bg,
    bgSurface: SanbaoColors.bgSurface,
    bgSurfaceAlt: SanbaoColors.bgSurfaceAlt,
    bgSurfaceHover: SanbaoColors.bgSurfaceHover,
    bgOverlay: SanbaoColors.bgOverlay,
    textPrimary: SanbaoColors.textPrimary,
    textSecondary: SanbaoColors.textSecondary,
    textMuted: SanbaoColors.textMuted,
    textInverse: SanbaoColors.textInverse,
    accent: SanbaoColors.accent,
    accentHover: SanbaoColors.accentHover,
    accentLight: SanbaoColors.accentLight,
    legalRef: SanbaoColors.legalRef,
    legalRefBg: SanbaoColors.legalRefBg,
    legalRefHover: SanbaoColors.legalRefHover,
    border: SanbaoColors.border,
    borderHover: SanbaoColors.borderHover,
    borderFocus: SanbaoColors.borderFocus,
    success: SanbaoColors.success,
    successLight: SanbaoColors.successLight,
    warning: SanbaoColors.warning,
    warningLight: SanbaoColors.warningLight,
    error: SanbaoColors.error,
    errorLight: SanbaoColors.errorLight,
    info: SanbaoColors.info,
    infoLight: SanbaoColors.infoLight,
    sidebarBg: SanbaoColors.sidebarBg,
  );

  /// Dark mode color scheme.
  static const dark = SanbaoColorScheme(
    bg: SanbaoColors.bgDark,
    bgSurface: SanbaoColors.bgSurfaceDark,
    bgSurfaceAlt: SanbaoColors.bgSurfaceAltDark,
    bgSurfaceHover: SanbaoColors.bgSurfaceHoverDark,
    bgOverlay: SanbaoColors.bgOverlayDark,
    textPrimary: SanbaoColors.textPrimaryDark,
    textSecondary: SanbaoColors.textSecondaryDark,
    textMuted: SanbaoColors.textMutedDark,
    textInverse: SanbaoColors.textInverse,
    accent: SanbaoColors.accentDark,
    accentHover: SanbaoColors.accent,
    accentLight: Color(0xFF1E2844),
    legalRef: SanbaoColors.legalRefDark,
    legalRefBg: Color(0xFF1E1833),
    legalRefHover: SanbaoColors.legalRef,
    border: SanbaoColors.borderDark,
    borderHover: Color(0xFF3A4558),
    borderFocus: SanbaoColors.accentDark,
    success: SanbaoColors.success,
    successLight: Color(0xFF0D2818),
    warning: SanbaoColors.warning,
    warningLight: Color(0xFF2D1F08),
    error: SanbaoColors.error,
    errorLight: Color(0xFF2D1212),
    info: SanbaoColors.info,
    infoLight: Color(0xFF0D1B2D),
    sidebarBg: Color(0xBF181D27),
  );

  @override
  SanbaoColorScheme copyWith({
    Color? bg,
    Color? bgSurface,
    Color? bgSurfaceAlt,
    Color? bgSurfaceHover,
    Color? bgOverlay,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textInverse,
    Color? accent,
    Color? accentHover,
    Color? accentLight,
    Color? legalRef,
    Color? legalRefBg,
    Color? legalRefHover,
    Color? border,
    Color? borderHover,
    Color? borderFocus,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? error,
    Color? errorLight,
    Color? info,
    Color? infoLight,
    Color? sidebarBg,
  }) =>
      SanbaoColorScheme(
        bg: bg ?? this.bg,
        bgSurface: bgSurface ?? this.bgSurface,
        bgSurfaceAlt: bgSurfaceAlt ?? this.bgSurfaceAlt,
        bgSurfaceHover: bgSurfaceHover ?? this.bgSurfaceHover,
        bgOverlay: bgOverlay ?? this.bgOverlay,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        textInverse: textInverse ?? this.textInverse,
        accent: accent ?? this.accent,
        accentHover: accentHover ?? this.accentHover,
        accentLight: accentLight ?? this.accentLight,
        legalRef: legalRef ?? this.legalRef,
        legalRefBg: legalRefBg ?? this.legalRefBg,
        legalRefHover: legalRefHover ?? this.legalRefHover,
        border: border ?? this.border,
        borderHover: borderHover ?? this.borderHover,
        borderFocus: borderFocus ?? this.borderFocus,
        success: success ?? this.success,
        successLight: successLight ?? this.successLight,
        warning: warning ?? this.warning,
        warningLight: warningLight ?? this.warningLight,
        error: error ?? this.error,
        errorLight: errorLight ?? this.errorLight,
        info: info ?? this.info,
        infoLight: infoLight ?? this.infoLight,
        sidebarBg: sidebarBg ?? this.sidebarBg,
      );

  @override
  SanbaoColorScheme lerp(ThemeExtension<SanbaoColorScheme>? other, double t) {
    if (other is! SanbaoColorScheme) return this;
    return SanbaoColorScheme(
      bg: Color.lerp(bg, other.bg, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgSurfaceAlt: Color.lerp(bgSurfaceAlt, other.bgSurfaceAlt, t)!,
      bgSurfaceHover: Color.lerp(bgSurfaceHover, other.bgSurfaceHover, t)!,
      bgOverlay: Color.lerp(bgOverlay, other.bgOverlay, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      legalRef: Color.lerp(legalRef, other.legalRef, t)!,
      legalRefBg: Color.lerp(legalRefBg, other.legalRefBg, t)!,
      legalRefHover: Color.lerp(legalRefHover, other.legalRefHover, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderHover: Color.lerp(borderHover, other.borderHover, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
    );
  }
}

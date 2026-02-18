/// Sanbao ThemeData for light and dark modes.
///
/// Assembles colors, typography, shadows, radius, and component
/// themes into complete ThemeData instances.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/theme/shadows.dart';
import 'package:sanbao_flutter/core/theme/typography.dart';

/// Builds the application's [ThemeData] for light and dark modes.
abstract final class SanbaoTheme {
  /// Light mode theme.
  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        colorScheme: SanbaoColorScheme.light,
        textTheme: SanbaoTypography.lightTextTheme,
      );

  /// Dark mode theme.
  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        colorScheme: SanbaoColorScheme.dark,
        textTheme: SanbaoTypography.darkTextTheme,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required SanbaoColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isLight = brightness == Brightness.light;

    final materialColorScheme = ColorScheme(
      brightness: brightness,
      primary: colorScheme.accent,
      onPrimary: colorScheme.textInverse,
      primaryContainer: colorScheme.accentLight,
      onPrimaryContainer: colorScheme.accent,
      secondary: colorScheme.legalRef,
      onSecondary: colorScheme.textInverse,
      secondaryContainer: colorScheme.legalRefBg,
      onSecondaryContainer: colorScheme.legalRef,
      tertiary: colorScheme.info,
      onTertiary: colorScheme.textInverse,
      error: colorScheme.error,
      onError: colorScheme.textInverse,
      errorContainer: colorScheme.errorLight,
      onErrorContainer: colorScheme.error,
      surface: colorScheme.bgSurface,
      onSurface: colorScheme.textPrimary,
      surfaceContainerHighest: colorScheme.bgSurfaceAlt,
      onSurfaceVariant: colorScheme.textSecondary,
      outline: colorScheme.border,
      outlineVariant: colorScheme.borderHover,
      shadow: const Color(0x141A2138),
      scrim: colorScheme.bgOverlay,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: materialColorScheme,
      textTheme: textTheme,
      fontFamily: SanbaoTypography.fontFamily,
      scaffoldBackgroundColor: colorScheme.bg,
      extensions: [colorScheme],

      // ---- AppBar ----
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.bgSurface,
        foregroundColor: colorScheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x0A1A2138),
        shape: Border(
          bottom: BorderSide(color: colorScheme.border, width: 0.5),
        ),
      ),

      // ---- Card ----
      cardTheme: CardThemeData(
        color: colorScheme.bgSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: SanbaoRadius.lg,
          side: BorderSide(color: colorScheme.border, width: 0.5),
        ),
      ),

      // ---- Elevated Button ----
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.accent,
          foregroundColor: colorScheme.textInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: SanbaoRadius.md,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ---- Filled Button ----
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.accent,
          foregroundColor: colorScheme.textInverse,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: SanbaoRadius.md,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ---- Outlined Button ----
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: SanbaoRadius.md,
            side: BorderSide(color: colorScheme.border),
          ),
          side: BorderSide(color: colorScheme.border),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ---- Text Button ----
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: const RoundedRectangleBorder(
            borderRadius: SanbaoRadius.md,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ---- Icon Button ----
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.textMuted,
          shape: const RoundedRectangleBorder(
            borderRadius: SanbaoRadius.md,
          ),
        ),
      ),

      // ---- Input Decoration ----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.bgSurfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: SanbaoRadius.md,
          borderSide: BorderSide(color: colorScheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.md,
          borderSide: BorderSide(color: colorScheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.md,
          borderSide: BorderSide(color: colorScheme.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.md,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: SanbaoRadius.md,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.textMuted,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.textSecondary,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
        ),
      ),

      // ---- Bottom Sheet ----
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SanbaoRadius.lgValue),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: colorScheme.borderHover,
        dragHandleSize: const Size(32, 4),
        elevation: 0,
        modalBarrierColor: SanbaoColors.mobileOverlay,
      ),

      // ---- Dialog ----
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: SanbaoRadius.lg,
        ),
        elevation: 0,
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // ---- Snackbar ----
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.textInverse,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: SanbaoRadius.md,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ---- Divider ----
      dividerTheme: DividerThemeData(
        color: colorScheme.border,
        thickness: 0.5,
        space: 0,
      ),

      // ---- Chip ----
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.bgSurfaceAlt,
        selectedColor: colorScheme.accentLight,
        labelStyle: textTheme.labelMedium,
        shape: const RoundedRectangleBorder(
          borderRadius: SanbaoRadius.sm,
        ),
        side: BorderSide(color: colorScheme.border),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ---- Bottom Navigation ----
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.bgSurface,
        selectedItemColor: colorScheme.accent,
        unselectedItemColor: colorScheme.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
      ),

      // ---- Navigation Bar (Material 3) ----
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.bgSurface,
        indicatorColor: colorScheme.accentLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),

      // ---- Progress Indicator ----
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.accent,
        linearTrackColor: colorScheme.bgSurfaceAlt,
        circularTrackColor: colorScheme.bgSurfaceAlt,
      ),

      // ---- Switch ----
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.textInverse;
          }
          return colorScheme.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.accent;
          }
          return colorScheme.bgSurfaceAlt;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.border;
        }),
      ),

      // ---- ListTile ----
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const RoundedRectangleBorder(
          borderRadius: SanbaoRadius.md,
        ),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        iconColor: colorScheme.textMuted,
      ),

      // ---- Tooltip ----
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.textPrimary,
          borderRadius: SanbaoRadius.sm,
          boxShadow: SanbaoShadows.md,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.textInverse,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // ---- Tab Bar ----
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.accent,
        unselectedLabelColor: colorScheme.textMuted,
        indicatorColor: colorScheme.accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        dividerColor: colorScheme.border,
      ),

      // ---- Popup Menu ----
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.bgSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: SanbaoRadius.md,
        ),
        elevation: 4,
        textStyle: textTheme.bodyMedium,
      ),
    );
  }
}

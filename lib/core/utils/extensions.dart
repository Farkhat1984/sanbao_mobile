/// Extension methods for String, DateTime, and BuildContext.
///
/// Provides convenience accessors to reduce boilerplate throughout
/// the codebase.
library;

import 'package:flutter/material.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';

// ---- String Extensions ----

/// Convenience extensions on [String].
extension StringExtension on String {
  /// Capitalizes the first letter of the string.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Truncates the string to [maxLength] and appends an ellipsis if needed.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Returns the initials (up to 2 characters) from the string.
  ///
  /// Example: "John Doe" => "JD", "Alice" => "A"
  String get initials {
    if (isEmpty) return '';
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Deterministic color from the avatar palette based on the string hash.
  Color get avatarColor {
    if (isEmpty) return SanbaoColors.avatarPalette[0];
    final index = hashCode.abs() % SanbaoColors.avatarPalette.length;
    return SanbaoColors.avatarPalette[index];
  }

  /// Parses a hex color string (e.g., "#4F6EF7") into a [Color].
  Color? toColor() {
    try {
      final hex = replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Whether the string is a valid email address.
  bool get isValidEmail => RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(this);

  /// Whether the string is a valid URL.
  bool get isValidUrl {
    final uri = Uri.tryParse(this);
    return uri != null && uri.hasScheme && uri.hasAuthority;
  }

  /// Returns `null` if the string is empty, otherwise returns itself.
  String? get nullIfEmpty => isEmpty ? null : this;
}

// ---- DateTime Extensions ----

/// Convenience extensions on [DateTime].
extension DateTimeExtension on DateTime {
  /// Whether this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Whether this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Whether this date is within the current week (Mon-Sun).
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
        isBefore(endOfWeek);
  }

  /// Returns the number of full days since this date.
  int get daysAgo {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .difference(DateTime(year, month, day))
        .inDays;
  }

  /// Returns a time-only string (HH:mm).
  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

// ---- Nullable Extensions ----

/// Extension on nullable types for safe access.
extension NullableExtension<T> on T? {
  /// Applies [transform] if the value is non-null, otherwise returns null.
  R? let<R>(R Function(T value) transform) {
    final self = this;
    if (self != null) return transform(self);
    return null;
  }
}

// ---- BuildContext Extensions ----

/// Convenience extensions on [BuildContext] for accessing theme and media query.
extension ContextExtension on BuildContext {
  /// Shortcut to the current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Shortcut to the current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Shortcut to the current [ColorScheme].
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Shortcut to the Sanbao color scheme extension.
  SanbaoColorScheme get sanbaoColors =>
      Theme.of(this).extension<SanbaoColorScheme>()!;

  /// Shortcut to [MediaQueryData].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Bottom safe area padding (for notched devices).
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;

  /// Top safe area padding (for status bar).
  double get topPadding => MediaQuery.paddingOf(this).top;

  /// Whether the device is in dark mode.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Whether the screen width is considered "mobile" (< 600).
  bool get isMobile => screenWidth < 600;

  /// Whether the screen width is considered "tablet" (600-1024).
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;

  /// Whether the screen width is considered "desktop" (>= 1024).
  bool get isDesktop => screenWidth >= 1024;

  /// Shows a snackbar with the given message.
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          action: action,
        ),
      );
  }

  /// Shows an error snackbar.
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: sanbaoColors.error,
        ),
      );
  }

  /// Shows a success snackbar.
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: sanbaoColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}

// ---- List Extensions ----

/// Extensions on [List] for common operations.
extension ListExtension<T> on List<T> {
  /// Safely returns the element at [index], or null if out of bounds.
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}

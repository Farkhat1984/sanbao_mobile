/// Date and number formatting utilities.
///
/// Date formatting uses Russian labels by default, matching the
/// web project's `formatDate()` function with labels like
/// "Сегодня", "Вчера", "X дн. назад".
library;

import 'package:sanbao_flutter/core/utils/extensions.dart';

/// Formatting utilities for dates, numbers, and file sizes.
abstract final class Formatters {
  // ---- Date Formatting ----

  /// Formats a [DateTime] into a relative Russian date string.
  ///
  /// - Today: "Сегодня"
  /// - Yesterday: "Вчера"
  /// - 2-6 days ago: "X дн. назад"
  /// - This week: day of week name
  /// - Older: "DD.MM.YYYY"
  static String formatDate(DateTime date) {
    if (date.isToday) return 'Сегодня';
    if (date.isYesterday) return 'Вчера';

    final days = date.daysAgo;

    if (days >= 2 && days <= 6) {
      return '$days дн. назад';
    }

    if (date.isThisWeek) {
      return _dayOfWeekRu(date.weekday);
    }

    return _formatFullDate(date);
  }

  /// Formats a [DateTime] for chat group headers.
  ///
  /// Returns: "Сегодня", "Вчера", "Эта неделя", "Ранее"
  static String formatChatGroup(DateTime date) {
    if (date.isToday) return 'Сегодня';
    if (date.isYesterday) return 'Вчера';
    if (date.isThisWeek) return 'Эта неделя';
    return 'Ранее';
  }

  /// Formats a [DateTime] as a time string (HH:mm).
  static String formatTime(DateTime date) => date.timeString;

  /// Formats a [DateTime] as a full date-time string.
  ///
  /// Example: "15.02.2025 14:30"
  static String formatDateTime(DateTime date) =>
      '${_formatFullDate(date)} ${formatTime(date)}';

  /// Formats a [DateTime] as a relative time string.
  ///
  /// - < 1 minute: "только что"
  /// - < 1 hour: "X мин. назад"
  /// - < 24 hours: "X ч. назад"
  /// - Otherwise: delegates to [formatDate]
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'только что';
    if (diff.inHours < 1) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours} ч. назад';

    return formatDate(date);
  }

  // ---- Number Formatting ----

  /// Formats a large number with Russian thousands separators.
  ///
  /// Example: 1234567 => "1 234 567"
  static String formatNumber(int number) {
    final str = number.abs().toString();
    final buffer = StringBuffer();
    final sign = number < 0 ? '-' : '';

    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('\u00A0'); // Non-breaking space
      }
      buffer.write(str[i]);
    }

    return '$sign$buffer';
  }

  /// Formats a token count in a human-readable way.
  ///
  /// Example: 128000 => "128K", 1500000 => "1.5M"
  static String formatTokenCount(int count) {
    if (count >= 1000000) {
      final millions = count / 1000000;
      return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M';
    }
    if (count >= 1000) {
      final thousands = count / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}K';
    }
    return count.toString();
  }

  // ---- File Size ----

  /// Formats a file size in bytes to a human-readable string.
  ///
  /// Example: 1048576 => "1.0 MB"
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ---- Percentage ----

  /// Formats a percentage value (0-100).
  static String formatPercent(int percent) => '$percent%';

  // ---- Private Helpers ----

  static String _formatFullDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String _dayOfWeekRu(int weekday) => switch (weekday) {
        1 => 'Понедельник',
        2 => 'Вторник',
        3 => 'Среда',
        4 => 'Четверг',
        5 => 'Пятница',
        6 => 'Суббота',
        7 => 'Воскресенье',
        _ => '',
      };
}

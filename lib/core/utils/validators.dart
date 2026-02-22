/// Input validation utilities for forms.
///
/// Provides field-level validators compatible with [TextFormField.validator].
library;

import 'package:sanbao_flutter/core/config/app_config.dart';

/// Collection of form field validators.
abstract final class Validators {
  /// Validates an email address.
  ///
  /// Returns an error message string if invalid, or `null` if valid.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email обязателен';
    }
    final trimmed = value.trim();
    if (trimmed.length > 254) {
      return 'Email слишком длинный';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Некорректный формат email';
    }
    return null;
  }

  /// Validates a password.
  ///
  /// Requirements:
  /// - At least [AppConfig.passwordMinLength] characters
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one digit
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пароль обязателен';
    }
    if (value.length < AppConfig.passwordMinLength) {
      return 'Минимум ${AppConfig.passwordMinLength} символов';
    }
    if (!RegExp('[A-Z]').hasMatch(value)) {
      return 'Нужна хотя бы одна заглавная буква';
    }
    if (!RegExp('[a-z]').hasMatch(value)) {
      return 'Нужна хотя бы одна строчная буква';
    }
    if (!RegExp('[0-9]').hasMatch(value)) {
      return 'Нужна хотя бы одна цифра';
    }
    return null;
  }

  /// Validates password confirmation matches.
  static String? Function(String?) confirmPassword(String password) =>
      (value) {
        if (value == null || value.isEmpty) {
          return 'Подтверждение пароля обязательно';
        }
        if (value != password) {
          return 'Пароли не совпадают';
        }
        return null;
      };

  /// Validates a required field is not empty.
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "Поле"} обязательно';
    }
    return null;
  }

  /// Validates minimum length.
  static String? Function(String?) minLength(int min, {String? fieldName}) =>
      (value) {
        if (value == null || value.trim().isEmpty) {
          return '${fieldName ?? "Поле"} обязательно';
        }
        if (value.trim().length < min) {
          return 'Минимум $min символов';
        }
        return null;
      };

  /// Validates maximum length.
  static String? Function(String?) maxLength(int max, {String? fieldName}) =>
      (value) {
        if (value != null && value.length > max) {
          return 'Максимум $max символов';
        }
        return null;
      };

  /// Validates a conversation title.
  static String? conversationTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Название обязательно';
    }
    if (value.length > AppConfig.conversationTitleMaxLength) {
      return 'Максимум ${AppConfig.conversationTitleMaxLength} символов';
    }
    return null;
  }

  /// Validates a URL format.
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL обязателен';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Некорректный формат URL';
    }
    return null;
  }

  /// Chains multiple validators. Returns the first error found.
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) =>
      (value) {
        for (final validator in validators) {
          final error = validator(value);
          if (error != null) return error;
        }
        return null;
      };
}

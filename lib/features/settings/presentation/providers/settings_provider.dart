/// Riverpod providers for settings state management.
///
/// Manages theme mode, biometric lock, and notification preferences
/// using SharedPreferences for persistence.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---- Storage Keys ----

/// SharedPreferences keys for settings.
abstract final class _SettingsKeys {
  static const String themeMode = 'settings_theme_mode';
  static const String biometricEnabled = 'settings_biometric_enabled';
  static const String notificationsEnabled = 'settings_notifications_enabled';
  static const String chatNotifications = 'settings_chat_notifications';
  static const String updateNotifications = 'settings_update_notifications';
}

// ---- Theme Mode Provider ----

/// Notifier for the application theme mode.
///
/// Persists the selected theme mode to SharedPreferences.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_SettingsKeys.themeMode);
    if (modeIndex != null && modeIndex < ThemeMode.values.length) {
      state = ThemeMode.values[modeIndex];
    }
  }

  /// Sets the theme mode and persists it.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_SettingsKeys.themeMode, mode.index);
  }
}

/// Provider for the current theme mode.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// ---- Biometric Provider ----

/// Notifier for the biometric lock setting.
class BiometricEnabledNotifier extends StateNotifier<bool> {
  BiometricEnabledNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_SettingsKeys.biometricEnabled) ?? false;
  }

  /// Toggles the biometric lock setting.
  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_SettingsKeys.biometricEnabled, state);
  }

  /// Sets the biometric lock setting explicitly.
  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_SettingsKeys.biometricEnabled, enabled);
  }
}

/// Provider for the biometric lock setting.
final biometricEnabledProvider =
    StateNotifierProvider<BiometricEnabledNotifier, bool>((ref) {
  return BiometricEnabledNotifier();
});

// ---- Notification Settings Provider ----

/// State for notification preferences.
class NotificationSettings {
  const NotificationSettings({
    this.enabled = true,
    this.chatNotifications = true,
    this.updateNotifications = true,
  });

  /// Whether push notifications are enabled globally.
  final bool enabled;

  /// Whether chat message notifications are enabled.
  final bool chatNotifications;

  /// Whether app update notifications are enabled.
  final bool updateNotifications;

  /// Creates a copy with given fields replaced.
  NotificationSettings copyWith({
    bool? enabled,
    bool? chatNotifications,
    bool? updateNotifications,
  }) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        chatNotifications: chatNotifications ?? this.chatNotifications,
        updateNotifications: updateNotifications ?? this.updateNotifications,
      );
}

/// Notifier for notification preferences.
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      enabled: prefs.getBool(_SettingsKeys.notificationsEnabled) ?? true,
      chatNotifications:
          prefs.getBool(_SettingsKeys.chatNotifications) ?? true,
      updateNotifications:
          prefs.getBool(_SettingsKeys.updateNotifications) ?? true,
    );
  }

  /// Toggles the global notification setting.
  Future<void> toggleEnabled() async {
    state = state.copyWith(enabled: !state.enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_SettingsKeys.notificationsEnabled, state.enabled);
  }

  /// Toggles the chat notification setting.
  Future<void> toggleChatNotifications() async {
    state = state.copyWith(chatNotifications: !state.chatNotifications);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _SettingsKeys.chatNotifications,
      state.chatNotifications,
    );
  }

  /// Toggles the update notification setting.
  Future<void> toggleUpdateNotifications() async {
    state = state.copyWith(updateNotifications: !state.updateNotifications);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _SettingsKeys.updateNotifications,
      state.updateNotifications,
    );
  }
}

/// Provider for notification preferences.
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        (ref) {
  return NotificationSettingsNotifier();
});

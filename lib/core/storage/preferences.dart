/// SharedPreferences wrapper for non-sensitive user preferences.
///
/// Provides typed getters/setters for common app settings like
/// theme mode, locale, notification preferences, etc.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences entries.
abstract final class PrefKeys {
  static const String themeMode = 'sanbao_theme_mode';
  static const String locale = 'sanbao_locale';
  static const String onboardingCompleted = 'sanbao_onboarding_completed';
  static const String notificationsEnabled = 'sanbao_notifications_enabled';
  static const String hapticFeedback = 'sanbao_haptic_feedback';
  static const String textScale = 'sanbao_text_scale';
  static const String lastAgentId = 'sanbao_last_agent_id';
  static const String thinkingEnabled = 'sanbao_thinking_enabled';
  static const String webSearchEnabled = 'sanbao_web_search_enabled';
  static const String planningEnabled = 'sanbao_planning_enabled';
}

/// Service providing typed access to SharedPreferences.
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  // ---- Theme ----

  /// Gets the stored theme mode preference.
  ThemeMode get themeMode {
    final value = _prefs.getString(PrefKeys.themeMode);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Stores the theme mode preference.
  Future<bool> setThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return _prefs.setString(PrefKeys.themeMode, value);
  }

  // ---- Locale ----

  /// Gets the stored locale (language code).
  String get locale => _prefs.getString(PrefKeys.locale) ?? 'ru';

  /// Stores the locale preference.
  Future<bool> setLocale(String languageCode) =>
      _prefs.setString(PrefKeys.locale, languageCode);

  // ---- Onboarding ----

  /// Whether the onboarding flow has been completed.
  bool get isOnboardingCompleted =>
      _prefs.getBool(PrefKeys.onboardingCompleted) ?? false;

  /// Marks the onboarding flow as completed.
  Future<bool> setOnboardingCompleted() =>
      _prefs.setBool(PrefKeys.onboardingCompleted, true);

  // ---- Notifications ----

  /// Whether push notifications are enabled.
  bool get areNotificationsEnabled =>
      _prefs.getBool(PrefKeys.notificationsEnabled) ?? true;

  /// Sets the notification preference.
  Future<bool> setNotificationsEnabled({required bool enabled}) =>
      _prefs.setBool(PrefKeys.notificationsEnabled, enabled);

  // ---- Haptic Feedback ----

  /// Whether haptic feedback is enabled.
  bool get isHapticFeedbackEnabled =>
      _prefs.getBool(PrefKeys.hapticFeedback) ?? true;

  /// Sets the haptic feedback preference.
  Future<bool> setHapticFeedbackEnabled({required bool enabled}) =>
      _prefs.setBool(PrefKeys.hapticFeedback, enabled);

  // ---- Text Scale ----

  /// Gets the custom text scale factor (1.0 = default).
  double get textScale => _prefs.getDouble(PrefKeys.textScale) ?? 1.0;

  /// Sets the text scale factor.
  Future<bool> setTextScale(double scale) =>
      _prefs.setDouble(PrefKeys.textScale, scale);

  // ---- Last Agent ----

  /// Gets the last selected agent ID.
  String? get lastAgentId => _prefs.getString(PrefKeys.lastAgentId);

  /// Stores the last selected agent ID.
  Future<bool> setLastAgentId(String agentId) =>
      _prefs.setString(PrefKeys.lastAgentId, agentId);

  // ---- Chat Settings ----

  /// Whether thinking/reasoning mode is enabled.
  bool get isThinkingEnabled =>
      _prefs.getBool(PrefKeys.thinkingEnabled) ?? true;

  /// Sets the thinking mode preference.
  Future<bool> setThinkingEnabled({required bool enabled}) =>
      _prefs.setBool(PrefKeys.thinkingEnabled, enabled);

  /// Whether web search is enabled.
  bool get isWebSearchEnabled =>
      _prefs.getBool(PrefKeys.webSearchEnabled) ?? false;

  /// Sets the web search preference.
  Future<bool> setWebSearchEnabled({required bool enabled}) =>
      _prefs.setBool(PrefKeys.webSearchEnabled, enabled);

  /// Whether planning mode is enabled.
  bool get isPlanningEnabled =>
      _prefs.getBool(PrefKeys.planningEnabled) ?? false;

  /// Sets the planning mode preference.
  Future<bool> setPlanningEnabled({required bool enabled}) =>
      _prefs.setBool(PrefKeys.planningEnabled, enabled);

  // ---- Clear All ----

  /// Clears all stored preferences.
  Future<bool> clearAll() => _prefs.clear();
}

/// Riverpod provider for [SharedPreferences].
///
/// Must be overridden in the root ProviderScope with the actual
/// SharedPreferences instance obtained asynchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden '
    'with an initialized SharedPreferences instance.',
  ),
);

/// Riverpod provider for [PreferencesService].
final preferencesProvider = Provider<PreferencesService>(
  (ref) => PreferencesService(ref.watch(sharedPreferencesProvider)),
);

/// Onboarding state management provider.
///
/// Tracks whether the user has completed the onboarding flow
/// using [SharedPreferences] for persistence across app restarts.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/storage/preferences.dart';

/// Provider that exposes whether onboarding has been completed.
///
/// Reads from [PreferencesService] on first access. The UI checks
/// this to decide whether to show the onboarding screen or redirect
/// to the main chat.
final onboardingCompletedProvider = StateNotifierProvider<
    OnboardingCompletedNotifier, bool>(
  (ref) => OnboardingCompletedNotifier(ref.watch(preferencesProvider)),
);

/// Manages the onboarding completion state.
///
/// Persists the completed flag to [SharedPreferences] so the
/// onboarding screen is only shown once per device.
class OnboardingCompletedNotifier extends StateNotifier<bool> {
  OnboardingCompletedNotifier(this._prefs)
      : super(_prefs.isOnboardingCompleted);

  final PreferencesService _prefs;

  /// Marks onboarding as complete and persists the flag.
  Future<void> complete() async {
    await _prefs.setOnboardingCompleted();
    state = true;
  }
}

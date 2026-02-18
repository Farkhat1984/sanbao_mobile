/// Voice input state management via Riverpod.
///
/// Provides speech recognition state, availability checking,
/// and permission status tracking for the voice input feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Whether the device supports speech recognition.
///
/// Initializes the speech engine once and caches the result.
/// Returns `false` if speech-to-text is unavailable or initialization fails.
final speechAvailableProvider = FutureProvider<bool>((ref) async {
  try {
    final speech = SpeechToText();
    return await speech.initialize();
  } on Object {
    return false;
  }
});

/// Current microphone permission status.
///
/// Checks the current permission without requesting it.
/// Use [requestMicrophonePermission] to trigger the permission dialog.
final microphonePermissionProvider =
    FutureProvider<PermissionStatus>((ref) => Permission.microphone.status);

/// Requests microphone permission and returns the resulting status.
///
/// This is a family provider keyed on a dummy value to allow re-invocation.
/// Pass a unique value (e.g., timestamp) each time to force a new request.
final requestMicrophonePermissionProvider =
    FutureProvider.family<PermissionStatus, int>(
  (ref, _) => Permission.microphone.request(),
);

/// Whether voice recording is currently active.
///
/// Set by the [VoiceButton] widget when recording starts/stops.
/// Other widgets can watch this to adjust their behavior during recording
/// (e.g., changing hint text, disabling other inputs).
final isVoiceRecordingProvider = StateProvider<bool>((ref) => false);

/// The most recent partial recognition result.
///
/// Updated in real-time as the speech engine recognizes words.
/// Useful for showing live transcription preview in the UI.
final partialRecognitionProvider = StateProvider<String?>((ref) => null);

/// The current state of the voice input session.
///
/// Tracks the lifecycle from idle -> listening -> processing -> idle.
final voiceSessionStateProvider =
    StateProvider<VoiceSessionState>((ref) => VoiceSessionState.idle);

/// Possible states for a voice input session.
enum VoiceSessionState {
  /// No voice session in progress.
  idle,

  /// Microphone is active, listening for speech.
  listening,

  /// Speech recognized, processing final result.
  processing,

  /// An error occurred during the session.
  error,
}

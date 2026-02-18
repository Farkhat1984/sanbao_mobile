/// Debounce utility for rate-limiting rapid calls.
///
/// Commonly used for search-as-you-type, resize handlers,
/// and preventing rapid button taps.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Delays the execution of a callback until after a specified duration
/// has elapsed since the last invocation.
///
/// Usage:
/// ```dart
/// final debouncer = Debouncer(duration: Duration(milliseconds: 300));
///
/// // In a text field's onChanged:
/// onChanged: (value) {
///   debouncer.run(() => searchApi(value));
/// }
///
/// // Dispose when no longer needed:
/// debouncer.dispose();
/// ```
class Debouncer {
  Debouncer({
    this.duration = const Duration(milliseconds: 300),
  });

  /// The delay before the callback is executed.
  final Duration duration;

  Timer? _timer;

  /// Whether the debouncer currently has a pending callback.
  bool get isActive => _timer?.isActive ?? false;

  /// Schedules [action] to run after [duration].
  ///
  /// If called again before the duration elapses, the previous
  /// scheduled action is cancelled and a new one is scheduled.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Schedules an async [action] to run after [duration].
  ///
  /// Returns a [Future] that completes when the action executes.
  Future<T> runAsync<T>(Future<T> Function() action) {
    _timer?.cancel();
    final completer = Completer<T>();

    _timer = Timer(duration, () async {
      try {
        final result = await action();
        completer.complete(result);
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  /// Cancels any pending callback.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Disposes the debouncer, cancelling any pending callback.
  void dispose() {
    cancel();
  }
}

/// A throttler that ensures a callback runs at most once per [duration].
///
/// Unlike [Debouncer], this executes the first call immediately
/// and ignores subsequent calls within the window.
class Throttler {
  Throttler({
    this.duration = const Duration(milliseconds: 300),
  });

  /// The minimum interval between executions.
  final Duration duration;

  DateTime? _lastExecutionTime;

  /// Executes [action] immediately if enough time has passed,
  /// otherwise ignores the call.
  void run(VoidCallback action) {
    final now = DateTime.now();

    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!) >= duration) {
      _lastExecutionTime = now;
      action();
    }
  }

  /// Resets the throttler, allowing the next call to execute immediately.
  void reset() {
    _lastExecutionTime = null;
  }
}

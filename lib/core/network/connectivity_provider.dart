/// Network connectivity monitoring with Riverpod.
///
/// Provides reactive online/offline state via [connectivityStatusProvider].
/// Uses the `connectivity_plus` package to listen for network changes and
/// performs a lightweight reachability check to confirm actual internet access.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';

import 'connectivity_reachability.dart'
    if (dart.library.html) 'connectivity_reachability_web.dart' as reachability;

/// Represents the application's current network connectivity state.
enum ConnectivityStatus {
  /// The device is connected to the internet.
  online,

  /// The device has no internet access.
  offline;

  /// Whether the device is currently online.
  bool get isOnline => this == ConnectivityStatus.online;

  /// Whether the device is currently offline.
  bool get isOffline => this == ConnectivityStatus.offline;
}

/// Monitors network connectivity changes and exposes a reactive stream.
///
/// Combines the `connectivity_plus` transport-level events with an actual
/// reachability check (DNS lookup) to avoid false positives when the device
/// is connected to Wi-Fi but has no internet.
class ConnectivityMonitor {
  ConnectivityMonitor({
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Duration to debounce connectivity change events.
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  /// Timeout for the reachability check.
  static const Duration _reachabilityTimeout = Duration(seconds: 5);

  /// Returns a stream of [ConnectivityStatus] that emits whenever the
  /// network state changes. The initial value is determined immediately.
  Stream<ConnectivityStatus> get statusStream =>
      _connectivity.onConnectivityChanged
          .transform(const _DebounceTransformer<List<ConnectivityResult>>(
            _debounceDuration,
          ),)
          .asyncMap(_evaluateConnectivity);

  /// Performs a one-shot connectivity check.
  Future<ConnectivityStatus> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    return _evaluateConnectivity(results);
  }

  /// Evaluates connectivity by checking both the transport layer and
  /// actual reachability.
  Future<ConnectivityStatus> _evaluateConnectivity(
    List<ConnectivityResult> results,
  ) async {
    // If all results indicate no connectivity, we are offline
    if (results.every((r) => r == ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }

    // Transport says we have a connection -- verify with a reachability check
    return _checkReachability();
  }

  /// Performs a lightweight reachability check to verify actual internet access.
  ///
  /// On native: DNS lookup via dart:io.
  /// On web: assumes online (browser handles connectivity).
  Future<ConnectivityStatus> _checkReachability() async {
    try {
      final uri = Uri.tryParse(AppConfig.baseUrl);
      final host = uri?.host ?? 'google.com';

      final isReachable = await reachability
          .checkHost(host)
          .timeout(_reachabilityTimeout);

      return isReachable
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;
    } on TimeoutException {
      return ConnectivityStatus.offline;
    } catch (_) {
      return ConnectivityStatus.offline;
    }
  }
}

/// Stream transformer that debounces events by [duration].
///
/// Only emits the latest event after [duration] has passed without
/// new events arriving. This prevents rapid-fire connectivity changes
/// from causing excessive reachability checks.
class _DebounceTransformer<T> extends StreamTransformerBase<T, T> {
  const _DebounceTransformer(this.duration);

  final Duration duration;

  @override
  Stream<T> bind(Stream<T> stream) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    Timer? debounceTimer;

    controller = StreamController<T>(
      onListen: () {
        subscription = stream.listen(
          (data) {
            debounceTimer?.cancel();
            debounceTimer = Timer(duration, () {
              if (!controller.isClosed) {
                controller.add(data);
              }
            });
          },
          onError: controller.addError,
          onDone: () {
            debounceTimer?.cancel();
            controller.close();
          },
        );
      },
      onCancel: () {
        debounceTimer?.cancel();
        subscription?.cancel();
      },
    );

    return controller.stream;
  }
}

// ---- Riverpod Providers ----

/// Provides a singleton [ConnectivityMonitor] instance.
final connectivityMonitorProvider = Provider<ConnectivityMonitor>(
  (ref) => ConnectivityMonitor(),
);

/// Reactive stream of [ConnectivityStatus] changes.
///
/// Widgets can watch this provider to respond to connectivity changes.
/// The stream is automatically managed by Riverpod's lifecycle.
///
/// Usage:
/// ```dart
/// final status = ref.watch(connectivityStatusProvider);
/// status.when(
///   data: (s) => s.isOnline ? onlineWidget : offlineWidget,
///   loading: () => loadingWidget,
///   error: (_, __) => offlineWidget,
/// );
/// ```
final connectivityStatusProvider =
    StreamProvider<ConnectivityStatus>((ref) async* {
  final monitor = ref.watch(connectivityMonitorProvider);

  // Emit the initial status immediately
  final initial = await monitor.checkNow();
  yield initial;

  // Then yield changes from the stream
  yield* monitor.statusStream;
});

/// Convenience provider that returns a simple boolean for online status.
///
/// Defaults to `true` when the status is loading (optimistic assumption)
/// so that the app doesn't block on startup.
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  return status.when(
    data: (s) => s.isOnline,
    loading: () => true, // Optimistic default
    error: (_, __) => false,
  );
});

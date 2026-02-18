/// Background polling service for notifications.
///
/// Uses a periodic timer to check for new notifications while
/// the app is in the foreground. Designed to be started after
/// successful login and stopped on logout.
///
/// This service does NOT depend on Firebase or push notifications.
/// It polls the server at a configurable interval and notifies
/// listeners when the unread count changes. Can be extended with
/// FCM support in the future without modifying consumers.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:sanbao_flutter/features/notifications/domain/repositories/notification_repository.dart';

/// Interval between notification polling requests.
const Duration _kPollingInterval = Duration(seconds: 30);

/// Service that periodically polls the server for new notifications.
///
/// Lifecycle:
/// 1. Call [start] after successful authentication.
/// 2. The service polls every 30 seconds and updates [unreadCount].
/// 3. Call [stop] on logout or when the app goes to background.
/// 4. Listeners on [onUnreadCountChanged] are notified when the count changes.
///
/// Usage via Riverpod:
/// ```dart
/// final service = ref.read(notificationPollingServiceProvider);
/// service.start();
/// ```
class NotificationPollingService with WidgetsBindingObserver {
  NotificationPollingService({
    required NotificationRepository repository,
  }) : _repository = repository;

  final NotificationRepository _repository;
  Timer? _timer;
  bool _isRunning = false;
  int _lastUnreadCount = 0;

  /// Stream controller for unread count changes.
  final _unreadCountController = StreamController<int>.broadcast();

  /// Stream of unread count updates.
  ///
  /// Emits a new value whenever the unread count changes from the
  /// previously known value.
  Stream<int> get onUnreadCountChanged => _unreadCountController.stream;

  /// The last known unread count.
  int get lastUnreadCount => _lastUnreadCount;

  /// Whether the polling service is currently running.
  bool get isRunning => _isRunning;

  /// Starts periodic polling for new notifications.
  ///
  /// If already running, this is a no-op. Immediately performs
  /// one poll, then schedules repeating polls at [_kPollingInterval].
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    debugPrint('[NotificationPolling] Started');

    // Register as app lifecycle observer to pause/resume on background
    WidgetsBinding.instance.addObserver(this);

    // Perform an immediate poll
    _poll();

    // Schedule periodic polls
    _timer = Timer.periodic(_kPollingInterval, (_) => _poll());
  }

  /// Stops periodic polling and releases resources.
  ///
  /// Safe to call even if not running.
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _timer?.cancel();
    _timer = null;
    _lastUnreadCount = 0;

    WidgetsBinding.instance.removeObserver(this);

    debugPrint('[NotificationPolling] Stopped');
  }

  /// Disposes the service and its stream controller.
  ///
  /// Must be called when the service is no longer needed.
  void dispose() {
    stop();
    _unreadCountController.close();
  }

  /// Triggers a single poll immediately.
  ///
  /// Can be called externally to force a refresh (e.g., after
  /// receiving a push notification or returning from background).
  Future<void> pollNow() => _poll();

  /// Handles app lifecycle state changes.
  ///
  /// Pauses polling when the app goes to background to conserve
  /// battery and bandwidth. Resumes and polls immediately when
  /// the app returns to foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground -- restart polling and check immediately
        if (_isRunning && _timer == null) {
          debugPrint('[NotificationPolling] Resumed -- polling now');
          _poll();
          _timer = Timer.periodic(_kPollingInterval, (_) => _poll());
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background -- pause timer to save battery
        _timer?.cancel();
        _timer = null;
        debugPrint('[NotificationPolling] Paused (app backgrounded)');
    }
  }

  /// Performs a single poll to check the unread notification count.
  Future<void> _poll() async {
    if (!_isRunning) return;

    try {
      final count = await _repository.getUnreadCount();

      if (count != _lastUnreadCount) {
        _lastUnreadCount = count;
        _unreadCountController.add(count);
        debugPrint('[NotificationPolling] Unread count changed: $count');
      }
    } on Object catch (e) {
      // Silently ignore polling errors to avoid spamming the user.
      // The main notification list will show proper error UI if needed.
      debugPrint('[NotificationPolling] Poll failed: $e');
    }
  }
}

/// Riverpod provider for the [NotificationPollingService].
///
/// The service is created once and shared across the app.
/// It must be started explicitly via [NotificationPollingService.start]
/// after authentication and stopped via [stop] on logout.
final notificationPollingServiceProvider =
    Provider<NotificationPollingService>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final service = NotificationPollingService(repository: repository);

  // Clean up when the provider is disposed (e.g., on hot restart)
  ref.onDispose(service.dispose);

  return service;
});

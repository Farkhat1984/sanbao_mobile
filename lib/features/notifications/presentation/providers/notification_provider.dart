/// Notification list, unread count, and state providers.
///
/// Manages the notifications list, unread count badge,
/// mark-as-read, delete, and polling lifecycle.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:sanbao_flutter/features/notifications/data/services/notification_polling_service.dart';
import 'package:sanbao_flutter/features/notifications/domain/entities/notification.dart';

// ---- Notification List ----

/// The raw notifications list, auto-refreshable.
final notificationsListProvider = AsyncNotifierProvider<
    NotificationsListNotifier, List<AppNotification>>(
  NotificationsListNotifier.new,
);

/// Notifier for the notifications list.
///
/// Provides methods for refreshing, marking as read, deleting,
/// and integrating with the polling service for automatic
/// refresh when new notifications arrive.
class NotificationsListNotifier
    extends AsyncNotifier<List<AppNotification>> {
  StreamSubscription<int>? _pollingSubscription;

  @override
  Future<List<AppNotification>> build() async {
    final repo = ref.watch(notificationRepositoryProvider);

    // Listen to the polling service for unread count changes.
    // When the count changes, refresh the list to pick up new items.
    final pollingService = ref.read(notificationPollingServiceProvider);
    unawaited(_pollingSubscription?.cancel());
    _pollingSubscription = pollingService.onUnreadCountChanged.listen((_) {
      unawaited(_silentRefresh());
    });

    // Clean up subscription when provider is disposed
    ref.onDispose(() {
      _pollingSubscription?.cancel();
      _pollingSubscription = null;
    });

    return repo.getAll();
  }

  /// Refreshes the notifications list from the server.
  ///
  /// Shows loading state while fetching.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(notificationRepositoryProvider);
      return repo.getAll();
    });
  }

  /// Silently refreshes the list without showing loading state.
  ///
  /// Used by the polling service to update the list in the
  /// background without disrupting the user's view.
  Future<void> _silentRefresh() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final notifications = await repo.getAll();
      state = AsyncData(notifications);
    } on Object catch (e) {
      debugPrint('[NotificationsNotifier] Silent refresh failed: $e');
      // Do not update state on silent refresh failure
    }
  }

  /// Marks a single notification as read.
  ///
  /// Uses optimistic update: marks as read immediately in the UI,
  /// then sends the request. Reverts on failure.
  Future<void> markAsRead(String id) async {
    final current = state.valueOrNull ?? [];
    final originalItem = current.firstWhere(
      (n) => n.id == id,
      orElse: () => current.first,
    );

    // Optimistic update
    state = AsyncData(
      current
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAsRead(id);
    } on Object {
      // Revert on failure
      state = AsyncData(
        (state.valueOrNull ?? [])
            .map(
              (n) => n.id == id
                  ? n.copyWith(isRead: originalItem.isRead)
                  : n,
            )
            .toList(),
      );
    }
  }

  /// Marks all notifications as read.
  ///
  /// Uses optimistic update: marks all as read immediately,
  /// then sends the request. Reverts on failure.
  Future<void> markAllAsRead() async {
    final current = state.valueOrNull ?? [];

    // Optimistic update
    state = AsyncData(
      current.map((n) => n.copyWith(isRead: true)).toList(),
    );

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllAsRead();
    } on Object {
      // Revert on failure
      state = AsyncData(current);
    }
  }

  /// Deletes a notification by [id].
  ///
  /// Uses optimistic update: removes from the list immediately,
  /// then sends the delete request. Reverts on failure.
  Future<bool> delete(String id) async {
    final current = state.valueOrNull ?? [];
    final removedIndex = current.indexWhere((n) => n.id == id);

    if (removedIndex == -1) return false;

    final removedItem = current[removedIndex];

    // Optimistic removal
    state = AsyncData(
      current.where((n) => n.id != id).toList(),
    );

    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.delete(id);
      return true;
    } on Object {
      // Revert: insert back at original position
      final reverted = [...(state.valueOrNull ?? [])];
      final insertAt = removedIndex.clamp(0, reverted.length);
      reverted.insert(insertAt, removedItem);
      state = AsyncData(reverted);
      return false;
    }
  }
}

// ---- Unread Count ----

/// Number of unread notifications.
///
/// Derived from the notifications list to ensure consistency
/// between the list view and the badge count.
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsListProvider);
  return notifications.valueOrNull
          ?.where((n) => !n.isRead)
          .length ??
      0;
});

/// Whether there are any unread notifications.
final hasUnreadNotificationsProvider = Provider<bool>(
  (ref) => ref.watch(unreadNotificationCountProvider) > 0,
);

// ---- Polling Lifecycle ----

/// Starts the notification polling service.
///
/// Call this after successful authentication. Safe to call
/// multiple times -- subsequent calls are no-ops.
void startNotificationPolling(WidgetRef ref) {
  ref.read(notificationPollingServiceProvider).start();

  // Also do an initial load of the notifications list
  ref.invalidate(notificationsListProvider);
}

/// Starts the notification polling service (Reader version).
///
/// For use in contexts where only a [Ref] is available
/// (e.g., inside providers or notifiers).
void startNotificationPollingRef(Ref ref) {
  ref.read(notificationPollingServiceProvider).start();

  // Also do an initial load of the notifications list
  ref.invalidate(notificationsListProvider);
}

/// Stops the notification polling service.
///
/// Call this on logout. Clears the last known count.
void stopNotificationPolling(WidgetRef ref) {
  ref.read(notificationPollingServiceProvider).stop();
}

/// Stops the notification polling service (Reader version).
void stopNotificationPollingRef(Ref ref) {
  ref.read(notificationPollingServiceProvider).stop();
}

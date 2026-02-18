/// Task list and detail state providers.
///
/// Manages the task list, status filtering, and task details.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:sanbao_flutter/features/tasks/domain/entities/task.dart';
import 'package:sanbao_flutter/features/tasks/domain/repositories/task_repository.dart';

// ---- Task List ----

/// The raw tasks list, auto-refreshable.
final taskListProvider =
    AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);

/// Notifier for the tasks list with refresh and delete.
class TaskListNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final repo = ref.watch(taskRepositoryProvider);
    return repo.getAll();
  }

  /// Refreshes the tasks list from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(taskRepositoryProvider);
      return repo.getAll();
    });
  }

  /// Deletes a task from the list.
  Future<void> deleteTask(String id) async {
    final current = state.valueOrNull ?? [];
    final task = current.where((t) => t.id == id).firstOrNull;

    // Optimistic removal
    state = AsyncData(current.where((t) => t.id != id).toList());

    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.delete(id);
    } on Object {
      if (task != null) {
        state = AsyncData([...state.valueOrNull ?? [], task]);
      }
    }
  }
}

// ---- Task Detail ----

/// Provider for a specific task's details.
final taskDetailProvider =
    FutureProvider.autoDispose.family<Task?, String>((ref, id) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getById(id);
});

// ---- Status Filter ----

/// Active task status filter. Null means all statuses.
final taskStatusFilterProvider = StateProvider<TaskStatus?>((ref) => null);

/// Filtered tasks based on status filter.
final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasks = ref.watch(taskListProvider);
  final statusFilter = ref.watch(taskStatusFilterProvider);

  return tasks.whenData(
    (list) => list
        .where((t) => statusFilter == null || t.status == statusFilter)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );
});

/// Count of currently running tasks.
final runningTaskCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(taskListProvider);
  return tasks.valueOrNull
          ?.where((t) => t.status == TaskStatus.running)
          .length ??
      0;
});

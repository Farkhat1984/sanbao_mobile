/// Abstract task repository contract.
///
/// Defines operations for fetching and managing background tasks.
library;

import 'package:sanbao_flutter/features/tasks/domain/entities/task.dart';

/// Abstract repository for task operations.
abstract class TaskRepository {
  /// Fetches all tasks for the current user.
  Future<List<Task>> getAll();

  /// Fetches a single task by [id] with full step details.
  Future<Task?> getById(String id);

  /// Deletes a task by [id].
  Future<void> delete(String id);
}

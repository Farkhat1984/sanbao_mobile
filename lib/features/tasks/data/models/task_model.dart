/// Task data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [Task] entity.
library;

import 'package:sanbao_flutter/features/tasks/data/models/task_step_model.dart';
import 'package:sanbao_flutter/features/tasks/domain/entities/task.dart';

/// Data model for [Task] with JSON serialization support.
class TaskModel {
  const TaskModel._({required this.task});

  /// Creates a model from an API JSON response.
  factory TaskModel.fromJson(Map<String, Object?> json) {
    final stepsJson = json['steps'] as List<Object?>?;
    final statusStr = json['status'] as String? ?? 'pending';

    return TaskModel._(
      task: Task(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        status: _parseStatus(statusStr),
        steps: stepsJson != null
            ? TaskStepModel.fromJsonList(stepsJson)
            : const [],
        progress: ((json['progress'] as num?)?.toDouble() ?? 0.0) / 100.0,
        conversationId: json['conversationId'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      ),
    );
  }

  /// The underlying domain entity.
  final Task task;

  /// Parses a list of task JSON objects.
  static List<Task> fromJsonList(List<Object?> jsonList) => jsonList
      .whereType<Map<String, Object?>>()
      .map((json) => TaskModel.fromJson(json).task)
      .toList();

  static TaskStatus _parseStatus(String status) =>
      switch (status.toUpperCase()) {
        'RUNNING' || 'IN_PROGRESS' => TaskStatus.running,
        'COMPLETED' => TaskStatus.completed,
        'FAILED' => TaskStatus.failed,
        'PAUSED' || 'PENDING' => TaskStatus.pending,
        _ => TaskStatus.pending,
      };
}

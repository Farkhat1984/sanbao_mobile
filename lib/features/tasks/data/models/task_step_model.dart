/// TaskStep data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [TaskStep] entity.
library;

import 'package:sanbao_flutter/features/tasks/domain/entities/task_step.dart';

/// Data model for [TaskStep] with JSON serialization support.
class TaskStepModel {
  const TaskStepModel._({required this.step});

  /// Creates a model from an API JSON response.
  factory TaskStepModel.fromJson(Map<String, Object?> json) {
    final statusStr = json['status'] as String? ?? 'pending';

    return TaskStepModel._(
      step: TaskStep(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        status: _parseStatus(statusStr),
        output: json['output'] as String?,
      ),
    );
  }

  /// The underlying domain entity.
  final TaskStep step;

  /// Parses a list of task step JSON objects.
  static List<TaskStep> fromJsonList(List<Object?> jsonList) => jsonList
      .whereType<Map<String, Object?>>()
      .map((json) => TaskStepModel.fromJson(json).step)
      .toList();

  static TaskStepStatus _parseStatus(String status) =>
      switch (status.toLowerCase()) {
        'running' => TaskStepStatus.running,
        'completed' => TaskStepStatus.completed,
        'failed' => TaskStepStatus.failed,
        _ => TaskStepStatus.pending,
      };
}

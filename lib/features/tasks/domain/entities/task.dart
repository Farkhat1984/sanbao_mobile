/// Task entity representing an AI-driven background task.
///
/// Tasks track long-running AI operations with step-by-step
/// progress and status updates.
library;

import 'package:sanbao_flutter/features/tasks/domain/entities/task_step.dart';

/// Status of a background task.
enum TaskStatus {
  /// Task is queued but not yet started.
  pending,

  /// Task is currently executing.
  running,

  /// Task completed successfully.
  completed,

  /// Task failed during execution.
  failed,
}

/// A background task with execution tracking.
///
/// Tasks represent long-running operations (document generation,
/// analysis, batch processing) with step-by-step progress.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.description,
    this.steps = const [],
    this.progress = 0.0,
    this.conversationId,
  });

  /// Unique task identifier.
  final String id;

  /// Display title of the task.
  final String title;

  /// Optional detailed description.
  final String? description;

  /// Current execution status.
  final TaskStatus status;

  /// Ordered list of execution steps.
  final List<TaskStep> steps;

  /// Overall progress from 0.0 to 1.0.
  final double progress;

  /// Associated conversation ID (if triggered from chat).
  final String? conversationId;

  /// When the task was created.
  final DateTime createdAt;

  /// Human-readable status label in Russian.
  String get statusLabel => switch (status) {
        TaskStatus.pending => 'Ожидание',
        TaskStatus.running => 'Выполняется',
        TaskStatus.completed => 'Завершена',
        TaskStatus.failed => 'Ошибка',
      };

  /// Number of completed steps.
  int get completedStepCount =>
      steps.where((s) => s.status == TaskStepStatus.completed).length;

  /// Progress as a percentage (0-100).
  int get progressPercent => (progress * 100).round();

  /// Creates a copy with modified fields.
  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    List<TaskStep>? steps,
    double? progress,
    String? conversationId,
    DateTime? createdAt,
  }) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        steps: steps ?? this.steps,
        progress: progress ?? this.progress,
        conversationId: conversationId ?? this.conversationId,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Task(id=$id, title=$title, status=$status)';
}

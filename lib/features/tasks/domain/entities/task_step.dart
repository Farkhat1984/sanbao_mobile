/// Task step entity representing a single step within a task.
///
/// Each task is composed of sequential steps that track
/// individual operations.
library;

/// Status of a task step.
enum TaskStepStatus {
  /// Step has not started yet.
  pending,

  /// Step is currently executing.
  running,

  /// Step completed successfully.
  completed,

  /// Step failed.
  failed,
}

/// A single step within a task's execution plan.
///
/// Steps provide granular progress tracking for complex
/// multi-step operations.
class TaskStep {
  const TaskStep({
    required this.id,
    required this.title,
    required this.status,
    this.output,
  });

  /// Unique step identifier.
  final String id;

  /// Display title describing what this step does.
  final String title;

  /// Current execution status.
  final TaskStepStatus status;

  /// Output produced by this step (if completed).
  final String? output;

  /// Human-readable status label in Russian.
  String get statusLabel => switch (status) {
        TaskStepStatus.pending => 'Ожидание',
        TaskStepStatus.running => 'Выполняется',
        TaskStepStatus.completed => 'Завершен',
        TaskStepStatus.failed => 'Ошибка',
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStep && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

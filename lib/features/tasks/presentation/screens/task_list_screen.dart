/// Task list screen with status filters and progress indicators.
///
/// Displays all tasks with status-based filtering, progress bars,
/// and expandable step details.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/empty_state.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_modal.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/tasks/domain/entities/task.dart';
import 'package:sanbao_flutter/features/tasks/presentation/providers/task_provider.dart';
import 'package:sanbao_flutter/features/tasks/presentation/widgets/task_item.dart';
import 'package:sanbao_flutter/features/tasks/presentation/widgets/task_progress.dart';
import 'package:sanbao_flutter/features/tasks/presentation/widgets/task_step_list.dart';

/// Screen displaying all tasks with status filtering.
///
/// Shows tasks in a list with status filter chips at the top.
/// Tapping a task opens a detail bottom sheet with step info.
class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  void _openTaskDetail(Task task) {
    showSanbaoBottomSheet<void>(
      context: context,
      builder: (context) => _TaskDetailSheet(taskId: task.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final filteredTasks = ref.watch(filteredTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(taskListProvider.notifier).refresh(),
        color: colors.accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildStatusFilters(colors)),
            filteredTasks.when(
              loading: () =>
                  SliverToBoxAdapter(child: _TaskListSkeleton()),
              error: (_, __) => SliverToBoxAdapter(
                child: EmptyState.error(
                  message: 'Не удалось загрузить задачи',
                  onRetry: () =>
                      ref.read(taskListProvider.notifier).refresh(),
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.task_alt_outlined,
                      title: 'Нет задач',
                      message: 'Задачи появятся, когда AI начнет выполнять длительные операции',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskItem(
                        task: task,
                        onTap: () => _openTaskDetail(task),
                      );
                    },
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters(SanbaoColorScheme colors) {
    final selectedStatus = ref.watch(taskStatusFilterProvider);

    final filters = <(String label, TaskStatus? status)>[
      ('Все', null),
      ('Выполняются', TaskStatus.running),
      ('Завершены', TaskStatus.completed),
      ('Ожидание', TaskStatus.pending),
      ('Ошибки', TaskStatus.failed),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, status) = filters[index];
          final isSelected = selectedStatus == status;

          return GestureDetector(
            onTap: () => ref
                .read(taskStatusFilterProvider.notifier)
                .state = status,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.accentLight
                    : colors.bgSurfaceAlt,
                borderRadius: SanbaoRadius.md,
                border: Border.all(
                  color: isSelected ? colors.accent : colors.border,
                  width: isSelected ? 1 : 0.5,
                ),
              ),
              child: Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? colors.accent
                      : colors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bottom sheet displaying task detail with steps.
class _TaskDetailSheet extends ConsumerWidget {
  const _TaskDetailSheet({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));
    final colors = context.sanbaoColors;

    return SanbaoBottomSheetContent(
      title: 'Детали задачи',
      child: taskAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => EmptyState.error(
          message: 'Не удалось загрузить детали задачи',
        ),
        data: (task) {
          if (task == null) {
            return const EmptyState(message: 'Задача не найдена');
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with progress
                Row(
                  children: [
                    TaskProgress(task: task, size: 56),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style:
                                context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.statusLabel,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (task.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    task.description!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Steps
                TaskStepList(steps: task.steps),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TaskListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SanbaoSkeleton.box(height: 90),
            ),
          ),
        ),
      );
}

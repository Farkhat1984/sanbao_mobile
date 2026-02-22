/// Remote data source for task operations.
///
/// Handles GET/DELETE calls to /api/tasks.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/tasks/data/models/task_model.dart';
import 'package:sanbao_flutter/features/tasks/domain/entities/task.dart';

/// Remote data source for task operations via the REST API.
class TaskRemoteDataSource {
  TaskRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Fetches all tasks for the current user.
  ///
  /// GET /api/tasks → JSON array of task objects.
  Future<List<Task>> getAll() async {
    final response = await _dioClient.get<List<dynamic>>(
      AppConfig.tasksEndpoint,
    );

    return TaskModel.fromJsonList(response.cast<Object?>());
  }

  /// Fetches a single task by [id] with full step details.
  Future<Task?> getById(String id) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '${AppConfig.tasksEndpoint}/$id',
    );

    final taskJson = response.containsKey('task')
        ? response['task'] as Map<String, Object?>? ?? response
        : response;

    return TaskModel.fromJson(taskJson).task;
  }

  /// Deletes a task by [id].
  Future<void> delete(String id) async {
    await _dioClient.delete<Map<String, Object?>>(
      '${AppConfig.tasksEndpoint}/$id',
    );
  }
}

/// Riverpod provider for [TaskRemoteDataSource].
final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return TaskRemoteDataSource(dioClient: dioClient);
});

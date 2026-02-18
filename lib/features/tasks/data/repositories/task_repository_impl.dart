/// Implementation of the task repository.
///
/// Delegates to the remote data source for all operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:sanbao_flutter/features/tasks/domain/entities/task.dart';
import 'package:sanbao_flutter/features/tasks/domain/repositories/task_repository.dart';

/// Concrete implementation of [TaskRepository].
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({required TaskRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final TaskRemoteDataSource _remoteDataSource;

  @override
  Future<List<Task>> getAll() => _remoteDataSource.getAll();

  @override
  Future<Task?> getById(String id) => _remoteDataSource.getById(id);

  @override
  Future<void> delete(String id) => _remoteDataSource.delete(id);
}

/// Riverpod provider for [TaskRepository].
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final remoteDataSource = ref.watch(taskRemoteDataSourceProvider);
  return TaskRepositoryImpl(remoteDataSource: remoteDataSource);
});

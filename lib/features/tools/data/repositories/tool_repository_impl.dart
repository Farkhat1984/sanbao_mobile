/// Implementation of the tool repository.
///
/// Delegates to the remote data source for all operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/tools/data/datasources/tool_remote_datasource.dart';
import 'package:sanbao_flutter/features/tools/domain/entities/tool.dart';
import 'package:sanbao_flutter/features/tools/domain/repositories/tool_repository.dart';

/// Concrete implementation of [ToolRepository].
class ToolRepositoryImpl implements ToolRepository {
  ToolRepositoryImpl({required ToolRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final ToolRemoteDataSource _remoteDataSource;

  @override
  Future<List<Tool>> getAll() => _remoteDataSource.getAll();

  @override
  Future<Tool?> getById(String id) => _remoteDataSource.getById(id);

  @override
  Future<Tool> create({
    required String name,
    required ToolType type,
    String? description,
    Map<String, Object?>? config,
  }) =>
      _remoteDataSource.create(
        name: name,
        type: type,
        description: description,
        config: config,
      );

  @override
  Future<Tool> update({
    required String id,
    String? name,
    String? description,
    ToolType? type,
    Map<String, Object?>? config,
    bool? isEnabled,
  }) =>
      _remoteDataSource.update(
        id: id,
        name: name,
        description: description,
        type: type,
        config: config,
        isEnabled: isEnabled,
      );

  @override
  Future<void> delete(String id) => _remoteDataSource.delete(id);
}

/// Riverpod provider for [ToolRepository].
final toolRepositoryProvider = Provider<ToolRepository>((ref) {
  final remoteDataSource = ref.watch(toolRemoteDataSourceProvider);
  return ToolRepositoryImpl(remoteDataSource: remoteDataSource);
});

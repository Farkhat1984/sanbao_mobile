/// Implementation of the plugin repository.
///
/// Delegates to the remote data source for all operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/plugins/data/datasources/plugin_remote_datasource.dart';
import 'package:sanbao_flutter/features/plugins/domain/entities/plugin.dart';
import 'package:sanbao_flutter/features/plugins/domain/repositories/plugin_repository.dart';

/// Concrete implementation of [PluginRepository].
class PluginRepositoryImpl implements PluginRepository {
  PluginRepositoryImpl({required PluginRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final PluginRemoteDataSource _remoteDataSource;

  @override
  Future<List<Plugin>> getAll() => _remoteDataSource.getAll();

  @override
  Future<Plugin?> getById(String id) => _remoteDataSource.getById(id);

  @override
  Future<Plugin> create({
    required String name,
    String? description,
    List<String>? tools,
    List<String>? skills,
  }) =>
      _remoteDataSource.create(
        name: name,
        description: description,
        tools: tools,
        skills: skills,
      );

  @override
  Future<Plugin> update({
    required String id,
    String? name,
    String? description,
    List<String>? tools,
    List<String>? skills,
    bool? isEnabled,
  }) =>
      _remoteDataSource.update(
        id: id,
        name: name,
        description: description,
        tools: tools,
        skills: skills,
        isEnabled: isEnabled,
      );

  @override
  Future<void> delete(String id) => _remoteDataSource.delete(id);
}

/// Riverpod provider for [PluginRepository].
final pluginRepositoryProvider = Provider<PluginRepository>((ref) {
  final remoteDataSource = ref.watch(pluginRemoteDataSourceProvider);
  return PluginRepositoryImpl(remoteDataSource: remoteDataSource);
});

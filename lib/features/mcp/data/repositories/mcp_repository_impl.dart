/// Implementation of the MCP server repository.
///
/// Delegates to the remote data source for all operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/mcp/data/datasources/mcp_remote_datasource.dart';
import 'package:sanbao_flutter/features/mcp/domain/entities/mcp_server.dart';
import 'package:sanbao_flutter/features/mcp/domain/repositories/mcp_repository.dart';

/// Concrete implementation of [McpRepository].
class McpRepositoryImpl implements McpRepository {
  McpRepositoryImpl({required McpRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final McpRemoteDataSource _remoteDataSource;

  @override
  Future<List<McpServer>> getAll() => _remoteDataSource.getAll();

  @override
  Future<McpServer?> getById(String id) => _remoteDataSource.getById(id);

  @override
  Future<McpServer> create({
    required String name,
    required String url,
    String? apiKey,
  }) =>
      _remoteDataSource.create(name: name, url: url, apiKey: apiKey);

  @override
  Future<McpServer> update({
    required String id,
    String? name,
    String? url,
    String? apiKey,
  }) =>
      _remoteDataSource.update(id: id, name: name, url: url, apiKey: apiKey);

  @override
  Future<void> delete(String id) => _remoteDataSource.delete(id);

  @override
  Future<McpServer> testConnection(String id) =>
      _remoteDataSource.testConnection(id);
}

/// Riverpod provider for [McpRepository].
final mcpRepositoryProvider = Provider<McpRepository>((ref) {
  final remoteDataSource = ref.watch(mcpRemoteDataSourceProvider);
  return McpRepositoryImpl(remoteDataSource: remoteDataSource);
});

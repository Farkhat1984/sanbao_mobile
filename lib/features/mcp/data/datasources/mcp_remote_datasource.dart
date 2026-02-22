/// Remote data source for MCP server CRUD operations.
///
/// Handles GET/POST/PUT/DELETE calls to /api/mcp-servers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/mcp/data/models/mcp_server_model.dart';
import 'package:sanbao_flutter/features/mcp/domain/entities/mcp_server.dart';

/// Remote data source for MCP server operations via the REST API.
class McpRemoteDataSource {
  McpRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Fetches all MCP servers for the current user.
  Future<List<McpServer>> getAll() async {
    final response = await _dioClient.get<Object>(AppConfig.mcpServersEndpoint);

    // API returns a plain list
    final List<Object?> serversJson;
    if (response is List) {
      serversJson = response.cast<Object?>();
    } else if (response is Map<String, Object?>) {
      serversJson = response['servers'] as List<Object?>? ??
          response['data'] as List<Object?>? ??
          [];
    } else {
      serversJson = [];
    }

    return McpServerModel.fromJsonList(serversJson);
  }

  /// Fetches a single MCP server by [id].
  Future<McpServer?> getById(String id) async {
    final response =
        await _dioClient.get<Map<String, Object?>>('${AppConfig.mcpServersEndpoint}/$id');

    final serverJson = response.containsKey('server')
        ? response['server'] as Map<String, Object?>? ?? response
        : response;

    return McpServerModel.fromJson(serverJson).server;
  }

  /// Creates a new MCP server configuration.
  Future<McpServer> create({
    required String name,
    required String url,
    String? apiKey,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      AppConfig.mcpServersEndpoint,
      data: {
        'name': name,
        'url': url,
        if (apiKey != null && apiKey.isNotEmpty) 'apiKey': apiKey,
      },
    );

    return McpServerModel.fromJson(response).server;
  }

  /// Updates an existing MCP server.
  Future<McpServer> update({
    required String id,
    String? name,
    String? url,
    String? apiKey,
  }) async {
    final response = await _dioClient.put<Map<String, Object?>>(
      '${AppConfig.mcpServersEndpoint}/$id',
      data: {
        if (name != null) 'name': name,
        if (url != null) 'url': url,
        if (apiKey != null) 'apiKey': apiKey,
      },
    );

    return McpServerModel.fromJson(response).server;
  }

  /// Deletes an MCP server by [id].
  Future<void> delete(String id) async {
    await _dioClient.delete<Map<String, Object?>>('${AppConfig.mcpServersEndpoint}/$id');
  }

  /// Tests the connection to an MCP server.
  Future<McpServer> testConnection(String id) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '${AppConfig.mcpServersEndpoint}/$id/connect',
    );

    return McpServerModel.fromJson(response).server;
  }
}

/// Riverpod provider for [McpRemoteDataSource].
final mcpRemoteDataSourceProvider = Provider<McpRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return McpRemoteDataSource(dioClient: dioClient);
});

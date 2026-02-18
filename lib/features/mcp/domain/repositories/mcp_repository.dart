/// Abstract MCP server repository contract.
///
/// Defines CRUD and test-connection operations for MCP servers.
library;

import 'package:sanbao_flutter/features/mcp/domain/entities/mcp_server.dart';

/// Abstract repository for MCP server operations.
abstract class McpRepository {
  /// Fetches all MCP servers for the current user.
  Future<List<McpServer>> getAll();

  /// Fetches a single MCP server by [id].
  Future<McpServer?> getById(String id);

  /// Creates a new MCP server configuration.
  Future<McpServer> create({
    required String name,
    required String url,
    String? apiKey,
  });

  /// Updates an existing MCP server configuration.
  Future<McpServer> update({
    required String id,
    String? name,
    String? url,
    String? apiKey,
  });

  /// Deletes an MCP server by [id].
  Future<void> delete(String id);

  /// Tests the connection to an MCP server.
  ///
  /// Returns the updated server with refreshed status and tool list.
  Future<McpServer> testConnection(String id);
}

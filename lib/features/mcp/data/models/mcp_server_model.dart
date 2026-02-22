/// MCP server data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [McpServer] entity.
library;

import 'package:sanbao_flutter/features/mcp/domain/entities/mcp_server.dart';

/// Data model for [McpServer] with JSON serialization support.
class McpServerModel {
  const McpServerModel._({required this.server});

  /// Creates a model from a domain entity.
  factory McpServerModel.fromEntity(McpServer server) =>
      McpServerModel._(server: server);

  /// Creates a model from an API JSON response.
  factory McpServerModel.fromJson(Map<String, Object?> json) {
    final toolsJson = json['tools'] as List<Object?>?;
    final statusStr = json['status'] as String? ?? 'disconnected';

    return McpServerModel._(
      server: McpServer(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
        apiKey: json['apiKey'] as String?,
        status: _parseStatus(statusStr),
        tools: toolsJson?.whereType<String>().toList() ?? const [],
        lastConnected:
            DateTime.tryParse(json['lastConnected'] as String? ?? ''),
        userId: json['userId'] as String?,
        errorMessage: json['errorMessage'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      ),
    );
  }

  /// The underlying domain entity.
  final McpServer server;

  /// Converts to JSON for API requests (create/update).
  Map<String, Object?> toJson() => {
        'name': server.name,
        'url': server.url,
        if (server.apiKey != null) 'apiKey': server.apiKey,
      };

  /// Parses a list of MCP server JSON objects.
  static List<McpServer> fromJsonList(List<Object?> jsonList) => jsonList
      .whereType<Map<String, Object?>>()
      .map((json) => McpServerModel.fromJson(json).server)
      .toList();

  static McpServerStatus _parseStatus(String status) =>
      switch (status.toLowerCase()) {
        'connected' => McpServerStatus.connected,
        'error' => McpServerStatus.error,
        _ => McpServerStatus.disconnected,
      };
}

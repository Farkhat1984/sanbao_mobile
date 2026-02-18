/// MCP (Model Context Protocol) server entity.
///
/// Represents an external MCP server connection that provides
/// additional tools and capabilities to the AI platform.
library;

/// Connection status of an MCP server.
enum McpServerStatus {
  /// Server is connected and responding.
  connected,

  /// Server is not currently connected.
  disconnected,

  /// Server connection encountered an error.
  error,
}

/// An MCP server configuration with its connection state.
///
/// MCP servers expose tools via the Model Context Protocol,
/// allowing agents to access external capabilities.
class McpServer {
  const McpServer({
    required this.id,
    required this.name,
    required this.url,
    required this.status,
    required this.createdAt,
    this.apiKey,
    this.tools = const [],
    this.lastConnected,
    this.userId,
    this.errorMessage,
  });

  /// Unique server identifier.
  final String id;

  /// Display name of the server.
  final String name;

  /// Server URL (WebSocket or HTTP endpoint).
  final String url;

  /// Optional API key for authentication.
  final String? apiKey;

  /// Current connection status.
  final McpServerStatus status;

  /// Tools exposed by this server.
  final List<String> tools;

  /// When the server was last successfully connected.
  final DateTime? lastConnected;

  /// Owner user ID.
  final String? userId;

  /// Error message if status is [McpServerStatus.error].
  final String? errorMessage;

  /// When the server configuration was created.
  final DateTime createdAt;

  /// Whether the server has an API key configured.
  bool get hasApiKey => apiKey != null && apiKey!.isNotEmpty;

  /// Human-readable status label in Russian.
  String get statusLabel => switch (status) {
        McpServerStatus.connected => 'Подключен',
        McpServerStatus.disconnected => 'Отключен',
        McpServerStatus.error => 'Ошибка',
      };

  /// Creates a copy with modified fields.
  McpServer copyWith({
    String? id,
    String? name,
    String? url,
    String? apiKey,
    McpServerStatus? status,
    List<String>? tools,
    DateTime? lastConnected,
    String? userId,
    String? errorMessage,
    DateTime? createdAt,
  }) =>
      McpServer(
        id: id ?? this.id,
        name: name ?? this.name,
        url: url ?? this.url,
        apiKey: apiKey ?? this.apiKey,
        status: status ?? this.status,
        tools: tools ?? this.tools,
        lastConnected: lastConnected ?? this.lastConnected,
        userId: userId ?? this.userId,
        errorMessage: errorMessage ?? this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McpServer &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'McpServer(id=$id, name=$name, status=$status)';
}

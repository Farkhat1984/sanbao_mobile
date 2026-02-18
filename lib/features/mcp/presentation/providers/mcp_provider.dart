/// MCP server list and form state providers.
///
/// Manages the MCP server list, search filtering, test connection,
/// and CRUD form state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/mcp/data/repositories/mcp_repository_impl.dart';
import 'package:sanbao_flutter/features/mcp/domain/entities/mcp_server.dart';
import 'package:sanbao_flutter/features/mcp/domain/repositories/mcp_repository.dart';

// ---- MCP Server List ----

/// The raw MCP servers list, auto-refreshable.
final mcpServersProvider =
    AsyncNotifierProvider<McpServersNotifier, List<McpServer>>(
  McpServersNotifier.new,
);

/// Notifier for the MCP servers list with CRUD and test operations.
class McpServersNotifier extends AsyncNotifier<List<McpServer>> {
  @override
  Future<List<McpServer>> build() async {
    final repo = ref.watch(mcpRepositoryProvider);
    return repo.getAll();
  }

  /// Refreshes the MCP servers list from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(mcpRepositoryProvider);
      return repo.getAll();
    });
  }

  /// Creates a new MCP server and adds it to the list.
  Future<McpServer> createServer({
    required String name,
    required String url,
    String? apiKey,
  }) async {
    final repo = ref.read(mcpRepositoryProvider);
    final server = await repo.create(name: name, url: url, apiKey: apiKey);

    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, server]);
    return server;
  }

  /// Updates an existing MCP server in the list.
  Future<McpServer> updateServer({
    required String id,
    String? name,
    String? url,
    String? apiKey,
  }) async {
    final repo = ref.read(mcpRepositoryProvider);
    final updated =
        await repo.update(id: id, name: name, url: url, apiKey: apiKey);

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((s) => s.id == id ? updated : s).toList(),
    );
    return updated;
  }

  /// Deletes an MCP server from the list.
  Future<void> deleteServer(String id) async {
    final current = state.valueOrNull ?? [];
    final server = current.where((s) => s.id == id).firstOrNull;

    // Optimistic removal
    state = AsyncData(current.where((s) => s.id != id).toList());

    try {
      final repo = ref.read(mcpRepositoryProvider);
      await repo.delete(id);
    } on Object {
      // Revert on failure
      if (server != null) {
        state = AsyncData([...state.valueOrNull ?? [], server]);
      }
    }
  }

  /// Tests connection to an MCP server and updates its status.
  Future<McpServer> testConnection(String id) async {
    final repo = ref.read(mcpRepositoryProvider);
    final updated = await repo.testConnection(id);

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((s) => s.id == id ? updated : s).toList(),
    );
    return updated;
  }
}

// ---- Search ----

/// Search query for MCP servers list.
final mcpSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered MCP servers based on search query.
final filteredMcpServersProvider =
    Provider<AsyncValue<List<McpServer>>>((ref) {
  final servers = ref.watch(mcpServersProvider);
  final query = ref.watch(mcpSearchQueryProvider).toLowerCase();

  return servers.whenData(
    (list) => list
        .where((s) =>
            query.isEmpty ||
            s.name.toLowerCase().contains(query) ||
            s.url.toLowerCase().contains(query))
        .toList(),
  );
});

// ---- Test Connection State ----

/// Tracks which server is currently being tested.
final mcpTestingServerIdProvider = StateProvider<String?>((ref) => null);

// ---- Form State ----

/// Form data for creating or editing an MCP server.
class McpFormData {
  McpFormData({
    this.name = '',
    this.url = '',
    this.apiKey = '',
  });

  /// Creates form data pre-filled from an existing server.
  factory McpFormData.fromServer(McpServer server) => McpFormData(
        name: server.name,
        url: server.url,
        apiKey: server.apiKey ?? '',
      );

  String name;
  String url;
  String apiKey;

  /// Whether the minimum required fields are filled.
  bool get isValid => name.trim().isNotEmpty && url.trim().isNotEmpty;

  /// Creates a copy with modified fields.
  McpFormData copyWith({
    String? name,
    String? url,
    String? apiKey,
  }) =>
      McpFormData(
        name: name ?? this.name,
        url: url ?? this.url,
        apiKey: apiKey ?? this.apiKey,
      );
}

/// Provider for the MCP server form state.
final mcpFormProvider =
    StateNotifierProvider.autoDispose<McpFormNotifier, McpFormData>(
  (ref) => McpFormNotifier(),
);

/// Notifier managing the MCP server form state.
class McpFormNotifier extends StateNotifier<McpFormData> {
  McpFormNotifier() : super(McpFormData());

  /// Resets the form with optional pre-fill from an existing server.
  void initialize({McpServer? server}) {
    state = server != null ? McpFormData.fromServer(server) : McpFormData();
  }

  void updateName(String value) => state = state.copyWith(name: value);
  void updateUrl(String value) => state = state.copyWith(url: value);
  void updateApiKey(String value) => state = state.copyWith(apiKey: value);
}

/// Tracks whether the MCP form is currently submitting.
final mcpFormSubmittingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

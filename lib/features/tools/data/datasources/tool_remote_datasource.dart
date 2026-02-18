/// Remote data source for tool CRUD operations.
///
/// Handles GET/POST/PUT/DELETE calls to /api/tools.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/tools/data/models/tool_model.dart';
import 'package:sanbao_flutter/features/tools/domain/entities/tool.dart';

/// Remote data source for tool operations via the REST API.
class ToolRemoteDataSource {
  ToolRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Fetches all tools for the current user.
  Future<List<Tool>> getAll() async {
    final response = await _dioClient.get<Map<String, Object?>>(AppConfig.toolsEndpoint);

    final toolsJson = response['tools'] as List<Object?>? ??
        response['data'] as List<Object?>? ??
        [];

    return ToolModel.fromJsonList(toolsJson);
  }

  /// Fetches a single tool by [id].
  Future<Tool?> getById(String id) async {
    final response =
        await _dioClient.get<Map<String, Object?>>('${AppConfig.toolsEndpoint}/$id');

    final toolJson = response.containsKey('tool')
        ? response['tool'] as Map<String, Object?>? ?? response
        : response;

    return ToolModel.fromJson(toolJson).tool;
  }

  /// Creates a new tool.
  Future<Tool> create({
    required String name,
    required ToolType type,
    String? description,
    Map<String, Object?>? config,
  }) async {
    final model = ToolModel.fromEntity(Tool(
      id: '',
      name: name,
      type: type,
      description: description,
      config: config ?? const {},
      createdAt: DateTime.now(),
    ));

    final response = await _dioClient.post<Map<String, Object?>>(
      AppConfig.toolsEndpoint,
      data: model.toJson(),
    );

    return ToolModel.fromJson(response).tool;
  }

  /// Updates an existing tool.
  Future<Tool> update({
    required String id,
    String? name,
    String? description,
    ToolType? type,
    Map<String, Object?>? config,
    bool? isEnabled,
  }) async {
    final response = await _dioClient.put<Map<String, Object?>>(
      '${AppConfig.toolsEndpoint}/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (type != null)
          'type': switch (type) {
            ToolType.promptTemplate => 'PROMPT_TEMPLATE',
            ToolType.webhook => 'WEBHOOK',
            ToolType.url => 'URL',
            ToolType.function_ => 'FUNCTION',
          },
        if (config != null) 'config': config,
        if (isEnabled != null) 'isEnabled': isEnabled,
      },
    );

    return ToolModel.fromJson(response).tool;
  }

  /// Deletes a tool by [id].
  Future<void> delete(String id) async {
    await _dioClient.delete<Map<String, Object?>>('${AppConfig.toolsEndpoint}/$id');
  }
}

/// Riverpod provider for [ToolRemoteDataSource].
final toolRemoteDataSourceProvider = Provider<ToolRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ToolRemoteDataSource(dioClient: dioClient);
});

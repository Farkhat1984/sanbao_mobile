/// Remote data source for agent CRUD operations.
///
/// Handles GET/POST/PUT/DELETE calls to /api/agents.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/agents/data/models/agent_model.dart';
import 'package:sanbao_flutter/features/agents/domain/entities/agent.dart';

/// Remote data source for agent operations via the REST API.
class AgentRemoteDataSource {
  AgentRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Fetches all agents for the current user (system + user-created).
  Future<List<Agent>> getAll() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      AppConfig.agentsEndpoint,
    );

    final agentsJson = response['agents'] as List<Object?>? ??
        response['data'] as List<Object?>? ??
        [];

    return AgentModel.fromJsonList(agentsJson);
  }

  /// Fetches a single agent by [id] with full details.
  Future<Agent?> getById(String id) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '${AppConfig.agentsEndpoint}/$id',
    );

    // API may return the agent directly or nested under a key
    final agentJson = response.containsKey('agent')
        ? response['agent'] as Map<String, Object?>? ?? response
        : response;

    return AgentModel.fromJson(agentJson).agent;
  }

  /// Creates a new agent.
  Future<Agent> create({
    required String name,
    required String instructions,
    required String model,
    required String icon,
    required String iconColor,
    String? description,
    String? avatar,
    List<String>? starterPrompts,
    List<String>? skillIds,
    List<String>? toolIds,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      AppConfig.agentsEndpoint,
      data: {
        'name': name,
        'instructions': instructions,
        'model': model,
        'icon': icon,
        'iconColor': iconColor,
        if (description != null) 'description': description,
        if (avatar != null) 'avatar': avatar,
        if (starterPrompts != null && starterPrompts.isNotEmpty)
          'starterPrompts': starterPrompts,
        if (skillIds != null && skillIds.isNotEmpty) 'skillIds': skillIds,
        if (toolIds != null && toolIds.isNotEmpty) 'toolIds': toolIds,
      },
    );

    return AgentModel.fromJson(response).agent;
  }

  /// Updates an existing agent.
  Future<Agent> update({
    required String id,
    String? name,
    String? description,
    String? instructions,
    String? model,
    String? icon,
    String? iconColor,
    String? avatar,
    List<String>? starterPrompts,
    List<String>? skillIds,
    List<String>? toolIds,
  }) async {
    final response = await _dioClient.put<Map<String, Object?>>(
      '${AppConfig.agentsEndpoint}/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (instructions != null) 'instructions': instructions,
        if (model != null) 'model': model,
        if (icon != null) 'icon': icon,
        if (iconColor != null) 'iconColor': iconColor,
        if (avatar != null) 'avatar': avatar,
        if (starterPrompts != null) 'starterPrompts': starterPrompts,
        if (skillIds != null) 'skillIds': skillIds,
        if (toolIds != null) 'toolIds': toolIds,
      },
    );

    return AgentModel.fromJson(response).agent;
  }

  /// Deletes an agent by [id].
  Future<void> delete(String id) async {
    await _dioClient.delete<Map<String, Object?>>(
      '${AppConfig.agentsEndpoint}/$id',
    );
  }
}

/// Riverpod provider for [AgentRemoteDataSource].
final agentRemoteDataSourceProvider =
    Provider<AgentRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AgentRemoteDataSource(dioClient: dioClient);
});

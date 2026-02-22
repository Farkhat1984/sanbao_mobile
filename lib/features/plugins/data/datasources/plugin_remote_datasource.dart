/// Remote data source for plugin CRUD operations.
///
/// Handles GET/POST/PUT/DELETE calls to /api/plugins.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/plugins/data/models/plugin_model.dart';
import 'package:sanbao_flutter/features/plugins/domain/entities/plugin.dart';

/// Remote data source for plugin operations via the REST API.
class PluginRemoteDataSource {
  PluginRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Fetches all plugins for the current user.
  Future<List<Plugin>> getAll() async {
    final response = await _dioClient.get<Object>(AppConfig.pluginsEndpoint);

    // API returns a plain list
    final List<Object?> pluginsJson;
    if (response is List) {
      pluginsJson = response.cast<Object?>();
    } else if (response is Map<String, Object?>) {
      pluginsJson = response['plugins'] as List<Object?>? ??
          response['data'] as List<Object?>? ??
          [];
    } else {
      pluginsJson = [];
    }

    return PluginModel.fromJsonList(pluginsJson);
  }

  /// Fetches a single plugin by [id].
  Future<Plugin?> getById(String id) async {
    final response =
        await _dioClient.get<Map<String, Object?>>('${AppConfig.pluginsEndpoint}/$id');

    final pluginJson = response.containsKey('plugin')
        ? response['plugin'] as Map<String, Object?>? ?? response
        : response;

    return PluginModel.fromJson(pluginJson).plugin;
  }

  /// Creates a new plugin.
  Future<Plugin> create({
    required String name,
    String? description,
    List<String>? tools,
    List<String>? skills,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      AppConfig.pluginsEndpoint,
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (tools != null && tools.isNotEmpty) 'tools': tools,
        if (skills != null && skills.isNotEmpty) 'skills': skills,
      },
    );

    return PluginModel.fromJson(response).plugin;
  }

  /// Updates an existing plugin.
  Future<Plugin> update({
    required String id,
    String? name,
    String? description,
    List<String>? tools,
    List<String>? skills,
    bool? isEnabled,
  }) async {
    final response = await _dioClient.put<Map<String, Object?>>(
      '${AppConfig.pluginsEndpoint}/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (tools != null) 'tools': tools,
        if (skills != null) 'skills': skills,
        if (isEnabled != null) 'isEnabled': isEnabled,
      },
    );

    return PluginModel.fromJson(response).plugin;
  }

  /// Deletes a plugin by [id].
  Future<void> delete(String id) async {
    await _dioClient.delete<Map<String, Object?>>('${AppConfig.pluginsEndpoint}/$id');
  }
}

/// Riverpod provider for [PluginRemoteDataSource].
final pluginRemoteDataSourceProvider =
    Provider<PluginRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return PluginRemoteDataSource(dioClient: dioClient);
});

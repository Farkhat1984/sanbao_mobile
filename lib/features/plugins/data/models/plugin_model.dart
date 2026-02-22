/// Plugin data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [Plugin] entity.
library;

import 'package:sanbao_flutter/features/plugins/domain/entities/plugin.dart';

/// Data model for [Plugin] with JSON serialization support.
class PluginModel {
  const PluginModel._({required this.plugin});

  /// Creates a model from a domain entity.
  factory PluginModel.fromEntity(Plugin plugin) =>
      PluginModel._(plugin: plugin);

  /// Creates a model from an API JSON response.
  factory PluginModel.fromJson(Map<String, Object?> json) {
    final toolsJson = json['tools'] as List<Object?>?;
    final skillsJson = json['skills'] as List<Object?>?;

    return PluginModel._(
      plugin: Plugin(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        tools: _extractIds(toolsJson, 'tool'),
        skills: _extractIds(skillsJson, 'skill'),
        isEnabled: json['isActive'] as bool? ??
            json['isEnabled'] as bool? ??
            true,
        userId: json['userId'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      ),
    );
  }

  /// Extracts IDs from either flat string list or nested junction objects.
  ///
  /// Backend may return:
  /// - `["id1", "id2"]` (flat IDs)
  /// - `[{tool: {id: "...", name: "..."}}, ...]` (nested junction objects)
  static List<String> _extractIds(List<Object?>? json, String nestedKey) {
    if (json == null || json.isEmpty) return const [];

    final ids = <String>[];
    for (final item in json) {
      if (item is String) {
        ids.add(item);
      } else if (item is Map<String, Object?>) {
        final nested = item[nestedKey] as Map<String, Object?>?;
        final id = (nested?['id'] as String?) ?? (item['id'] as String?);
        if (id != null && id.isNotEmpty) ids.add(id);
      }
    }
    return ids;
  }

  /// The underlying domain entity.
  final Plugin plugin;

  /// Converts to JSON for API requests (create/update).
  Map<String, Object?> toJson() => {
        'name': plugin.name,
        if (plugin.description != null) 'description': plugin.description,
        if (plugin.tools.isNotEmpty) 'tools': plugin.tools,
        if (plugin.skills.isNotEmpty) 'skills': plugin.skills,
        'isEnabled': plugin.isEnabled,
      };

  /// Parses a list of plugin JSON objects.
  static List<Plugin> fromJsonList(List<Object?> jsonList) => jsonList
      .whereType<Map<String, Object?>>()
      .map((json) => PluginModel.fromJson(json).plugin)
      .toList();
}

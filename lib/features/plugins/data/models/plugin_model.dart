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
        tools: toolsJson?.whereType<String>().toList() ?? const [],
        skills: skillsJson?.whereType<String>().toList() ?? const [],
        isEnabled: json['isEnabled'] as bool? ?? true,
        userId: json['userId'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      ),
    );
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

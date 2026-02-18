/// Tool data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [Tool] entity.
library;

import 'package:sanbao_flutter/features/tools/domain/entities/tool.dart';

/// Data model for [Tool] with JSON serialization support.
class ToolModel {
  const ToolModel._({required this.tool});

  /// Creates a model from a domain entity.
  factory ToolModel.fromEntity(Tool tool) => ToolModel._(tool: tool);

  /// Creates a model from an API JSON response.
  factory ToolModel.fromJson(Map<String, Object?> json) {
    final configJson = json['config'] as Map<String, Object?>? ?? const {};
    final typeStr = json['type'] as String? ?? 'PROMPT_TEMPLATE';

    return ToolModel._(
      tool: Tool(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        type: _parseType(typeStr),
        config: configJson,
        isEnabled: json['isEnabled'] as bool? ?? true,
        userId: json['userId'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      ),
    );
  }

  /// The underlying domain entity.
  final Tool tool;

  /// Converts to JSON for API requests (create/update).
  Map<String, Object?> toJson() => {
        'name': tool.name,
        'type': _typeToString(tool.type),
        if (tool.description != null) 'description': tool.description,
        if (tool.config.isNotEmpty) 'config': tool.config,
        'isEnabled': tool.isEnabled,
      };

  /// Parses a list of tool JSON objects.
  static List<Tool> fromJsonList(List<Object?> jsonList) => jsonList
      .whereType<Map<String, Object?>>()
      .map((json) => ToolModel.fromJson(json).tool)
      .toList();

  static ToolType _parseType(String type) => switch (type.toUpperCase()) {
        'PROMPT_TEMPLATE' => ToolType.promptTemplate,
        'WEBHOOK' => ToolType.webhook,
        'URL' => ToolType.url,
        'FUNCTION' => ToolType.function_,
        _ => ToolType.promptTemplate,
      };

  static String _typeToString(ToolType type) => switch (type) {
        ToolType.promptTemplate => 'PROMPT_TEMPLATE',
        ToolType.webhook => 'WEBHOOK',
        ToolType.url => 'URL',
        ToolType.function_ => 'FUNCTION',
      };
}

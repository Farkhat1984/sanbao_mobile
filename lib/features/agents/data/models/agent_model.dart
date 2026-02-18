/// Agent data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [Agent] entity.
library;

import 'package:sanbao_flutter/features/agents/domain/entities/agent.dart';

/// Data model for [Agent] with JSON serialization support.
class AgentModel {
  const AgentModel._({required this.agent});

  /// Creates an [AgentModel] from a domain [Agent].
  factory AgentModel.fromEntity(Agent agent) => AgentModel._(agent: agent);

  /// Creates an [AgentModel] from a JSON map (API response).
  factory AgentModel.fromJson(Map<String, Object?> json) {
    final skillsJson = json['skills'] as List<Object?>?;
    final toolsJson = json['tools'] as List<Object?>?;
    final filesJson = json['files'] as List<Object?>?;
    final starterPromptsJson = json['starterPrompts'] as List<Object?>?;
    final countJson = json['_count'] as Map<String, Object?>?;

    return AgentModel._(
      agent: Agent(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        instructions: json['instructions'] as String? ?? '',
        model: json['model'] as String? ?? '',
        icon: json['icon'] as String? ?? 'Bot',
        iconColor: json['iconColor'] as String? ?? '#4F6EF7',
        avatar: json['avatar'] as String?,
        isSystem: json['isSystem'] as bool? ?? false,
        starterPrompts: starterPromptsJson
                ?.whereType<String>()
                .toList() ??
            const [],
        skills: skillsJson
                ?.whereType<Map<String, Object?>>()
                .map(_parseSkillRef)
                .toList() ??
            const [],
        tools: toolsJson
                ?.whereType<Map<String, Object?>>()
                .map(_parseToolRef)
                .toList() ??
            const [],
        files: filesJson
                ?.whereType<Map<String, Object?>>()
                .map(_parseFile)
                .toList() ??
            const [],
        conversationCount:
            (countJson?['conversations'] as num?)?.toInt() ?? 0,
        fileCount: (countJson?['files'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      ),
    );
  }

  /// The underlying domain entity.
  final Agent agent;

  /// Converts to a JSON map for API requests (create/update).
  Map<String, Object?> toJson() => {
        'name': agent.name,
        'instructions': agent.instructions,
        'model': agent.model,
        'icon': agent.icon,
        'iconColor': agent.iconColor,
        if (agent.description != null) 'description': agent.description,
        if (agent.avatar != null) 'avatar': agent.avatar,
        if (agent.starterPrompts.isNotEmpty)
          'starterPrompts': agent.starterPrompts,
      };

  /// Parses a list of agent JSON objects.
  static List<Agent> fromJsonList(List<Object?> jsonList) => jsonList
      .whereType<Map<String, Object?>>()
      .map((json) => AgentModel.fromJson(json).agent)
      .toList();
}

AgentSkillRef _parseSkillRef(Map<String, Object?> json) {
  final skillJson = json['skill'] as Map<String, Object?>? ?? json;
  return AgentSkillRef(
    id: json['id'] as String? ?? '',
    skillId: skillJson['id'] as String? ?? '',
    skillName: skillJson['name'] as String? ?? '',
    skillIcon: skillJson['icon'] as String?,
    skillIconColor: skillJson['iconColor'] as String?,
  );
}

AgentToolRef _parseToolRef(Map<String, Object?> json) {
  final toolJson = json['tool'] as Map<String, Object?>? ?? json;
  return AgentToolRef(
    id: json['id'] as String? ?? '',
    toolId: toolJson['id'] as String? ?? '',
    toolName: toolJson['name'] as String? ?? '',
    toolIcon: toolJson['icon'] as String?,
    toolIconColor: toolJson['iconColor'] as String?,
  );
}

AgentFile _parseFile(Map<String, Object?> json) => AgentFile(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      extractedText: json['extractedText'] as String?,
      inContext: json['inContext'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );

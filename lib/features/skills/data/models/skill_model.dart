/// Skill data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [Skill] entity.
library;

import 'package:sanbao_flutter/features/skills/domain/entities/skill.dart';

/// Data model for [Skill] with JSON serialization support.
class SkillModel {
  const SkillModel._({required this.skill});

  /// Creates a [SkillModel] from a domain [Skill].
  factory SkillModel.fromEntity(Skill skill) => SkillModel._(skill: skill);

  /// Creates a [SkillModel] from a JSON map (API response).
  factory SkillModel.fromJson(Map<String, Object?> json) => SkillModel._(
        skill: Skill(
          id: json['id'] as String? ?? '',
          name: json['name'] as String? ?? '',
          description: json['description'] as String?,
          systemPrompt: json['systemPrompt'] as String? ?? '',
          citationRules: json['citationRules'] as String?,
          jurisdiction: json['jurisdiction'] as String?,
          icon: json['icon'] as String? ?? 'BookOpen',
          iconColor: json['iconColor'] as String? ?? '#4F6EF7',
          isBuiltIn: json['isBuiltIn'] as bool? ?? false,
          isPublic: json['isPublic'] as bool? ?? false,
          userId: json['userId'] as String?,
          cloneCount: (json['cloneCount'] as num?)?.toInt() ??
              (json['_count'] as Map<String, Object?>?)?['clones'] as int? ??
              0,
          createdAt:
              DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                  DateTime.now(),
          updatedAt:
              DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
                  DateTime.now(),
        ),
      );

  /// The underlying domain entity.
  final Skill skill;

  /// Converts to a JSON map for API requests (create/update).
  Map<String, Object?> toJson() => {
        'name': skill.name,
        'systemPrompt': skill.systemPrompt,
        'icon': skill.icon,
        'iconColor': skill.iconColor,
        if (skill.description != null) 'description': skill.description,
        if (skill.citationRules != null) 'citationRules': skill.citationRules,
        if (skill.jurisdiction != null) 'jurisdiction': skill.jurisdiction,
        'isPublic': skill.isPublic,
      };

  /// Parses a list of skill JSON objects.
  static List<Skill> fromJsonList(List<Object?> jsonList) => jsonList
      .whereType<Map<String, Object?>>()
      .map((json) => SkillModel.fromJson(json).skill)
      .toList();
}

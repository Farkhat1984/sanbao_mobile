/// Remote data source for skill CRUD operations.
///
/// Handles GET/POST/PUT/DELETE calls to /api/skills.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/skills/data/models/skill_model.dart';
import 'package:sanbao_flutter/features/skills/domain/entities/skill.dart';

/// Remote data source for skill operations via the REST API.
class SkillRemoteDataSource {
  SkillRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Fetches all skills for the current user (built-in + custom).
  Future<List<Skill>> getAll() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      AppConfig.skillsEndpoint,
    );

    final skillsJson = response['skills'] as List<Object?>? ??
        response['data'] as List<Object?>? ??
        [];

    return SkillModel.fromJsonList(skillsJson);
  }

  /// Fetches all public skills available in the marketplace.
  Future<List<Skill>> getPublic() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      AppConfig.skillsEndpoint,
      queryParameters: {'public': true},
    );

    final skillsJson = response['skills'] as List<Object?>? ??
        response['data'] as List<Object?>? ??
        [];

    return SkillModel.fromJsonList(skillsJson);
  }

  /// Fetches a single skill by [id] with full details.
  Future<Skill?> getById(String id) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '${AppConfig.skillsEndpoint}/$id',
    );

    final skillJson = response.containsKey('skill')
        ? response['skill'] as Map<String, Object?>? ?? response
        : response;

    return SkillModel.fromJson(skillJson).skill;
  }

  /// Creates a new skill.
  Future<Skill> create({
    required String name,
    required String systemPrompt,
    required String icon,
    required String iconColor,
    String? description,
    String? citationRules,
    String? jurisdiction,
    bool isPublic = false,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      AppConfig.skillsEndpoint,
      data: {
        'name': name,
        'systemPrompt': systemPrompt,
        'icon': icon,
        'iconColor': iconColor,
        if (description != null) 'description': description,
        if (citationRules != null) 'citationRules': citationRules,
        if (jurisdiction != null) 'jurisdiction': jurisdiction,
        'isPublic': isPublic,
      },
    );

    return SkillModel.fromJson(response).skill;
  }

  /// Updates an existing skill.
  Future<Skill> update({
    required String id,
    String? name,
    String? description,
    String? systemPrompt,
    String? citationRules,
    String? jurisdiction,
    String? icon,
    String? iconColor,
    bool? isPublic,
  }) async {
    final response = await _dioClient.put<Map<String, Object?>>(
      '${AppConfig.skillsEndpoint}/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (systemPrompt != null) 'systemPrompt': systemPrompt,
        if (citationRules != null) 'citationRules': citationRules,
        if (jurisdiction != null) 'jurisdiction': jurisdiction,
        if (icon != null) 'icon': icon,
        if (iconColor != null) 'iconColor': iconColor,
        if (isPublic != null) 'isPublic': isPublic,
      },
    );

    return SkillModel.fromJson(response).skill;
  }

  /// Deletes a skill by [id].
  Future<void> delete(String id) async {
    await _dioClient.delete<Map<String, Object?>>(
      '${AppConfig.skillsEndpoint}/$id',
    );
  }

  /// Clones a public skill into the current user's library.
  Future<Skill> clone(String id) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '${AppConfig.skillsEndpoint}/$id/clone',
    );

    return SkillModel.fromJson(response).skill;
  }

  /// Generates skill configuration from a text description using AI.
  ///
  /// Returns a map with: `name`, `description`, `systemPrompt`,
  /// `citationRules`, `jurisdiction`, `icon`, `iconColor`.
  Future<Map<String, Object?>> generateSkill({
    required String description,
    String? jurisdiction,
  }) async => _dioClient.post<Map<String, Object?>>(
      '${AppConfig.skillsEndpoint}/generate',
      data: {
        'description': description,
        if (jurisdiction != null) 'jurisdiction': jurisdiction,
      },
    );
}

/// Riverpod provider for [SkillRemoteDataSource].
final skillRemoteDataSourceProvider =
    Provider<SkillRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SkillRemoteDataSource(dioClient: dioClient);
});

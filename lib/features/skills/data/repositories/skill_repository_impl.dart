/// Implementation of the skill repository.
///
/// Delegates to the remote data source for all operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/skills/data/datasources/skill_remote_datasource.dart';
import 'package:sanbao_flutter/features/skills/domain/entities/skill.dart';
import 'package:sanbao_flutter/features/skills/domain/repositories/skill_repository.dart';

/// Concrete implementation of [SkillRepository].
class SkillRepositoryImpl implements SkillRepository {
  SkillRepositoryImpl({
    required SkillRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final SkillRemoteDataSource _remoteDataSource;

  @override
  Future<List<Skill>> getAll() => _remoteDataSource.getAll();

  @override
  Future<List<Skill>> getPublic() => _remoteDataSource.getPublic();

  @override
  Future<Skill?> getById(String id) => _remoteDataSource.getById(id);

  @override
  Future<Skill> create({
    required String name,
    required String systemPrompt,
    required String icon,
    required String iconColor,
    String? description,
    String? citationRules,
    String? jurisdiction,
    bool isPublic = false,
  }) =>
      _remoteDataSource.create(
        name: name,
        systemPrompt: systemPrompt,
        icon: icon,
        iconColor: iconColor,
        description: description,
        citationRules: citationRules,
        jurisdiction: jurisdiction,
        isPublic: isPublic,
      );

  @override
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
  }) =>
      _remoteDataSource.update(
        id: id,
        name: name,
        description: description,
        systemPrompt: systemPrompt,
        citationRules: citationRules,
        jurisdiction: jurisdiction,
        icon: icon,
        iconColor: iconColor,
        isPublic: isPublic,
      );

  @override
  Future<void> delete(String id) => _remoteDataSource.delete(id);

  @override
  Future<Skill> clone(String id) => _remoteDataSource.clone(id);
}

/// Riverpod provider for [SkillRepository].
final skillRepositoryProvider = Provider<SkillRepository>((ref) {
  final remoteDataSource = ref.watch(skillRemoteDataSourceProvider);
  return SkillRepositoryImpl(remoteDataSource: remoteDataSource);
});

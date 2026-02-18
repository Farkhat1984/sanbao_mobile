/// Implementation of the agent repository.
///
/// Delegates to the remote data source for all operations.
/// A caching layer can be added here in the future.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/agents/data/datasources/agent_remote_datasource.dart';
import 'package:sanbao_flutter/features/agents/domain/entities/agent.dart';
import 'package:sanbao_flutter/features/agents/domain/repositories/agent_repository.dart';

/// Concrete implementation of [AgentRepository].
///
/// Currently network-only. A cache-first strategy can be added
/// by introducing a local data source similar to conversations.
class AgentRepositoryImpl implements AgentRepository {
  AgentRepositoryImpl({
    required AgentRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AgentRemoteDataSource _remoteDataSource;

  @override
  Future<List<Agent>> getAll() => _remoteDataSource.getAll();

  @override
  Future<Agent?> getById(String id) => _remoteDataSource.getById(id);

  @override
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
  }) =>
      _remoteDataSource.create(
        name: name,
        instructions: instructions,
        model: model,
        icon: icon,
        iconColor: iconColor,
        description: description,
        avatar: avatar,
        starterPrompts: starterPrompts,
        skillIds: skillIds,
        toolIds: toolIds,
      );

  @override
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
  }) =>
      _remoteDataSource.update(
        id: id,
        name: name,
        description: description,
        instructions: instructions,
        model: model,
        icon: icon,
        iconColor: iconColor,
        avatar: avatar,
        starterPrompts: starterPrompts,
        skillIds: skillIds,
        toolIds: toolIds,
      );

  @override
  Future<void> delete(String id) => _remoteDataSource.delete(id);
}

/// Riverpod provider for [AgentRepository].
final agentRepositoryProvider = Provider<AgentRepository>((ref) {
  final remoteDataSource = ref.watch(agentRemoteDataSourceProvider);
  return AgentRepositoryImpl(remoteDataSource: remoteDataSource);
});

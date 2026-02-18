/// Abstract agent repository defining the contract for agent CRUD operations.
///
/// Implementations handle the actual network communication and
/// optional caching layer.
library;

import 'package:sanbao_flutter/features/agents/domain/entities/agent.dart';

/// Abstract repository for agent operations.
///
/// Provides CRUD operations for both system and user agents.
/// Implementations should handle error mapping to domain [Failure]s.
abstract class AgentRepository {
  /// Fetches all agents (system + user) for the current user.
  ///
  /// Results are typically ordered with system agents first,
  /// then user agents sorted by creation date descending.
  Future<List<Agent>> getAll();

  /// Fetches a single agent by [id].
  ///
  /// Returns `null` if the agent does not exist.
  Future<Agent?> getById(String id);

  /// Creates a new user agent.
  ///
  /// Returns the created agent with server-generated ID and timestamps.
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
  });

  /// Updates an existing user agent.
  ///
  /// Only fields that are non-null in the parameters will be updated.
  /// System agents cannot be updated; attempting to do so will throw
  /// a [PermissionFailure].
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
  });

  /// Deletes a user agent by [id].
  ///
  /// System agents cannot be deleted; attempting to do so will throw
  /// a [PermissionFailure].
  Future<void> delete(String id);
}

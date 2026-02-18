/// Abstract skill repository defining the contract for skill CRUD operations.
///
/// Implementations handle network communication, caching, and
/// error mapping to domain failures.
library;

import 'package:sanbao_flutter/features/skills/domain/entities/skill.dart';

/// Abstract repository for skill operations.
///
/// Provides CRUD operations for user skills, access to the public
/// marketplace, and cloning functionality.
abstract class SkillRepository {
  /// Fetches all skills owned by the current user (including built-in).
  Future<List<Skill>> getAll();

  /// Fetches all public skills available in the marketplace.
  Future<List<Skill>> getPublic();

  /// Fetches a single skill by [id].
  ///
  /// Returns `null` if the skill does not exist.
  Future<Skill?> getById(String id);

  /// Creates a new user skill.
  ///
  /// Returns the created skill with server-generated ID and timestamps.
  Future<Skill> create({
    required String name,
    required String systemPrompt,
    required String icon,
    required String iconColor,
    String? description,
    String? citationRules,
    String? jurisdiction,
    bool isPublic = false,
  });

  /// Updates an existing user skill.
  ///
  /// Built-in skills cannot be updated; attempting to do so will throw
  /// a [PermissionFailure].
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
  });

  /// Deletes a user skill by [id].
  ///
  /// Built-in skills cannot be deleted.
  Future<void> delete(String id);

  /// Clones a public skill into the current user's skill library.
  ///
  /// Returns the newly created skill copy owned by the current user.
  Future<Skill> clone(String id);
}

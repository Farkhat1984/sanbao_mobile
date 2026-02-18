/// Abstract plugin repository contract.
///
/// Defines CRUD operations for plugins.
library;

import 'package:sanbao_flutter/features/plugins/domain/entities/plugin.dart';

/// Abstract repository for plugin operations.
abstract class PluginRepository {
  /// Fetches all plugins for the current user.
  Future<List<Plugin>> getAll();

  /// Fetches a single plugin by [id].
  Future<Plugin?> getById(String id);

  /// Creates a new plugin.
  Future<Plugin> create({
    required String name,
    String? description,
    List<String>? tools,
    List<String>? skills,
  });

  /// Updates an existing plugin.
  Future<Plugin> update({
    required String id,
    String? name,
    String? description,
    List<String>? tools,
    List<String>? skills,
    bool? isEnabled,
  });

  /// Deletes a plugin by [id].
  Future<void> delete(String id);
}

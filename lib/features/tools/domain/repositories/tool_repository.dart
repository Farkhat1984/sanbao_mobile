/// Abstract tool repository contract.
///
/// Defines CRUD operations for custom tools.
library;

import 'package:sanbao_flutter/features/tools/domain/entities/tool.dart';

/// Abstract repository for tool operations.
abstract class ToolRepository {
  /// Fetches all tools for the current user.
  Future<List<Tool>> getAll();

  /// Fetches a single tool by [id].
  Future<Tool?> getById(String id);

  /// Creates a new tool.
  Future<Tool> create({
    required String name,
    required ToolType type,
    String? description,
    Map<String, Object?>? config,
  });

  /// Updates an existing tool.
  Future<Tool> update({
    required String id,
    String? name,
    String? description,
    ToolType? type,
    Map<String, Object?>? config,
    bool? isEnabled,
  });

  /// Deletes a tool by [id].
  Future<void> delete(String id);
}

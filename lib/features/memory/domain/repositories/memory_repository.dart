/// Abstract memory repository contract.
///
/// Defines CRUD operations for AI memories.
library;

import 'package:sanbao_flutter/features/memory/domain/entities/memory.dart';

/// Abstract repository for memory operations.
abstract class MemoryRepository {
  /// Fetches all memories for the current user.
  Future<List<Memory>> getAll();

  /// Creates a new memory.
  Future<Memory> create({
    required String content,
    String? category,
  });

  /// Updates an existing memory.
  Future<Memory> update({
    required String id,
    String? content,
    String? category,
  });

  /// Deletes a memory by [id].
  Future<void> delete(String id);
}

/// Abstract knowledge repository contract.
///
/// Defines CRUD operations for user knowledge base files.
library;

import 'package:sanbao_flutter/features/knowledge/domain/entities/knowledge_file.dart';

/// Abstract repository for knowledge file operations.
abstract class KnowledgeRepository {
  /// Fetches all knowledge files for the current user.
  ///
  /// Returns files ordered by [KnowledgeFile.updatedAt] descending.
  Future<List<KnowledgeFile>> getFiles();

  /// Fetches a single knowledge file by [id], including its content.
  Future<KnowledgeFile> getFile(String id);

  /// Creates a new knowledge file with text content.
  ///
  /// The [name] is required and must not exceed 100 characters.
  /// The [content] is required and must not exceed 100KB.
  /// The optional [description] must not exceed 500 characters.
  Future<KnowledgeFile> createFile({
    required String name,
    required String content,
    String? description,
  });

  /// Updates an existing knowledge file's metadata or content.
  ///
  /// Only non-null fields will be updated.
  Future<KnowledgeFile> updateFile(
    String id, {
    String? name,
    String? description,
    String? content,
  });

  /// Deletes a knowledge file by [id].
  Future<void> deleteFile(String id);
}

/// Knowledge file data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [KnowledgeFile] entity.
library;

import 'package:sanbao_flutter/features/knowledge/domain/entities/knowledge_file.dart';

/// Data model for [KnowledgeFile] with JSON serialization support.
class KnowledgeFileModel {
  const KnowledgeFileModel._({required this.file});

  /// Creates a model from a domain entity.
  factory KnowledgeFileModel.fromEntity(KnowledgeFile file) =>
      KnowledgeFileModel._(file: file);

  /// Creates a model from an API JSON response.
  ///
  /// The API returns the following fields:
  /// - `id` (String) -- unique identifier
  /// - `name` (String) -- user-facing name
  /// - `description` (String?) -- optional description
  /// - `content` (String?) -- extracted text (only in detail endpoint)
  /// - `fileType` (String) -- file type identifier (e.g., "md")
  /// - `sizeBytes` (int) -- file size in bytes
  /// - `createdAt` (String) -- ISO 8601 timestamp
  /// - `updatedAt` (String) -- ISO 8601 timestamp
  factory KnowledgeFileModel.fromJson(Map<String, Object?> json) =>
      KnowledgeFileModel._(
        file: KnowledgeFile(
          id: json['id'] as String? ?? '',
          name: json['name'] as String? ?? '',
          description: json['description'] as String?,
          content: json['content'] as String?,
          fileType: json['fileType'] as String? ?? 'md',
          sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
          createdAt:
              DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                  DateTime.now(),
          updatedAt:
              DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
                  DateTime.now(),
        ),
      );

  /// The underlying domain entity.
  final KnowledgeFile file;

  /// Converts to JSON for API create/update requests.
  Map<String, Object?> toJson() => {
        'name': file.name,
        if (file.description != null) 'description': file.description,
        if (file.content != null) 'content': file.content,
      };

  /// Parses a list of knowledge file JSON objects.
  static List<KnowledgeFile> fromJsonList(List<Object?> jsonList) => jsonList
      .whereType<Map<String, Object?>>()
      .map((json) => KnowledgeFileModel.fromJson(json).file)
      .toList();
}

/// Knowledge file entity for the user knowledge base.
///
/// Represents a user-uploaded file that the AI uses as additional
/// context during conversations. Files contain extracted text content.
library;

/// A file in the user's personal knowledge base.
///
/// Knowledge files are text-based documents (typically markdown) that
/// the AI references to provide personalized, context-aware responses.
class KnowledgeFile {
  const KnowledgeFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.fileType,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.content,
  });

  /// Unique file identifier.
  final String id;

  /// User-facing file name.
  final String name;

  /// Optional description of the file's purpose or contents.
  final String? description;

  /// Extracted text content of the file.
  final String? content;

  /// File size in bytes.
  final int sizeBytes;

  /// File type identifier (e.g., "md" for markdown).
  final String fileType;

  /// When the file was created.
  final DateTime createdAt;

  /// When the file was last updated.
  final DateTime updatedAt;

  /// Creates a copy with modified fields.
  KnowledgeFile copyWith({
    String? id,
    String? name,
    String? description,
    String? content,
    int? sizeBytes,
    String? fileType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      KnowledgeFile(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        content: content ?? this.content,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        fileType: fileType ?? this.fileType,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Human-readable file size string.
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeFile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'KnowledgeFile(id=$id, name=$name, size=$formattedSize)';
}

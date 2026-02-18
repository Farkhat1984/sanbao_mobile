/// Version snapshot of an artifact.
///
/// Each time the AI regenerates or the user edits an artifact,
/// a new [ArtifactVersion] is created so the user can restore
/// any previous state.
library;

/// An immutable snapshot of an artifact's content at a point in time.
class ArtifactVersion {
  const ArtifactVersion({
    required this.id,
    required this.versionNumber,
    required this.content,
    required this.createdAt,
    this.label,
  });

  /// Unique identifier for this version.
  final String id;

  /// Sequential version number (1-based).
  final int versionNumber;

  /// The full content of the artifact at this version.
  final String content;

  /// When this version was created.
  final DateTime createdAt;

  /// Optional human-readable label (e.g., "Original", "After review").
  final String? label;

  /// Creates a copy with modified fields.
  ArtifactVersion copyWith({
    String? id,
    int? versionNumber,
    String? content,
    DateTime? createdAt,
    String? label,
  }) =>
      ArtifactVersion(
        id: id ?? this.id,
        versionNumber: versionNumber ?? this.versionNumber,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
        label: label ?? this.label,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtifactVersion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ArtifactVersion(id=$id, v$versionNumber, label=$label)';
}

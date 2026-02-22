/// Data model for artifact versions with JSON serialization.
///
/// Maps between the server's JSON representation and the
/// domain [ArtifactVersion] entity.
library;

import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact_version.dart';

/// JSON-serializable model for [ArtifactVersion].
class ArtifactVersionModel {
  const ArtifactVersionModel({
    required this.id,
    required this.versionNumber,
    required this.content,
    required this.createdAt,
    this.label,
  });

  /// Deserializes from a JSON map.
  factory ArtifactVersionModel.fromJson(Map<String, Object?> json) => ArtifactVersionModel(
      id: json['id'] as String? ?? '',
      versionNumber: json['version'] as int? ??
          json['versionNumber'] as int? ??
          1,
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'] as String) ??
                  DateTime.now()
              : DateTime.now(),
      label: json['label'] as String?,
    );

  /// Creates from a domain entity.
  factory ArtifactVersionModel.fromEntity(ArtifactVersion entity) => ArtifactVersionModel(
      id: entity.id,
      versionNumber: entity.versionNumber,
      content: entity.content,
      createdAt: entity.createdAt,
      label: entity.label,
    );

  final String id;
  final int versionNumber;
  final String content;
  final DateTime createdAt;
  final String? label;

  /// Serializes to a JSON map.
  Map<String, Object?> toJson() => {
        'id': id,
        'version': versionNumber,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        if (label != null) 'label': label,
      };

  /// Converts to the domain entity.
  ArtifactVersion toEntity() => ArtifactVersion(
        id: id,
        versionNumber: versionNumber,
        content: content,
        createdAt: createdAt,
        label: label,
      );
}

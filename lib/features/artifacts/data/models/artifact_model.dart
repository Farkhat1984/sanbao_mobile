/// Data model for artifacts with JSON serialization.
///
/// Maps between the server's JSON representation and the
/// domain [FullArtifact] entity, including nested versions.
library;

import 'package:sanbao_flutter/features/artifacts/data/models/artifact_version_model.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact.dart';

/// JSON-serializable model for [FullArtifact].
class ArtifactModel {
  const ArtifactModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.conversationId,
    this.messageId,
    this.language,
    this.versions = const [],
    this.currentVersion = 1,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserializes from a JSON map.
  ///
  /// Handles both flat and nested server response formats.
  factory ArtifactModel.fromJson(Map<String, Object?> json) {
    final versionsJson = json['versions'] as List<Object?>?;
    final versions = versionsJson
            ?.map((v) =>
                ArtifactVersionModel.fromJson(v! as Map<String, Object?>),)
            .toList() ??
        const [];

    return ArtifactModel(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String?,
      messageId: json['messageId'] as String?,
      type: ArtifactType.fromString(json['type'] as String? ?? 'DOCUMENT'),
      title: json['title'] as String? ?? 'Без названия',
      content: json['content'] as String? ?? '',
      language: json['language'] as String?,
      versions: versions,
      currentVersion: json['version'] as int? ??
          json['currentVersion'] as int? ??
          1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Creates from a domain entity.
  factory ArtifactModel.fromEntity(FullArtifact entity) => ArtifactModel(
      id: entity.id,
      conversationId: entity.conversationId,
      messageId: entity.messageId,
      type: entity.type,
      title: entity.title,
      content: entity.content,
      language: entity.language,
      versions: entity.versions
          .map(ArtifactVersionModel.fromEntity)
          .toList(),
      currentVersion: entity.currentVersion,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );

  final String id;
  final String? conversationId;
  final String? messageId;
  final ArtifactType type;
  final String title;
  final String content;
  final String? language;
  final List<ArtifactVersionModel> versions;
  final int currentVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Serializes to a JSON map.
  Map<String, Object?> toJson() => {
        'id': id,
        if (conversationId != null) 'conversationId': conversationId,
        if (messageId != null) 'messageId': messageId,
        'type': type.name.toUpperCase(),
        'title': title,
        'content': content,
        if (language != null) 'language': language,
        'versions': versions.map((v) => v.toJson()).toList(),
        'version': currentVersion,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  /// Converts to the domain entity.
  FullArtifact toEntity() => FullArtifact(
        id: id,
        conversationId: conversationId,
        messageId: messageId,
        type: type,
        title: title,
        content: content,
        language: language,
        versions: versions.map((v) => v.toEntity()).toList(),
        currentVersion: currentVersion,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

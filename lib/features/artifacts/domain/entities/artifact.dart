/// Full artifact entity for the artifacts feature module.
///
/// Extends the lightweight [chat/Artifact] entity with versioning,
/// conversation binding, timestamps, and export-related metadata.
library;

import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact_version.dart';

/// Type classification for artifacts.
///
/// Matches the server-side artifact types and provides
/// Russian labels and icon mappings for the UI.
enum ArtifactType {
  /// Text documents: contracts, letters, reports, memos.
  document,

  /// Executable code: HTML+JS, React, Python.
  code,

  /// Legal analysis, expertise, audit materials.
  legal,

  /// Tabular data: spreadsheets, schedules, budgets.
  spreadsheet,

  /// Analytical material.
  analysis,

  /// Image content.
  image;

  /// Parses an [ArtifactType] from its server-side string representation.
  static ArtifactType fromString(String value) =>
      switch (value.toUpperCase()) {
        'DOCUMENT' || 'CONTRACT' || 'CLAIM' || 'COMPLAINT' => document,
        'CODE' => code,
        'LEGAL' || 'LEGAL_ANALYSIS' => legal,
        'SPREADSHEET' || 'TABLE' => spreadsheet,
        'ANALYSIS' => analysis,
        'IMAGE' => image,
        _ => document,
      };

  /// Russian display label.
  String get label => switch (this) {
        ArtifactType.document => 'Документ',
        ArtifactType.code => 'Код',
        ArtifactType.legal => 'Юридический документ',
        ArtifactType.spreadsheet => 'Таблица',
        ArtifactType.analysis => 'Анализ',
        ArtifactType.image => 'Изображение',
      };

  /// Short badge label.
  String get badgeLabel => switch (this) {
        ArtifactType.document => 'Документ',
        ArtifactType.code => 'Код',
        ArtifactType.legal => 'Юр. документ',
        ArtifactType.spreadsheet => 'Таблица',
        ArtifactType.analysis => 'Анализ',
        ArtifactType.image => 'Изображение',
      };

  /// Whether this artifact type supports the editor tab.
  bool get supportsEditor => this != image;

  /// Whether this artifact type should show preview as default tab.
  bool get defaultsToPreview => this != code;
}

/// A full artifact entity with versioning and metadata.
///
/// Represents a generated document, code block, legal document,
/// or spreadsheet that the AI has produced. Supports version
/// history for undo/redo and restoration.
class FullArtifact {
  const FullArtifact({
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

  /// Unique identifier.
  final String id;

  /// The conversation this artifact was generated in.
  final String? conversationId;

  /// The message that produced this artifact.
  final String? messageId;

  /// Type of artifact content.
  final ArtifactType type;

  /// Human-readable title.
  final String title;

  /// The full content (Markdown, source code, etc.).
  final String content;

  /// Programming language (for code artifacts).
  final String? language;

  /// All saved versions of this artifact.
  final List<ArtifactVersion> versions;

  /// The currently active version number.
  final int currentVersion;

  /// When the artifact was first created.
  final DateTime? createdAt;

  /// When the artifact was last modified.
  final DateTime? updatedAt;

  /// Whether this artifact has multiple versions.
  bool get hasVersions => versions.length > 1;

  /// The total number of versions.
  int get versionCount => versions.length;

  /// Creates a copy with modified fields.
  FullArtifact copyWith({
    String? id,
    String? conversationId,
    String? messageId,
    ArtifactType? type,
    String? title,
    String? content,
    String? language,
    List<ArtifactVersion>? versions,
    int? currentVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      FullArtifact(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        messageId: messageId ?? this.messageId,
        type: type ?? this.type,
        title: title ?? this.title,
        content: content ?? this.content,
        language: language ?? this.language,
        versions: versions ?? this.versions,
        currentVersion: currentVersion ?? this.currentVersion,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullArtifact &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'FullArtifact(id=$id, type=$type, title=$title, v$currentVersion)';
}

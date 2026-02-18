/// Abstract artifact repository defining the data access contract.
///
/// Provides CRUD operations for artifacts, version management,
/// and export functionality.
library;

import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact_version.dart';

/// Supported export formats for artifacts.
enum ExportFormat {
  pdf,
  docx,
  txt,
  markdown,
  html,
  copy;

  /// Russian display label.
  String get label => switch (this) {
        ExportFormat.pdf => 'PDF (.pdf)',
        ExportFormat.docx => 'Word (.docx)',
        ExportFormat.txt => 'Текст (.txt)',
        ExportFormat.markdown => 'Markdown (.md)',
        ExportFormat.html => 'HTML (.html)',
        ExportFormat.copy => 'Копировать',
      };

  /// Short format name for buttons.
  String get shortLabel => switch (this) {
        ExportFormat.pdf => 'PDF',
        ExportFormat.docx => 'DOCX',
        ExportFormat.txt => 'TXT',
        ExportFormat.markdown => 'MD',
        ExportFormat.html => 'HTML',
        ExportFormat.copy => 'Копировать',
      };

  /// Description text.
  String get description => switch (this) {
        ExportFormat.pdf => 'Документ для печати и просмотра',
        ExportFormat.docx => 'Редактируемый формат Microsoft Word',
        ExportFormat.txt => 'Простой текстовый файл',
        ExportFormat.markdown => 'Текст с разметкой Markdown',
        ExportFormat.html => 'Веб-страница с форматированием',
        ExportFormat.copy => 'Скопировать содержимое в буфер обмена',
      };
}

/// Abstract repository for artifact operations.
///
/// Implementations handle the actual network communication,
/// caching, and format conversion.
abstract class ArtifactRepository {
  /// Retrieves an artifact by its ID.
  ///
  /// Returns the full artifact with current content and metadata.
  /// Throws a [Failure] if the artifact is not found or on
  /// network error.
  Future<FullArtifact> getById(String artifactId);

  /// Retrieves all artifacts for a conversation.
  ///
  /// Returns the artifacts sorted by creation date (newest first).
  Future<List<FullArtifact>> getByConversation(String conversationId);

  /// Updates an artifact's content.
  ///
  /// Creates a new version automatically on the server side.
  /// Returns the updated artifact with the new version appended.
  Future<FullArtifact> update({
    required String artifactId,
    required String content,
    String? title,
  });

  /// Exports an artifact in the specified format.
  ///
  /// Returns the raw bytes of the exported file.
  /// For [ExportFormat.copy], returns the plain text content
  /// as UTF-8 bytes.
  Future<List<int>> export({
    required String artifactId,
    required ExportFormat format,
  });

  /// Retrieves all versions of an artifact.
  ///
  /// Returns versions sorted by version number (newest first).
  Future<List<ArtifactVersion>> getVersions(String artifactId);

  /// Restores an artifact to a specific version.
  ///
  /// The restored content becomes the new current version
  /// (a new version entry is created, not a rollback).
  /// Returns the updated artifact.
  Future<FullArtifact> restoreVersion({
    required String artifactId,
    required int versionNumber,
  });
}

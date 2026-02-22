/// Riverpod providers for the artifacts feature.
///
/// Manages the current artifact state, active tab, version
/// selection, and export operations.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/artifacts/data/repositories/artifact_repository_impl.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact_version.dart';
import 'package:sanbao_flutter/features/artifacts/domain/repositories/artifact_repository.dart';

// ---- Active Tab ----

/// The tabs available in the artifact viewer.
enum ArtifactViewTab {
  /// Rendered preview (Markdown / code preview).
  preview,

  /// Rich text editor (flutter_quill).
  editor,

  /// Raw source view.
  source;

  /// Russian tab label.
  String get label => switch (this) {
        ArtifactViewTab.preview => 'Просмотр',
        ArtifactViewTab.editor => 'Редактор',
        ArtifactViewTab.source => 'Исходник',
      };
}

/// The currently active tab in the artifact viewer.
final artifactViewTabProvider = StateProvider<ArtifactViewTab>((ref) {
  final artifact = ref.watch(currentArtifactProvider);
  if (artifact == null) return ArtifactViewTab.preview;
  return artifact.type.defaultsToPreview
      ? ArtifactViewTab.preview
      : ArtifactViewTab.source;
});

// ---- Current Artifact ----

/// The currently displayed artifact in the viewer.
///
/// Set when the user opens an artifact from a message card.
/// Null when no artifact is being viewed.
final currentArtifactProvider =
    StateNotifierProvider<CurrentArtifactNotifier, FullArtifact?>(CurrentArtifactNotifier.new);

/// Notifier for the currently displayed artifact.
class CurrentArtifactNotifier extends StateNotifier<FullArtifact?> {
  CurrentArtifactNotifier(this._ref) : super(null);

  final Ref _ref;

  /// Opens an artifact in the viewer.
  void open(FullArtifact artifact) {
    state = artifact;
    // Reset tab to appropriate default
    _ref.read(artifactViewTabProvider.notifier).state =
        artifact.type.defaultsToPreview
            ? ArtifactViewTab.preview
            : ArtifactViewTab.source;
  }

  /// Opens an artifact by ID, loading from the server.
  Future<void> openById(String artifactId) async {
    try {
      final repo = _ref.read(artifactRepositoryProvider);
      final artifact = await repo.getById(artifactId);
      state = artifact;
      _ref.read(artifactViewTabProvider.notifier).state =
          artifact.type.defaultsToPreview
              ? ArtifactViewTab.preview
              : ArtifactViewTab.source;
    } on Object {
      // Error handled by caller
    }
  }

  /// Updates the artifact content (from the editor).
  void updateContent(String newContent) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
    );
  }

  /// Replaces the current artifact with an updated version from the server.
  // ignore: use_setters_to_change_properties
  void replace(FullArtifact updated) => state = updated;

  /// Closes the artifact viewer.
  void close() {
    state = null;
  }
}

// ---- Artifact Versions ----

/// Sealed state for version loading.
sealed class VersionsState {
  const VersionsState();
}

final class VersionsInitial extends VersionsState {
  const VersionsInitial();
}

final class VersionsLoading extends VersionsState {
  const VersionsLoading();
}

final class VersionsLoaded extends VersionsState {
  const VersionsLoaded({required this.versions});
  final List<ArtifactVersion> versions;
}

final class VersionsError extends VersionsState {
  const VersionsError({required this.message});
  final String message;
}

/// Provider for the artifact versions list.
final artifactVersionsProvider =
    StateNotifierProvider<ArtifactVersionsNotifier, VersionsState>(ArtifactVersionsNotifier.new);

/// Notifier that loads and manages artifact versions.
class ArtifactVersionsNotifier extends StateNotifier<VersionsState> {
  ArtifactVersionsNotifier(this._ref) : super(const VersionsInitial());

  final Ref _ref;

  /// Loads versions for the given artifact.
  Future<void> loadVersions(String artifactId) async {
    state = const VersionsLoading();
    try {
      final repo = _ref.read(artifactRepositoryProvider);
      final versions = await repo.getVersions(artifactId);
      state = VersionsLoaded(versions: versions);
    } on Object catch (e) {
      state = VersionsError(message: e.toString());
    }
  }

  /// Restores the artifact to a specific version.
  Future<void> restoreVersion({
    required String artifactId,
    required int versionNumber,
  }) async {
    try {
      final repo = _ref.read(artifactRepositoryProvider);
      final updated = await repo.restoreVersion(
        artifactId: artifactId,
        versionNumber: versionNumber,
      );
      // Update the current artifact with restored content
      _ref.read(currentArtifactProvider.notifier).replace(updated);
      // Reload versions to reflect the new state
      await loadVersions(artifactId);
    } on Object catch (e) {
      state = VersionsError(message: e.toString());
    }
  }

  /// Resets to initial state.
  void reset() {
    state = const VersionsInitial();
  }
}

// ---- Export State ----

/// Sealed state for export operations.
sealed class ExportState {
  const ExportState();
}

final class ExportIdle extends ExportState {
  const ExportIdle();
}

final class ExportInProgress extends ExportState {
  const ExportInProgress({required this.format});
  final ExportFormat format;
}

final class ExportSuccess extends ExportState {
  const ExportSuccess({required this.format, required this.data});
  final ExportFormat format;
  final List<int> data;
}

final class ExportError extends ExportState {
  const ExportError({required this.message});
  final String message;
}

/// Provider for the export operation state.
final exportProvider =
    StateNotifierProvider<ExportNotifier, ExportState>(ExportNotifier.new);

/// Notifier that manages artifact export operations.
class ExportNotifier extends StateNotifier<ExportState> {
  ExportNotifier(this._ref) : super(const ExportIdle());

  final Ref _ref;

  /// Exports the current artifact in the specified format.
  Future<void> exportArtifact({
    required String artifactId,
    required ExportFormat format,
  }) async {
    // Handle copy specially -- no server round-trip needed
    if (format == ExportFormat.copy) {
      final artifact = _ref.read(currentArtifactProvider);
      if (artifact != null) {
        await Clipboard.setData(ClipboardData(text: artifact.content));
        state = ExportSuccess(
          format: format,
          data: utf8.encode(artifact.content),
        );
        return;
      }
    }

    state = ExportInProgress(format: format);
    try {
      final repo = _ref.read(artifactRepositoryProvider);
      final data = await repo.export(
        artifactId: artifactId,
        format: format,
      );
      state = ExportSuccess(format: format, data: data);
    } on Object catch (e) {
      state = ExportError(message: e.toString());
    }
  }

  /// Saves the current artifact content to the server.
  Future<void> saveContent({
    required String artifactId,
    required String content,
    String? title,
  }) async {
    try {
      final repo = _ref.read(artifactRepositoryProvider);
      final updated = await repo.update(
        artifactId: artifactId,
        content: content,
        title: title,
      );
      _ref.read(currentArtifactProvider.notifier).replace(updated);
    } on Object {
      // Error handled silently; auto-save should not disrupt
    }
  }

  /// Resets to idle state.
  void reset() {
    state = const ExportIdle();
  }
}

// ---- Selected Export Format ----

/// The currently selected export format in the dropdown.
final selectedExportFormatProvider = StateProvider<ExportFormat>((ref) => ExportFormat.docx);

/// Artifacts feature barrel export.
///
/// Exports all public APIs for the artifacts feature including entities,
/// repositories, providers, screens, and widgets.
library;

// Data
export 'data/datasources/artifact_remote_datasource.dart';
export 'data/models/artifact_model.dart';
export 'data/models/artifact_version_model.dart';
export 'data/repositories/artifact_repository_impl.dart';
export 'data/services/artifact_parser.dart';
// Domain
export 'domain/entities/artifact.dart';
export 'domain/entities/artifact_version.dart';
export 'domain/repositories/artifact_repository.dart';
// Presentation
export 'presentation/providers/artifact_provider.dart';
export 'presentation/screens/artifact_view_screen.dart';
export 'presentation/widgets/code_preview.dart';
export 'presentation/widgets/document_editor.dart';
export 'presentation/widgets/document_preview.dart';
export 'presentation/widgets/editor_toolbar.dart';
export 'presentation/widgets/export_menu.dart';
export 'presentation/widgets/markdown_editor.dart';
export 'presentation/widgets/version_selector.dart';

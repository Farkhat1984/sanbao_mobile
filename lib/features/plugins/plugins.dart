/// Plugins feature barrel export.
///
/// Exports all public APIs for the plugins feature including entities,
/// repositories, providers, screens, and widgets.
library;

// Data
export 'data/datasources/plugin_remote_datasource.dart';
export 'data/models/plugin_model.dart';
export 'data/repositories/plugin_repository_impl.dart';
// Domain
export 'domain/entities/plugin.dart';
export 'domain/repositories/plugin_repository.dart';
// Presentation
export 'presentation/providers/plugins_provider.dart';
export 'presentation/screens/plugin_form_screen.dart';
export 'presentation/screens/plugin_list_screen.dart';

/// Tools feature barrel export.
///
/// Exports all public APIs for the tools feature including entities,
/// repositories, providers, screens, and widgets.
library;

// Domain
export 'domain/entities/tool.dart';
export 'domain/repositories/tool_repository.dart';

// Data
export 'data/datasources/tool_remote_datasource.dart';
export 'data/models/tool_model.dart';
export 'data/repositories/tool_repository_impl.dart';

// Presentation
export 'presentation/providers/tools_provider.dart';
export 'presentation/screens/tool_form_screen.dart';
export 'presentation/screens/tool_list_screen.dart';
export 'presentation/widgets/tool_card.dart';
export 'presentation/widgets/tool_type_selector.dart';

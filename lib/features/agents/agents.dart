/// Agents feature barrel export.
///
/// Exports all public APIs for the agents feature including entities,
/// repositories, providers, screens, and widgets.
library;

// Data
export 'data/datasources/agent_remote_datasource.dart';
export 'data/models/agent_model.dart';
export 'data/repositories/agent_repository_impl.dart';
// Domain
export 'domain/entities/agent.dart';
export 'domain/repositories/agent_repository.dart';
// Presentation
export 'presentation/providers/agents_provider.dart';
export 'presentation/screens/agent_detail_screen.dart';
export 'presentation/screens/agent_form_screen.dart';
export 'presentation/screens/agent_list_screen.dart';
export 'presentation/widgets/agent_card.dart';
export 'presentation/widgets/agent_icon.dart';
export 'presentation/widgets/starter_prompts.dart';

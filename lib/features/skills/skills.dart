/// Skills feature barrel export.
///
/// Exports all public APIs for the skills feature including entities,
/// repositories, providers, screens, and widgets.
library;

// Domain
export 'domain/entities/skill.dart';
export 'domain/repositories/skill_repository.dart';

// Data
export 'data/datasources/skill_remote_datasource.dart';
export 'data/models/skill_model.dart';
export 'data/repositories/skill_repository_impl.dart';

// Presentation
export 'presentation/providers/skills_provider.dart';
export 'presentation/screens/skill_detail_screen.dart';
export 'presentation/screens/skill_form_screen.dart';
export 'presentation/screens/skill_list_screen.dart';
export 'presentation/widgets/skill_card.dart';
export 'presentation/widgets/skill_selector.dart';

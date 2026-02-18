/// Profile feature barrel export.
///
/// Exports all public APIs for the profile feature including
/// repositories, providers, screens, and widgets.
library;

// Domain
export 'domain/repositories/profile_repository.dart';

// Data
export 'data/datasources/profile_remote_datasource.dart';
export 'data/repositories/profile_repository_impl.dart';

// Presentation
export 'presentation/providers/profile_provider.dart';
export 'presentation/screens/edit_profile_screen.dart';
export 'presentation/screens/profile_screen.dart';
export 'presentation/widgets/avatar_picker.dart';
export 'presentation/widgets/locale_selector.dart';

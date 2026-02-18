/// Auth feature barrel export.
///
/// Exports all public APIs for authentication including entities,
/// repositories, providers, screens, and widgets.
library;

// Domain
export 'domain/entities/auth_token.dart';
export 'domain/entities/user.dart';
export 'domain/repositories/auth_repository.dart';
export 'domain/usecases/login_usecase.dart';
export 'domain/usecases/logout_usecase.dart';
export 'domain/usecases/register_usecase.dart';
export 'domain/usecases/setup_2fa_usecase.dart';

// Data
export 'data/datasources/auth_local_datasource.dart';
export 'data/datasources/auth_remote_datasource.dart';
export 'data/models/token_model.dart';
export 'data/models/user_model.dart';
export 'data/repositories/auth_repository_impl.dart';

// Presentation
export 'presentation/providers/auth_provider.dart';
export 'presentation/screens/login_screen.dart';
export 'presentation/screens/register_screen.dart';
export 'presentation/widgets/login_form.dart';
export 'presentation/widgets/social_login_button.dart';
export 'presentation/widgets/two_factor_input.dart';

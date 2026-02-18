/// Notifications feature barrel export.
///
/// Exports all public APIs for the notifications feature including
/// entities, repositories, providers, services, and widgets.
library;

// Data
export 'data/datasources/notification_remote_datasource.dart';
export 'data/models/notification_model.dart';
export 'data/repositories/notification_repository_impl.dart';
export 'data/services/notification_polling_service.dart';

// Domain
export 'domain/entities/notification.dart';
export 'domain/repositories/notification_repository.dart';

// Presentation
export 'presentation/providers/notification_provider.dart';
export 'presentation/widgets/notification_bell.dart';
export 'presentation/widgets/notification_list.dart';

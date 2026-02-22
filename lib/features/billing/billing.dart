/// Billing feature barrel export.
///
/// Exports all public APIs for the billing feature including entities,
/// repositories, providers, screens, and widgets.
library;

// Data
export 'data/datasources/billing_remote_datasource.dart';
export 'data/models/plan_model.dart';
export 'data/models/subscription_model.dart';
export 'data/models/usage_model.dart';
export 'data/repositories/billing_repository_impl.dart';
// Domain
export 'domain/entities/plan.dart';
export 'domain/entities/subscription.dart';
export 'domain/entities/usage.dart';
export 'domain/repositories/billing_repository.dart';
// Presentation
export 'presentation/providers/billing_provider.dart';
export 'presentation/screens/billing_screen.dart';
export 'presentation/screens/payment_success_screen.dart';
export 'presentation/screens/plans_screen.dart';
export 'presentation/widgets/plan_card.dart';
export 'presentation/widgets/subscription_badge.dart';
export 'presentation/widgets/usage_indicator.dart';

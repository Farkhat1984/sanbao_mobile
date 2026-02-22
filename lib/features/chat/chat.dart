/// Chat feature barrel export.
///
/// Exports all public APIs for chat including entities,
/// repositories, providers, screens, and widgets.
library;

// Data
export 'data/datasources/chat_local_datasource.dart';
export 'data/datasources/chat_remote_datasource.dart';
export 'data/datasources/conversation_remote_datasource.dart';
export 'data/datasources/file_remote_datasource.dart';
export 'data/datasources/report_datasource.dart';
export 'data/models/chat_event_model.dart';
export 'data/models/conversation_model.dart';
export 'data/models/message_model.dart';
export 'data/repositories/chat_repository_impl.dart';
export 'data/repositories/conversation_repository_impl.dart';
// Domain
export 'domain/entities/artifact.dart';
export 'domain/entities/chat_event.dart';
export 'domain/entities/conversation.dart';
export 'domain/entities/message.dart';
export 'domain/repositories/chat_repository.dart';
export 'domain/repositories/conversation_repository.dart';
export 'domain/usecases/load_conversations_usecase.dart';
export 'domain/usecases/send_message_usecase.dart';
// Presentation
export 'presentation/providers/chat_provider.dart';
export 'presentation/providers/conversations_provider.dart';
export 'presentation/providers/file_provider.dart';
export 'presentation/providers/voice_provider.dart';
export 'presentation/screens/chat_screen.dart';
export 'presentation/screens/conversation_list_screen.dart';
export 'presentation/screens/main_layout.dart';
export 'presentation/widgets/app_drawer.dart';
export 'presentation/widgets/artifact_card.dart';
export 'presentation/widgets/conversation_item.dart';
export 'presentation/widgets/feature_badges.dart';
export 'presentation/widgets/file_attachment.dart';
export 'presentation/widgets/file_picker_sheet.dart';
export 'presentation/widgets/image_preview.dart';
export 'presentation/widgets/legal_ref_badge.dart';
export 'presentation/widgets/markdown_renderer.dart';
export 'presentation/widgets/message_bubble.dart';
export 'presentation/widgets/message_input.dart';
export 'presentation/widgets/new_chat_button.dart';
export 'presentation/widgets/report_dialog.dart';
export 'presentation/widgets/search_field.dart';
export 'presentation/widgets/thinking_indicator.dart';
export 'presentation/widgets/user_footer.dart';
export 'presentation/widgets/voice_button.dart';
export 'presentation/widgets/welcome_screen.dart';

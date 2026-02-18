/// MCP (Model Context Protocol) feature barrel export.
///
/// Exports all public APIs for the MCP servers feature including
/// entities, repositories, providers, screens, and widgets.
library;

// Domain
export 'domain/entities/mcp_server.dart';
export 'domain/repositories/mcp_repository.dart';

// Data
export 'data/datasources/mcp_remote_datasource.dart';
export 'data/models/mcp_server_model.dart';
export 'data/repositories/mcp_repository_impl.dart';

// Presentation
export 'presentation/providers/mcp_provider.dart';
export 'presentation/screens/mcp_form_screen.dart';
export 'presentation/screens/mcp_list_screen.dart';
export 'presentation/widgets/mcp_server_card.dart';
export 'presentation/widgets/mcp_status_badge.dart';

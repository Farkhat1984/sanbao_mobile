/// MCP server list screen with status indicators and add FAB.
///
/// Displays all MCP servers in a list with search, status badges,
/// and the ability to test connections inline.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/empty_state.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/mcp/domain/entities/mcp_server.dart';
import 'package:sanbao_flutter/features/mcp/presentation/providers/mcp_provider.dart';
import 'package:sanbao_flutter/features/mcp/presentation/screens/mcp_form_screen.dart';
import 'package:sanbao_flutter/features/mcp/presentation/widgets/mcp_server_card.dart';

/// Screen displaying all MCP server connections.
///
/// Shows a list of configured MCP servers with their connection
/// status. Includes search, test connection, and a FAB to add
/// new servers.
class McpListScreen extends ConsumerStatefulWidget {
  const McpListScreen({super.key});

  @override
  ConsumerState<McpListScreen> createState() => _McpListScreenState();
}

class _McpListScreenState extends ConsumerState<McpListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ignore: use_setters_to_change_properties
  void _onSearchChanged(String query) {
    ref.read(mcpSearchQueryProvider.notifier).state = query;
  }

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const McpFormScreen(),
      ),
    );
  }

  void _navigateToEdit(McpServer server) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => McpFormScreen(server: server),
      ),
    );
  }

  Future<void> _testConnection(McpServer server) async {
    ref.read(mcpTestingServerIdProvider.notifier).state = server.id;
    try {
      final updated = await ref
          .read(mcpServersProvider.notifier)
          .testConnection(server.id);
      if (mounted) {
        if (updated.status == McpServerStatus.connected) {
          context.showSuccessSnackBar('Сервер подключен успешно');
        } else {
          context.showErrorSnackBar(
            updated.errorMessage ?? 'Не удалось подключиться',
          );
        }
      }
    } on Object catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Ошибка проверки: $e');
      }
    } finally {
      ref.read(mcpTestingServerIdProvider.notifier).state = null;
    }
  }

  Future<void> _deleteServer(McpServer server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сервер'),
        content: Text('Удалить MCP сервер "${server.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Удалить',
              style: TextStyle(color: context.sanbaoColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(mcpServersProvider.notifier).deleteServer(server.id);
      if (mounted) {
        context.showSnackBar('Сервер "${server.name}" удален');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;
    final filteredServers = ref.watch(filteredMcpServersProvider);
    final testingId = ref.watch(mcpTestingServerIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP серверы'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreate,
        backgroundColor: colors.accent,
        foregroundColor: colors.textInverse,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(mcpServersProvider.notifier).refresh(),
        color: colors.accent,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchField(colors)),
            filteredServers.when(
              loading: () => SliverToBoxAdapter(
                child: _McpListSkeleton(),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: EmptyState.error(
                  message: 'Не удалось загрузить серверы',
                  onRetry: () =>
                      ref.read(mcpServersProvider.notifier).refresh(),
                ),
              ),
              data: (servers) {
                if (servers.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.dns_outlined,
                      title: 'Нет MCP серверов',
                      message:
                          'Добавьте MCP сервер для расширения возможностей агентов',
                      actionLabel: 'Добавить сервер',
                      onAction: _navigateToCreate,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: servers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      return Dismissible(
                        key: ValueKey(server.id),
                        direction: DismissDirection.endToStart,
                        background: _buildDismissBackground(colors),
                        confirmDismiss: (_) async {
                          await _deleteServer(server);
                          return false; // We handle deletion manually
                        },
                        child: McpServerCard(
                          server: server,
                          onTap: () => _navigateToEdit(server),
                          onTestConnection: () => _testConnection(server),
                          isTesting: testingId == server.id,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(SanbaoColorScheme colors) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Поиск серверов...',
            hintStyle: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 18,
              color: colors.textMuted,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: Icon(Icons.close, size: 16, color: colors.textMuted),
                  )
                : null,
            filled: true,
            fillColor: colors.bgSurfaceAlt,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: SanbaoRadius.md,
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: SanbaoRadius.md,
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: SanbaoRadius.md,
              borderSide: BorderSide(color: colors.borderFocus, width: 1.5),
            ),
            isDense: true,
          ),
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textPrimary,
          ),
        ),
      );

  Widget _buildDismissBackground(SanbaoColorScheme colors) => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.errorLight,
          borderRadius: SanbaoRadius.lg,
        ),
        child: Icon(Icons.delete_outline, color: colors.error),
      );
}

/// Skeleton loading state for the MCP server list.
class _McpListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            3,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SanbaoSkeleton.box(),
            ),
          ),
        ),
      );
}

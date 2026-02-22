/// Full app drawer with logo, new chat, search, conversation list, and user footer.
///
/// Implements the sidebar design from the web project with glassmorphism
/// background, grouped conversation list, and responsive behavior.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanbao_flutter/core/config/routes.dart';
import 'package:sanbao_flutter/core/theme/colors.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_compass.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/conversation.dart';
import 'package:sanbao_flutter/features/chat/domain/usecases/load_conversations_usecase.dart';
import 'package:sanbao_flutter/features/chat/presentation/providers/chat_provider.dart';
import 'package:sanbao_flutter/features/chat/presentation/providers/conversations_provider.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/conversation_item.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/new_chat_button.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/search_field.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/user_footer.dart';

/// Provider for the drawer search query state.
final drawerSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider that filters grouped conversations based on search query.
final filteredGroupedConversationsProvider =
    Provider.autoDispose<AsyncValue<List<ConversationGroup>>>((ref) {
  final groupedAsync = ref.watch(groupedConversationsProvider);
  final query = ref.watch(drawerSearchQueryProvider).toLowerCase().trim();

  if (query.isEmpty) return groupedAsync;

  return groupedAsync.whenData((groups) {
    final filtered = <ConversationGroup>[];
    for (final group in groups) {
      final matchingConversations = group.conversations
          .where((c) =>
              c.title.toLowerCase().contains(query) ||
              (c.lastMessagePreview?.toLowerCase().contains(query) ?? false),)
          .toList();

      if (matchingConversations.isNotEmpty) {
        filtered.add(ConversationGroup(
          label: group.label,
          conversations: matchingConversations,
        ),);
      }
    }
    return filtered;
  });
});

/// The full sidebar drawer widget.
///
/// Structure (matching web Sidebar.tsx):
/// 1. Header with logo and close button
/// 2. New Chat button
/// 3. Search field
/// 4. Scrollable conversation list grouped by date
/// 5. User footer with avatar, name, and settings
class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    this.onConversationSelected,
    this.onNewChat,
    this.onSettingsTap,
    this.onProfileTap,
    this.onClose,
  });

  /// Callback when a conversation is selected.
  final void Function(String conversationId)? onConversationSelected;

  /// Callback when the new chat button is pressed.
  final VoidCallback? onNewChat;

  /// Callback when settings is tapped in the footer.
  final VoidCallback? onSettingsTap;

  /// Callback when the user profile area is tapped.
  final VoidCallback? onProfileTap;

  /// Callback to close the drawer (mobile only).
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;
    final isStreaming = ref.watch(isStreamingProvider);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: ColoredBox(
          color: colors.sidebarBg,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 1. Header
                _DrawerHeader(
                  isStreaming: isStreaming,
                  onClose: onClose,
                ),

                // 2. New Chat button
                NewChatButton(
                  onPressed: () {
                    ref.read(chatControllerProvider).startNewConversation();
                    onNewChat?.call();
                  },
                ),

                const SizedBox(height: 4),

                // 3. Search field
                SearchField(
                  onChanged: (query) {
                    ref.read(drawerSearchQueryProvider.notifier).state = query;
                  },
                ),

                // 4. Conversation list
                Expanded(
                  child: _ConversationListSection(
                    onConversationSelected: onConversationSelected,
                  ),
                ),

                // 5. Feature navigation links
                const _FeatureNavSection(),

                // 6. User footer
                UserFooter(
                  onSettingsTap: onSettingsTap,
                  onProfileTap: onProfileTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header row with Sanbao logo/name and close button.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.isStreaming,
    this.onClose,
  });

  final bool isStreaming;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Logo icon
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [SanbaoColors.gradientStart, SanbaoColors.gradientEnd],
                ),
                borderRadius: SanbaoRadius.md,
              ),
              child: Center(
                child: SanbaoCompass(
                  state: isStreaming ? CompassState.loading : CompassState.idle,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // App name
            Expanded(
              child: Text(
                'Sanbao',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // Close button (visible when onClose is provided)
            if (onClose != null)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onClose?.call();
                  },
                  borderRadius: SanbaoRadius.sm,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 16,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable section displaying conversations grouped by date.
class _ConversationListSection extends ConsumerWidget {
  const _ConversationListSection({
    this.onConversationSelected,
  });

  final void Function(String conversationId)? onConversationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredGroups = ref.watch(filteredGroupedConversationsProvider);
    final currentConversationId = ref.watch(currentConversationIdProvider);

    return filteredGroups.when(
      data: (groups) => _buildGroupedList(
        context,
        ref,
        groups,
        currentConversationId,
      ),
      loading: () => const _DrawerLoadingSkeleton(),
      error: (error, _) => _buildErrorState(context, ref),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    WidgetRef ref,
    List<ConversationGroup> groups,
    String? selectedId,
  ) {
    if (groups.isEmpty) {
      return _buildEmptyState(context);
    }

    // Build flat list items with headers
    final items = <_ListItem>[];
    for (final group in groups) {
      items.add(_ListItem.header(group.label));
      for (final conversation in group.conversations) {
        items.add(_ListItem.conversation(conversation));
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(groupedConversationsProvider);
      },
      color: context.sanbaoColors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return switch (item) {
            _HeaderItem(:final label) => _buildSectionHeader(context, label),
            _ConversationListItem(:final conversation) => ConversationItem(
                conversation: conversation,
                isSelected: conversation.id == selectedId,
                onTap: () {
                  onConversationSelected?.call(conversation.id);
                  ref
                      .read(chatControllerProvider)
                      .loadConversation(conversation.id);
                },
                onPin: () {
                  ref
                      .read(conversationsListProvider.notifier)
                      .togglePin(conversation.id);
                },
                onArchive: () {
                  ref
                      .read(conversationsListProvider.notifier)
                      .toggleArchive(conversation.id);
                },
                onDelete: () {
                  ref
                      .read(conversationsListProvider.notifier)
                      .deleteConversation(conversation.id);

                  if (conversation.id == selectedId) {
                    ref.read(chatControllerProvider).startNewConversation();
                  }
                },
                onRename: () => _showRenameDialog(
                  context,
                  ref,
                  conversation.id,
                  conversation.title,
                ),
              ),
          };
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label) {
    final colors = context.sanbaoColors;

    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 4,
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(
          color: colors.textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.sanbaoColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.accentLight,
                borderRadius: SanbaoRadius.md,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 22,
                color: colors.accent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Нет чатов',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Начните новый разговор',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    final colors = context.sanbaoColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: colors.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Ошибка загрузки',
              style: context.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Проверьте подключение',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                ref.invalidate(groupedConversationsProvider);
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    String conversationId,
    String currentTitle,
  ) {
    final controller = TextEditingController(text: currentTitle);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать чат'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Название чата',
          ),
          onSubmitted: (value) {
            Navigator.of(context).pop();
            if (value.trim().isNotEmpty) {
              ref
                  .read(conversationsListProvider.notifier)
                  .renameConversation(conversationId, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                ref
                    .read(conversationsListProvider.notifier)
                    .renameConversation(conversationId, value);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}

/// Compact row of feature navigation icons between conversation list and footer.
class _FeatureNavSection extends StatelessWidget {
  const _FeatureNavSection();

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _NavIcon(
              icon: Icons.smart_toy_rounded,
              label: 'Агенты',
              path: RoutePaths.agents,
            ),
          ),
          Expanded(
            child: _NavIcon(
              icon: Icons.auto_fix_high_rounded,
              label: 'Навыки',
              path: RoutePaths.skills,
            ),
          ),
          Expanded(
            child: _NavIcon(
              icon: Icons.build_rounded,
              label: 'Тулы',
              path: RoutePaths.tools,
            ),
          ),
          Expanded(
            child: _NavIcon(
              icon: Icons.extension_rounded,
              label: 'Плагины',
              path: RoutePaths.plugins,
            ),
          ),
          Expanded(
            child: _NavIcon(
              icon: Icons.dns_rounded,
              label: 'MCP',
              path: RoutePaths.mcpServers,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single navigation icon button in the feature nav row.
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    final colors = context.sanbaoColors;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            // Close drawer on mobile before navigating
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.hasDrawer && scaffold.isDrawerOpen) {
              Navigator.of(context).pop();
            }
            context.push(path);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: colors.textSecondary),
                const SizedBox(height: 2),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading skeleton for the drawer conversation list.
class _DrawerLoadingSkeleton extends StatelessWidget {
  const _DrawerLoadingSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Section header skeleton
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 12, bottom: 8),
          child: SanbaoSkeleton.line(width: 70, height: 10),
        ),
        // Conversation item skeletons
        for (var i = 0; i < 6; i++) const SanbaoConversationSkeleton(),
      ],
    );
}

// ---- Sealed list item types for type-safe rendering ----

/// Sealed type for list items in the grouped conversation list.
sealed class _ListItem {
  const _ListItem();

  factory _ListItem.header(String label) = _HeaderItem;
  factory _ListItem.conversation(
    Conversation conversation,
  ) = _ConversationListItem;
}

/// A section header item with a date label.
class _HeaderItem extends _ListItem {
  const _HeaderItem(this.label);

  final String label;
}

/// A conversation item entry.
class _ConversationListItem extends _ListItem {
  const _ConversationListItem(this.conversation);

  final Conversation conversation;
}

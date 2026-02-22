/// Conversation list screen for standalone use.
///
/// Displays conversations grouped by date (Сегодня, Вчера,
/// На этой неделе, Ранее) with pull-to-refresh, loading skeleton,
/// empty state, and error handling. Used both in the sidebar drawer
/// and as a standalone route.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/theme/radius.dart';
import 'package:sanbao_flutter/core/utils/extensions.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_compass.dart';
import 'package:sanbao_flutter/core/widgets/sanbao_skeleton.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/conversation.dart';
import 'package:sanbao_flutter/features/chat/domain/usecases/load_conversations_usecase.dart';
import 'package:sanbao_flutter/features/chat/presentation/providers/chat_provider.dart';
import 'package:sanbao_flutter/features/chat/presentation/providers/conversations_provider.dart';
import 'package:sanbao_flutter/features/chat/presentation/widgets/conversation_item.dart';

/// Screen displaying the list of conversations.
///
/// Features:
/// - Grouped by date with section headers
/// - Pull-to-refresh
/// - New chat button in app bar
/// - Loading skeleton state
/// - Empty state with illustration
/// - Error state with retry
/// - Swipe actions on items
class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({
    super.key,
    this.onConversationSelected,
    this.onNewChat,
  });

  /// Callback when a conversation is selected.
  final void Function(String conversationId)? onConversationSelected;

  /// Callback when new chat is requested.
  final VoidCallback? onNewChat;

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  @override
  Widget build(BuildContext context) {
    final groupedConversations = ref.watch(groupedConversationsProvider);
    final currentConversationId = ref.watch(currentConversationIdProvider);
    final colors = context.sanbaoColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            SanbaoCompass(
              size: 20,
              color: colors.accent,
            ),
            const SizedBox(width: 8),
            const Text('Sanbao'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              widget.onNewChat?.call();
              ref.read(chatControllerProvider).startNewConversation();
            },
            icon: Icon(
              Icons.edit_square,
              color: colors.accent,
              size: 22,
            ),
            tooltip: 'Новый чат',
          ),
        ],
      ),
      body: groupedConversations.when(
        data: (groups) => _buildGroupedList(
          context,
          groups,
          currentConversationId,
        ),
        loading: () => const _LoadingSkeleton(),
        error: (error, _) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    List<ConversationGroup> groups,
    String? selectedId,
  ) {
    final colors = context.sanbaoColors;

    if (groups.isEmpty) {
      return _buildEmptyState(context);
    }

    // Build flat items from groups
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
      color: colors.accent,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return switch (item) {
            _HeaderItem(:final label) => _buildSectionHeader(context, label),
            _ConversationEntry(:final conversation) => ConversationItem(
                conversation: conversation,
                isSelected: conversation.id == selectedId,
                onTap: () {
                  widget.onConversationSelected?.call(conversation.id);
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

                  // If the deleted conversation was selected, start a new chat
                  if (conversation.id == selectedId) {
                    ref.read(chatControllerProvider).startNewConversation();
                  }
                },
                onRename: () => _showRenameDialog(
                  context,
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.accentLight,
                borderRadius: SanbaoRadius.lg,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 28,
                color: colors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет чатов',
              style: context.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Начните новый разговор,\nнажав кнопку выше',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final colors = context.sanbaoColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Не удалось загрузить чаты',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Проверьте подключение к интернету',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                ref.invalidate(groupedConversationsProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
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

/// Loading skeleton for the conversation list.
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Section header skeleton
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 16, bottom: 8),
          child: SanbaoSkeleton.line(width: 80, height: 10),
        ),
        // Conversation item skeletons
        for (var i = 0; i < 8; i++) const SanbaoConversationSkeleton(),
      ],
    );
}

// ---- Sealed list item types ----

/// Sealed type for flat list rendering of grouped conversations.
sealed class _ListItem {
  const _ListItem();

  factory _ListItem.header(String label) = _HeaderItem;
  factory _ListItem.conversation(
    Conversation conversation,
  ) = _ConversationEntry;
}

/// A date group header.
class _HeaderItem extends _ListItem {
  const _HeaderItem(this.label);

  final String label;
}

/// A conversation item in the list.
class _ConversationEntry extends _ListItem {
  const _ConversationEntry(this.conversation);

  final Conversation conversation;
}

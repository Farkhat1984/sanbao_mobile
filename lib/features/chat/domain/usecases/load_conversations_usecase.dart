/// Use case for loading the conversations list.
///
/// Fetches conversations from the repository and groups them
/// by date for display in the sidebar.
library;

import 'package:sanbao_flutter/core/utils/formatters.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/conversation.dart';
import 'package:sanbao_flutter/features/chat/domain/repositories/conversation_repository.dart';

/// A group of conversations sharing the same date label.
class ConversationGroup {
  const ConversationGroup({
    required this.label,
    required this.conversations,
  });

  /// Group header label (e.g., "Сегодня", "Вчера", "Эта неделя", "Ранее").
  final String label;

  /// Conversations in this group, sorted by most recent first.
  final List<Conversation> conversations;
}

/// Loads and optionally groups conversations by date.
///
/// Pinned conversations are always shown first, followed by
/// the rest grouped by their last activity date.
class LoadConversationsUseCase {
  const LoadConversationsUseCase({
    required ConversationRepository repository,
  }) : _repository = repository;

  final ConversationRepository _repository;

  /// Fetches conversations and returns them as a flat list,
  /// sorted with pinned first, then by [Conversation.updatedAt] descending.
  Future<List<Conversation>> call({
    int limit = 50,
    int offset = 0,
  }) async {
    final conversations = await _repository.getConversations(
      limit: limit,
      offset: offset,
    );

    // Sort: pinned first, then by updatedAt descending
    return List.of(conversations)
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
  }

  /// Fetches conversations and groups them by date.
  ///
  /// Returns a list of [ConversationGroup]s with labels matching
  /// the Russian date grouping convention: Сегодня, Вчера,
  /// Эта неделя, Ранее.
  Future<List<ConversationGroup>> callGrouped({
    int limit = 50,
    int offset = 0,
  }) async {
    final conversations = await call(limit: limit, offset: offset);

    // Separate pinned and unpinned
    final pinned = conversations.where((c) => c.isPinned).toList();
    final unpinned = conversations.where((c) => !c.isPinned).toList();

    final groups = <ConversationGroup>[];

    // Add pinned group if any
    if (pinned.isNotEmpty) {
      groups.add(ConversationGroup(
        label: 'Закрепленные',
        conversations: pinned,
      ),);
    }

    // Group unpinned by date
    final dateGroups = <String, List<Conversation>>{};
    for (final conversation in unpinned) {
      final label = Formatters.formatChatGroup(conversation.updatedAt);
      dateGroups.putIfAbsent(label, () => []).add(conversation);
    }

    // Add date groups in order
    const groupOrder = ['Сегодня', 'Вчера', 'Эта неделя', 'Ранее'];
    for (final label in groupOrder) {
      final convs = dateGroups[label];
      if (convs != null && convs.isNotEmpty) {
        groups.add(ConversationGroup(
          label: label,
          conversations: convs,
        ),);
      }
    }

    return groups;
  }
}

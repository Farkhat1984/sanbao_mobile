/// Conversations list providers with date grouping.
///
/// Manages the sidebar conversation list state, including
/// loading, grouping by date, and CRUD operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/chat/data/repositories/conversation_repository_impl.dart';
import 'package:sanbao_flutter/features/chat/domain/entities/conversation.dart';
import 'package:sanbao_flutter/features/chat/domain/usecases/load_conversations_usecase.dart';

// ---- Use Case Provider ----

/// Provider for the load conversations use case.
final loadConversationsUseCaseProvider =
    Provider<LoadConversationsUseCase>((ref) {
  final repository = ref.watch(conversationRepositoryProvider);
  return LoadConversationsUseCase(repository: repository);
});

// ---- Conversations List ----

/// The raw conversations list, auto-refreshable.
final conversationsListProvider =
    AsyncNotifierProvider<ConversationsListNotifier, List<Conversation>>(
  ConversationsListNotifier.new,
);

/// Notifier for the conversations list with CRUD operations.
class ConversationsListNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    final useCase = ref.watch(loadConversationsUseCaseProvider);
    return useCase.call();
  }

  /// Refreshes the conversations list from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(loadConversationsUseCaseProvider);
      return useCase.call();
    });
  }

  /// Adds a new conversation to the list optimistically.
  void addConversation(Conversation conversation) {
    final current = state.valueOrNull ?? [];
    state = AsyncData([conversation, ...current]);
  }

  /// Updates a conversation in the list.
  void updateConversation(Conversation updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((c) => c.id == updated.id ? updated : c).toList(),
    );
  }

  /// Removes a conversation from the list.
  void removeConversation(String id) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((c) => c.id != id).toList());
  }

  /// Pins or unpins a conversation.
  Future<void> togglePin(String id) async {
    final current = state.valueOrNull ?? [];
    final conversation = current.where((c) => c.id == id).firstOrNull;
    if (conversation == null) return;

    final updatedConversation = conversation.copyWith(
      isPinned: !conversation.isPinned,
    );
    updateConversation(updatedConversation);

    try {
      final repo = ref.read(conversationRepositoryProvider);
      await repo.updateConversation(
        id: id,
        isPinned: !conversation.isPinned,
      );
    } on Object {
      // Revert on failure
      updateConversation(conversation);
    }
  }

  /// Archives or unarchives a conversation.
  Future<void> toggleArchive(String id) async {
    final current = state.valueOrNull ?? [];
    final conversation = current.where((c) => c.id == id).firstOrNull;
    if (conversation == null) return;

    final updatedConversation = conversation.copyWith(
      isArchived: !conversation.isArchived,
    );
    updateConversation(updatedConversation);

    try {
      final repo = ref.read(conversationRepositoryProvider);
      await repo.updateConversation(
        id: id,
        isArchived: !conversation.isArchived,
      );
    } on Object {
      updateConversation(conversation);
    }
  }

  /// Deletes a conversation permanently.
  Future<void> deleteConversation(String id) async {
    final current = state.valueOrNull ?? [];
    final conversation = current.where((c) => c.id == id).firstOrNull;

    removeConversation(id);

    try {
      final repo = ref.read(conversationRepositoryProvider);
      await repo.deleteConversation(id);
    } on Object {
      // Revert on failure
      if (conversation != null) {
        addConversation(conversation);
      }
    }
  }

  /// Renames a conversation.
  Future<void> renameConversation(String id, String newTitle) async {
    final current = state.valueOrNull ?? [];
    final conversation = current.where((c) => c.id == id).firstOrNull;
    if (conversation == null) return;

    final updatedConversation = conversation.copyWith(title: newTitle);
    updateConversation(updatedConversation);

    try {
      final repo = ref.read(conversationRepositoryProvider);
      await repo.updateConversation(id: id, title: newTitle);
    } on Object {
      updateConversation(conversation);
    }
  }
}

// ---- Grouped Conversations ----

/// Conversations grouped by date labels.
final groupedConversationsProvider =
    FutureProvider.autoDispose<List<ConversationGroup>>((ref) async {
  final useCase = ref.watch(loadConversationsUseCaseProvider);
  return useCase.callGrouped();
});

/// Knowledge file list and detail state providers.
///
/// Manages the knowledge file list, search filtering, detail loading,
/// and CRUD operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/knowledge/data/repositories/knowledge_repository_impl.dart';
import 'package:sanbao_flutter/features/knowledge/domain/entities/knowledge_file.dart';

// ---- Knowledge File List ----

/// The raw knowledge file list, auto-refreshable.
final knowledgeListProvider =
    AsyncNotifierProvider<KnowledgeListNotifier, List<KnowledgeFile>>(
  KnowledgeListNotifier.new,
);

/// Notifier for the knowledge file list with CRUD operations.
class KnowledgeListNotifier extends AsyncNotifier<List<KnowledgeFile>> {
  @override
  Future<List<KnowledgeFile>> build() async {
    final repo = ref.watch(knowledgeRepositoryProvider);
    return repo.getFiles();
  }

  /// Refreshes the knowledge file list from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(knowledgeRepositoryProvider);
      return repo.getFiles();
    });
  }

  /// Creates a new knowledge file and adds it to the list.
  Future<KnowledgeFile> createFile({
    required String name,
    required String content,
    String? description,
  }) async {
    final repo = ref.read(knowledgeRepositoryProvider);
    final file = await repo.createFile(
      name: name,
      content: content,
      description: description,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData([file, ...current]); // Newest first
    return file;
  }

  /// Updates an existing knowledge file in the list.
  Future<KnowledgeFile> updateFile(
    String id, {
    String? name,
    String? description,
    String? content,
  }) async {
    final repo = ref.read(knowledgeRepositoryProvider);
    final updated = await repo.updateFile(
      id,
      name: name,
      description: description,
      content: content,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((f) => f.id == id ? updated : f).toList(),
    );
    return updated;
  }

  /// Deletes a knowledge file from the list with optimistic removal.
  Future<void> deleteFile(String id) async {
    final current = state.valueOrNull ?? [];
    final file = current.where((f) => f.id == id).firstOrNull;

    // Optimistic removal
    state = AsyncData(current.where((f) => f.id != id).toList());

    try {
      final repo = ref.read(knowledgeRepositoryProvider);
      await repo.deleteFile(id);
    } on Object {
      // Restore on failure
      if (file != null) {
        state = AsyncData([...state.valueOrNull ?? [], file]);
      }
    }
  }
}

// ---- Search & Filtering ----

/// Search query for the knowledge file list.
final knowledgeSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered knowledge files based on search query.
final filteredKnowledgeFilesProvider =
    Provider<AsyncValue<List<KnowledgeFile>>>((ref) {
  final files = ref.watch(knowledgeListProvider);
  final query = ref.watch(knowledgeSearchQueryProvider).toLowerCase();

  return files.whenData(
    (list) => list
        .where((f) =>
            query.isEmpty ||
            f.name.toLowerCase().contains(query) ||
            (f.description?.toLowerCase().contains(query) ?? false),)
        .toList(),
  );
});

// ---- Knowledge File Detail ----

/// Provider for loading a single knowledge file with its content.
///
/// Use [knowledgeDetailProvider(fileId)] to fetch a specific file.
final knowledgeDetailProvider =
    FutureProvider.family<KnowledgeFile, String>((ref, id,) async {
  final repo = ref.watch(knowledgeRepositoryProvider);
  return repo.getFile(id);
});

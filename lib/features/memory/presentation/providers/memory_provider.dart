/// Memory list and form state providers.
///
/// Manages the memory list, search filtering, and CRUD operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:sanbao_flutter/features/memory/domain/entities/memory.dart';
import 'package:sanbao_flutter/features/memory/domain/repositories/memory_repository.dart';

// ---- Memory List ----

/// The raw memory list, auto-refreshable.
final memoryListProvider =
    AsyncNotifierProvider<MemoryListNotifier, List<Memory>>(
  MemoryListNotifier.new,
);

/// Notifier for the memory list with CRUD operations.
class MemoryListNotifier extends AsyncNotifier<List<Memory>> {
  @override
  Future<List<Memory>> build() async {
    final repo = ref.watch(memoryRepositoryProvider);
    return repo.getAll();
  }

  /// Refreshes the memory list from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(memoryRepositoryProvider);
      return repo.getAll();
    });
  }

  /// Creates a new memory and adds it to the list.
  Future<Memory> createMemory({
    required String content,
    String? category,
  }) async {
    final repo = ref.read(memoryRepositoryProvider);
    final memory =
        await repo.create(content: content, category: category);

    final current = state.valueOrNull ?? [];
    state = AsyncData([memory, ...current]); // Newest first
    return memory;
  }

  /// Updates an existing memory in the list.
  Future<Memory> updateMemory({
    required String id,
    String? content,
    String? category,
  }) async {
    final repo = ref.read(memoryRepositoryProvider);
    final updated =
        await repo.update(id: id, content: content, category: category);

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((m) => m.id == id ? updated : m).toList(),
    );
    return updated;
  }

  /// Deletes a memory from the list.
  Future<void> deleteMemory(String id) async {
    final current = state.valueOrNull ?? [];
    final memory = current.where((m) => m.id == id).firstOrNull;

    // Optimistic removal
    state = AsyncData(current.where((m) => m.id != id).toList());

    try {
      final repo = ref.read(memoryRepositoryProvider);
      await repo.delete(id);
    } on Object {
      if (memory != null) {
        state = AsyncData([...state.valueOrNull ?? [], memory]);
      }
    }
  }
}

// ---- Search & Filtering ----

/// Search query for the memory list.
final memorySearchQueryProvider = StateProvider<String>((ref) => '');

/// Optional category filter.
final memoryCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Filtered memories based on search query and category filter.
final filteredMemoriesProvider =
    Provider<AsyncValue<List<Memory>>>((ref) {
  final memories = ref.watch(memoryListProvider);
  final query = ref.watch(memorySearchQueryProvider).toLowerCase();
  final categoryFilter = ref.watch(memoryCategoryFilterProvider);

  return memories.whenData(
    (list) => list
        .where((m) =>
            categoryFilter == null || m.category == categoryFilter)
        .where((m) =>
            query.isEmpty || m.content.toLowerCase().contains(query))
        .toList(),
  );
});

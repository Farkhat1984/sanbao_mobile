/// Tools list, filtering, and form state providers.
///
/// Manages the tools list, type filtering, search, CRUD form
/// state, and enabled toggling.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/tools/data/repositories/tool_repository_impl.dart';
import 'package:sanbao_flutter/features/tools/domain/entities/tool.dart';

// ---- Tools List ----

/// The raw tools list, auto-refreshable.
final toolsListProvider =
    AsyncNotifierProvider<ToolsListNotifier, List<Tool>>(
  ToolsListNotifier.new,
);

/// Notifier for the tools list with CRUD operations.
class ToolsListNotifier extends AsyncNotifier<List<Tool>> {
  @override
  Future<List<Tool>> build() async {
    final repo = ref.watch(toolRepositoryProvider);
    return repo.getAll();
  }

  /// Refreshes the tools list from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(toolRepositoryProvider);
      return repo.getAll();
    });
  }

  /// Creates a new tool and adds it to the list.
  Future<Tool> createTool({
    required String name,
    required ToolType type,
    String? description,
    Map<String, Object?>? config,
  }) async {
    final repo = ref.read(toolRepositoryProvider);
    final tool = await repo.create(
      name: name,
      type: type,
      description: description,
      config: config,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, tool]);
    return tool;
  }

  /// Updates an existing tool in the list.
  Future<Tool> updateTool({
    required String id,
    String? name,
    String? description,
    ToolType? type,
    Map<String, Object?>? config,
    bool? isEnabled,
  }) async {
    final repo = ref.read(toolRepositoryProvider);
    final updated = await repo.update(
      id: id,
      name: name,
      description: description,
      type: type,
      config: config,
      isEnabled: isEnabled,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((t) => t.id == id ? updated : t).toList(),
    );
    return updated;
  }

  /// Toggles the enabled state of a tool.
  Future<void> toggleEnabled(String id) async {
    final current = state.valueOrNull ?? [];
    final tool = current.where((t) => t.id == id).firstOrNull;
    if (tool == null) return;

    // Optimistic update
    state = AsyncData(
      current
          .map((t) =>
              t.id == id ? t.copyWith(isEnabled: !t.isEnabled) : t,)
          .toList(),
    );

    try {
      final repo = ref.read(toolRepositoryProvider);
      await repo.update(id: id, isEnabled: !tool.isEnabled);
    } on Object {
      // Revert on failure
      state = AsyncData(
        (state.valueOrNull ?? [])
            .map((t) =>
                t.id == id ? t.copyWith(isEnabled: tool.isEnabled) : t,)
            .toList(),
      );
    }
  }

  /// Deletes a tool from the list.
  Future<void> deleteTool(String id) async {
    final current = state.valueOrNull ?? [];
    final tool = current.where((t) => t.id == id).firstOrNull;

    // Optimistic removal
    state = AsyncData(current.where((t) => t.id != id).toList());

    try {
      final repo = ref.read(toolRepositoryProvider);
      await repo.delete(id);
    } on Object {
      if (tool != null) {
        state = AsyncData([...state.valueOrNull ?? [], tool]);
      }
    }
  }
}

// ---- Search & Filtering ----

/// Search query for the tools list.
final toolsSearchQueryProvider = StateProvider<String>((ref) => '');

/// Active type filter. Null means all types.
final toolsTypeFilterProvider = StateProvider<ToolType?>((ref) => null);

/// Filtered tools based on search query and type filter.
final filteredToolsProvider = Provider<AsyncValue<List<Tool>>>((ref) {
  final tools = ref.watch(toolsListProvider);
  final query = ref.watch(toolsSearchQueryProvider).toLowerCase();
  final typeFilter = ref.watch(toolsTypeFilterProvider);

  return tools.whenData(
    (list) => list
        .where((t) => typeFilter == null || t.type == typeFilter)
        .where((t) =>
            query.isEmpty ||
            t.name.toLowerCase().contains(query) ||
            (t.description?.toLowerCase().contains(query) ?? false),)
        .toList(),
  );
});

// ---- Form State ----

/// Form data for creating or editing a tool.
class ToolFormData {
  ToolFormData({
    this.name = '',
    this.description = '',
    this.type = ToolType.promptTemplate,
    this.config = const {},
    this.isEnabled = true,
  });

  /// Creates form data pre-filled from an existing tool.
  factory ToolFormData.fromTool(Tool tool) => ToolFormData(
        name: tool.name,
        description: tool.description ?? '',
        type: tool.type,
        config: Map.of(tool.config),
        isEnabled: tool.isEnabled,
      );

  String name;
  String description;
  ToolType type;
  Map<String, Object?> config;
  bool isEnabled;

  /// Whether the minimum required fields are filled.
  bool get isValid => name.trim().isNotEmpty;

  /// Creates a copy with modified fields.
  ToolFormData copyWith({
    String? name,
    String? description,
    ToolType? type,
    Map<String, Object?>? config,
    bool? isEnabled,
  }) =>
      ToolFormData(
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        config: config ?? Map.of(this.config),
        isEnabled: isEnabled ?? this.isEnabled,
      );
}

/// Provider for the tool form state.
final toolFormProvider =
    StateNotifierProvider.autoDispose<ToolFormNotifier, ToolFormData>(
  (ref) => ToolFormNotifier(),
);

/// Notifier managing the tool form state.
class ToolFormNotifier extends StateNotifier<ToolFormData> {
  ToolFormNotifier() : super(ToolFormData());

  /// Resets the form with optional pre-fill from an existing tool.
  void initialize({Tool? tool}) {
    state = tool != null ? ToolFormData.fromTool(tool) : ToolFormData();
  }

  void updateName(String value) => state = state.copyWith(name: value);
  void updateDescription(String value) =>
      state = state.copyWith(description: value);
  void updateType(ToolType value) => state = state.copyWith(type: value);
  void updateConfig(Map<String, Object?> value) =>
      state = state.copyWith(config: value);

  /// Updates a single config key.
  void updateConfigKey(String key, Object? value) {
    final newConfig = Map<String, Object?>.of(state.config);
    newConfig[key] = value;
    state = state.copyWith(config: newConfig);
  }
}

/// Tracks whether the tool form is currently submitting.
final toolFormSubmittingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

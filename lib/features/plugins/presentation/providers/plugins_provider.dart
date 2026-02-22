/// Plugins list and form state providers.
///
/// Manages the plugin list, search filtering, enable/disable
/// toggling, and CRUD form state.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/plugins/data/repositories/plugin_repository_impl.dart';
import 'package:sanbao_flutter/features/plugins/domain/entities/plugin.dart';

// ---- Plugins List ----

/// The raw plugins list, auto-refreshable.
final pluginsListProvider =
    AsyncNotifierProvider<PluginsListNotifier, List<Plugin>>(
  PluginsListNotifier.new,
);

/// Notifier for the plugins list with CRUD operations.
class PluginsListNotifier extends AsyncNotifier<List<Plugin>> {
  @override
  Future<List<Plugin>> build() async {
    final repo = ref.watch(pluginRepositoryProvider);
    return repo.getAll();
  }

  /// Refreshes the plugins list from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(pluginRepositoryProvider);
      return repo.getAll();
    });
  }

  /// Creates a new plugin and adds it to the list.
  Future<Plugin> createPlugin({
    required String name,
    String? description,
    List<String>? tools,
    List<String>? skills,
  }) async {
    final repo = ref.read(pluginRepositoryProvider);
    final plugin = await repo.create(
      name: name,
      description: description,
      tools: tools,
      skills: skills,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, plugin]);
    return plugin;
  }

  /// Updates an existing plugin in the list.
  Future<Plugin> updatePlugin({
    required String id,
    String? name,
    String? description,
    List<String>? tools,
    List<String>? skills,
    bool? isEnabled,
  }) async {
    final repo = ref.read(pluginRepositoryProvider);
    final updated = await repo.update(
      id: id,
      name: name,
      description: description,
      tools: tools,
      skills: skills,
      isEnabled: isEnabled,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((p) => p.id == id ? updated : p).toList(),
    );
    return updated;
  }

  /// Toggles the enabled state of a plugin.
  Future<void> toggleEnabled(String id) async {
    final current = state.valueOrNull ?? [];
    final plugin = current.where((p) => p.id == id).firstOrNull;
    if (plugin == null) return;

    // Optimistic update
    state = AsyncData(
      current
          .map((p) =>
              p.id == id ? p.copyWith(isEnabled: !p.isEnabled) : p,)
          .toList(),
    );

    try {
      final repo = ref.read(pluginRepositoryProvider);
      await repo.update(id: id, isEnabled: !plugin.isEnabled);
    } on Object {
      // Revert on failure
      state = AsyncData(
        (state.valueOrNull ?? [])
            .map((p) =>
                p.id == id ? p.copyWith(isEnabled: plugin.isEnabled) : p,)
            .toList(),
      );
    }
  }

  /// Deletes a plugin from the list.
  Future<void> deletePlugin(String id) async {
    final current = state.valueOrNull ?? [];
    final plugin = current.where((p) => p.id == id).firstOrNull;

    // Optimistic removal
    state = AsyncData(current.where((p) => p.id != id).toList());

    try {
      final repo = ref.read(pluginRepositoryProvider);
      await repo.delete(id);
    } on Object {
      if (plugin != null) {
        state = AsyncData([...state.valueOrNull ?? [], plugin]);
      }
    }
  }
}

// ---- Search ----

/// Search query for the plugins list.
final pluginsSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered plugins based on search query.
final filteredPluginsProvider =
    Provider<AsyncValue<List<Plugin>>>((ref) {
  final plugins = ref.watch(pluginsListProvider);
  final query = ref.watch(pluginsSearchQueryProvider).toLowerCase();

  return plugins.whenData(
    (list) => list
        .where((p) =>
            query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            (p.description?.toLowerCase().contains(query) ?? false),)
        .toList(),
  );
});

// ---- Form State ----

/// Form data for creating or editing a plugin.
class PluginFormData {
  PluginFormData({
    this.name = '',
    this.description = '',
    this.tools = const [],
    this.skills = const [],
  });

  /// Creates form data pre-filled from an existing plugin.
  factory PluginFormData.fromPlugin(Plugin plugin) => PluginFormData(
        name: plugin.name,
        description: plugin.description ?? '',
        tools: List.of(plugin.tools),
        skills: List.of(plugin.skills),
      );

  String name;
  String description;
  List<String> tools;
  List<String> skills;

  /// Whether the minimum required fields are filled.
  bool get isValid => name.trim().isNotEmpty;

  /// Creates a copy with modified fields.
  PluginFormData copyWith({
    String? name,
    String? description,
    List<String>? tools,
    List<String>? skills,
  }) =>
      PluginFormData(
        name: name ?? this.name,
        description: description ?? this.description,
        tools: tools ?? List.of(this.tools),
        skills: skills ?? List.of(this.skills),
      );
}

/// Provider for the plugin form state.
final pluginFormProvider =
    StateNotifierProvider.autoDispose<PluginFormNotifier, PluginFormData>(
  (ref) => PluginFormNotifier(),
);

/// Notifier managing the plugin form state.
class PluginFormNotifier extends StateNotifier<PluginFormData> {
  PluginFormNotifier() : super(PluginFormData());

  void initialize({Plugin? plugin}) {
    state = plugin != null
        ? PluginFormData.fromPlugin(plugin)
        : PluginFormData();
  }

  void updateName(String value) => state = state.copyWith(name: value);
  void updateDescription(String value) =>
      state = state.copyWith(description: value);
  void updateTools(List<String> ids) => state = state.copyWith(tools: ids);
  void updateSkills(List<String> ids) => state = state.copyWith(skills: ids);
}

/// Tracks whether the plugin form is currently submitting.
final pluginFormSubmittingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

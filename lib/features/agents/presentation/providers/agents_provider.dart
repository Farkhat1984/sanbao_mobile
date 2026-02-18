/// Agents list and form state providers.
///
/// Manages the agent list, current selection, search filtering,
/// and CRUD form state for agents.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/agents/data/repositories/agent_repository_impl.dart';
import 'package:sanbao_flutter/features/agents/domain/entities/agent.dart';
import 'package:sanbao_flutter/features/agents/domain/repositories/agent_repository.dart';

// ---- Agents List ----

/// The raw agents list, auto-refreshable.
final agentsListProvider =
    AsyncNotifierProvider<AgentsListNotifier, List<Agent>>(
  AgentsListNotifier.new,
);

/// Notifier for the agents list with CRUD operations.
class AgentsListNotifier extends AsyncNotifier<List<Agent>> {
  @override
  Future<List<Agent>> build() async {
    final repo = ref.watch(agentRepositoryProvider);
    return repo.getAll();
  }

  /// Refreshes the agents list from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(agentRepositoryProvider);
      return repo.getAll();
    });
  }

  /// Creates a new agent and adds it to the list.
  Future<Agent> createAgent({
    required String name,
    required String instructions,
    required String model,
    required String icon,
    required String iconColor,
    String? description,
    String? avatar,
    List<String>? starterPrompts,
    List<String>? skillIds,
    List<String>? toolIds,
  }) async {
    final repo = ref.read(agentRepositoryProvider);
    final agent = await repo.create(
      name: name,
      instructions: instructions,
      model: model,
      icon: icon,
      iconColor: iconColor,
      description: description,
      avatar: avatar,
      starterPrompts: starterPrompts,
      skillIds: skillIds,
      toolIds: toolIds,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, agent]);
    return agent;
  }

  /// Updates an existing agent in the list.
  Future<Agent> updateAgent({
    required String id,
    String? name,
    String? description,
    String? instructions,
    String? model,
    String? icon,
    String? iconColor,
    String? avatar,
    List<String>? starterPrompts,
    List<String>? skillIds,
    List<String>? toolIds,
  }) async {
    final repo = ref.read(agentRepositoryProvider);
    final updated = await repo.update(
      id: id,
      name: name,
      description: description,
      instructions: instructions,
      model: model,
      icon: icon,
      iconColor: iconColor,
      avatar: avatar,
      starterPrompts: starterPrompts,
      skillIds: skillIds,
      toolIds: toolIds,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((a) => a.id == id ? updated : a).toList(),
    );
    return updated;
  }

  /// Deletes an agent from the list.
  Future<void> deleteAgent(String id) async {
    final current = state.valueOrNull ?? [];
    final agent = current.where((a) => a.id == id).firstOrNull;

    // Optimistic removal
    state = AsyncData(current.where((a) => a.id != id).toList());

    try {
      final repo = ref.read(agentRepositoryProvider);
      await repo.delete(id);
    } on Object {
      // Revert on failure
      if (agent != null) {
        state = AsyncData([...state.valueOrNull ?? [], agent]);
      }
    }
  }
}

// ---- Current Agent ----

/// Provider for the currently selected agent detail.
final currentAgentProvider =
    FutureProvider.autoDispose.family<Agent?, String>((ref, id) async {
  final repo = ref.watch(agentRepositoryProvider);
  return repo.getById(id);
});

// ---- Search & Filtering ----

/// Search query for the agents list.
final agentsSearchQueryProvider = StateProvider<String>((ref) => '');

/// System agents filtered and sorted.
final systemAgentsProvider = Provider<AsyncValue<List<Agent>>>((ref) {
  final agents = ref.watch(agentsListProvider);
  final query = ref.watch(agentsSearchQueryProvider).toLowerCase();

  return agents.whenData(
    (list) => list
        .where((a) => a.isSystem)
        .where((a) =>
            query.isEmpty ||
            a.name.toLowerCase().contains(query) ||
            (a.description?.toLowerCase().contains(query) ?? false))
        .toList(),
  );
});

/// User agents filtered and sorted.
final userAgentsProvider = Provider<AsyncValue<List<Agent>>>((ref) {
  final agents = ref.watch(agentsListProvider);
  final query = ref.watch(agentsSearchQueryProvider).toLowerCase();

  return agents.whenData(
    (list) => list
        .where((a) => !a.isSystem)
        .where((a) =>
            query.isEmpty ||
            a.name.toLowerCase().contains(query) ||
            (a.description?.toLowerCase().contains(query) ?? false))
        .toList(),
  );
});

// ---- Agent Form State ----

/// Form data for creating or editing an agent.
class AgentFormData {
  AgentFormData({
    this.name = '',
    this.description = '',
    this.instructions = '',
    this.model = 'gpt-4o',
    this.icon = 'Bot',
    this.iconColor = '#4F6EF7',
    this.avatar,
    this.starterPrompts = const [],
    this.skillIds = const [],
    this.toolIds = const [],
  });

  /// Creates form data pre-filled from an existing agent.
  factory AgentFormData.fromAgent(Agent agent) => AgentFormData(
        name: agent.name,
        description: agent.description ?? '',
        instructions: agent.instructions,
        model: agent.model,
        icon: agent.icon,
        iconColor: agent.iconColor,
        avatar: agent.avatar,
        starterPrompts: List.of(agent.starterPrompts),
        skillIds: agent.skills.map((s) => s.skillId).toList(),
        toolIds: agent.tools.map((t) => t.toolId).toList(),
      );

  String name;
  String description;
  String instructions;
  String model;
  String icon;
  String iconColor;
  String? avatar;
  List<String> starterPrompts;
  List<String> skillIds;
  List<String> toolIds;

  /// Whether the minimum required fields are filled.
  bool get isValid =>
      name.trim().isNotEmpty && instructions.trim().isNotEmpty;

  /// Creates a copy with modified fields.
  AgentFormData copyWith({
    String? name,
    String? description,
    String? instructions,
    String? model,
    String? icon,
    String? iconColor,
    String? avatar,
    List<String>? starterPrompts,
    List<String>? skillIds,
    List<String>? toolIds,
  }) {
    final copy = AgentFormData(
      name: name ?? this.name,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      model: model ?? this.model,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      avatar: avatar ?? this.avatar,
      starterPrompts: starterPrompts ?? List.of(this.starterPrompts),
      skillIds: skillIds ?? List.of(this.skillIds),
      toolIds: toolIds ?? List.of(this.toolIds),
    );
    return copy;
  }
}

/// Provider for the agent form state.
final agentFormProvider =
    StateNotifierProvider.autoDispose<AgentFormNotifier, AgentFormData>(
  (ref) => AgentFormNotifier(),
);

/// Notifier managing the agent form state.
class AgentFormNotifier extends StateNotifier<AgentFormData> {
  AgentFormNotifier() : super(AgentFormData());

  /// Resets the form with optional pre-fill from an existing agent.
  void initialize({Agent? agent}) {
    state = agent != null
        ? AgentFormData.fromAgent(agent)
        : AgentFormData();
  }

  void updateName(String value) => state = state.copyWith(name: value);

  void updateDescription(String value) =>
      state = state.copyWith(description: value);

  void updateInstructions(String value) =>
      state = state.copyWith(instructions: value);

  void updateModel(String value) => state = state.copyWith(model: value);

  void updateIcon(String value) => state = state.copyWith(icon: value);

  void updateIconColor(String value) =>
      state = state.copyWith(iconColor: value);

  /// Adds a starter prompt to the list.
  void addStarterPrompt(String prompt) {
    if (prompt.trim().isEmpty) return;
    state = state.copyWith(
      starterPrompts: [...state.starterPrompts, prompt.trim()],
    );
  }

  /// Removes a starter prompt at [index].
  void removeStarterPrompt(int index) {
    final prompts = List.of(state.starterPrompts);
    if (index >= 0 && index < prompts.length) {
      prompts.removeAt(index);
      state = state.copyWith(starterPrompts: prompts);
    }
  }

  /// Updates the selected skill IDs.
  void updateSkillIds(List<String> ids) =>
      state = state.copyWith(skillIds: ids);

  /// Updates the selected tool IDs.
  void updateToolIds(List<String> ids) =>
      state = state.copyWith(toolIds: ids);
}

/// Tracks whether the agent form is currently submitting.
final agentFormSubmittingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

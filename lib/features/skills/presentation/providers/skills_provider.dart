/// Skills list and form state providers.
///
/// Manages the skill list (personal + marketplace), search
/// filtering, and CRUD form state for skills.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/skills/data/datasources/skill_remote_datasource.dart';
import 'package:sanbao_flutter/features/skills/data/repositories/skill_repository_impl.dart';
import 'package:sanbao_flutter/features/skills/domain/entities/skill.dart';
import 'package:sanbao_flutter/features/skills/domain/repositories/skill_repository.dart';

// ---- Skills List (Personal) ----

/// The user's skills list, auto-refreshable.
final skillsListProvider =
    AsyncNotifierProvider<SkillsListNotifier, List<Skill>>(
  SkillsListNotifier.new,
);

/// Notifier for the user's skill list with CRUD operations.
class SkillsListNotifier extends AsyncNotifier<List<Skill>> {
  @override
  Future<List<Skill>> build() async {
    final repo = ref.watch(skillRepositoryProvider);
    return repo.getAll();
  }

  /// Refreshes the skills list from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(skillRepositoryProvider);
      return repo.getAll();
    });
  }

  /// Creates a new skill and adds it to the list.
  Future<Skill> createSkill({
    required String name,
    required String systemPrompt,
    required String icon,
    required String iconColor,
    String? description,
    String? citationRules,
    String? jurisdiction,
    bool isPublic = false,
  }) async {
    final repo = ref.read(skillRepositoryProvider);
    final skill = await repo.create(
      name: name,
      systemPrompt: systemPrompt,
      icon: icon,
      iconColor: iconColor,
      description: description,
      citationRules: citationRules,
      jurisdiction: jurisdiction,
      isPublic: isPublic,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, skill]);
    return skill;
  }

  /// Updates an existing skill in the list.
  Future<Skill> updateSkill({
    required String id,
    String? name,
    String? description,
    String? systemPrompt,
    String? citationRules,
    String? jurisdiction,
    String? icon,
    String? iconColor,
    bool? isPublic,
  }) async {
    final repo = ref.read(skillRepositoryProvider);
    final updated = await repo.update(
      id: id,
      name: name,
      description: description,
      systemPrompt: systemPrompt,
      citationRules: citationRules,
      jurisdiction: jurisdiction,
      icon: icon,
      iconColor: iconColor,
      isPublic: isPublic,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((s) => s.id == id ? updated : s).toList(),
    );
    return updated;
  }

  /// Deletes a skill from the list.
  Future<void> deleteSkill(String id) async {
    final current = state.valueOrNull ?? [];
    final skill = current.where((s) => s.id == id).firstOrNull;

    // Optimistic removal
    state = AsyncData(current.where((s) => s.id != id).toList());

    try {
      final repo = ref.read(skillRepositoryProvider);
      await repo.delete(id);
    } on Object {
      if (skill != null) {
        state = AsyncData([...state.valueOrNull ?? [], skill]);
      }
    }
  }

  /// Clones a public skill into the user's library.
  Future<Skill> cloneSkill(String id) async {
    final repo = ref.read(skillRepositoryProvider);
    final cloned = await repo.clone(id);

    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, cloned]);
    return cloned;
  }
}

// ---- Public / Marketplace Skills ----

/// Public skills available in the marketplace.
final publicSkillsProvider =
    AsyncNotifierProvider<PublicSkillsNotifier, List<Skill>>(
  PublicSkillsNotifier.new,
);

/// Notifier for the marketplace skills list.
class PublicSkillsNotifier extends AsyncNotifier<List<Skill>> {
  @override
  Future<List<Skill>> build() async {
    final repo = ref.watch(skillRepositoryProvider);
    return repo.getPublic();
  }

  /// Refreshes the marketplace list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(skillRepositoryProvider);
      return repo.getPublic();
    });
  }
}

// ---- Current Skill Detail ----

/// Provider for a single skill detail.
final currentSkillProvider =
    FutureProvider.autoDispose.family<Skill?, String>((ref, id) async {
  final repo = ref.watch(skillRepositoryProvider);
  return repo.getById(id);
});

// ---- Search & Filtering ----

/// Search query for the skills lists.
final skillsSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered personal skills based on search query.
final filteredSkillsProvider = Provider<AsyncValue<List<Skill>>>((ref) {
  final skills = ref.watch(skillsListProvider);
  final query = ref.watch(skillsSearchQueryProvider).toLowerCase();

  return skills.whenData(
    (list) => list
        .where((s) =>
            query.isEmpty ||
            s.name.toLowerCase().contains(query) ||
            (s.description?.toLowerCase().contains(query) ?? false) ||
            (s.jurisdiction?.toLowerCase().contains(query) ?? false))
        .toList(),
  );
});

/// Filtered marketplace skills based on search query.
final filteredPublicSkillsProvider = Provider<AsyncValue<List<Skill>>>((ref) {
  final skills = ref.watch(publicSkillsProvider);
  final query = ref.watch(skillsSearchQueryProvider).toLowerCase();

  return skills.whenData(
    (list) => list
        .where((s) =>
            query.isEmpty ||
            s.name.toLowerCase().contains(query) ||
            (s.description?.toLowerCase().contains(query) ?? false) ||
            (s.jurisdiction?.toLowerCase().contains(query) ?? false))
        .toList(),
  );
});

// ---- Skill Form State ----

/// Form data for creating or editing a skill.
class SkillFormData {
  SkillFormData({
    this.name = '',
    this.description = '',
    this.systemPrompt = '',
    this.citationRules = '',
    this.jurisdiction,
    this.icon = 'BookOpen',
    this.iconColor = '#4F6EF7',
    this.isPublic = false,
  });

  /// Creates form data pre-filled from an existing skill.
  factory SkillFormData.fromSkill(Skill skill) => SkillFormData(
        name: skill.name,
        description: skill.description ?? '',
        systemPrompt: skill.systemPrompt,
        citationRules: skill.citationRules ?? '',
        jurisdiction: skill.jurisdiction,
        icon: skill.icon,
        iconColor: skill.iconColor,
        isPublic: skill.isPublic,
      );

  String name;
  String description;
  String systemPrompt;
  String citationRules;
  String? jurisdiction;
  String icon;
  String iconColor;
  bool isPublic;

  /// Whether the minimum required fields are filled.
  bool get isValid =>
      name.trim().isNotEmpty && systemPrompt.trim().isNotEmpty;

  /// Creates a copy with modified fields.
  SkillFormData copyWith({
    String? name,
    String? description,
    String? systemPrompt,
    String? citationRules,
    String? jurisdiction,
    String? icon,
    String? iconColor,
    bool? isPublic,
  }) =>
      SkillFormData(
        name: name ?? this.name,
        description: description ?? this.description,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        citationRules: citationRules ?? this.citationRules,
        jurisdiction: jurisdiction ?? this.jurisdiction,
        icon: icon ?? this.icon,
        iconColor: iconColor ?? this.iconColor,
        isPublic: isPublic ?? this.isPublic,
      );
}

/// Provider for the skill form state.
final skillFormProvider =
    StateNotifierProvider.autoDispose<SkillFormNotifier, SkillFormData>(
  (ref) => SkillFormNotifier(),
);

/// Notifier managing the skill form state.
class SkillFormNotifier extends StateNotifier<SkillFormData> {
  SkillFormNotifier() : super(SkillFormData());

  /// Resets the form with optional pre-fill from an existing skill.
  void initialize({Skill? skill}) {
    state = skill != null
        ? SkillFormData.fromSkill(skill)
        : SkillFormData();
  }

  void updateName(String value) => state = state.copyWith(name: value);

  void updateDescription(String value) =>
      state = state.copyWith(description: value);

  void updateSystemPrompt(String value) =>
      state = state.copyWith(systemPrompt: value);

  void updateCitationRules(String value) =>
      state = state.copyWith(citationRules: value);

  void updateJurisdiction(String? value) =>
      state = state.copyWith(jurisdiction: value);

  void updateIcon(String value) => state = state.copyWith(icon: value);

  void updateIconColor(String value) =>
      state = state.copyWith(iconColor: value);

  void togglePublic() => state = state.copyWith(isPublic: !state.isPublic);
}

/// Tracks whether the skill form is currently submitting.
final skillFormSubmittingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

// ---- Skill AI Generation ----

/// Sealed state for the skill AI generation process.
sealed class SkillGenState {
  const SkillGenState();
}

/// Initial state before any generation attempt.
final class SkillGenInitial extends SkillGenState {
  const SkillGenInitial();
}

/// Skill generation is in progress.
final class SkillGenLoading extends SkillGenState {
  const SkillGenLoading();
}

/// Skill generation completed successfully.
final class SkillGenSuccess extends SkillGenState {
  const SkillGenSuccess({required this.data});

  /// The generated skill configuration map.
  final Map<String, Object?> data;
}

/// Skill generation failed.
final class SkillGenError extends SkillGenState {
  const SkillGenError({required this.message});

  /// User-facing error message.
  final String message;
}

/// The main skill generation state provider.
final skillGenProvider =
    StateNotifierProvider.autoDispose<SkillGenNotifier, SkillGenState>(
  SkillGenNotifier.new,
);

/// Notifier that handles skill AI generation requests.
class SkillGenNotifier extends StateNotifier<SkillGenState> {
  SkillGenNotifier(this._ref) : super(const SkillGenInitial());

  final Ref _ref;

  /// Generates skill configuration from a [description].
  Future<void> generate({
    required String description,
    String? jurisdiction,
  }) async {
    if (description.trim().isEmpty) return;

    state = const SkillGenLoading();

    try {
      final datasource = _ref.read(skillRemoteDataSourceProvider);
      final data = await datasource.generateSkill(
        description: description.trim(),
        jurisdiction: jurisdiction,
      );

      state = SkillGenSuccess(data: data);
    } on Exception catch (e) {
      state = SkillGenError(message: _extractErrorMessage(e));
    }
  }

  /// Resets the state to initial.
  void reset() {
    state = const SkillGenInitial();
  }

  String _extractErrorMessage(Exception e) {
    final message = e.toString();

    if (message.contains('429') || message.contains('rate')) {
      return 'Слишком много запросов. Подождите минуту.';
    }
    if (message.contains('401') || message.contains('unauthorized')) {
      return 'Требуется авторизация';
    }
    if (message.contains('timeout') || message.contains('Timeout')) {
      return 'Превышено время ожидания. Попробуйте снова.';
    }
    if (message.contains('network') || message.contains('Network')) {
      return 'Нет подключения к интернету';
    }

    final errorMatch =
        RegExp(r'message:\s*(.+?)(?:,|\))').firstMatch(message);
    if (errorMatch != null) {
      return errorMatch.group(1) ?? 'Не удалось сгенерировать навык';
    }

    return 'Не удалось сгенерировать навык';
  }
}

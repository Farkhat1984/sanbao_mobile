/// Skill entity representing a specialized AI capability.
///
/// Skills define domain-specific instructions, citation rules,
/// and jurisdiction context that can be attached to agents or
/// activated per-conversation.
library;

/// A skill with its configuration and metadata.
///
/// Built-in skills are system-provided and read-only.
/// User skills can be created, cloned from the marketplace,
/// and optionally made public.
class Skill {
  const Skill({
    required this.id,
    required this.name,
    required this.systemPrompt,
    required this.icon,
    required this.iconColor,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.citationRules,
    this.jurisdiction,
    this.isBuiltIn = false,
    this.isPublic = false,
    this.userId,
    this.cloneCount = 0,
  });

  /// Unique skill identifier.
  final String id;

  /// Display name of the skill.
  final String name;

  /// Human-readable description (optional).
  final String? description;

  /// System prompt that defines the skill's behavior and expertise.
  final String systemPrompt;

  /// Citation formatting rules (for legal skills).
  final String? citationRules;

  /// Legal jurisdiction code (e.g., "RF", "UK", "EU").
  final String? jurisdiction;

  /// Icon identifier from the valid icons list.
  final String icon;

  /// Hex color for the skill icon background.
  final String iconColor;

  /// Whether this is a system-provided (built-in) skill.
  final bool isBuiltIn;

  /// Whether this skill is publicly visible in the marketplace.
  final bool isPublic;

  /// Owner user ID (null for built-in skills).
  final String? userId;

  /// Number of times this skill has been cloned.
  final int cloneCount;

  /// When the skill was created.
  final DateTime createdAt;

  /// When the skill was last updated.
  final DateTime updatedAt;

  /// Whether the skill can be edited by the current user.
  bool get isEditable => !isBuiltIn;

  /// Whether this is a legal domain skill (has jurisdiction).
  bool get isLegal => jurisdiction != null && jurisdiction!.isNotEmpty;

  /// Human-readable jurisdiction label.
  String? get jurisdictionLabel => switch (jurisdiction) {
        'RF' => 'Россия',
        'UK' => 'Великобритания',
        'EU' => 'Евросоюз',
        'US' => 'США',
        'KZ' => 'Казахстан',
        'BY' => 'Беларусь',
        'UZ' => 'Узбекистан',
        _ => jurisdiction,
      };

  /// Creates a copy with modified fields.
  Skill copyWith({
    String? id,
    String? name,
    String? description,
    String? systemPrompt,
    String? citationRules,
    String? jurisdiction,
    String? icon,
    String? iconColor,
    bool? isBuiltIn,
    bool? isPublic,
    String? userId,
    int? cloneCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Skill(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        citationRules: citationRules ?? this.citationRules,
        jurisdiction: jurisdiction ?? this.jurisdiction,
        icon: icon ?? this.icon,
        iconColor: iconColor ?? this.iconColor,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        isPublic: isPublic ?? this.isPublic,
        userId: userId ?? this.userId,
        cloneCount: cloneCount ?? this.cloneCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Skill && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Skill(id=$id, name=$name, isBuiltIn=$isBuiltIn)';
}

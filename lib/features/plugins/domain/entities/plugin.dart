/// Plugin entity representing a bundled set of tools and skills.
///
/// Plugins combine tools and skills into a single package that
/// can be enabled/disabled as a unit.
library;

/// A plugin bundling multiple tools and skills.
///
/// Plugins provide a convenient way to package related capabilities
/// and enable/disable them together.
class Plugin {
  const Plugin({
    required this.id,
    required this.name,
    required this.createdAt,
    this.description,
    this.tools = const [],
    this.skills = const [],
    this.isEnabled = true,
    this.userId,
  });

  /// Unique plugin identifier.
  final String id;

  /// Display name of the plugin.
  final String name;

  /// Human-readable description.
  final String? description;

  /// Tool IDs included in this plugin.
  final List<String> tools;

  /// Skill IDs included in this plugin.
  final List<String> skills;

  /// Whether the plugin is currently enabled.
  final bool isEnabled;

  /// Owner user ID.
  final String? userId;

  /// When the plugin was created.
  final DateTime createdAt;

  /// Total number of capabilities (tools + skills).
  int get capabilityCount => tools.length + skills.length;

  /// Creates a copy with modified fields.
  Plugin copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? tools,
    List<String>? skills,
    bool? isEnabled,
    String? userId,
    DateTime? createdAt,
  }) =>
      Plugin(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        tools: tools ?? this.tools,
        skills: skills ?? this.skills,
        isEnabled: isEnabled ?? this.isEnabled,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Plugin && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Plugin(id=$id, name=$name, isEnabled=$isEnabled)';
}

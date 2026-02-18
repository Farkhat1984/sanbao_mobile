/// Tool entity representing a custom tool configuration.
///
/// Tools can be of different types and provide extended
/// capabilities that agents can use during conversations.
library;

/// Type of a custom tool.
enum ToolType {
  /// A prompt template that generates structured prompts.
  promptTemplate,

  /// A webhook that calls an external HTTP endpoint.
  webhook,

  /// A URL tool that fetches content from a web address.
  url,

  /// A function tool that executes custom logic.
  function_,
}

/// A custom tool with its configuration.
///
/// Tools are attached to agents to provide additional capabilities
/// beyond the base AI model.
class Tool {
  const Tool({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    this.description,
    this.config = const {},
    this.isEnabled = true,
    this.userId,
  });

  /// Unique tool identifier.
  final String id;

  /// Display name of the tool.
  final String name;

  /// Human-readable description.
  final String? description;

  /// The tool type defining its behavior.
  final ToolType type;

  /// Type-specific configuration (e.g., URL, webhook endpoint, template).
  final Map<String, Object?> config;

  /// Whether the tool is currently enabled.
  final bool isEnabled;

  /// Owner user ID.
  final String? userId;

  /// When the tool was created.
  final DateTime createdAt;

  /// Human-readable type label in Russian.
  String get typeLabel => switch (type) {
        ToolType.promptTemplate => 'Шаблон промпта',
        ToolType.webhook => 'Вебхук',
        ToolType.url => 'URL',
        ToolType.function_ => 'Функция',
      };

  /// Icon data for the tool type.
  String get typeIconName => switch (type) {
        ToolType.promptTemplate => 'description',
        ToolType.webhook => 'webhook',
        ToolType.url => 'link',
        ToolType.function_ => 'code',
      };

  /// Creates a copy with modified fields.
  Tool copyWith({
    String? id,
    String? name,
    String? description,
    ToolType? type,
    Map<String, Object?>? config,
    bool? isEnabled,
    String? userId,
    DateTime? createdAt,
  }) =>
      Tool(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        config: config ?? this.config,
        isEnabled: isEnabled ?? this.isEnabled,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tool && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Tool(id=$id, name=$name, type=$type)';
}

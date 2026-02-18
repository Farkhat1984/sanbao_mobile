/// Agent entity representing an AI assistant configuration.
///
/// Agents define the behavior, personality, and capabilities of
/// an AI assistant. They can be system-provided (built-in) or
/// user-created (custom).
library;

/// An AI agent with its configuration and metadata.
///
/// System agents are read-only and provided by the platform.
/// User agents can be fully customized with tools, skills,
/// system prompts, and starter prompts.
class Agent {
  const Agent({
    required this.id,
    required this.name,
    required this.instructions,
    required this.model,
    required this.icon,
    required this.iconColor,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.avatar,
    this.isSystem = false,
    this.starterPrompts = const [],
    this.skills = const [],
    this.tools = const [],
    this.files = const [],
    this.conversationCount = 0,
    this.fileCount = 0,
  });

  /// Unique agent identifier.
  final String id;

  /// Display name of the agent.
  final String name;

  /// Human-readable description (optional).
  final String? description;

  /// System prompt / instructions for the AI model.
  final String instructions;

  /// AI model identifier (e.g., "gpt-4o", "claude-3").
  final String model;

  /// Icon identifier from the valid icons list (e.g., "Bot", "Scale").
  final String icon;

  /// Hex color for the agent icon background (e.g., "#4F6EF7").
  final String iconColor;

  /// Optional avatar image URL.
  final String? avatar;

  /// Whether this is a system-provided (built-in) agent.
  final bool isSystem;

  /// Suggested starter prompts shown in the welcome screen.
  final List<String> starterPrompts;

  /// Skills attached to this agent.
  final List<AgentSkillRef> skills;

  /// Tools attached to this agent.
  final List<AgentToolRef> tools;

  /// Files attached to this agent for context.
  final List<AgentFile> files;

  /// Number of conversations using this agent.
  final int conversationCount;

  /// Number of files attached to this agent.
  final int fileCount;

  /// When the agent was created.
  final DateTime createdAt;

  /// When the agent was last updated.
  final DateTime updatedAt;

  /// Whether the agent can be edited by the current user.
  bool get isEditable => !isSystem;

  /// Creates a copy with modified fields.
  Agent copyWith({
    String? id,
    String? name,
    String? description,
    String? instructions,
    String? model,
    String? icon,
    String? iconColor,
    String? avatar,
    bool? isSystem,
    List<String>? starterPrompts,
    List<AgentSkillRef>? skills,
    List<AgentToolRef>? tools,
    List<AgentFile>? files,
    int? conversationCount,
    int? fileCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Agent(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        instructions: instructions ?? this.instructions,
        model: model ?? this.model,
        icon: icon ?? this.icon,
        iconColor: iconColor ?? this.iconColor,
        avatar: avatar ?? this.avatar,
        isSystem: isSystem ?? this.isSystem,
        starterPrompts: starterPrompts ?? this.starterPrompts,
        skills: skills ?? this.skills,
        tools: tools ?? this.tools,
        files: files ?? this.files,
        conversationCount: conversationCount ?? this.conversationCount,
        fileCount: fileCount ?? this.fileCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Agent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Agent(id=$id, name=$name, isSystem=$isSystem)';
}

/// Reference to a skill attached to an agent.
class AgentSkillRef {
  const AgentSkillRef({
    required this.id,
    required this.skillId,
    required this.skillName,
    this.skillIcon,
    this.skillIconColor,
  });

  /// Junction record ID.
  final String id;

  /// Referenced skill ID.
  final String skillId;

  /// Skill display name.
  final String skillName;

  /// Skill icon identifier.
  final String? skillIcon;

  /// Skill icon color hex string.
  final String? skillIconColor;
}

/// Reference to a tool attached to an agent.
class AgentToolRef {
  const AgentToolRef({
    required this.id,
    required this.toolId,
    required this.toolName,
    this.toolIcon,
    this.toolIconColor,
  });

  /// Junction record ID.
  final String id;

  /// Referenced tool ID.
  final String toolId;

  /// Tool display name.
  final String toolName;

  /// Tool icon identifier.
  final String? toolIcon;

  /// Tool icon color hex string.
  final String? toolIconColor;
}

/// A file attached to an agent for context.
class AgentFile {
  const AgentFile({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
    required this.fileSize,
    required this.createdAt,
    this.extractedText,
    this.inContext = false,
  });

  /// Unique file identifier.
  final String id;

  /// Original file name.
  final String fileName;

  /// MIME type of the file.
  final String fileType;

  /// URL to access the file.
  final String fileUrl;

  /// File size in bytes.
  final int fileSize;

  /// Extracted text content (for document files).
  final String? extractedText;

  /// Whether this file is included in the agent's context.
  final bool inContext;

  /// When the file was uploaded.
  final DateTime createdAt;
}

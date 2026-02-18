/// Memory entity representing a saved knowledge item.
///
/// Memories are pieces of information that the AI retains across
/// conversations for personalization and context.
library;

/// A memory item stored by the AI for cross-conversation context.
///
/// Memories help the AI remember user preferences, important facts,
/// and recurring patterns across conversations.
class Memory {
  const Memory({
    required this.id,
    required this.content,
    required this.createdAt,
    this.category,
    this.userId,
  });

  /// Unique memory identifier.
  final String id;

  /// The memory content text.
  final String content;

  /// Optional category for organization (e.g., "preference", "fact").
  final String? category;

  /// Owner user ID.
  final String? userId;

  /// When the memory was created.
  final DateTime createdAt;

  /// Creates a copy with modified fields.
  Memory copyWith({
    String? id,
    String? content,
    String? category,
    String? userId,
    DateTime? createdAt,
  }) =>
      Memory(
        id: id ?? this.id,
        content: content ?? this.content,
        category: category ?? this.category,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Memory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Memory(id=$id, category=$category, content=${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
}

/// Predefined memory categories.
abstract final class MemoryCategory {
  static const String preference = 'preference';
  static const String fact = 'fact';
  static const String instruction = 'instruction';
  static const String context = 'context';
  static const String other = 'other';

  /// All available categories with Russian labels.
  static const Map<String, String> labels = {
    preference: 'Предпочтение',
    fact: 'Факт',
    instruction: 'Инструкция',
    context: 'Контекст',
    other: 'Прочее',
  };

  /// Returns the Russian label for a category key.
  static String labelFor(String? category) =>
      labels[category] ?? labels[other]!;
}

/// Memory data model with JSON serialization.
///
/// Handles conversion between the API JSON format and the
/// domain [Memory] entity.
library;

import 'package:sanbao_flutter/features/memory/domain/entities/memory.dart';

/// Data model for [Memory] with JSON serialization support.
class MemoryModel {
  const MemoryModel._({required this.memory});

  /// Creates a model from a domain entity.
  factory MemoryModel.fromEntity(Memory memory) =>
      MemoryModel._(memory: memory);

  /// Creates a model from an API JSON response.
  factory MemoryModel.fromJson(Map<String, Object?> json) => MemoryModel._(
        memory: Memory(
          id: json['id'] as String? ?? '',
          content: json['content'] as String? ?? '',
          category: json['category'] as String?,
          userId: json['userId'] as String?,
          createdAt:
              DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                  DateTime.now(),
        ),
      );

  /// The underlying domain entity.
  final Memory memory;

  /// Converts to JSON for API requests (create/update).
  Map<String, Object?> toJson() => {
        'content': memory.content,
        if (memory.category != null) 'category': memory.category,
      };

  /// Parses a list of memory JSON objects.
  static List<Memory> fromJsonList(List<Object?> jsonList) => jsonList
      .whereType<Map<String, Object?>>()
      .map((json) => MemoryModel.fromJson(json).memory)
      .toList();
}

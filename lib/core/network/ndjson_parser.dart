/// NDJSON (Newline-Delimited JSON) stream parser.
///
/// Parses the Sanbao chat streaming protocol:
/// `POST /api/chat` returns an NDJSON stream of `{t, v}` objects:
/// - `c` = content text chunk
/// - `r` = reasoning/thinking text chunk
/// - `p` = plan text chunk
/// - `s` = status event (searching, using_tool, etc.)
/// - `x` = context info (usage percent, token counts)
/// - `e` = error message
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Sealed class representing all possible events from the chat stream.
sealed class ChatEvent {
  const ChatEvent();
}

/// A chunk of assistant response content.
final class ContentEvent extends ChatEvent {
  const ContentEvent(this.text);

  /// The text content fragment.
  final String text;

  @override
  String toString() => 'ContentEvent(${text.length} chars)';
}

/// A chunk of reasoning/thinking content.
final class ReasoningEvent extends ChatEvent {
  const ReasoningEvent(this.text);

  /// The reasoning text fragment.
  final String text;

  @override
  String toString() => 'ReasoningEvent(${text.length} chars)';
}

/// A chunk of plan content.
final class PlanEvent extends ChatEvent {
  const PlanEvent(this.text);

  /// The plan text fragment.
  final String text;

  @override
  String toString() => 'PlanEvent(${text.length} chars)';
}

/// A status update (e.g., searching, using_tool).
final class StatusEvent extends ChatEvent {
  const StatusEvent(this.status);

  /// The status string.
  final String status;

  /// Whether the AI is currently searching the web.
  bool get isSearching => status == 'searching';

  /// Whether the AI is using a tool.
  bool get isUsingTool => status == 'using_tool';

  @override
  String toString() => 'StatusEvent($status)';
}

/// Context information about token usage and window.
final class ContextEvent extends ChatEvent {
  const ContextEvent({
    required this.usagePercent,
    required this.totalTokens,
    required this.contextWindowSize,
    required this.compacting,
  });

  /// Creates a [ContextEvent] from a decoded JSON map.
  factory ContextEvent.fromJson(Map<String, Object?> json) => ContextEvent(
        usagePercent: (json['usagePercent'] as num?)?.toInt() ?? 0,
        totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
        contextWindowSize: (json['contextWindowSize'] as num?)?.toInt() ?? 0,
        compacting: (json['compacting'] as bool?) ?? false,
      );

  /// Percentage of context window used (0-100).
  final int usagePercent;

  /// Total tokens in the conversation.
  final int totalTokens;

  /// Maximum context window size for the model.
  final int contextWindowSize;

  /// Whether the conversation is being compacted.
  final bool compacting;

  @override
  String toString() =>
      'ContextEvent(usage=$usagePercent%, tokens=$totalTokens/$contextWindowSize)';
}

/// An error returned from the streaming API.
final class ErrorEvent extends ChatEvent {
  const ErrorEvent(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => 'ErrorEvent($message)';
}

/// Parses a byte stream into a stream of [ChatEvent]s.
///
/// The input is expected to be an NDJSON stream where each line
/// is a JSON object with `t` (type) and `v` (value) fields.
///
/// Example input:
/// ```
/// {"t":"c","v":"Hello"}
/// {"t":"r","v":"thinking..."}
/// {"t":"s","v":"searching"}
/// {"t":"x","v":{"usagePercent":42,"totalTokens":1200,"contextWindowSize":128000,"compacting":false}}
/// {"t":"e","v":"Something went wrong"}
/// ```
class NdjsonParser {
  /// Transforms a raw byte stream into typed [ChatEvent]s.
  ///
  /// Handles partial lines that span multiple chunks, UTF-8 decoding,
  /// and gracefully skips malformed JSON lines.
  Stream<ChatEvent> parse(Stream<List<int>> byteStream) {
    final controller = StreamController<ChatEvent>();
    final buffer = StringBuffer();

    final subscription = byteStream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .listen(
      (chunk) {
        buffer.write(chunk);

        // Process complete lines
        final content = buffer.toString();
        final lines = content.split('\n');

        // Keep the last (possibly incomplete) line in the buffer
        buffer
          ..clear()
          ..write(lines.last);

        // Process all complete lines (all except the last)
        for (var i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          final event = _parseLine(line);
          if (event != null) {
            controller.add(event);
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        controller.addError(error, stackTrace);
      },
      onDone: () {
        // Process any remaining content in the buffer
        final remaining = buffer.toString().trim();
        if (remaining.isNotEmpty) {
          final event = _parseLine(remaining);
          if (event != null) {
            controller.add(event);
          }
        }
        controller.close();
      },
      cancelOnError: false,
    );

    controller.onCancel = () async {
      await subscription.cancel();
    };

    return controller.stream;
  }

  /// Parses a single NDJSON line into a [ChatEvent].
  ///
  /// Returns `null` if the line is malformed or has an unknown type.
  ChatEvent? _parseLine(String line) {
    try {
      final json = jsonDecode(line);
      if (json is! Map<String, Object?>) return null;

      final type = json['t'] as String?;
      final value = json['v'];

      if (type == null) return null;

      return switch (type) {
        'c' => ContentEvent(value as String? ?? ''),
        'r' => ReasoningEvent(value as String? ?? ''),
        'p' => PlanEvent(value as String? ?? ''),
        's' => StatusEvent(value as String? ?? ''),
        'x' => value is Map<String, Object?>
            ? ContextEvent.fromJson(value)
            : null,
        'e' => ErrorEvent(value as String? ?? 'Unknown error'),
        _ => null,
      };
    } on FormatException {
      // Skip malformed JSON lines silently
      return null;
    }
  }
}

/// Convenience function to parse a Dio streaming response body.
///
/// Usage:
/// ```dart
/// final response = await dioClient.postStream('/api/chat', data: payload);
/// final events = parseStreamResponse(response.data!.stream);
/// await for (final event in events) {
///   switch (event) {
///     case ContentEvent(:final text):
///       // append text to UI
///     case ReasoningEvent(:final text):
///       // show reasoning
///     case StatusEvent(:final status):
///       // update status indicator
///     case ErrorEvent(:final message):
///       // show error
///   }
/// }
/// ```
Stream<ChatEvent> parseChatStream(Stream<Uint8List> byteStream) =>
    NdjsonParser().parse(byteStream);

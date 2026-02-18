/// Chat event sealed class for domain-layer stream event handling.
///
/// Re-exports and extends the NDJSON parser events with additional
/// domain-level semantics for the chat feature.
library;

import 'package:sanbao_flutter/core/network/ndjson_parser.dart' as ndjson;

/// The phase of AI response streaming, matching the web's StreamingPhase.
enum StreamingPhase {
  /// AI is thinking/reasoning before responding.
  thinking,

  /// AI is searching the web or using tools.
  searching,

  /// AI is using a specific tool.
  usingTool,

  /// AI is generating a plan.
  planning,

  /// AI is producing the response content.
  answering;

  /// Returns the Russian label for this phase.
  String get label => switch (this) {
        StreamingPhase.thinking => 'Думает',
        StreamingPhase.searching => 'Ищет',
        StreamingPhase.usingTool => 'Использует инструменты',
        StreamingPhase.planning => 'Составляет план',
        StreamingPhase.answering => 'Отвечает',
      };
}

/// Tool category for granular status display in the thinking indicator.
enum ToolCategory {
  webSearch,
  knowledge,
  calculation,
  memory,
  task,
  notification,
  scratchpad,
  chart,
  http,
  mcp,
  generic;

  /// Returns the Russian label for this tool category.
  String get label => switch (this) {
        ToolCategory.webSearch => 'Ищет в интернете',
        ToolCategory.knowledge => 'Ищет в базе знаний',
        ToolCategory.calculation => 'Вычисляет',
        ToolCategory.memory => 'Сохраняет в память',
        ToolCategory.task => 'Создает задачу',
        ToolCategory.notification => 'Отправляет уведомление',
        ToolCategory.scratchpad => 'Работает с заметками',
        ToolCategory.chart => 'Строит график',
        ToolCategory.http => 'Выполняет запрос',
        ToolCategory.mcp => 'Использует плагин',
        ToolCategory.generic => 'Использует инструменты',
      };

  /// Resolves a tool name string to its category.
  static ToolCategory fromToolName(String? toolName) {
    if (toolName == null || toolName.isEmpty) return ToolCategory.generic;

    return switch (toolName) {
      'read_knowledge' || 'search_knowledge' => ToolCategory.knowledge,
      'calculate' || 'analyze_csv' => ToolCategory.calculation,
      'generate_chart_data' => ToolCategory.chart,
      'save_memory' => ToolCategory.memory,
      'create_task' => ToolCategory.task,
      'send_notification' => ToolCategory.notification,
      'write_scratchpad' || 'read_scratchpad' => ToolCategory.scratchpad,
      'http_request' => ToolCategory.http,
      'get_current_time' ||
      'get_user_info' ||
      'get_conversation_context' =>
        ToolCategory.generic,
      _ => ToolCategory.mcp,
    };
  }
}

/// Converts an NDJSON [ndjson.ChatEvent] to a [StreamingPhase].
///
/// Used by the chat provider to track what the AI is currently doing.
StreamingPhase? phaseFromEvent(ndjson.ChatEvent event) => switch (event) {
      ndjson.ReasoningEvent() => StreamingPhase.thinking,
      ndjson.PlanEvent() => StreamingPhase.planning,
      ndjson.ContentEvent() => StreamingPhase.answering,
      ndjson.StatusEvent(:final status) => switch (status) {
          'searching' => StreamingPhase.searching,
          'using_tool' => StreamingPhase.usingTool,
          _ => null,
        },
      _ => null,
    };

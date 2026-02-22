/// Application-wide configuration constants.
///
/// Contains base URLs, version info, feature flags, and limits
/// derived from the web project's constants.ts.
library;

import 'package:sanbao_flutter/core/config/env.dart';

/// Central configuration for the Sanbao mobile app.
abstract final class AppConfig {
  // ---- App Identity ----

  static const String appName = 'Sanbao';
  static const String appDescription = 'AI-платформа для профессионалов';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;

  // ---- API ----

  static String get baseUrl => Env.apiBaseUrl;
  static String get apiPath => '/api';
  static String get chatEndpoint => '$apiPath/chat';
  static String get conversationsEndpoint => '$apiPath/conversations';
  static String get agentsEndpoint => '$apiPath/agents';
  static String get skillsEndpoint => '$apiPath/skills';
  static String get artifactsEndpoint => '$apiPath/artifacts';
  static String get tasksEndpoint => '$apiPath/tasks';
  static String get memoryEndpoint => '$apiPath/memory';
  static String get billingEndpoint => '$apiPath/billing';
  static String get profileEndpoint => '$apiPath/profile';
  static String get authEndpoint => '$apiPath/auth';
  static String get healthEndpoint => '$apiPath/health';
  static String get filesEndpoint => '$apiPath/files';
  static String get mcpServersEndpoint => '$apiPath/mcp';
  static String get toolsEndpoint => '$apiPath/tools';
  static String get pluginsEndpoint => '$apiPath/plugins';
  static String get notificationsEndpoint => '$apiPath/notifications';
  static String get userFilesEndpoint => '$apiPath/user-files';
  static String get imageGenerateEndpoint => '$apiPath/image-generate';
  static String get imageEditEndpoint => '$apiPath/image-edit';
  static String get fixCodeEndpoint => '$apiPath/fix-code';

  // ---- Timeouts ----

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const Duration streamTimeout = Duration(minutes: 5);

  // ---- File Limits ----

  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxFileSizeParseBytes = 20 * 1024 * 1024; // 20MB
  static const int maxLogoSizeBytes = 512 * 1024; // 512KB
  static const int maxAttachments = 20;

  // ---- Pagination ----

  static const int defaultPaginationLimit = 50;
  static const int maxPaginationLimit = 100;

  // ---- Conversation ----

  static const int conversationTitleMaxLength = 60;
  static const int maxMessagesPerRequest = 200;
  static const int maxMessageSizeBytes = 100 * 1024; // 100KB

  // ---- AI Defaults ----

  static const double defaultTemperature = 0.6;
  static const int defaultMaxTokens = 4096;
  static const double defaultTopP = 0.95;
  static const int defaultContextWindow = 128000;

  // ---- Auth ----

  static const int passwordMinLength = 8;
  static const String apiKeyPrefix = 'lma_';

  // ---- Retry ----

  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // ---- Feature Flags ----

  static const bool enableBiometricAuth = true;
  static const bool enableVoiceInput = true;
  static const bool enableFileAttachments = true;
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableImageGeneration = true;

  // ---- Allowed File Types ----

  static const List<String> allowedFileTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/rtf',
    'text/csv',
    'text/html',
    'text/plain',
    'image/png',
    'image/jpeg',
    'image/webp',
  ];

  // ---- Icon & Color Palettes (from web constants) ----

  static const List<String> validIcons = [
    'Bot', 'Scale', 'Briefcase', 'Shield', 'BookOpen', 'Gavel', 'FileText',
    'Building', 'User', 'HeartPulse', 'GraduationCap', 'Landmark',
    'Code', 'MessageSquare', 'Globe', 'Lightbulb', 'FileSearch',
    'ShieldCheck', 'ClipboardCheck', 'Brain', 'Triangle', 'Sparkles',
  ];

  static const List<String> validColors = [
    '#4F6EF7', '#7C3AED', '#10B981', '#F59E0B',
    '#EF4444', '#EC4899', '#06B6D4', '#6366F1',
  ];

  // ---- Artifact Type Labels ----

  static const Map<String, String> artifactTypeLabels = {
    'CONTRACT': 'Договор',
    'CLAIM': 'Исковое заявление',
    'COMPLAINT': 'Жалоба',
    'DOCUMENT': 'Документ',
    'CODE': 'Код',
    'ANALYSIS': 'Правовой анализ',
    'IMAGE': 'Изображение',
  };

  // ---- Correlation Header ----

  static const String correlationHeader = 'x-request-id';
}

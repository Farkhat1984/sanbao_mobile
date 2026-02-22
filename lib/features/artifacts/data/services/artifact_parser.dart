/// Parser for `<sanbao-doc>` tags in AI message content.
///
/// Extracts artifact metadata (id, title, type) from the
/// raw message content produced by the AI assistant.
/// This is the artifact feature module's own parser that
/// produces [FullArtifact] entities (vs. the lightweight
/// chat module parser that produces [chat/Artifact]).
library;

import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact_version.dart';

/// Result of parsing sanbao-doc tags from content.
class ArtifactParseResult {
  const ArtifactParseResult({
    required this.artifacts,
    required this.cleanContent,
  });

  /// The extracted artifacts.
  final List<FullArtifact> artifacts;

  /// The content with `<sanbao-doc>` tags removed.
  final String cleanContent;

  /// Whether any artifacts were found.
  bool get hasArtifacts => artifacts.isNotEmpty;
}

/// Parses `<sanbao-doc>` tags from AI message content.
///
/// Extracts artifact metadata and content, creating [FullArtifact]
/// entities with an initial version snapshot.
///
/// Tag format:
/// ```html
/// <sanbao-doc type="DOCUMENT" title="Contract Title">
///   Markdown or code content here...
/// </sanbao-doc>
/// ```
///
/// Supported type values:
/// - DOCUMENT, CONTRACT, CLAIM, COMPLAINT
/// - CODE
/// - LEGAL, LEGAL_ANALYSIS
/// - SPREADSHEET, TABLE
/// - ANALYSIS
/// - IMAGE
abstract final class ArtifactContentParser {
  /// Matches `<sanbao-doc type="TYPE" title="TITLE">CONTENT</sanbao-doc>`.
  static final RegExp _tagPattern = RegExp(
    r'<sanbao-doc\s+(?:type="([^"]*?)"\s+title="([^"]*?)"|title="([^"]*?)"\s+type="([^"]*?)")\s*>([\s\S]*?)</sanbao-doc>',
    multiLine: true,
  );

  /// Simpler pattern that handles the standard attribute order.
  static final RegExp _simplePattern = RegExp(
    r'<sanbao-doc\s+type="([^"]*?)"\s+title="([^"]*?)">([\s\S]*?)</sanbao-doc>',
    multiLine: true,
  );

  /// Parses all `<sanbao-doc>` tags from [content].
  ///
  /// Returns extracted [FullArtifact] entities with initial version
  /// snapshots and the cleaned content without tags.
  ///
  /// The [conversationId] and [messageId] are attached to the
  /// resulting artifacts for context binding.
  static ArtifactParseResult parse(
    String content, {
    String? conversationId,
    String? messageId,
  }) {
    final artifacts = <FullArtifact>[];
    var cleanContent = content;
    var index = 0;

    // Try the simple pattern first (most common case)
    for (final match in _simplePattern.allMatches(content)) {
      final typeStr = match.group(1) ?? 'DOCUMENT';
      final title = match.group(2) ?? 'Документ';
      final body = (match.group(3) ?? '').trim();

      final now = DateTime.now();
      final artifactId = 'artifact_${now.millisecondsSinceEpoch}_$index';
      final versionId = 'version_${now.millisecondsSinceEpoch}_${index}_1';

      final type = ArtifactType.fromString(typeStr);

      artifacts.add(FullArtifact(
        id: artifactId,
        conversationId: conversationId,
        messageId: messageId,
        type: type,
        title: title,
        content: body,
        language: _detectLanguage(typeStr, body),
        versions: [
          ArtifactVersion(
            id: versionId,
            versionNumber: 1,
            content: body,
            createdAt: now,
            label: 'Оригинал',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),);

      index++;
    }

    // If the simple pattern found nothing, try the flexible pattern
    if (artifacts.isEmpty) {
      for (final match in _tagPattern.allMatches(content)) {
        // Handle both attribute orders
        final typeStr =
            match.group(1) ?? match.group(4) ?? 'DOCUMENT';
        final title =
            match.group(2) ?? match.group(3) ?? 'Документ';
        final body = (match.group(5) ?? '').trim();

        final now = DateTime.now();
        final artifactId = 'artifact_${now.millisecondsSinceEpoch}_$index';
        final versionId = 'version_${now.millisecondsSinceEpoch}_${index}_1';

        final type = ArtifactType.fromString(typeStr);

        artifacts.add(FullArtifact(
          id: artifactId,
          conversationId: conversationId,
          messageId: messageId,
          type: type,
          title: title,
          content: body,
          language: _detectLanguage(typeStr, body),
          versions: [
            ArtifactVersion(
              id: versionId,
              versionNumber: 1,
              content: body,
              createdAt: now,
              label: 'Оригинал',
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),);

        index++;
      }
    }

    // Remove all sanbao-doc tags from displayed content
    if (artifacts.isNotEmpty) {
      cleanContent = content
          .replaceAll(_simplePattern, '')
          .replaceAll(_tagPattern, '')
          .trim();
    }

    return ArtifactParseResult(
      artifacts: artifacts,
      cleanContent: cleanContent,
    );
  }

  /// Detects the programming language from artifact type and content.
  static String? _detectLanguage(String typeStr, String body) {
    if (typeStr.toUpperCase() != 'CODE') return null;

    final trimmed = body.trim().toLowerCase();
    if (trimmed.contains('<!doctype html') || trimmed.contains('<html')) {
      return 'html';
    }
    if (trimmed.contains('import react') ||
        trimmed.contains('from "react"') ||
        trimmed.contains("from 'react'")) {
      return 'jsx';
    }
    if (trimmed.contains('def ') && trimmed.contains('import ')) {
      return 'python';
    }
    if (trimmed.contains('func ') && trimmed.contains('package ')) {
      return 'go';
    }
    if (trimmed.contains('class ') && trimmed.contains('void ')) {
      return 'dart';
    }
    return 'javascript';
  }

  /// Checks whether content contains any `<sanbao-doc>` tags.
  static bool hasArtifactTags(String content) =>
      _simplePattern.hasMatch(content) || _tagPattern.hasMatch(content);
}

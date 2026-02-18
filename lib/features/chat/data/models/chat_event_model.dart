/// Chat event model for parsing NDJSON stream events.
///
/// Provides artifact extraction from the content stream by
/// detecting `<sanbao-doc>` tags in the accumulated content.
library;

import 'package:sanbao_flutter/features/chat/domain/entities/artifact.dart';

/// Regular expressions for parsing sanbao custom tags from content.
abstract final class SanbaoTagParser {
  /// Matches `<sanbao-doc type="TYPE" title="TITLE">CONTENT</sanbao-doc>`.
  static final RegExp artifactPattern = RegExp(
    r'<sanbao-doc\s+type="([^"]*?)"\s+title="([^"]*?)">([\s\S]*?)</sanbao-doc>',
    multiLine: true,
  );

  /// Matches `[ст. NN CODE](article://code_name/NN)` legal reference links.
  static final RegExp legalRefPattern = RegExp(
    r'\[ст\.\s*(\d+(?:\.\d+)?)\s+([^\]]+)\]\(article://([^/]+)/(\d+(?:\.\d+)?)\)',
  );

  /// Extracts all artifacts from the given content string.
  ///
  /// Returns a list of [Artifact]s found within `<sanbao-doc>` tags
  /// and the content with artifact tags removed.
  static ({List<Artifact> artifacts, String cleanContent}) extractArtifacts(
    String content,
  ) {
    final artifacts = <Artifact>[];
    var cleanContent = content;
    var index = 0;

    for (final match in artifactPattern.allMatches(content)) {
      final typeStr = match.group(1) ?? 'DOCUMENT';
      final title = match.group(2) ?? 'Документ';
      final body = match.group(3) ?? '';

      artifacts.add(Artifact(
        id: 'artifact_${index++}',
        type: ArtifactType.fromString(typeStr),
        title: title,
        content: body.trim(),
        language: _detectLanguage(typeStr, body),
      ));
    }

    // Remove artifact tags from the displayed content
    if (artifacts.isNotEmpty) {
      cleanContent = content.replaceAll(artifactPattern, '').trim();
    }

    return (artifacts: artifacts, cleanContent: cleanContent);
  }

  /// Detects the programming language from artifact type and content.
  static String? _detectLanguage(String typeStr, String body) {
    if (typeStr.toUpperCase() != 'CODE') return null;

    final trimmed = body.trim().toLowerCase();
    if (trimmed.contains('<!doctype html') || trimmed.contains('<html')) {
      return 'html';
    }
    if (trimmed.contains('import react') || trimmed.contains('from "react"')) {
      return 'jsx';
    }
    if (trimmed.contains('def ') || trimmed.contains('import ')) {
      return 'python';
    }
    return 'javascript';
  }

  /// Checks whether the content contains any legal reference links.
  static bool hasLegalReferences(String content) =>
      legalRefPattern.hasMatch(content);

  /// Extracts all legal reference article codes from content.
  static List<({String code, String article, String displayText})>
      extractLegalReferences(String content) {
    final refs = <({String code, String article, String displayText})>[];
    for (final match in legalRefPattern.allMatches(content)) {
      refs.add((
        code: match.group(3) ?? '',
        article: match.group(4) ?? match.group(1) ?? '',
        displayText: 'ст. ${match.group(1)} ${match.group(2)}',
      ));
    }
    return refs;
  }
}

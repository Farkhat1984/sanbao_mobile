/// Remote data source for artifact API operations.
///
/// Handles all HTTP communication with the artifact endpoints:
/// - GET /api/artifacts/:id
/// - PUT /api/artifacts/:id
/// - GET /api/artifacts/:id/versions
/// - POST /api/artifacts/:id/export
/// - GET /api/conversations/:id/artifacts
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/artifacts/data/models/artifact_model.dart';
import 'package:sanbao_flutter/features/artifacts/data/models/artifact_version_model.dart';
import 'package:sanbao_flutter/features/artifacts/domain/repositories/artifact_repository.dart';

/// Remote data source for artifact API calls.
class ArtifactRemoteDataSource {
  ArtifactRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Fetches a single artifact by ID.
  Future<ArtifactModel> getArtifact(String artifactId) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '${AppConfig.artifactsEndpoint}/$artifactId',
    );
    return ArtifactModel.fromJson(response);
  }

  /// Fetches all artifacts for a conversation.
  Future<List<ArtifactModel>> getArtifactsByConversation(
    String conversationId,
  ) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '${AppConfig.conversationsEndpoint}/$conversationId/artifacts',
    );
    final items = response['artifacts'] as List<Object?>? ?? [];
    return items
        .map((item) => ArtifactModel.fromJson(item! as Map<String, Object?>))
        .toList();
  }

  /// Updates an artifact's content and/or title.
  Future<ArtifactModel> updateArtifact({
    required String artifactId,
    required String content,
    String? title,
  }) async {
    final data = <String, Object?>{
      'content': content,
      if (title != null) 'title': title,
    };

    final response = await _dioClient.put<Map<String, Object?>>(
      '${AppConfig.artifactsEndpoint}/$artifactId',
      data: data,
    );
    return ArtifactModel.fromJson(response);
  }

  /// Exports an artifact in the specified format.
  ///
  /// Returns the raw bytes of the exported file.
  Future<List<int>> exportArtifact({
    required String artifactId,
    required ExportFormat format,
  }) async {
    final formatString = switch (format) {
      ExportFormat.pdf => 'pdf',
      ExportFormat.docx => 'docx',
      ExportFormat.txt => 'txt',
      ExportFormat.markdown => 'md',
      ExportFormat.html => 'html',
      ExportFormat.copy => 'txt',
    };

    final response = await _dioClient.post<Map<String, Object?>>(
      '${AppConfig.artifactsEndpoint}/$artifactId/export',
      data: {'format': formatString},
    );

    // The server may return base64-encoded content or a download URL
    final encoded = response['data'] as String?;
    if (encoded != null) {
      return base64Decode(encoded);
    }

    // Fallback: return the artifact content as UTF-8 bytes
    final content = response['content'] as String? ?? '';
    return utf8.encode(content);
  }

  /// Fetches all versions of an artifact.
  Future<List<ArtifactVersionModel>> getVersions(String artifactId) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '${AppConfig.artifactsEndpoint}/$artifactId/versions',
    );
    final items = response['versions'] as List<Object?>? ?? [];
    return items
        .map((item) =>
            ArtifactVersionModel.fromJson(item! as Map<String, Object?>),)
        .toList();
  }

  /// Restores an artifact to a specific version.
  Future<ArtifactModel> restoreVersion({
    required String artifactId,
    required int versionNumber,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      '${AppConfig.artifactsEndpoint}/$artifactId/versions/$versionNumber/restore',
    );
    return ArtifactModel.fromJson(response);
  }
}

/// Riverpod provider for [ArtifactRemoteDataSource].
final artifactRemoteDataSourceProvider =
    Provider<ArtifactRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ArtifactRemoteDataSource(dioClient: dioClient);
});

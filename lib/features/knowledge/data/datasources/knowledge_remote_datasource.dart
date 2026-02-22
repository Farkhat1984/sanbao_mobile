/// Remote data source for knowledge file CRUD operations.
///
/// Handles GET/POST/PUT/DELETE calls to /api/user-files.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/knowledge/data/models/knowledge_file_model.dart';
import 'package:sanbao_flutter/features/knowledge/domain/entities/knowledge_file.dart';

/// Remote data source for knowledge file operations via the REST API.
class KnowledgeRemoteDataSource {
  KnowledgeRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// API endpoint for user files.
  static String get _endpoint => AppConfig.userFilesEndpoint;

  /// Fetches all knowledge files for the current user.
  ///
  /// The list endpoint returns files without their content body
  /// to minimize payload size.
  Future<List<KnowledgeFile>> getFiles() async {
    final response = await _dioClient.get<List<Object?>>(
      _endpoint,
    );

    return KnowledgeFileModel.fromJsonList(response);
  }

  /// Fetches a single knowledge file by [id], including its content.
  Future<KnowledgeFile> getFile(String id) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '$_endpoint/$id',
    );

    return KnowledgeFileModel.fromJson(response).file;
  }

  /// Creates a new knowledge file with text content.
  Future<KnowledgeFile> createFile({
    required String name,
    required String content,
    String? description,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      _endpoint,
      data: {
        'name': name,
        'content': content,
        if (description != null) 'description': description,
      },
    );

    return KnowledgeFileModel.fromJson(response).file;
  }

  /// Updates an existing knowledge file.
  Future<KnowledgeFile> updateFile(
    String id, {
    String? name,
    String? description,
    String? content,
  }) async {
    final response = await _dioClient.put<Map<String, Object?>>(
      '$_endpoint/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (content != null) 'content': content,
      },
    );

    return KnowledgeFileModel.fromJson(response).file;
  }

  /// Deletes a knowledge file by [id].
  Future<void> deleteFile(String id) async {
    await _dioClient.delete<Map<String, Object?>>(
      '$_endpoint/$id',
    );
  }
}

/// Riverpod provider for [KnowledgeRemoteDataSource].
final knowledgeRemoteDataSourceProvider =
    Provider<KnowledgeRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return KnowledgeRemoteDataSource(dioClient: dioClient);
});

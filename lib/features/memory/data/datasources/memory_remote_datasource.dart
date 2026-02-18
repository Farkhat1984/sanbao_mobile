/// Remote data source for memory CRUD operations.
///
/// Handles GET/POST/PUT/DELETE calls to /api/memories.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/memory/data/models/memory_model.dart';
import 'package:sanbao_flutter/features/memory/domain/entities/memory.dart';

/// Remote data source for memory operations via the REST API.
class MemoryRemoteDataSource {
  MemoryRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Fetches all memories for the current user.
  Future<List<Memory>> getAll() async {
    final response = await _dioClient.get<Map<String, Object?>>(
      AppConfig.memoryEndpoint,
    );

    final memoriesJson = response['memories'] as List<Object?>? ??
        response['data'] as List<Object?>? ??
        [];

    return MemoryModel.fromJsonList(memoriesJson);
  }

  /// Creates a new memory.
  Future<Memory> create({
    required String content,
    String? category,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      AppConfig.memoryEndpoint,
      data: {
        'content': content,
        if (category != null) 'category': category,
      },
    );

    return MemoryModel.fromJson(response).memory;
  }

  /// Updates an existing memory.
  Future<Memory> update({
    required String id,
    String? content,
    String? category,
  }) async {
    final response = await _dioClient.put<Map<String, Object?>>(
      '${AppConfig.memoryEndpoint}/$id',
      data: {
        if (content != null) 'content': content,
        if (category != null) 'category': category,
      },
    );

    return MemoryModel.fromJson(response).memory;
  }

  /// Deletes a memory by [id].
  Future<void> delete(String id) async {
    await _dioClient.delete<Map<String, Object?>>(
      '${AppConfig.memoryEndpoint}/$id',
    );
  }
}

/// Riverpod provider for [MemoryRemoteDataSource].
final memoryRemoteDataSourceProvider =
    Provider<MemoryRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return MemoryRemoteDataSource(dioClient: dioClient);
});

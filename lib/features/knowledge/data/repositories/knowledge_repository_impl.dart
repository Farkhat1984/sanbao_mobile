/// Implementation of the knowledge repository.
///
/// Delegates to the remote data source for all operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/knowledge/data/datasources/knowledge_remote_datasource.dart';
import 'package:sanbao_flutter/features/knowledge/domain/entities/knowledge_file.dart';
import 'package:sanbao_flutter/features/knowledge/domain/repositories/knowledge_repository.dart';

/// Concrete implementation of [KnowledgeRepository].
class KnowledgeRepositoryImpl implements KnowledgeRepository {
  KnowledgeRepositoryImpl({
    required KnowledgeRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final KnowledgeRemoteDataSource _remoteDataSource;

  @override
  Future<List<KnowledgeFile>> getFiles() => _remoteDataSource.getFiles();

  @override
  Future<KnowledgeFile> getFile(String id) => _remoteDataSource.getFile(id);

  @override
  Future<KnowledgeFile> createFile({
    required String name,
    required String content,
    String? description,
  }) =>
      _remoteDataSource.createFile(
        name: name,
        content: content,
        description: description,
      );

  @override
  Future<KnowledgeFile> updateFile(
    String id, {
    String? name,
    String? description,
    String? content,
  }) =>
      _remoteDataSource.updateFile(
        id,
        name: name,
        description: description,
        content: content,
      );

  @override
  Future<void> deleteFile(String id) => _remoteDataSource.deleteFile(id);
}

/// Riverpod provider for [KnowledgeRepository].
final knowledgeRepositoryProvider = Provider<KnowledgeRepository>((ref) {
  final remoteDataSource = ref.watch(knowledgeRemoteDataSourceProvider);
  return KnowledgeRepositoryImpl(remoteDataSource: remoteDataSource);
});

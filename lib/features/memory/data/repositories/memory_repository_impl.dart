/// Implementation of the memory repository.
///
/// Delegates to the remote data source for all operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/memory/data/datasources/memory_remote_datasource.dart';
import 'package:sanbao_flutter/features/memory/domain/entities/memory.dart';
import 'package:sanbao_flutter/features/memory/domain/repositories/memory_repository.dart';

/// Concrete implementation of [MemoryRepository].
class MemoryRepositoryImpl implements MemoryRepository {
  MemoryRepositoryImpl({required MemoryRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final MemoryRemoteDataSource _remoteDataSource;

  @override
  Future<List<Memory>> getAll() => _remoteDataSource.getAll();

  @override
  Future<Memory> create({
    required String content,
    String? category,
  }) =>
      _remoteDataSource.create(content: content, category: category);

  @override
  Future<Memory> update({
    required String id,
    String? content,
    String? category,
  }) =>
      _remoteDataSource.update(id: id, content: content, category: category);

  @override
  Future<void> delete(String id) => _remoteDataSource.delete(id);
}

/// Riverpod provider for [MemoryRepository].
final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  final remoteDataSource = ref.watch(memoryRemoteDataSourceProvider);
  return MemoryRepositoryImpl(remoteDataSource: remoteDataSource);
});

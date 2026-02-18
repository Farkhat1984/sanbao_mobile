/// Concrete implementation of the artifact repository.
///
/// Bridges the domain [ArtifactRepository] contract with the
/// [ArtifactRemoteDataSource] for server communication.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/core/network/api_exceptions.dart';
import 'package:sanbao_flutter/features/artifacts/data/datasources/artifact_remote_datasource.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact.dart';
import 'package:sanbao_flutter/features/artifacts/domain/entities/artifact_version.dart';
import 'package:sanbao_flutter/features/artifacts/domain/repositories/artifact_repository.dart';

/// Implementation of [ArtifactRepository].
///
/// Maps API exceptions to domain [Failure] types for clean
/// error handling in the presentation layer.
class ArtifactRepositoryImpl implements ArtifactRepository {
  ArtifactRepositoryImpl({
    required ArtifactRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final ArtifactRemoteDataSource _remoteDataSource;

  @override
  Future<FullArtifact> getById(String artifactId) async {
    try {
      final model = await _remoteDataSource.getArtifact(artifactId);
      return model.toEntity();
    } on NotFoundException {
      throw const NotFoundFailure(
        message: 'Артефакт не найден',
      );
    } on ApiException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<List<FullArtifact>> getByConversation(String conversationId) async {
    try {
      final models = await _remoteDataSource.getArtifactsByConversation(
        conversationId,
      );
      return models.map((m) => m.toEntity()).toList();
    } on ApiException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<FullArtifact> update({
    required String artifactId,
    required String content,
    String? title,
  }) async {
    try {
      final model = await _remoteDataSource.updateArtifact(
        artifactId: artifactId,
        content: content,
        title: title,
      );
      return model.toEntity();
    } on NotFoundException {
      throw const NotFoundFailure(
        message: 'Артефакт не найден',
      );
    } on ApiException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<List<int>> export({
    required String artifactId,
    required ExportFormat format,
  }) async {
    try {
      return await _remoteDataSource.exportArtifact(
        artifactId: artifactId,
        format: format,
      );
    } on ApiException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<List<ArtifactVersion>> getVersions(String artifactId) async {
    try {
      final models = await _remoteDataSource.getVersions(artifactId);
      return models.map((m) => m.toEntity()).toList();
    } on ApiException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }

  @override
  Future<FullArtifact> restoreVersion({
    required String artifactId,
    required int versionNumber,
  }) async {
    try {
      final model = await _remoteDataSource.restoreVersion(
        artifactId: artifactId,
        versionNumber: versionNumber,
      );
      return model.toEntity();
    } on NotFoundException {
      throw const NotFoundFailure(
        message: 'Версия не найдена',
      );
    } on ApiException catch (e) {
      throw ServerFailure(message: e.message);
    }
  }
}

/// Riverpod provider for [ArtifactRepository].
final artifactRepositoryProvider = Provider<ArtifactRepository>((ref) {
  final remoteDataSource = ref.watch(artifactRemoteDataSourceProvider);
  return ArtifactRepositoryImpl(remoteDataSource: remoteDataSource);
});

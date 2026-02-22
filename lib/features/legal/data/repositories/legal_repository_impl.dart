/// Implementation of the legal repository.
///
/// Delegates to the remote data source and maps API exceptions
/// to domain [Failure] types.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/errors/error_handler.dart';
import 'package:sanbao_flutter/core/errors/failure.dart';
import 'package:sanbao_flutter/features/legal/data/datasources/legal_remote_datasource.dart';
import 'package:sanbao_flutter/features/legal/domain/entities/legal_article.dart';
import 'package:sanbao_flutter/features/legal/domain/repositories/legal_repository.dart';

/// Concrete implementation of [LegalRepository].
///
/// Wraps remote data source calls with error handling, converting
/// API exceptions to domain failures via [ErrorHandler.toFailure].
class LegalRepositoryImpl implements LegalRepository {
  LegalRepositoryImpl({
    required LegalRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final LegalRemoteDataSource _remoteDataSource;

  @override
  Future<LegalArticle> getArticle({
    required String codeName,
    required String articleNum,
  }) async {
    try {
      return await _remoteDataSource.getArticle(
        codeName: codeName,
        articleNum: articleNum,
      );
    } on Failure {
      rethrow;
    } on Object catch (e) {
      debugPrint('[LegalRepo] getArticle($codeName/$articleNum) failed: $e');
      throw ErrorHandler.toFailure(e);
    }
  }
}

/// Riverpod provider for [LegalRepository].
final legalRepositoryProvider = Provider<LegalRepository>((ref) {
  final remoteDataSource = ref.watch(legalRemoteDataSourceProvider);
  return LegalRepositoryImpl(remoteDataSource: remoteDataSource);
});

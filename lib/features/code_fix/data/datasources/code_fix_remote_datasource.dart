/// Remote data source for code fix operations.
///
/// Handles POST calls to /api/fix-code.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';

/// Remote data source for fixing code via the AI API.
class CodeFixRemoteDataSource {
  CodeFixRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Sends code and error to the API and returns the fixed code.
  ///
  /// Request: `{code: string, error: string}`
  /// Response: `{fixedCode: string}`
  Future<String> fixCode({
    required String code,
    required String error,
  }) async {
    final response = await _dioClient.post<Map<String, Object?>>(
      AppConfig.fixCodeEndpoint,
      data: {'code': code, 'error': error},
    );

    return response['fixedCode'] as String;
  }
}

/// Riverpod provider for [CodeFixRemoteDataSource].
final codeFixRemoteDataSourceProvider =
    Provider<CodeFixRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CodeFixRemoteDataSource(dioClient: dioClient);
});

/// Remote data source for legal article operations.
///
/// Calls `GET /api/articles?code=<code>&article=<num>` to fetch
/// the full article text with validity and annotation data.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/core/config/app_config.dart';
import 'package:sanbao_flutter/core/network/dio_client.dart';
import 'package:sanbao_flutter/features/legal/domain/entities/legal_article.dart';

/// Remote data source for fetching legal articles via the REST API.
///
/// The backend endpoint mirrors the web project's
/// `GET /api/articles?code=<code>&article=<num>`.
class LegalRemoteDataSource {
  LegalRemoteDataSource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  /// Fetches a legal article by [codeName] and [articleNum].
  ///
  /// Returns a [LegalArticle] entity parsed from the API response.
  /// The API response shape (from web `route.ts`):
  /// ```json
  /// {
  ///   "code": "criminal_code",
  ///   "article": "188",
  ///   "title": "...",
  ///   "text": "...",
  ///   "annotation": "..."
  /// }
  /// ```
  Future<LegalArticle> getArticle({
    required String codeName,
    required String articleNum,
  }) async {
    final response = await _dioClient.get<Map<String, Object?>>(
      '${AppConfig.apiPath}/articles',
      queryParameters: {
        'code': codeName,
        'article': articleNum,
      },
    );

    return _parseArticle(response, codeName, articleNum);
  }

  /// Parses the API response JSON into a [LegalArticle] entity.
  LegalArticle _parseArticle(
    Map<String, Object?> json,
    String codeName,
    String articleNum,
  ) {
    final code = (json['code'] as String?) ?? codeName;
    final article = (json['article'] as String?) ?? articleNum;
    final title = (json['title'] as String?) ?? 'Статья $article';
    final text = (json['text'] as String?) ??
        (json['content'] as String?) ??
        '';
    final annotation = (json['annotation'] as String?)?.nullIfEmpty;
    final sourceUrl = (json['sourceUrl'] as String?)?.nullIfEmpty;

    // Parse validity if present; default to valid
    final isValid = json['isValid'] as bool? ?? true;

    // Parse dates if present
    final validFrom = _parseDate(json['validFrom']);
    final validTo = _parseDate(json['validTo']);

    return LegalArticle(
      id: '$code/$article',
      codeName: code,
      articleNum: article,
      title: title,
      content: text,
      annotation: annotation,
      isValid: isValid,
      sourceUrl: sourceUrl,
      validFrom: validFrom,
      validTo: validTo,
    );
  }

  /// Safely parses a date value that could be String or null.
  DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

/// Helper extension to treat empty strings as null.
extension _StringNullEmpty on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

/// Riverpod provider for [LegalRemoteDataSource].
final legalRemoteDataSourceProvider =
    Provider<LegalRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return LegalRemoteDataSource(dioClient: dioClient);
});

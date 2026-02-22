/// Abstract legal repository contract.
///
/// Defines the operation for fetching a legal article by its
/// code name and article number.
library;

import 'package:sanbao_flutter/features/legal/domain/entities/legal_article.dart';

/// Abstract repository for legal article operations.
abstract class LegalRepository {
  /// Fetches a legal article by [codeName] and [articleNum].
  ///
  /// Throws a [Failure] if the article cannot be retrieved.
  Future<LegalArticle> getArticle({
    required String codeName,
    required String articleNum,
  });
}

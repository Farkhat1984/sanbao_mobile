/// Riverpod providers for legal article data.
///
/// Provides a family-based async provider keyed by (codeName, articleNum)
/// so that multiple articles can be loaded independently without collisions.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanbao_flutter/features/legal/data/repositories/legal_repository_impl.dart';
import 'package:sanbao_flutter/features/legal/domain/entities/legal_article.dart';

/// Compound key for identifying a legal article request.
///
/// Used as the family parameter for [legalArticleProvider].
/// Implements equality so that identical requests share a single provider.
class LegalArticleKey {
  const LegalArticleKey({
    required this.codeName,
    required this.articleNum,
  });

  /// Internal code name (e.g., "criminal_code").
  final String codeName;

  /// Article number (e.g., "188").
  final String articleNum;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalArticleKey &&
          runtimeType == other.runtimeType &&
          codeName == other.codeName &&
          articleNum == other.articleNum;

  @override
  int get hashCode => Object.hash(codeName, articleNum);

  @override
  String toString() => 'LegalArticleKey($codeName/$articleNum)';
}

/// Async provider that fetches a single legal article.
///
/// Keyed by [LegalArticleKey] so that multiple articles can be loaded
/// at the same time without interfering with each other.
///
/// Usage:
/// ```dart
/// final articleAsync = ref.watch(
///   legalArticleProvider(LegalArticleKey(
///     codeName: 'criminal_code',
///     articleNum: '188',
///   )),
/// );
/// ```
final legalArticleProvider =
    FutureProvider.family<LegalArticle, LegalArticleKey>((ref, key) async {
  final repository = ref.watch(legalRepositoryProvider);
  return repository.getArticle(
    codeName: key.codeName,
    articleNum: key.articleNum,
  );
});

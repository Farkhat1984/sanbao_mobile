/// Legal article entity.
///
/// Represents a single article from a legal code (e.g., Article 188 of the
/// Criminal Code of Kazakhstan). Contains the full text, validity status,
/// and optional source URL for the official publication.
library;

/// A legal article retrieved from the Sanbao legal reference system.
///
/// This is a pure domain entity with no framework dependencies.
/// Equality is based on [id] (or [codeName]+[articleNum] compound key).
class LegalArticle {
  const LegalArticle({
    required this.id,
    required this.codeName,
    required this.articleNum,
    required this.title,
    required this.content,
    this.annotation,
    this.isValid = true,
    this.sourceUrl,
    this.validFrom,
    this.validTo,
  });

  /// Unique identifier for the article.
  ///
  /// Typically derived from `codeName/articleNum` on the server side.
  final String id;

  /// Internal code name (e.g., "criminal_code", "civil_code_general").
  final String codeName;

  /// Article number as a string (e.g., "188", "188-1").
  final String articleNum;

  /// Human-readable title of the article.
  final String title;

  /// Full text content of the article.
  final String content;

  /// Optional annotation or footnote text.
  final String? annotation;

  /// Whether the article is currently in force.
  ///
  /// `true` means the article is active and enforceable.
  /// `false` means it has been repealed, amended, or is pending enactment.
  final bool isValid;

  /// URL to the official source of the article text.
  final String? sourceUrl;

  /// Date from which the article is effective.
  final DateTime? validFrom;

  /// Date until which the article is effective.
  ///
  /// `null` means the article has no expiration (indefinitely valid).
  final DateTime? validTo;

  /// Returns the human-readable label for the legal code.
  ///
  /// Maps internal code names to their Russian abbreviations.
  String get codeLabel => codeLabelMap[codeName] ?? codeName;

  /// Formatted header string (e.g., "Ст. 188 УК РК").
  String get headerLabel => 'Ст. $articleNum $codeLabel';

  /// Creates a copy with modified fields.
  LegalArticle copyWith({
    String? id,
    String? codeName,
    String? articleNum,
    String? title,
    String? content,
    String? annotation,
    bool? isValid,
    String? sourceUrl,
    DateTime? validFrom,
    DateTime? validTo,
  }) =>
      LegalArticle(
        id: id ?? this.id,
        codeName: codeName ?? this.codeName,
        articleNum: articleNum ?? this.articleNum,
        title: title ?? this.title,
        content: content ?? this.content,
        annotation: annotation ?? this.annotation,
        isValid: isValid ?? this.isValid,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        validFrom: validFrom ?? this.validFrom,
        validTo: validTo ?? this.validTo,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegalArticle &&
          runtimeType == other.runtimeType &&
          codeName == other.codeName &&
          articleNum == other.articleNum;

  @override
  int get hashCode => Object.hash(codeName, articleNum);

  @override
  String toString() =>
      'LegalArticle(code=$codeName, article=$articleNum, title=$title)';

  /// Maps internal code names to Russian code abbreviations.
  ///
  /// Matches the web project's `CODE_LABELS` mapping from
  /// `ArticleContentView.tsx`.
  static const Map<String, String> codeLabelMap = {
    'constitution': 'Конституция РК',
    'criminal_code': 'УК РК',
    'criminal_procedure': 'УПК РК',
    'civil_code_general': 'ГК РК (Общая часть)',
    'civil_code_special': 'ГК РК (Особенная часть)',
    'civil_procedure': 'ГПК РК',
    'admin_offenses': 'КоАП РК',
    'admin_procedure': 'АППК РК',
    'tax_code': 'НК РК',
    'labor_code': 'ТК РК',
    'land_code': 'ЗК РК',
    'ecological_code': 'ЭК РК',
    'entrepreneurship': 'ПК РК',
    'budget_code': 'БК РК',
    'customs_code': 'ТамК РК',
    'family_code': 'КоБС РК',
    'social_code': 'СК РК',
    'water_code': 'ВК РК',
  };
}

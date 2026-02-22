/// Data model for usage tracking.
///
/// Handles JSON serialization/deserialization for Usage and PaymentHistoryItem.
/// Supports both the legacy format (`{messagesUsed, messagesLimit, ...}`) and
/// the backend /api/billing/current format (`{messageCount, tokenCount}` + plan limits).
library;

import 'package:sanbao_flutter/features/billing/domain/entities/usage.dart';

/// Data transfer model for [Usage].
class UsageModel {
  const UsageModel._({required this.usage});

  /// Parses a [UsageModel] from a JSON map (legacy format).
  factory UsageModel.fromJson(Map<String, Object?> json) => UsageModel._(
        usage: Usage(
          messagesUsed: (json['messagesUsed'] as num?)?.toInt() ??
              (json['messageCount'] as num?)?.toInt() ??
              0,
          messagesLimit: (json['messagesLimit'] as num?)?.toInt() ?? 0,
          tokensUsed: (json['tokensUsed'] as num?)?.toInt() ??
              (json['tokenCount'] as num?)?.toInt() ??
              0,
          tokensLimit: (json['tokensLimit'] as num?)?.toInt() ?? 0,
          storageUsed: (json['storageUsed'] as num?)?.toInt() ?? 0,
          storageLimit: (json['storageLimit'] as num?)?.toInt() ?? 0,
        ),
      );

  /// Parses usage from the /api/billing/current response.
  ///
  /// [usageJson] is `{messageCount, tokenCount}` from the `usage` field.
  /// [planJson] is the `plan` object containing limits like `messagesPerDay`, `tokensPerMonth`.
  factory UsageModel.fromCurrentJson(
    Map<String, Object?> usageJson,
    Map<String, Object?>? planJson,
  ) =>
      UsageModel._(
        usage: Usage(
          messagesUsed: (usageJson['messageCount'] as num?)?.toInt() ??
              (usageJson['messagesUsed'] as num?)?.toInt() ??
              0,
          messagesLimit:
              (planJson?['messagesPerDay'] as num?)?.toInt() ??
                  (usageJson['messagesLimit'] as num?)?.toInt() ??
                  0,
          tokensUsed: (usageJson['tokenCount'] as num?)?.toInt() ??
              (usageJson['tokensUsed'] as num?)?.toInt() ??
              0,
          tokensLimit:
              (planJson?['tokensPerMonth'] as num?)?.toInt() ??
                  (usageJson['tokensLimit'] as num?)?.toInt() ??
                  0,
          storageUsed: (usageJson['storageUsed'] as num?)?.toInt() ?? 0,
          storageLimit: (usageJson['storageLimit'] as num?)?.toInt() ?? 0,
        ),
      );

  /// The deserialized usage entity.
  final Usage usage;

  /// Serializes to JSON map.
  Map<String, Object?> toJson() => {
        'messagesUsed': usage.messagesUsed,
        'messagesLimit': usage.messagesLimit,
        'tokensUsed': usage.tokensUsed,
        'tokensLimit': usage.tokensLimit,
        'storageUsed': usage.storageUsed,
        'storageLimit': usage.storageLimit,
      };
}

/// Data transfer model for [PaymentHistoryItem].
class PaymentHistoryItemModel {
  const PaymentHistoryItemModel._({required this.item});

  /// Parses a [PaymentHistoryItemModel] from a JSON map.
  factory PaymentHistoryItemModel.fromJson(Map<String, Object?> json) =>
      PaymentHistoryItemModel._(
        item: PaymentHistoryItem(
          id: json['id'] as String? ?? '',
          amount: json['amount'] as int? ?? 0,
          currency: json['currency'] as String? ?? 'RUB',
          status: PaymentStatus.fromString(
            json['status'] as String? ?? 'pending',
          ),
          createdAt: DateTime.tryParse(
                json['createdAt'] as String? ?? '',
              ) ??
              DateTime.now(),
          description: json['description'] as String?,
          invoiceUrl: json['invoiceUrl'] as String?,
        ),
      );

  /// The deserialized payment history item.
  final PaymentHistoryItem item;

  /// Converts a list of JSON objects to a list of [PaymentHistoryItem] entities.
  static List<PaymentHistoryItem> fromJsonList(List<Object?> jsonList) =>
      jsonList
          .whereType<Map<String, Object?>>()
          .map((json) => PaymentHistoryItemModel.fromJson(json).item)
          .toList();

  /// Serializes to JSON map.
  Map<String, Object?> toJson() => {
        'id': item.id,
        'amount': item.amount,
        'currency': item.currency,
        'status': item.status.name,
        'createdAt': item.createdAt.toIso8601String(),
        if (item.description != null) 'description': item.description,
        if (item.invoiceUrl != null) 'invoiceUrl': item.invoiceUrl,
      };
}

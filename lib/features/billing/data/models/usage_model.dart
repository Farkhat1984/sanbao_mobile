/// Data model for usage tracking.
///
/// Handles JSON serialization/deserialization for Usage and PaymentHistoryItem.
library;

import 'package:sanbao_flutter/features/billing/domain/entities/usage.dart';

/// Data transfer model for [Usage].
class UsageModel {
  const UsageModel._({required this.usage});

  /// Parses a [UsageModel] from a JSON map.
  factory UsageModel.fromJson(Map<String, Object?> json) => UsageModel._(
        usage: Usage(
          messagesUsed: json['messagesUsed'] as int? ?? 0,
          messagesLimit: json['messagesLimit'] as int? ?? 0,
          tokensUsed: json['tokensUsed'] as int? ?? 0,
          tokensLimit: json['tokensLimit'] as int? ?? 0,
          storageUsed: json['storageUsed'] as int? ?? 0,
          storageLimit: json['storageLimit'] as int? ?? 0,
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

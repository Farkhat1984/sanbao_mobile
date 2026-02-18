/// Usage entity.
///
/// Tracks the user's current resource consumption against plan limits.
library;

/// Immutable representation of resource usage for the current billing period.
class Usage {
  const Usage({
    required this.messagesUsed,
    required this.messagesLimit,
    required this.tokensUsed,
    required this.tokensLimit,
    required this.storageUsed,
    required this.storageLimit,
  });

  /// Number of messages sent this period.
  final int messagesUsed;

  /// Maximum messages allowed per period.
  final int messagesLimit;

  /// Number of tokens consumed this period.
  final int tokensUsed;

  /// Maximum tokens allowed per period.
  final int tokensLimit;

  /// Storage used in bytes.
  final int storageUsed;

  /// Storage limit in bytes.
  final int storageLimit;

  /// Message usage as a fraction (0.0 to 1.0).
  double get messagesProgress =>
      messagesLimit > 0 ? (messagesUsed / messagesLimit).clamp(0.0, 1.0) : 0.0;

  /// Token usage as a fraction (0.0 to 1.0).
  double get tokensProgress =>
      tokensLimit > 0 ? (tokensUsed / tokensLimit).clamp(0.0, 1.0) : 0.0;

  /// Storage usage as a fraction (0.0 to 1.0).
  double get storageProgress =>
      storageLimit > 0 ? (storageUsed / storageLimit).clamp(0.0, 1.0) : 0.0;

  /// Whether message usage is at warning level (>= 80%).
  bool get isMessagesWarning => messagesProgress >= 0.8;

  /// Whether message usage is at critical level (>= 95%).
  bool get isMessagesCritical => messagesProgress >= 0.95;

  /// Whether token usage is at warning level (>= 80%).
  bool get isTokensWarning => tokensProgress >= 0.8;

  /// Whether token usage is at critical level (>= 95%).
  bool get isTokensCritical => tokensProgress >= 0.95;

  /// Whether storage usage is at warning level (>= 80%).
  bool get isStorageWarning => storageProgress >= 0.8;

  /// Whether storage usage is at critical level (>= 95%).
  bool get isStorageCritical => storageProgress >= 0.95;

  /// Formatted storage used string (e.g., "1.2 ГБ").
  String get formattedStorageUsed => formatBytes(storageUsed);

  /// Formatted storage limit string (e.g., "10 ГБ").
  String get formattedStorageLimit => formatBytes(storageLimit);

  /// Formats byte count into a human-readable Russian string.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }

  /// Formats a large number with K/M suffix.
  static String formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Usage &&
          other.messagesUsed == messagesUsed &&
          other.tokensUsed == tokensUsed &&
          other.storageUsed == storageUsed);

  @override
  int get hashCode =>
      Object.hash(messagesUsed, tokensUsed, storageUsed);

  @override
  String toString() =>
      'Usage(messages=$messagesUsed/$messagesLimit, '
      'tokens=$tokensUsed/$tokensLimit, '
      'storage=$storageUsed/$storageLimit)';
}

/// Represents a single payment history entry.
class PaymentHistoryItem {
  const PaymentHistoryItem({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.description,
    this.invoiceUrl,
  });

  /// Unique payment identifier.
  final String id;

  /// Amount in smallest currency unit.
  final int amount;

  /// ISO 4217 currency code.
  final String currency;

  /// Payment status.
  final PaymentStatus status;

  /// When the payment was created.
  final DateTime createdAt;

  /// Optional description.
  final String? description;

  /// URL to the invoice/receipt.
  final String? invoiceUrl;

  /// Formatted amount string.
  String get formattedAmount {
    final currencySymbol = switch (currency.toUpperCase()) {
      'RUB' => '\u20BD',
      'USD' => '\$',
      'EUR' => '\u20AC',
      _ => currency,
    };
    final displayAmount = (amount / 100).toStringAsFixed(0);
    return '$displayAmount $currencySymbol';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentHistoryItem && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Status of a payment.
enum PaymentStatus {
  /// Payment succeeded.
  succeeded,

  /// Payment is pending.
  pending,

  /// Payment failed.
  failed,

  /// Payment was refunded.
  refunded;

  /// Parses a [PaymentStatus] from a string.
  static PaymentStatus fromString(String value) =>
      switch (value.toLowerCase()) {
        'succeeded' || 'paid' => PaymentStatus.succeeded,
        'pending' => PaymentStatus.pending,
        'failed' => PaymentStatus.failed,
        'refunded' => PaymentStatus.refunded,
        _ => PaymentStatus.pending,
      };

  /// Russian display label.
  String get displayLabel => switch (this) {
        PaymentStatus.succeeded => 'Оплачено',
        PaymentStatus.pending => 'Ожидание',
        PaymentStatus.failed => 'Ошибка',
        PaymentStatus.refunded => 'Возврат',
      };
}

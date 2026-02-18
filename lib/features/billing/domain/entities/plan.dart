/// Billing plan entity.
///
/// Represents a subscription plan with pricing, limits, and features.
/// Immutable value object used throughout the billing feature.
library;

/// Billing interval for a plan.
enum PlanInterval {
  /// Monthly billing cycle.
  monthly,

  /// Yearly billing cycle (typically discounted).
  yearly;

  /// Parses a [PlanInterval] from a string.
  static PlanInterval fromString(String value) =>
      switch (value.toLowerCase()) {
        'yearly' || 'annual' => PlanInterval.yearly,
        _ => PlanInterval.monthly,
      };

  /// Returns the serialized string.
  String toJson() => name;

  /// Russian display label.
  String get displayLabel => switch (this) {
        PlanInterval.monthly => 'в месяц',
        PlanInterval.yearly => 'в год',
      };
}

/// Plan tier name.
enum PlanName {
  /// Free tier with basic limits.
  free,

  /// Pro tier with expanded limits.
  pro,

  /// Business tier with premium features.
  business,

  /// Enterprise tier with custom limits.
  enterprise;

  /// Parses a [PlanName] from a string.
  static PlanName fromString(String value) => switch (value.toLowerCase()) {
        'pro' => PlanName.pro,
        'business' => PlanName.business,
        'enterprise' => PlanName.enterprise,
        _ => PlanName.free,
      };

  /// Returns the serialized string.
  String toJson() => name;

  /// Russian display name.
  String get displayName => switch (this) {
        PlanName.free => 'Бесплатный',
        PlanName.pro => 'Про',
        PlanName.business => 'Бизнес',
        PlanName.enterprise => 'Корпоративный',
      };
}

/// Resource limits for a plan.
class PlanLimits {
  const PlanLimits({
    required this.messages,
    required this.tokens,
    required this.storage,
    required this.agents,
    required this.skills,
  });

  /// Maximum messages per month.
  final int messages;

  /// Maximum tokens per month.
  final int tokens;

  /// Maximum storage in bytes.
  final int storage;

  /// Maximum custom agents.
  final int agents;

  /// Maximum custom skills.
  final int skills;

  /// Creates a copy with given fields replaced.
  PlanLimits copyWith({
    int? messages,
    int? tokens,
    int? storage,
    int? agents,
    int? skills,
  }) =>
      PlanLimits(
        messages: messages ?? this.messages,
        tokens: tokens ?? this.tokens,
        storage: storage ?? this.storage,
        agents: agents ?? this.agents,
        skills: skills ?? this.skills,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanLimits &&
          other.messages == messages &&
          other.tokens == tokens &&
          other.storage == storage &&
          other.agents == agents &&
          other.skills == skills);

  @override
  int get hashCode => Object.hash(messages, tokens, storage, agents, skills);
}

/// Immutable representation of a billing plan.
class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.displayName,
    required this.price,
    required this.currency,
    required this.interval,
    required this.limits,
    required this.features,
    this.isPopular = false,
  });

  /// Unique plan identifier.
  final String id;

  /// Plan tier name.
  final PlanName name;

  /// Localized display name.
  final String displayName;

  /// Price in the smallest currency unit (e.g., kopecks, cents).
  final int price;

  /// ISO 4217 currency code (e.g., "RUB", "USD").
  final String currency;

  /// Billing interval.
  final PlanInterval interval;

  /// Resource limits for this plan.
  final PlanLimits limits;

  /// List of feature descriptions included in the plan.
  final List<String> features;

  /// Whether this plan is marked as the most popular choice.
  final bool isPopular;

  /// Whether this is the free tier.
  bool get isFree => name == PlanName.free;

  /// Formatted price string for display.
  String get formattedPrice {
    if (price == 0) return 'Бесплатно';
    final currencySymbol = switch (currency.toUpperCase()) {
      'RUB' => '\u20BD',
      'USD' => '\$',
      'EUR' => '\u20AC',
      _ => currency,
    };
    final amount = (price / 100).toStringAsFixed(0);
    return '$amount $currencySymbol ${interval.displayLabel}';
  }

  /// Creates a copy with given fields replaced.
  Plan copyWith({
    String? id,
    PlanName? name,
    String? displayName,
    int? price,
    String? currency,
    PlanInterval? interval,
    PlanLimits? limits,
    List<String>? features,
    bool? isPopular,
  }) =>
      Plan(
        id: id ?? this.id,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        price: price ?? this.price,
        currency: currency ?? this.currency,
        interval: interval ?? this.interval,
        limits: limits ?? this.limits,
        features: features ?? this.features,
        isPopular: isPopular ?? this.isPopular,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Plan && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Plan(id=$id, name=${name.name}, price=$price)';
}

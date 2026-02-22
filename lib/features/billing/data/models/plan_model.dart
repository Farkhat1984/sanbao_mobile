/// Data model for billing plans.
///
/// Handles JSON serialization/deserialization for the Plan entity.
/// Supports both the legacy format (with `limits` and `features` objects)
/// and the backend format (flat fields like `messagesPerDay`, `tokensPerMonth`).
library;

import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';

/// Data transfer model for [Plan].
class PlanModel {
  const PlanModel._({required this.plan});

  /// Parses a [PlanModel] from a JSON map.
  ///
  /// Backend returns flat fields:
  /// `{id, slug, name, price, messagesPerDay, tokensPerMonth, maxAgents,
  ///   canUseAdvancedTools, canUseReasoning, canUseRag, highlighted, ...}`
  factory PlanModel.fromJson(Map<String, Object?> json) {
    // Determine plan name: prefer `slug` (backend), fall back to `name`
    final slug = json['slug'] as String?;
    final nameStr = slug ?? json['name'] as String? ?? 'free';
    final planName = PlanName.fromString(nameStr);

    // Display name: `name` from backend is the display name when `slug` exists
    final displayName = slug != null
        ? (json['name'] as String? ?? planName.displayName)
        : (json['displayName'] as String? ?? planName.displayName);

    // Price: Prisma Decimal comes as String or int
    final priceRaw = json['price'];
    final int price;
    if (priceRaw is int) {
      price = priceRaw;
    } else if (priceRaw is num) {
      price = priceRaw.toInt();
    } else if (priceRaw is String) {
      price = int.tryParse(priceRaw) ?? 0;
    } else {
      price = 0;
    }

    // Limits: support both nested `limits` object and flat backend fields
    final limitsJson = json['limits'] as Map<String, Object?>?;
    final PlanLimits limits;
    if (limitsJson != null) {
      limits = PlanLimits(
        messages: limitsJson['messages'] as int? ?? 0,
        tokens: limitsJson['tokens'] as int? ?? 0,
        storage: limitsJson['storage'] as int? ?? 0,
        agents: limitsJson['agents'] as int? ?? 0,
        skills: limitsJson['skills'] as int? ?? 0,
      );
    } else {
      limits = PlanLimits(
        messages: (json['messagesPerDay'] as num?)?.toInt() ?? 0,
        tokens: (json['tokensPerMonth'] as num?)?.toInt() ?? 0,
        storage: 0,
        agents: (json['maxAgents'] as num?)?.toInt() ?? 0,
        skills: 0,
      );
    }

    // Features: support both explicit list and derive from boolean capabilities
    final featuresJson = json['features'] as List<Object?>?;
    final List<String> features;
    if (featuresJson != null) {
      features = featuresJson.whereType<String>().toList();
    } else {
      features = _deriveFeaturesFromCapabilities(json);
    }

    return PlanModel._(
      plan: Plan(
        id: json['id'] as String? ?? '',
        name: planName,
        displayName: displayName,
        price: price,
        currency: json['currency'] as String? ?? 'KZT',
        interval:
            PlanInterval.fromString(json['interval'] as String? ?? 'monthly'),
        limits: limits,
        features: features,
        isPopular: json['isPopular'] as bool? ??
            json['highlighted'] as bool? ??
            false,
      ),
    );
  }

  /// The deserialized plan entity.
  final Plan plan;

  /// Converts a list of JSON objects to a list of [Plan] entities.
  static List<Plan> fromJsonList(List<Object?> jsonList) => jsonList
      .whereType<Map<String, Object?>>()
      .map((json) => PlanModel.fromJson(json).plan)
      .toList();

  /// Serializes to JSON map.
  Map<String, Object?> toJson() => {
        'id': plan.id,
        'name': plan.name.toJson(),
        'displayName': plan.displayName,
        'price': plan.price,
        'currency': plan.currency,
        'interval': plan.interval.toJson(),
        'limits': {
          'messages': plan.limits.messages,
          'tokens': plan.limits.tokens,
          'storage': plan.limits.storage,
          'agents': plan.limits.agents,
          'skills': plan.limits.skills,
        },
        'features': plan.features,
        'isPopular': plan.isPopular,
      };

  /// Derives a feature list from boolean capability fields returned by backend.
  static List<String> _deriveFeaturesFromCapabilities(
    Map<String, Object?> json,
  ) {
    final features = <String>[];
    if (json['canUseAdvancedTools'] == true) {
      features.add('Продвинутые инструменты');
    }
    if (json['canUseReasoning'] == true) {
      features.add('Режим размышления');
    }
    if (json['canUseRag'] == true) {
      features.add('RAG (база знаний)');
    }
    if (json['canUseGraph'] == true) {
      features.add('Графовый анализ');
    }
    if (json['canChooseProvider'] == true) {
      features.add('Выбор AI-провайдера');
    }
    final docsPerMonth = (json['documentsPerMonth'] as num?)?.toInt() ?? 0;
    if (docsPerMonth > 0) {
      features.add('$docsPerMonth документов/мес');
    }
    return features;
  }
}

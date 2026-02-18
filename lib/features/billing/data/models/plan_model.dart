/// Data model for billing plans.
///
/// Handles JSON serialization/deserialization for the Plan entity.
library;

import 'package:sanbao_flutter/features/billing/domain/entities/plan.dart';

/// Data transfer model for [Plan].
class PlanModel {
  const PlanModel._({required this.plan});

  /// Parses a [PlanModel] from a JSON map.
  factory PlanModel.fromJson(Map<String, Object?> json) {
    final limitsJson = json['limits'] as Map<String, Object?>? ?? {};
    final featuresJson = json['features'] as List<Object?>? ?? [];

    return PlanModel._(
      plan: Plan(
        id: json['id'] as String? ?? '',
        name: PlanName.fromString(json['name'] as String? ?? 'free'),
        displayName: json['displayName'] as String? ??
            PlanName.fromString(json['name'] as String? ?? 'free').displayName,
        price: json['price'] as int? ?? 0,
        currency: json['currency'] as String? ?? 'RUB',
        interval:
            PlanInterval.fromString(json['interval'] as String? ?? 'monthly'),
        limits: PlanLimits(
          messages: limitsJson['messages'] as int? ?? 0,
          tokens: limitsJson['tokens'] as int? ?? 0,
          storage: limitsJson['storage'] as int? ?? 0,
          agents: limitsJson['agents'] as int? ?? 0,
          skills: limitsJson['skills'] as int? ?? 0,
        ),
        features: featuresJson
            .whereType<String>()
            .toList(),
        isPopular: json['isPopular'] as bool? ?? false,
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
}

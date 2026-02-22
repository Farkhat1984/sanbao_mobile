/// User data model with JSON serialization.
///
/// Maps between the API response JSON and the domain [User] entity.
library;

import 'package:sanbao_flutter/features/auth/domain/entities/user.dart';

/// Data transfer object for the User API responses.
///
/// Handles JSON parsing and serialization with null safety.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.image,
    this.role = UserRole.user,
    this.locale = 'ru',
    this.emailVerified = false,
    this.twoFactorEnabled = false,
    this.subscriptionTier = SubscriptionTier.free,
    this.isBanned = false,
    this.createdAt,
  });

  /// Creates a [UserModel] from a domain [User] entity.
  factory UserModel.fromEntity(User user) => UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        image: user.image,
        role: user.role,
        locale: user.locale,
        emailVerified: user.emailVerified,
        twoFactorEnabled: user.twoFactorEnabled,
        subscriptionTier: user.subscriptionTier,
        isBanned: user.isBanned,
        createdAt: user.createdAt,
      );

  /// Parses a [UserModel] from a JSON map.
  ///
  /// Handles multiple API response shapes (e.g., NextAuth session
  /// vs. direct user endpoint).
  factory UserModel.fromJson(Map<String, Object?> json) {
    // Parse emailVerified - can be bool or ISO date string
    final emailVerifiedRaw = json['emailVerified'];
    final bool emailVerified;
    if (emailVerifiedRaw is bool) {
      emailVerified = emailVerifiedRaw;
    } else if (emailVerifiedRaw is String && emailVerifiedRaw.isNotEmpty) {
      emailVerified = true;
    } else {
      emailVerified = false;
    }

    // Parse subscription tier from nested subscription object
    final subscriptionRaw = json['subscription'];
    var subscriptionTier = SubscriptionTier.free;
    if (subscriptionRaw is Map<String, Object?>) {
      final plan = subscriptionRaw['plan'];
      if (plan is Map<String, Object?>) {
        final slug = plan['slug'] as String?;
        if (slug != null) {
          subscriptionTier = SubscriptionTier.fromString(slug);
        }
      }
    } else if (json['subscriptionTier'] is String) {
      subscriptionTier =
          SubscriptionTier.fromString(json['subscriptionTier']! as String);
    }

    return UserModel(
      id: json['id']! as String,
      name: json['name'] as String?,
      email: json['email']! as String,
      image: json['image'] as String?,
      role: UserRole.fromString(
        (json['role'] as String?) ?? 'USER',
      ),
      locale: (json['locale'] as String?) ?? 'ru',
      emailVerified: emailVerified,
      twoFactorEnabled: (json['twoFactorEnabled'] as bool?) ?? false,
      subscriptionTier: subscriptionTier,
      isBanned: (json['isBanned'] as bool?) ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']! as String)
          : null,
    );
  }

  /// Unique user identifier.
  final String id;

  /// User display name.
  final String? name;

  /// Email address.
  final String email;

  /// Avatar image URL.
  final String? image;

  /// User role.
  final UserRole role;

  /// Preferred locale.
  final String locale;

  /// Whether email is verified.
  final bool emailVerified;

  /// Whether 2FA is enabled.
  final bool twoFactorEnabled;

  /// Subscription tier.
  final SubscriptionTier subscriptionTier;

  /// Whether the account is banned.
  final bool isBanned;

  /// Account creation timestamp.
  final DateTime? createdAt;

  /// Converts this model to a JSON map for API requests.
  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'image': image,
        'role': role.toJson(),
        'locale': locale,
        'emailVerified': emailVerified,
        'twoFactorEnabled': twoFactorEnabled,
        'subscriptionTier': subscriptionTier.toJson(),
        'isBanned': isBanned,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  /// Converts this data model to a domain [User] entity.
  User toEntity() => User(
        id: id,
        name: name,
        email: email,
        image: image,
        role: role,
        locale: locale,
        emailVerified: emailVerified,
        twoFactorEnabled: twoFactorEnabled,
        subscriptionTier: subscriptionTier,
        isBanned: isBanned,
        createdAt: createdAt,
      );
}

/// User domain entity.
///
/// Represents the authenticated user's profile. Immutable value object
/// with all fields from the Prisma User model that the mobile app needs.
library;

/// The role assigned to a user in the system.
enum UserRole {
  /// Standard user with default permissions.
  user,

  /// Pro subscriber with advanced features.
  pro,

  /// Administrator with full system access.
  admin;

  /// Parses a [UserRole] from a string (case-insensitive).
  static UserRole fromString(String value) => switch (value.toUpperCase()) {
        'ADMIN' => UserRole.admin,
        'PRO' => UserRole.pro,
        _ => UserRole.user,
      };

  /// Returns the serialized string representation.
  String toJson() => name.toUpperCase();
}

/// Subscription tier for billing/feature gating.
enum SubscriptionTier {
  /// Free plan with basic limits.
  free,

  /// Pro plan with expanded limits.
  pro,

  /// Business plan with full access.
  business;

  /// Parses a [SubscriptionTier] from a string (case-insensitive).
  static SubscriptionTier fromString(String value) =>
      switch (value.toLowerCase()) {
        'pro' => SubscriptionTier.pro,
        'business' => SubscriptionTier.business,
        _ => SubscriptionTier.free,
      };

  /// Returns the serialized string representation.
  String toJson() => name;
}

/// Immutable representation of an authenticated user.
///
/// Contains all profile fields needed by the mobile client.
/// Created from [UserModel.toEntity()] in the data layer.
class User {
  const User({
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

  /// Unique user identifier (CUID).
  final String id;

  /// User's display name.
  final String? name;

  /// Email address (always lowercase, trimmed).
  final String email;

  /// Avatar image URL (may be null for credential-based users).
  final String? image;

  /// User role for permission checks.
  final UserRole role;

  /// Preferred locale (e.g., "ru", "en").
  final String locale;

  /// Whether the user's email address has been verified.
  final bool emailVerified;

  /// Whether two-factor authentication is enabled.
  final bool twoFactorEnabled;

  /// The user's current subscription tier.
  final SubscriptionTier subscriptionTier;

  /// Whether the user account is banned.
  final bool isBanned;

  /// Account creation timestamp.
  final DateTime? createdAt;

  /// Display name with a fallback to the email prefix.
  String get displayName => name ?? email.split('@').first;

  /// Initials derived from the display name (up to 2 characters).
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Whether the user has admin privileges.
  bool get isAdmin => role == UserRole.admin;

  /// Whether the user has a pro or higher subscription.
  bool get isPro =>
      subscriptionTier == SubscriptionTier.pro ||
      subscriptionTier == SubscriptionTier.business;

  /// Creates a copy of this user with the given fields replaced.
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? image,
    UserRole? role,
    String? locale,
    bool? emailVerified,
    bool? twoFactorEnabled,
    SubscriptionTier? subscriptionTier,
    bool? isBanned,
    DateTime? createdAt,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        image: image ?? this.image,
        role: role ?? this.role,
        locale: locale ?? this.locale,
        emailVerified: emailVerified ?? this.emailVerified,
        twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
        subscriptionTier: subscriptionTier ?? this.subscriptionTier,
        isBanned: isBanned ?? this.isBanned,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id=$id, email=$email, role=$role)';
}

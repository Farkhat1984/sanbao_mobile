/// Local database interface for offline caching.
///
/// Provides a file-based cache abstraction on native platforms
/// and an in-memory fallback on web.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_db_native.dart' if (dart.library.html) 'local_db_web.dart'
    as impl;

/// Entry in the local cache with expiration support.
class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Creates a [CacheEntry] from a decoded JSON map.
  factory CacheEntry.fromJson(Map<String, Object?> json) => CacheEntry(
        key: json['key']! as String,
        data: json['data']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
        expiresAt: DateTime.parse(json['expiresAt']! as String),
      );

  final String key;
  final String data;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, Object?> toJson() => {
        'key': key,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };
}

/// Abstract local cache interface.
abstract class LocalDatabase {
  factory LocalDatabase() = impl.LocalDatabaseImpl;

  Future<void> initialize();

  Future<void> put({
    required String namespace,
    required String key,
    required Object data,
    Duration ttl = const Duration(hours: 1),
  });

  Future<T?> get<T>({
    required String namespace,
    required String key,
    T Function(Object? json)? fromJson,
  });

  Future<void> delete({
    required String namespace,
    required String key,
  });

  Future<void> clearNamespace(String namespace);
  Future<void> clearAll();
  Future<void> pruneExpired(String namespace);
}

/// Riverpod provider for [LocalDatabase].
final localDatabaseProvider = Provider<LocalDatabase>((ref) => LocalDatabase());

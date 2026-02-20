/// Web implementation of [LocalDatabase].
///
/// Uses an in-memory map since dart:io is not available on web.
library;

import 'dart:convert';

import 'local_db.dart';

class LocalDatabaseImpl implements LocalDatabase {
  LocalDatabaseImpl();

  final Map<String, Map<String, Object?>> _store = {};

  @override
  Future<void> initialize() async {
    // No-op on web — in-memory storage is ready immediately.
  }

  @override
  Future<void> put({
    required String namespace,
    required String key,
    required Object data,
    Duration ttl = const Duration(hours: 1),
  }) async {
    final ns = _store.putIfAbsent(namespace, () => {});
    final now = DateTime.now();
    final entry = CacheEntry(
      key: key,
      data: jsonEncode(data),
      createdAt: now,
      expiresAt: now.add(ttl),
    );
    ns[key] = entry.toJson();
  }

  @override
  Future<T?> get<T>({
    required String namespace,
    required String key,
    T Function(Object? json)? fromJson,
  }) async {
    final ns = _store[namespace];
    if (ns == null) return null;

    final entryJson = ns[key] as Map<String, Object?>?;
    if (entryJson == null) return null;

    final entry = CacheEntry.fromJson(entryJson);
    if (entry.isExpired) {
      await delete(namespace: namespace, key: key);
      return null;
    }

    final decoded = jsonDecode(entry.data);
    if (fromJson != null) return fromJson(decoded);
    return decoded as T?;
  }

  @override
  Future<void> delete({
    required String namespace,
    required String key,
  }) async {
    _store[namespace]?.remove(key);
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    _store.remove(namespace);
  }

  @override
  Future<void> clearAll() async {
    _store.clear();
  }

  @override
  Future<void> pruneExpired(String namespace) async {
    final ns = _store[namespace];
    if (ns == null) return;

    final now = DateTime.now();
    ns.removeWhere((key, value) {
      if (value is! Map<String, Object?>) return true;
      try {
        final entry = CacheEntry.fromJson(value);
        return now.isAfter(entry.expiresAt);
      } on Object {
        return true;
      }
    });
  }
}

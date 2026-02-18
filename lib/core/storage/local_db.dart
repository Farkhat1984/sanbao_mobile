/// Local database interface for offline caching.
///
/// Provides a file-based cache abstraction. The implementation uses
/// JSON files stored in the app's documents directory. This can be
/// replaced with a proper database (Hive, Drift, etc.) when needed.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

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

/// File-based local cache for offline data persistence.
///
/// Each cache namespace gets its own JSON file. Entries support
/// TTL-based expiration.
class LocalDatabase {
  LocalDatabase();

  Directory? _cacheDir;

  /// Initializes the cache directory.
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/sanbao_cache');
    if (!_cacheDir!.existsSync()) {
      _cacheDir!.createSync(recursive: true);
    }
  }

  /// Returns the cache directory, initializing if needed.
  Future<Directory> get _dir async {
    if (_cacheDir == null) await initialize();
    return _cacheDir!;
  }

  /// Stores a JSON-serializable value with a TTL.
  Future<void> put({
    required String namespace,
    required String key,
    required Object data,
    Duration ttl = const Duration(hours: 1),
  }) async {
    final dir = await _dir;
    final file = File('${dir.path}/$namespace.json');

    Map<String, Object?> store = {};
    if (file.existsSync()) {
      try {
        final content = await file.readAsString();
        store = (jsonDecode(content) as Map<String, Object?>?) ?? {};
      } on FormatException {
        store = {};
      }
    }

    final now = DateTime.now();
    final entry = CacheEntry(
      key: key,
      data: jsonEncode(data),
      createdAt: now,
      expiresAt: now.add(ttl),
    );

    store[key] = entry.toJson();
    await file.writeAsString(jsonEncode(store));
  }

  /// Retrieves a cached value, returning `null` if missing or expired.
  Future<T?> get<T>({
    required String namespace,
    required String key,
    T Function(Object? json)? fromJson,
  }) async {
    final dir = await _dir;
    final file = File('${dir.path}/$namespace.json');

    if (!file.existsSync()) return null;

    try {
      final content = await file.readAsString();
      final store = jsonDecode(content) as Map<String, Object?>?;
      if (store == null) return null;

      final entryJson = store[key] as Map<String, Object?>?;
      if (entryJson == null) return null;

      final entry = CacheEntry.fromJson(entryJson);
      if (entry.isExpired) {
        await delete(namespace: namespace, key: key);
        return null;
      }

      final decoded = jsonDecode(entry.data);
      if (fromJson != null) {
        return fromJson(decoded);
      }
      return decoded as T?;
    } on FormatException {
      return null;
    }
  }

  /// Removes a specific cache entry.
  Future<void> delete({
    required String namespace,
    required String key,
  }) async {
    final dir = await _dir;
    final file = File('${dir.path}/$namespace.json');

    if (!file.existsSync()) return;

    try {
      final content = await file.readAsString();
      final store =
          (jsonDecode(content) as Map<String, Object?>?) ?? {};
      store.remove(key);
      await file.writeAsString(jsonEncode(store));
    } on FormatException {
      // Corrupted file, delete it
      await file.delete();
    }
  }

  /// Clears all entries in a namespace.
  Future<void> clearNamespace(String namespace) async {
    final dir = await _dir;
    final file = File('${dir.path}/$namespace.json');
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Clears all cached data.
  Future<void> clearAll() async {
    final dir = await _dir;
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }

  /// Removes all expired entries from a namespace.
  Future<void> pruneExpired(String namespace) async {
    final dir = await _dir;
    final file = File('${dir.path}/$namespace.json');

    if (!file.existsSync()) return;

    try {
      final content = await file.readAsString();
      final store =
          (jsonDecode(content) as Map<String, Object?>?) ?? {};

      final now = DateTime.now();
      store.removeWhere((key, value) {
        if (value is! Map<String, Object?>) return true;
        try {
          final entry = CacheEntry.fromJson(value);
          return now.isAfter(entry.expiresAt);
        } on Object {
          return true;
        }
      });

      await file.writeAsString(jsonEncode(store));
    } on FormatException {
      await file.delete();
    }
  }
}

/// Riverpod provider for [LocalDatabase].
final localDatabaseProvider = Provider<LocalDatabase>((ref) => LocalDatabase());

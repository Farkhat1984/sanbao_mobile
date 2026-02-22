/// Native (iOS/Android/desktop) implementation of [LocalDatabase].
///
/// Uses dart:io File/Directory + path_provider for file-based caching.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'local_db.dart';

class LocalDatabaseImpl implements LocalDatabase {
  LocalDatabaseImpl();

  Directory? _cacheDir;

  @override
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/sanbao_cache');
    if (!_cacheDir!.existsSync()) {
      _cacheDir!.createSync(recursive: true);
    }
  }

  Future<Directory> get _dir async {
    if (_cacheDir == null) await initialize();
    return _cacheDir!;
  }

  @override
  Future<void> put({
    required String namespace,
    required String key,
    required Object data,
    Duration ttl = const Duration(hours: 1),
  }) async {
    final dir = await _dir;
    final file = File('${dir.path}/$namespace.json');

    var store = <String, Object?>{};
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

  @override
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

  @override
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
          (jsonDecode(content) as Map<String, Object?>?) ?? {}
            ..remove(key);
      await file.writeAsString(jsonEncode(store));
    } on FormatException {
      await file.delete();
    }
  }

  @override
  Future<void> clearNamespace(String namespace) async {
    final dir = await _dir;
    final file = File('${dir.path}/$namespace.json');
    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Future<void> clearAll() async {
    final dir = await _dir;
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }

  @override
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

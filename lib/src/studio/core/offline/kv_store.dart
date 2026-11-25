import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Small persistent string store for what the Studio keeps on the device: the
/// shoots downloaded for On set, their outbox of ticks and notes, and the
/// upload queue. One implementation over Hive (IndexedDB on web, a file on
/// Android) and one in memory for tests.
///
/// Limits: values are strings (JSON). Web storage is the browser's: it can be
/// cleared by the person or evicted by the browser under storage pressure.
abstract class KvStore {
  Future<String?> get(String key);
  Future<void> put(String key, String value);
  Future<void> delete(String key);

  /// Keys starting with [prefix].
  Future<List<String>> keys(String prefix);
}

class MemoryKvStore implements KvStore {
  MemoryKvStore([Map<String, String>? seed]) : data = {...?seed};

  /// Public so a test can "restart the app" by handing the same map to a new
  /// store.
  final Map<String, String> data;

  @override
  Future<String?> get(String key) async => data[key];
  @override
  Future<void> put(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
  @override
  Future<List<String>> keys(String prefix) async => [
    for (final k in data.keys)
      if (k.startsWith(prefix)) k,
  ];
}

class HiveKvStore implements KvStore {
  static const _boxName = 'studio_offline_v1';
  static Future<Box<String>>? _opening;

  Future<Box<String>> get _box => _opening ??= () async {
    await Hive.initFlutter();
    return Hive.openBox<String>(_boxName);
  }();

  @override
  Future<String?> get(String key) async => (await _box).get(key);
  @override
  Future<void> put(String key, String value) async =>
      (await _box).put(key, value);
  @override
  Future<void> delete(String key) async => (await _box).delete(key);
  @override
  Future<List<String>> keys(String prefix) async => [
    for (final k in (await _box).keys)
      if (k is String && k.startsWith(prefix)) k,
  ];
}

final studioKvStoreProvider = Provider<KvStore>((ref) => HiveKvStore());

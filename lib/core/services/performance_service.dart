import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class PerformanceService extends GetxService {
  static PerformanceService get instance => Get.find<PerformanceService>();

  final GetStorage _storage = GetStorage();
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadCacheFromStorage();
  }

  /// Cache data with automatic expiration
  void cacheData(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    _saveCacheToStorage();
  }

  /// Get cached data if not expired
  T? getCachedData<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      _saveCacheToStorage();
      return null;
    }

    return _cache[key] as T?;
  }

  /// Check if data is cached and not expired
  bool isDataCached(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;

    if (DateTime.now().difference(timestamp) > _cacheDuration) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      _saveCacheToStorage();
      return false;
    }

    return true;
  }

  /// Clear all cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _saveCacheToStorage();
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheDuration) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _saveCacheToStorage();
    }
  }

  /// Save cache to persistent storage
  void _saveCacheToStorage() {
    try {
      _storage.write('performance_cache', _cache);
      _storage.write(
        'performance_cache_timestamps',
        _cacheTimestamps.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch)),
      );
    } catch (e) {
      debugPrint('Error saving cache: $e');
    }
  }

  /// Load cache from persistent storage
  Future<void> _loadCacheFromStorage() async {
    try {
      final cachedData =
          _storage.read('performance_cache') as Map<String, dynamic>?;
      final cachedTimestamps =
          _storage.read('performance_cache_timestamps')
              as Map<String, dynamic>?;

      if (cachedData != null) {
        _cache.addAll(cachedData);
      }

      if (cachedTimestamps != null) {
        _cacheTimestamps.addAll(
          cachedTimestamps.map(
            (k, v) =>
                MapEntry(k, DateTime.fromMillisecondsSinceEpoch(v as int)),
          ),
        );
      }

      // Clear expired entries on startup
      clearExpiredCache();
    } catch (e) {
      debugPrint('Error loading cache: $e');
    }
  }

  /// Debounce function calls
  Timer? _debounceTimer;
  void debounce(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle function calls
  final Map<String, DateTime> _throttleTimestamps = {};
  bool throttle(
    String key,
    VoidCallback callback, {
    Duration delay = const Duration(seconds: 1),
  }) {
    final now = DateTime.now();
    final lastCall = _throttleTimestamps[key];

    if (lastCall == null || now.difference(lastCall) > delay) {
      _throttleTimestamps[key] = now;
      callback();
      return true;
    }

    return false;
  }
}

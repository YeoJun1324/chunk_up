import 'dart:async';
import 'dart:convert';
import 'package:chunk_up/data/services/storage/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/data/services/disposable_service.dart';
import 'package:flutter/foundation.dart';

/// Enhanced cache service with memory limits and lifecycle management
class CacheService extends DisposableService {
  static const String _cacheKeyPrefix = 'cache_';
  static const String _cacheTTLSuffix = '_ttl';
  static const int defaultTTL = 24 * 60 * 60 * 1000; // 24 hours
  
  // Memory limits
  static const int maxMemoryCacheItems = 100;
  static const int maxMemoryCacheSizeBytes = 50 * 1024 * 1024; // 50MB
  
  final StorageService _storageService;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, int> _memoryCacheTTL = {};
  final Map<String, int> _lastAccessTime = {};
  final Map<String, int> _itemSizes = {};
  
  int _currentCacheSizeBytes = 0;
  Timer? _cleanupTimer;
  bool _isCleanupRunning = false;

  CacheService({StorageService? storageService}) 
    : _storageService = storageService ?? LocalStorageService();

  String _createCacheKey(String key) => '$_cacheKeyPrefix$key';
  String _createTTLKey(String key) => '${_createCacheKey(key)}$_cacheTTLSuffix';

  /// Estimate size of an object in bytes
  int _estimateSize(dynamic value) {
    try {
      final encoded = jsonEncode(value);
      return encoded.length * 2; // Approximate UTF-16 size
    } catch (e) {
      return 1024; // Default 1KB for non-serializable objects
    }
  }

  /// Enforce memory limits using LRU eviction
  void _enforceMemoryLimits() {
    // Check item count limit
    while (_memoryCache.length >= maxMemoryCacheItems) {
      _evictLeastRecentlyUsed();
    }

    // Check size limit
    while (_currentCacheSizeBytes > maxMemoryCacheSizeBytes && _memoryCache.isNotEmpty) {
      _evictLeastRecentlyUsed();
    }
  }

  /// Evict least recently used item
  void _evictLeastRecentlyUsed() {
    if (_lastAccessTime.isEmpty) return;

    final oldestEntry = _lastAccessTime.entries
        .reduce((a, b) => a.value < b.value ? a : b);
    
    final oldestKey = oldestEntry.key;
    
    // Update size tracking
    final itemSize = _itemSizes[oldestKey] ?? 0;
    _currentCacheSizeBytes -= itemSize;
    
    // Remove from all maps
    _memoryCache.remove(oldestKey);
    _memoryCacheTTL.remove(oldestKey);
    _lastAccessTime.remove(oldestKey);
    _itemSizes.remove(oldestKey);
  }

  /// Check if item exists and is not expired
  Future<bool> has(String key) async {
    checkDisposed();
    
    final cacheKey = _createCacheKey(key);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      final expiryTime = _memoryCacheTTL[cacheKey] ?? 0;
      if (expiryTime > now) {
        _lastAccessTime[cacheKey] = now;
        return true;
      } else {
        _removeFromMemory(cacheKey);
      }
    }

    // Check persistent storage
    final ttlStr = await _storageService.getString(_createTTLKey(key));
    if (ttlStr != null) {
      final ttl = int.tryParse(ttlStr) ?? 0;
      if (ttl > now) {
        return true;
      } else {
        await _removeFromStorage(key);
      }
    }

    return false;
  }

  /// Get item from cache
  Future<T?> get<T>(String key) async {
    checkDisposed();
    
    final cacheKey = _createCacheKey(key);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      final expiryTime = _memoryCacheTTL[cacheKey] ?? 0;
      
      if (expiryTime > now) {
        _lastAccessTime[cacheKey] = now;
        try {
          return _memoryCache[cacheKey] as T?;
        } catch (e) {
          return null;
        }
      } else {
        _removeFromMemory(cacheKey);
      }
    }

    // Check persistent storage
    final data = await _storageService.getString(cacheKey);
    if (data != null) {
      final ttlStr = await _storageService.getString(_createTTLKey(key));
      if (ttlStr != null) {
        final ttl = int.tryParse(ttlStr) ?? 0;
        
        if (ttl > now) {
          try {
            final decoded = jsonDecode(data);
            
            // Add to memory cache
            await _addToMemory(cacheKey, decoded, ttl, now);
            
            return decoded as T?;
          } catch (e) {
            return null;
          }
        } else {
          await _removeFromStorage(key);
        }
      }
    }

    return null;
  }

  /// Set item in cache
  Future<void> set<T>(String key, T value, {Duration? duration}) async {
    checkDisposed();
    
    final cacheKey = _createCacheKey(key);
    final ttlKey = _createTTLKey(key);
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final ttlMs = duration?.inMilliseconds ?? defaultTTL;
    final expiryTime = now + ttlMs;

    // Add to memory cache
    await _addToMemory(cacheKey, value, expiryTime, now);

    // Persist to storage
    try {
      final encoded = jsonEncode(value);
      await _storageService.setString(cacheKey, encoded);
      await _storageService.setString(ttlKey, expiryTime.toString());
    } catch (e) {
      // Ignore serialization errors for storage
    }
  }

  /// Add item to memory cache with size tracking
  Future<void> _addToMemory(String cacheKey, dynamic value, int expiryTime, int now) async {
    // Calculate size
    final itemSize = _estimateSize(value);
    
    // Remove old value if exists
    if (_memoryCache.containsKey(cacheKey)) {
      _currentCacheSizeBytes -= _itemSizes[cacheKey] ?? 0;
    }
    
    // Enforce limits before adding
    _enforceMemoryLimits();
    
    // Add to cache
    _memoryCache[cacheKey] = value;
    _memoryCacheTTL[cacheKey] = expiryTime;
    _lastAccessTime[cacheKey] = now;
    _itemSizes[cacheKey] = itemSize;
    _currentCacheSizeBytes += itemSize;
  }

  /// Remove item from memory cache
  void _removeFromMemory(String cacheKey) {
    _currentCacheSizeBytes -= _itemSizes[cacheKey] ?? 0;
    _memoryCache.remove(cacheKey);
    _memoryCacheTTL.remove(cacheKey);
    _lastAccessTime.remove(cacheKey);
    _itemSizes.remove(cacheKey);
  }

  /// Remove item from persistent storage
  Future<void> _removeFromStorage(String key) async {
    final cacheKey = _createCacheKey(key);
    final ttlKey = _createTTLKey(key);
    await _storageService.remove(cacheKey);
    await _storageService.remove(ttlKey);
  }

  /// Remove specific item
  Future<void> remove(String key) async {
    checkDisposed();
    
    final cacheKey = _createCacheKey(key);
    _removeFromMemory(cacheKey);
    await _removeFromStorage(key);
  }

  /// Clear all cache
  Future<void> clear() async {
    checkDisposed();
    
    _memoryCache.clear();
    _memoryCacheTTL.clear();
    _lastAccessTime.clear();
    _itemSizes.clear();
    _currentCacheSizeBytes = 0;

    // Clear all cache-related keys from storage
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('cache_')) {
        await prefs.remove(key);
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    checkDisposed();
    
    return {
      'itemCount': _memoryCache.length,
      'sizeBytes': _currentCacheSizeBytes,
      'sizeMB': (_currentCacheSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'maxItems': maxMemoryCacheItems,
      'maxSizeMB': (maxMemoryCacheSizeBytes / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  /// Clean expired items from cache
  Future<void> cleanExpired() async {
    if (_isCleanupRunning) {
      debugPrint('Cache cleanup already in progress, skipping...');
      return;
    }

    _isCleanupRunning = true;
    try {
      checkDisposed();
      
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Clean memory cache
      final expiredKeys = <String>[];
      _memoryCacheTTL.forEach((key, ttl) {
        if (ttl < now) {
          expiredKeys.add(key);
        }
      });
      
      for (final key in expiredKeys) {
        _removeFromMemory(key);
      }
      
      // Clean persistent cache
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final keysToRemove = <String>[];
      
      for (final key in allKeys) {
        if (key.startsWith(_cacheKeyPrefix) && key.endsWith(_cacheTTLSuffix)) {
          final ttlString = prefs.getString(key);
          if (ttlString != null) {
            final ttl = int.tryParse(ttlString) ?? 0;
            if (ttl < now) {
              keysToRemove.add(key);
              final cacheKey = key.replaceAll(_cacheTTLSuffix, '');
              keysToRemove.add(cacheKey);
            }
          }
        }
      }
      
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      
      debugPrint('Cache cleanup completed: removed ${expiredKeys.length} memory items and ${keysToRemove.length ~/ 2} persistent items');
    } catch (e) {
      debugPrint('Error during cache cleanup: $e');
    } finally {
      _isCleanupRunning = false;
    }
  }

  /// Start periodic cleanup
  void startPeriodicCleanup({Duration interval = const Duration(hours: 1)}) {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(interval, (_) async {
      if (!_isCleanupRunning) {
        await cleanExpired();
      }
    });
  }

  /// Stop periodic cleanup
  void stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  @override
  Future<void> onDispose() async {
    // Stop cleanup timer
    stopPeriodicCleanup();
    
    // Clear memory cache but keep persistent cache
    _memoryCache.clear();
    _memoryCacheTTL.clear();
    _lastAccessTime.clear();
    _itemSizes.clear();
    _currentCacheSizeBytes = 0;
  }
}
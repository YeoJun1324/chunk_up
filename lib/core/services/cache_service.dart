// lib/core/services/cache_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:chunk_up/data/services/storage/local_storage_service.dart';

/// 앱 전반에서 사용되는 캐싱 서비스
/// 
/// API 응답 및 기타 데이터에 대한 캐싱을 제공합니다.
class CacheService {
  // 캐시 키 관련 상수
  static const String _cacheKeyPrefix = 'cache_';
  static const String _cacheTTLSuffix = '_ttl';
  
  // 기본 캐시 만료 시간 (밀리초)
  static const int defaultTTL = 24 * 60 * 60 * 1000; // 24시간
  
  final StorageService _storageService;
  
  // 메모리 캐시 (앱 실행 중에만 유효)
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, int> _memoryCacheTTL = {};
  
  CacheService({StorageService? storageService}) 
    : _storageService = storageService ?? LocalStorageService();
  
  /// 캐시 키 생성 헬퍼 메서드
  String _createCacheKey(String key) => '$_cacheKeyPrefix$key';
  
  /// TTL(Time-To-Live) 키 생성 헬퍼 메서드
  String _createTTLKey(String key) => '${_createCacheKey(key)}$_cacheTTLSuffix';
  
  /// 항목이 캐시에 있는지 확인
  Future<bool> has(String key) async {
    final cacheKey = _createCacheKey(key);
    
    // 1. 메모리 캐시 확인
    if (_memoryCache.containsKey(cacheKey)) {
      final expiryTime = _memoryCacheTTL[cacheKey] ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // 만료되지 않았으면 true 반환
      if (expiryTime > now) {
        return true;
      } else {
        // 만료된 항목 제거
        _memoryCache.remove(cacheKey);
        _memoryCacheTTL.remove(cacheKey);
      }
    }
    
    // 2. 영구 저장소 확인
    final data = await _storageService.getString(cacheKey);
    if (data != null) {
      final ttlStr = await _storageService.getString(_createTTLKey(key));
      if (ttlStr != null) {
        final ttl = int.tryParse(ttlStr) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // 만료되지 않았으면 true 반환
        if (ttl > now) {
          return true;
        } else {
          // 만료된 항목 제거
          await _storageService.remove(cacheKey);
          await _storageService.remove(_createTTLKey(key));
        }
      }
    }
    
    return false;
  }
  
  /// 캐시에서 항목 가져오기
  Future<T?> get<T>(String key) async {
    final cacheKey = _createCacheKey(key);
    
    // 1. 메모리 캐시 확인
    if (_memoryCache.containsKey(cacheKey)) {
      final expiryTime = _memoryCacheTTL[cacheKey] ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (expiryTime > now) {
        try {
          return _memoryCache[cacheKey] as T?;
        } catch (e) {
          debugPrint('캐시 형변환 오류: $e');
          return null;
        }
      } else {
        // 만료된 항목 제거
        _memoryCache.remove(cacheKey);
        _memoryCacheTTL.remove(cacheKey);
      }
    }
    
    // 2. 영구 저장소 확인
    final data = await _storageService.getString(cacheKey);
    if (data != null) {
      final ttlStr = await _storageService.getString(_createTTLKey(key));
      if (ttlStr != null) {
        final ttl = int.tryParse(ttlStr) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        if (ttl > now) {
          try {
            // JSON 데이터를 파싱하고 메모리 캐시에도 저장
            final decoded = jsonDecode(data);
            _memoryCache[cacheKey] = decoded;
            _memoryCacheTTL[cacheKey] = ttl;
            
            return decoded as T?;
          } catch (e) {
            debugPrint('캐시 디코딩 오류: $e');
            return null;
          }
        } else {
          // 만료된 항목 제거
          await _storageService.remove(cacheKey);
          await _storageService.remove(_createTTLKey(key));
        }
      }
    }
    
    return null;
  }
  
  /// 항목을 캐시에 저장
  Future<void> set<T>(String key, T value, {int? ttlMs}) async {
    final cacheKey = _createCacheKey(key);
    final ttlKey = _createTTLKey(key);
    
    // 만료 시간 계산
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiryTime = now + (ttlMs ?? defaultTTL);
    
    // 1. 메모리 캐시에 저장
    _memoryCache[cacheKey] = value;
    _memoryCacheTTL[cacheKey] = expiryTime;
    
    // 2. 영구 저장소에 저장
    try {
      final jsonValue = jsonEncode(value);
      await _storageService.setString(cacheKey, jsonValue);
      await _storageService.setString(ttlKey, expiryTime.toString());
    } catch (e) {
      debugPrint('캐시 인코딩 오류: $e');
    }
  }
  
  /// 캐시에서 항목 제거
  Future<void> remove(String key) async {
    final cacheKey = _createCacheKey(key);
    final ttlKey = _createTTLKey(key);
    
    // 1. 메모리 캐시에서 제거
    _memoryCache.remove(cacheKey);
    _memoryCacheTTL.remove(cacheKey);
    
    // 2. 영구 저장소에서 제거
    await _storageService.remove(cacheKey);
    await _storageService.remove(ttlKey);
  }
  
  /// 캐시 전체 비우기
  Future<void> clear() async {
    // 1. 메모리 캐시 비우기
    _memoryCache.clear();
    _memoryCacheTTL.clear();
    
    // 2. 영구 저장소의 캐시 항목 비우기
    final allKeys = await _storageService.getKeys();
    for (final key in allKeys) {
      if (key.startsWith(_cacheKeyPrefix)) {
        await _storageService.remove(key);
      }
    }
  }
  
  /// 만료된 캐시 항목 정리
  Future<void> cleanExpired() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 1. 메모리 캐시 정리
    final expiredMemoryKeys = _memoryCacheTTL.entries
        .where((entry) => entry.value < now)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredMemoryKeys) {
      _memoryCache.remove(key);
      _memoryCacheTTL.remove(key);
    }
    
    // 2. 영구 저장소 정리
    final allKeys = await _storageService.getKeys();
    for (final key in allKeys) {
      if (key.startsWith(_cacheKeyPrefix) && key.endsWith(_cacheTTLSuffix)) {
        final ttlStr = await _storageService.getString(key);
        if (ttlStr != null) {
          final ttl = int.tryParse(ttlStr) ?? 0;
          if (ttl < now) {
            // TTL 키에서 기본 캐시 키 추출
            final cacheKey = key.substring(0, key.length - _cacheTTLSuffix.length);
            await _storageService.remove(cacheKey);
            await _storageService.remove(key);
          }
        }
      }
    }
  }
}
// lib/data/repositories/base/unified_base_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/api_exception.dart';
import '../../../core/utils/business_exception.dart';
import 'package:chunk_up/infrastructure/logging/logging_service.dart';
import '../../../di/service_locator.dart';

/// 통합된 베이스 리포지토리 - 모든 공통 기능을 중앙화
/// 
/// 기존의 BaseRepository와 BaseRepositoryImpl 기능을 통합
/// CRUD 연산, 에러 처리, 재시도 로직, 로깅을 포함
abstract class UnifiedBaseRepository<T> {
  /// 로깅 서비스
  LoggingService get _loggingService => getIt<LoggingService>();

  /// 저장소 키 (각 구현체에서 오버라이드)
  String get storageKey;
  
  /// JSON에서 엔티티로 변환 (각 구현체에서 구현)
  T fromJson(Map<String, dynamic> json);
  
  /// 엔티티에서 JSON으로 변환 (각 구현체에서 구현)
  Map<String, dynamic> toJson(T entity);

  /// ID 추출 함수 (각 구현체에서 구현)
  String getId(T entity);

  /// 엔티티 비교 함수 (기본적으로 ID 기반)
  bool isSameEntity(T a, T b) => getId(a) == getId(b);

  /// 모든 엔티티 가져오기
  Future<List<T>> getAll() async {
    return executeOperation<List<T>>(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final String? dataJson = prefs.getString(storageKey);

        if (dataJson == null || dataJson.isEmpty) {
          return <T>[];
        }

        try {
          final dynamic decoded = jsonDecode(dataJson);
          
          if (decoded is! List) {
            _loggingService.logWarning('Invalid data format in storage for key: $storageKey');
            return <T>[];
          }

          return decoded
              .where((item) => item is Map<String, dynamic>)
              .map<T>((item) => fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (e) {
          _loggingService.logError('JSON parsing error for key: $storageKey', error: e);
          return <T>[];
        }
      },
      operationName: 'getAll entities from $storageKey',
      fallback: () => <T>[],
    );
  }

  /// 모든 엔티티 저장하기
  Future<void> saveAll(List<T> entities) async {
    await executeOperation<void>(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        
        try {
          final List<Map<String, dynamic>> jsonList = entities
              .map((e) => toJson(e))
              .toList();
          
          final String encoded = jsonEncode(jsonList);
          await prefs.setString(storageKey, encoded);
          
          _loggingService.logInfo('Saved ${entities.length} entities to $storageKey');
        } catch (e) {
          _loggingService.logError('Failed to save entities to $storageKey', error: e);
          rethrow;
        }
      },
      operationName: 'saveAll entities to $storageKey',
    );
  }

  /// ID로 엔티티 찾기
  Future<T?> findById(String id) async {
    return executeOperation<T?>(
      operation: () async {
        final entities = await getAll();
        try {
          return entities.firstWhere((entity) => getId(entity) == id);
        } catch (e) {
          return null;
        }
      },
      operationName: 'findById $id in $storageKey',
      fallback: () => null,
    );
  }

  /// 조건으로 엔티티 찾기
  Future<T?> findBy(bool Function(T entity) predicate) async {
    return executeOperation<T?>(
      operation: () async {
        final entities = await getAll();
        try {
          return entities.firstWhere(predicate);
        } catch (e) {
          return null;
        }
      },
      operationName: 'findBy predicate in $storageKey',
      fallback: () => null,
    );
  }

  /// 조건으로 여러 엔티티 찾기
  Future<List<T>> findWhere(bool Function(T entity) predicate) async {
    return executeOperation<List<T>>(
      operation: () async {
        final entities = await getAll();
        return entities.where(predicate).toList();
      },
      operationName: 'findWhere predicate in $storageKey',
      fallback: () => <T>[],
    );
  }

  /// 엔티티 개수 세기
  Future<int> count([bool Function(T entity)? predicate]) async {
    return executeOperation<int>(
      operation: () async {
        final entities = await getAll();
        if (predicate != null) {
          return entities.where(predicate).length;
        }
        return entities.length;
      },
      operationName: 'count entities in $storageKey',
      fallback: () => 0,
    );
  }

  /// 엔티티 존재 여부 확인
  Future<bool> exists(String id) async {
    return executeOperation<bool>(
      operation: () async {
        final entity = await findById(id);
        return entity != null;
      },
      operationName: 'check existence of $id in $storageKey',
      fallback: () => false,
    );
  }

  /// 새 엔티티 생성
  Future<T> create(T entity) async {
    return executeWithRetry<T>(
      operation: () async {
        final entities = await getAll();
        final entityId = getId(entity);
        
        // 중복 체크
        if (entities.any((e) => getId(e) == entityId)) {
          throw BusinessException(
            message: 'Entity with ID $entityId already exists',
            type: BusinessErrorType.duplicateWordList,
          );
        }
        
        entities.add(entity);
        await saveAll(entities);
        
        _loggingService.logInfo('Created entity with ID: $entityId in $storageKey');
        return entity;
      },
      operationName: 'create entity in $storageKey',
    );
  }

  /// 여러 엔티티 생성 (배치)
  Future<List<T>> createBatch(List<T> entities) async {
    return executeWithRetry<List<T>>(
      operation: () async {
        final existingEntities = await getAll();
        final newEntities = <T>[];
        
        for (final entity in entities) {
          final entityId = getId(entity);
          if (!existingEntities.any((e) => getId(e) == entityId)) {
            newEntities.add(entity);
          } else {
            _loggingService.logWarning('Skipping duplicate entity: $entityId');
          }
        }
        
        if (newEntities.isNotEmpty) {
          existingEntities.addAll(newEntities);
          await saveAll(existingEntities);
          _loggingService.logInfo('Created ${newEntities.length} entities in $storageKey');
        }
        
        return newEntities;
      },
      operationName: 'createBatch entities in $storageKey',
    );
  }

  /// 엔티티 업데이트
  Future<T> update(T entity) async {
    return executeWithRetry<T>(
      operation: () async {
        final entities = await getAll();
        final entityId = getId(entity);
        final index = entities.indexWhere((e) => getId(e) == entityId);
        
        if (index == -1) {
          throw BusinessException(
            message: 'Entity with ID $entityId not found',
            type: BusinessErrorType.wordNotFound,
          );
        }
        
        entities[index] = entity;
        await saveAll(entities);
        
        _loggingService.logInfo('Updated entity with ID: $entityId in $storageKey');
        return entity;
      },
      operationName: 'update entity in $storageKey',
    );
  }

  /// 조건부 업데이트
  Future<T> updateWhere(T entity, bool Function(T) finder) async {
    return executeWithRetry<T>(
      operation: () async {
        final entities = await getAll();
        final index = entities.indexWhere(finder);
        
        if (index == -1) {
          throw BusinessException(
            message: 'Entity not found for update condition',
            type: BusinessErrorType.wordNotFound,
          );
        }
        
        entities[index] = entity;
        await saveAll(entities);
        
        _loggingService.logInfo('Updated entity by condition in $storageKey');
        return entity;
      },
      operationName: 'updateWhere entity in $storageKey',
    );
  }

  /// 엔티티가 있으면 업데이트, 없으면 생성
  Future<T> upsert(T entity) async {
    return executeWithRetry<T>(
      operation: () async {
        final entityId = getId(entity);
        final existing = await findById(entityId);
        
        if (existing != null) {
          return await update(entity);
        } else {
          return await create(entity);
        }
      },
      operationName: 'upsert entity in $storageKey',
    );
  }

  /// ID로 엔티티 삭제
  Future<bool> deleteById(String id) async {
    return executeWithRetry<bool>(
      operation: () async {
        final entities = await getAll();
        final initialLength = entities.length;
        
        entities.removeWhere((entity) => getId(entity) == id);
        
        if (entities.length == initialLength) {
          return false;
        }
        
        await saveAll(entities);
        _loggingService.logInfo('Deleted entity with ID: $id from $storageKey');
        return true;
      },
      operationName: 'deleteById $id in $storageKey',
    );
  }

  /// 조건으로 엔티티 삭제
  Future<bool> deleteWhere(bool Function(T) finder) async {
    return executeWithRetry<bool>(
      operation: () async {
        final entities = await getAll();
        final initialLength = entities.length;
        
        entities.removeWhere(finder);
        
        if (entities.length == initialLength) {
          return false;
        }
        
        await saveAll(entities);
        _loggingService.logInfo('Deleted ${initialLength - entities.length} entities from $storageKey');
        return true;
      },
      operationName: 'deleteWhere condition in $storageKey',
    );
  }

  /// 모든 엔티티 삭제
  Future<void> deleteAll() async {
    await executeOperation<void>(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(storageKey);
        _loggingService.logInfo('Deleted all entities from $storageKey');
      },
      operationName: 'deleteAll entities in $storageKey',
    );
  }

  /// 페이지네이션 지원
  Future<List<T>> getPage({
    int page = 0,
    int pageSize = 20,
    bool Function(T entity)? filter,
    int Function(T a, T b)? comparator,
  }) async {
    return executeOperation<List<T>>(
      operation: () async {
        var entities = await getAll();
        
        // 필터 적용
        if (filter != null) {
          entities = entities.where(filter).toList();
        }
        
        // 정렬 적용
        if (comparator != null) {
          entities.sort(comparator);
        }
        
        // 페이지네이션 적용
        final startIndex = page * pageSize;
        final endIndex = (startIndex + pageSize).clamp(0, entities.length);
        
        if (startIndex >= entities.length) {
          return <T>[];
        }
        
        return entities.sublist(startIndex, endIndex);
      },
      operationName: 'getPage $page (size: $pageSize) from $storageKey',
      fallback: () => <T>[],
    );
  }

  /// 백업 생성
  Future<Map<String, dynamic>> createBackup() async {
    return executeOperation<Map<String, dynamic>>(
      operation: () async {
        final entities = await getAll();
        return {
          'storageKey': storageKey,
          'timestamp': DateTime.now().toIso8601String(),
          'count': entities.length,
          'data': entities.map((e) => toJson(e)).toList(),
        };
      },
      operationName: 'createBackup for $storageKey',
      fallback: () => {},
    );
  }

  /// 백업에서 복원
  Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    await executeWithRetry<void>(
      operation: () async {
        if (backup['storageKey'] != storageKey) {
          throw BusinessException(
            message: 'Backup storage key mismatch',
            type: BusinessErrorType.validationError,
          );
        }
        
        final data = backup['data'] as List<dynamic>?;
        if (data == null) {
          throw BusinessException(
            message: 'Invalid backup data',
            type: BusinessErrorType.dataFormatError,
          );
        }
        
        final entities = data
            .cast<Map<String, dynamic>>()
            .map((json) => fromJson(json))
            .toList();
            
        await saveAll(entities);
        _loggingService.logInfo('Restored ${entities.length} entities to $storageKey');
      },
      operationName: 'restoreFromBackup for $storageKey',
    );
  }

  /// 작업 실행 (에러 처리 포함)
  Future<T> executeOperation<T>({
    required Future<T> Function() operation,
    required String operationName,
    T Function()? fallback,
  }) async {
    try {
      if (kDebugMode) {
        _loggingService.logInfo('Starting operation: $operationName');
      }
      
      final result = await operation();
      
      if (kDebugMode) {
        _loggingService.logInfo('Completed operation: $operationName');
      }
      
      return result;
    } on ApiException catch (e, stackTrace) {
      _loggingService.logError(
        'API error in $operationName',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (fallback != null && e.type == ApiErrorType.noInternet) {
        _loggingService.logInfo('Using fallback for $operationName due to network issue');
        return fallback();
      }
      
      throw BusinessException(
        message: 'Failed to $operationName: ${e.message}',
        type: BusinessErrorType.dataFormatError,
      );
    } on BusinessException {
      rethrow;
    } catch (e, stackTrace) {
      _loggingService.logError(
        'Unexpected error in $operationName',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (fallback != null) {
        try {
          _loggingService.logInfo('Attempting fallback for $operationName');
          return fallback();
        } catch (fallbackError) {
          _loggingService.logError(
            'Fallback also failed for $operationName',
            error: fallbackError,
          );
        }
      }
      
      throw BusinessException(
        message: 'Unexpected error during $operationName: ${e.toString()}',
        type: BusinessErrorType.dataFormatError,
      );
    }
  }

  /// 재시도 로직을 포함한 작업 실행
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await executeOperation(
          operation: operation,
          operationName: '$operationName (attempt ${attempts + 1})',
        );
      } on BusinessException catch (e) {
        attempts++;
        
        // 재시도하지 않을 에러 타입들
        if (attempts >= maxRetries || 
            e.type == BusinessErrorType.validationError ||
            e.type == BusinessErrorType.wordNotFound ||
            e.type == BusinessErrorType.duplicateWordList) {
          rethrow;
        }
        
        _loggingService.logWarning(
          'Retrying $operationName after ${retryDelay.inSeconds}s (attempt $attempts/$maxRetries)',
        );
        
        await Future.delayed(retryDelay);
      }
    }
    
    throw BusinessException(
      message: 'Failed after $maxRetries attempts: $operationName',
      type: BusinessErrorType.dataFormatError,
    );
  }

  /// 저장소 상태 확인
  Future<Map<String, dynamic>> getStorageInfo() async {
    return executeOperation<Map<String, dynamic>>(
      operation: () async {
        final entities = await getAll();
        final prefs = await SharedPreferences.getInstance();
        final dataJson = prefs.getString(storageKey);
        
        return {
          'storageKey': storageKey,
          'entityCount': entities.length,
          'hasData': dataJson != null && dataJson.isNotEmpty,
          'dataSize': dataJson?.length ?? 0,
          'lastModified': DateTime.now().toIso8601String(),
        };
      },
      operationName: 'getStorageInfo for $storageKey',
      fallback: () => {
        'storageKey': storageKey,
        'entityCount': 0,
        'hasData': false,
        'dataSize': 0,
        'error': true,
      },
    );
  }

  /// 저장소 무결성 검사
  Future<bool> validateStorage() async {
    return executeOperation<bool>(
      operation: () async {
        try {
          final entities = await getAll();
          
          // 각 엔티티의 ID 중복 체크
          final ids = entities.map((e) => getId(e)).toList();
          final uniqueIds = ids.toSet();
          
          if (ids.length != uniqueIds.length) {
            _loggingService.logWarning('Duplicate IDs found in $storageKey');
            return false;
          }
          
          // 각 엔티티의 JSON 변환 가능성 체크
          for (final entity in entities) {
            try {
              final json = toJson(entity);
              fromJson(json); // 다시 변환해서 검증
            } catch (e) {
              _loggingService.logWarning('Invalid entity found in $storageKey: $e');
              return false;
            }
          }
          
          return true;
        } catch (e) {
          _loggingService.logError('Storage validation failed for $storageKey', error: e);
          return false;
        }
      },
      operationName: 'validateStorage for $storageKey',
      fallback: () => false,
    );
  }

  /// 저장소 압축 (중복 제거 및 정리)
  Future<int> compactStorage() async {
    return executeWithRetry<int>(
      operation: () async {
        final entities = await getAll();
        final uniqueEntities = <String, T>{};
        
        // ID 기반으로 중복 제거 (마지막 엔티티 유지)
        for (final entity in entities) {
          uniqueEntities[getId(entity)] = entity;
        }
        
        final compactedEntities = uniqueEntities.values.toList();
        final removedCount = entities.length - compactedEntities.length;
        
        if (removedCount > 0) {
          await saveAll(compactedEntities);
          _loggingService.logInfo('Compacted $storageKey: removed $removedCount duplicates');
        }
        
        return removedCount;
      },
      operationName: 'compactStorage for $storageKey',
    );
  }
}
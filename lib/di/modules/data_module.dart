// lib/di/modules/data_module.dart
import 'package:get_it/get_it.dart';

import 'package:chunk_up/data/services/importers/csv_import_service.dart';
import 'package:chunk_up/data/services/importers/excel_import_service.dart';
import 'package:chunk_up/data/services/api/unified_api_service.dart';
import 'package:chunk_up/data/services/auth/auth_service_extended.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:chunk_up/data/repositories/word_list_repository.dart';
import 'package:chunk_up/data/repositories/chunk_repository.dart';
import 'package:chunk_up/domain/services/api_service_interface.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/data/services/cache/cache_service.dart';
import 'package:chunk_up/infrastructure/network/network_service.dart';

/// 데이터 모듈 - 데이터 관련 서비스 및 저장소를 등록합니다.
class DataModule {
  static Future<void> register(GetIt getIt) async {
    // Firebase 인증 서비스 등록 (Auth와 Firestore는 유지)
    try {
      if (Firebase.apps.isNotEmpty) {
        getIt.registerLazySingleton<AuthServiceExtended>(() => AuthServiceExtended());
        print('✅ Firebase Auth 서비스 등록 성공');
      }
    } catch (e) {
      print('⚠️ Firebase Auth 서비스 등록 실패: $e');
    }
    
    // UnifiedApiService를 기본 API 서비스로 사용
    getIt.registerLazySingleton<ApiServiceInterface>(() => UnifiedApiService(
      httpClient: http.Client(),
      networkService: getIt<NetworkService>(),
      cacheService: getIt<CacheService>(),
    ));

    // API 서비스 초기화
    try {
      await getIt<ApiServiceInterface>().initialize();
      print('✅ API 서비스 초기화 완료');
    } catch (e) {
      print('⚠️ API 서비스 초기화 실패: $e');
    }

    // 데이터 서비스
    getIt.registerLazySingleton(() => CsvImportService());
    getIt.registerLazySingleton(() => ExcelImportService());
    
    // 레포지토리
    getIt.registerLazySingleton<WordListRepositoryInterface>(() => WordListRepositoryImpl());
    
    getIt.registerLazySingleton<ChunkRepositoryInterface>(() => ChunkRepositoryImpl(
      getIt<WordListRepositoryInterface>(),
      getIt<ApiServiceInterface>(),
    ));
  }
}
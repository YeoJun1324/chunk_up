// lib/di/modules/data_module.dart
import 'package:get_it/get_it.dart';

import 'package:chunk_up/data/services/csv_import_service.dart';
import 'package:chunk_up/data/services/excel_import_service.dart';
import 'package:chunk_up/data/services/api_service_impl.dart';
import 'package:chunk_up/data/repositories/word_list_repository.dart';
import 'package:chunk_up/data/repositories/chunk_repository.dart';
import 'package:chunk_up/domain/services/api_service_interface.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/core/services/cache_service.dart';
import 'package:chunk_up/core/services/network_service.dart';
import 'package:chunk_up/core/services/api_service.dart';

/// 데이터 모듈 - 데이터 관련 서비스 및 저장소를 등록합니다.
class DataModule {
  static Future<void> register(GetIt getIt) async {
    // API 서비스
    getIt.registerLazySingleton<ApiServiceInterface>(() => ApiServiceImpl(
      httpClient: getIt(),
      networkService: getIt<NetworkService>(),
      cacheService: getIt<CacheService>(),
    ));

    // 코어 API 서비스도 등록
    getIt.registerLazySingleton<ApiService>(() => ApiService(
      httpClient: getIt(),
      cacheService: getIt<CacheService>(),
    ));

    // API 서비스 초기화
    await getIt<ApiServiceInterface>().initialize();

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
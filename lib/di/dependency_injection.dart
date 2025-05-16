// lib/di/dependency_injection.dart
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

// Core
import 'package:chunk_up/core/services/api_service.dart';
import 'package:chunk_up/core/services/network_service.dart';
import 'package:chunk_up/core/services/logging_service.dart';
import 'package:chunk_up/core/services/error_service.dart';
import 'package:chunk_up/core/services/character_service.dart';
import 'package:chunk_up/core/services/navigation_service.dart';
import 'package:chunk_up/core/services/route_service.dart';
import 'package:chunk_up/core/services/notification_service.dart';
import 'package:chunk_up/core/services/review_service.dart';

// Data
import 'package:chunk_up/data/repositories/word_list_repository.dart';
import 'package:chunk_up/data/repositories/chunk_repository.dart';
import 'package:chunk_up/data/services/storage/local_storage_service.dart';
import 'package:chunk_up/data/services/csv_import_service.dart';
import 'package:chunk_up/data/services/excel_import_service.dart';

// Domain
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/domain/usecases/create_word_list_use_case.dart';
import 'package:chunk_up/domain/usecases/generate_chunk_use_case.dart';

// Presentation
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/presentation/providers/folder_notifier.dart';

final getIt = GetIt.instance;

enum Environment { development, staging, production }

Future<void> setupServiceLocator({Environment environment = Environment.production}) async {
  // 환경별 설정
  if (environment == Environment.development) {
    // 개발 환경 설정
    getIt.registerLazySingleton<String>(() => 'https://dev-api.example.com', instanceName: 'baseUrl');
  } else if (environment == Environment.staging) {
    // 스테이징 환경 설정
    getIt.registerLazySingleton<String>(() => 'https://staging-api.example.com', instanceName: 'baseUrl');
  } else {
    // 프로덕션 환경 설정
    getIt.registerLazySingleton<String>(() => 'https://api.anthropic.com', instanceName: 'baseUrl');
  }

  // 외부 라이브러리 및 공통 객체
  getIt.registerLazySingleton<http.Client>(() => http.Client());
  
  // 스토리지 서비스
  getIt.registerLazySingleton<StorageService>(() => LocalStorageService());

  // Core Services
  getIt.registerLazySingleton<LoggingService>(() => LoggingService());
  getIt.registerLazySingleton<ErrorService>(() => ErrorService());
  getIt.registerLazySingleton<NetworkService>(() => NetworkService()..initialize());
  getIt.registerLazySingleton<ApiService>(() => ApiService(
    storageService: getIt<StorageService>(),
    httpClient: getIt<http.Client>(),
  ));
  getIt.registerLazySingleton(() => CharacterService());
  getIt.registerLazySingleton(() => RouteService());
  getIt.registerLazySingleton(() => NotificationService());
  getIt.registerLazySingleton(() => ReviewService());

  // Data Services
  getIt.registerLazySingleton(() => CsvImportService());
  getIt.registerLazySingleton(() => ExcelImportService());

  // Repositories
  getIt.registerLazySingleton<WordListRepositoryInterface>(() => WordListRepositoryImpl(
    storageService: getIt<StorageService>(),
  ));
  getIt.registerLazySingleton<ChunkRepositoryInterface>(() => ChunkRepositoryImpl(
    getIt<WordListRepositoryInterface>(),
    getIt<ApiService>(),
  ));

  // Use Cases
  getIt.registerLazySingleton<CreateWordListUseCase>(() => CreateWordListUseCase(
    wordListRepository: getIt<WordListRepositoryInterface>(),
  ));
  getIt.registerLazySingleton<GenerateChunkUseCase>(() => GenerateChunkUseCase(
    chunkRepository: getIt<ChunkRepositoryInterface>(),
    wordListRepository: getIt<WordListRepositoryInterface>(),
    apiService: getIt<ApiService>(),
  ));

  // Providers
  getIt.registerFactory<WordListNotifier>(() => WordListNotifier(
    wordListRepository: getIt<WordListRepositoryInterface>(),
    chunkRepository: getIt<ChunkRepositoryInterface>(),
    createWordListUseCase: getIt<CreateWordListUseCase>(),
  ));

  getIt.registerFactory<FolderNotifier>(() => FolderNotifier());
}

void resetServiceLocator() {
  getIt.reset();
}
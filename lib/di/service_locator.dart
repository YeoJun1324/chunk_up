// lib/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

// Core
import 'package:chunk_up/core/services/network_service.dart';
import 'package:chunk_up/core/services/logging_service.dart';
import 'package:chunk_up/core/services/error_service.dart';
import 'package:chunk_up/core/services/enhanced_character_service.dart';
import 'package:chunk_up/core/services/cache_service.dart';
import 'package:chunk_up/core/services/subscription_service.dart';
import 'package:chunk_up/core/services/ad_service.dart';
import 'package:chunk_up/core/services/auth_service.dart';
import 'package:chunk_up/core/services/backup_service.dart';
import 'package:chunk_up/core/services/prompt_builder_service.dart';
import 'package:chunk_up/core/services/prompt_template_service.dart';

// Data
import 'package:chunk_up/data/repositories/word_list_repository.dart';
import 'package:chunk_up/data/repositories/chunk_repository.dart';
import 'package:chunk_up/data/services/storage/local_storage_service.dart';
import 'package:chunk_up/data/services/api_service_impl.dart';

// Domain
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/domain/usecases/create_word_list_use_case.dart';
import 'package:chunk_up/domain/usecases/generate_chunk_use_case.dart';
import 'package:chunk_up/domain/services/api_service_interface.dart';

// Presentation
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/presentation/providers/folder_notifier.dart';
import 'package:chunk_up/presentation/providers/theme_notifier.dart';

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

  // 스토리지 서비스 - StorageService 인터페이스로 등록
  getIt.registerLazySingleton<StorageService>(() => LocalStorageService());

  // Core Services
  getIt.registerLazySingleton<LoggingService>(() => LoggingService());
  getIt.registerLazySingleton<ErrorService>(() => ErrorService());
  getIt.registerLazySingleton<NetworkService>(() => NetworkService());
  getIt.registerLazySingleton<CacheService>(() => CacheService(
    storageService: getIt<StorageService>(),
  ));
  
  // API 서비스 - 인터페이스와 구현체
  getIt.registerLazySingleton<ApiServiceInterface>(() => ApiServiceImpl(
    httpClient: getIt<http.Client>(),
    networkService: getIt<NetworkService>(),
    cacheService: getIt<CacheService>(),
  ));
  
  getIt.registerLazySingleton(() => EnhancedCharacterService());

  // Auth & Subscription Services
  getIt.registerLazySingleton<AuthService>(() => AuthService(
    storageService: getIt<StorageService>(),
  ));

  // 명시적으로 SubscriptionService 등록 (대소문자 일치 확인)
  if (!getIt.isRegistered<SubscriptionService>()) {
    getIt.registerLazySingleton<SubscriptionService>(() => SubscriptionService());
  }

  // 명시적으로 AdService 등록 (대소문자 일치 확인)
  if (!getIt.isRegistered<AdService>()) {
    getIt.registerLazySingleton<AdService>(() => AdService());
  }

  getIt.registerLazySingleton<BackupService>(() => BackupService(
    authService: getIt<AuthService>(),
    storageService: getIt<StorageService>(),
  ));

  // Prompt Services
  getIt.registerLazySingleton<PromptBuilderService>(() => PromptBuilderService());
  getIt.registerLazySingleton<PromptTemplateService>(() => PromptTemplateService());

  // Repositories
  getIt.registerLazySingleton<WordListRepositoryInterface>(() => WordListRepositoryImpl());
  getIt.registerLazySingleton<ChunkRepositoryInterface>(() => ChunkRepositoryImpl(
    getIt<WordListRepositoryInterface>(),
    getIt<ApiServiceInterface>(),
  ));

  // Use Cases
  getIt.registerLazySingleton<CreateWordListUseCase>(() => CreateWordListUseCase(
    wordListRepository: getIt<WordListRepositoryInterface>(),
  ));
  getIt.registerLazySingleton<GenerateChunkUseCase>(() => GenerateChunkUseCase(
    chunkRepository: getIt<ChunkRepositoryInterface>(),
    wordListRepository: getIt<WordListRepositoryInterface>(),
    apiService: getIt<ApiServiceInterface>(),
  ));

  // Providers
  getIt.registerFactory<WordListNotifier>(() => WordListNotifier(
    wordListRepository: getIt<WordListRepositoryInterface>(),
    chunkRepository: getIt<ChunkRepositoryInterface>(),
    createWordListUseCase: getIt<CreateWordListUseCase>(),
  ));

  getIt.registerFactory<FolderNotifier>(() => FolderNotifier());
  getIt.registerFactory<ThemeNotifier>(() => ThemeNotifier());
}

void resetServiceLocator() {
  getIt.reset();
}
// lib/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

// Core - Unified Services
import 'package:chunk_up/infrastructure/network/network_service.dart';
import 'package:chunk_up/infrastructure/logging/logging_service.dart';
import 'package:chunk_up/infrastructure/error/error_service.dart';
import 'package:chunk_up/domain/services/character/enhanced_character_service.dart';
import 'package:chunk_up/data/services/cache/cache_service.dart';
import 'package:chunk_up/data/services/subscription/subscription_service.dart';
import 'package:chunk_up/data/services/ads/ad_service.dart';
import 'package:chunk_up/data/services/auth/auth_service.dart';
import 'package:chunk_up/data/services/backup/backup_service.dart';
import 'package:chunk_up/domain/services/prompt/prompt_builder_service.dart';
import 'package:chunk_up/domain/services/prompt/prompt_template_service.dart';
import 'package:chunk_up/domain/services/exam/unified_exam_generator.dart';
import 'package:chunk_up/domain/services/content/response_parser_service.dart';

// New Unified Services
import 'package:chunk_up/data/services/api/unified_api_service.dart';
import 'package:chunk_up/domain/services/sentence/unified_sentence_mapping_service.dart';
import 'package:chunk_up/data/services/pdf/pdf_coordinator.dart';

// Data
import 'package:chunk_up/data/repositories/word_list_repository.dart';
import 'package:chunk_up/data/repositories/chunk_repository.dart';
import 'package:chunk_up/data/services/storage/local_storage_service.dart';
// Legacy API service import removed - using unified API service

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
  
  // API 서비스 - 통합된 API 서비스
  getIt.registerLazySingleton<ApiServiceInterface>(() => UnifiedApiService(
    httpClient: getIt<http.Client>(),
    networkService: getIt<NetworkService>(),
    cacheService: getIt<CacheService>(),
  ));
  
  // 기존 API 서비스 구현체도 호환성을 위해 유지 (deprecated)
  getIt.registerLazySingleton(() => UnifiedApiService(
    httpClient: getIt<http.Client>(),
    networkService: getIt<NetworkService>(),
    cacheService: getIt<CacheService>(),
  ), instanceName: 'legacy');
  
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
  
  // Response Parser Service
  getIt.registerLazySingleton<ResponseParserService>(() => ResponseParserService());

  // Unified Services - 새로운 통합 서비스들
  getIt.registerLazySingleton<UnifiedSentenceMappingService>(() => UnifiedSentenceMappingService());
  getIt.registerLazySingleton<PdfCoordinator>(() => PdfCoordinator(getIt<SubscriptionService>()));

  // 기존 서비스들도 호환성을 위해 유지 (deprecated)
  // getIt.registerLazySingleton(() => SentenceMappingService(), instanceName: 'legacy');
  // getIt.registerLazySingleton(() => ExamPdfService(), instanceName: 'legacy');

  // Exam Services (Premium 전용)
  getIt.registerLazySingleton<UnifiedExamGenerator>(() => UnifiedExamGenerator(
    config: ExamGenerationConfig.premium,
  ));

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
    characterService: getIt<EnhancedCharacterService>(),
    promptBuilder: getIt<PromptBuilderService>(),
    templateService: getIt<PromptTemplateService>(),
    subscriptionService: getIt<SubscriptionService>(),
    responseParser: getIt<ResponseParserService>(),
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
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
import 'package:chunk_up/core/services/subscription_service.dart'; // 구독 서비스 추가
import 'package:chunk_up/core/services/ad_helper.dart'; // 광고 헬퍼 추가
import 'package:chunk_up/core/config/app_config.dart'; // 앱 설정 추가
import 'package:chunk_up/core/config/feature_flags.dart'; // 기능 플래그 추가

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

Future<void> setupServiceLocator({Environment environment = Environment.development}) async {
  // 환경별 설정
  // 기본값을 내부 테스트를 위해 development로 변경
  final envType = environment;

  // AppConfig 및 FeatureFlags 싱글톤 등록
  // 싱글톤이므로 이미 생성되어 있지만, DI 시스템에서 접근 가능하도록 등록
  getIt.registerLazySingleton<AppConfig>(() => AppConfig());
  getIt.registerLazySingleton<FeatureFlags>(() => FeatureFlags());

  // 로깅을 위한 환경 정보 출력
  final appConfig = getIt<AppConfig>();
  final featureFlags = getIt<FeatureFlags>();

  appConfig.logConfig();
  featureFlags.logFeatureFlags();

  // 환경별 API URL 설정
  if (environment == Environment.development) {
    // 개발 환경 설정
    getIt.registerLazySingleton<String>(() => 'https://api.anthropic.com', instanceName: 'baseUrl');
  } else if (environment == Environment.staging) {
    // 스테이징 환경 설정
    getIt.registerLazySingleton<String>(() => 'https://api.anthropic.com', instanceName: 'baseUrl');
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

  // 구독 및 광고 서비스
  getIt.registerLazySingleton<SubscriptionService>(() => SubscriptionService());
  getIt.registerLazySingleton<AdHelper>(() => AdHelper());

  // API 서비스
  getIt.registerLazySingleton<ApiService>(() => ApiService(
    storageService: getIt<StorageService>(),
    httpClient: getIt<http.Client>(),
  ));

  // 기타 서비스
  getIt.registerLazySingleton(() => CharacterService());
  getIt.registerLazySingleton(() => RouteService());
  getIt.registerLazySingleton(() => NotificationService());
  getIt.registerLazySingleton(() => ReviewService());

  // 서비스 초기화
  await getIt<AdHelper>().initialize();

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
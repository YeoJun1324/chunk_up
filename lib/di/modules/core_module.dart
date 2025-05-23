// lib/di/modules/core_module.dart
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'package:chunk_up/core/services/logging_service.dart';
import 'package:chunk_up/core/services/error_service.dart';
import 'package:chunk_up/core/services/network_service.dart';
import 'package:chunk_up/core/services/cache_service.dart';
import 'package:chunk_up/core/services/navigation_service.dart';
import 'package:chunk_up/core/services/route_service.dart';
import 'package:chunk_up/core/services/notification_service.dart';
import 'package:chunk_up/core/services/review_service.dart';
import 'package:chunk_up/core/services/subscription_service.dart';
import 'package:chunk_up/core/services/ad_helper.dart';
import 'package:chunk_up/core/services/ad_service.dart';
import 'package:chunk_up/core/config/app_config.dart';
import 'package:chunk_up/core/config/feature_flags.dart';
import 'package:chunk_up/data/services/storage/local_storage_service.dart';
import 'package:chunk_up/core/services/prompt_builder_service.dart';
import 'package:chunk_up/core/services/prompt_template_service.dart';
import 'package:chunk_up/core/services/auth_service.dart';
import 'package:chunk_up/core/services/backup_service.dart';
import 'package:chunk_up/core/services/enhanced_character_service.dart';
import 'package:chunk_up/core/services/series_service.dart';

/// 코어 모듈 - 기본 서비스 및 유틸리티를 등록합니다.
class CoreModule {
  static Future<void> register(GetIt getIt) async {
    // 외부 라이브러리 및 공통 객체
    getIt.registerLazySingleton<http.Client>(() => http.Client());

    // 스토리지 서비스
    getIt.registerLazySingleton<StorageService>(() => LocalStorageService());

    // 앱 설정 및 기능 플래그
    getIt.registerLazySingleton<AppConfig>(() => AppConfig());
    getIt.registerLazySingleton<FeatureFlags>(() => FeatureFlags());

    // 기본 서비스
    getIt.registerLazySingleton<LoggingService>(() => LoggingService());
    getIt.registerLazySingleton<ErrorService>(() => ErrorService());
    getIt.registerLazySingleton<NetworkService>(() => NetworkService()..initialize());
    getIt.registerLazySingleton<CacheService>(() => CacheService(
      storageService: getIt<StorageService>(),
    ));

    // 구독 및 광고 서비스
    getIt.registerLazySingleton<SubscriptionService>(() => SubscriptionService());
    getIt.registerLazySingleton<AdHelper>(() => AdHelper());
    getIt.registerLazySingleton<AdService>(() => AdService());

    // 기타 서비스
    getIt.registerLazySingleton(() => RouteService());
    getIt.registerLazySingleton(() => NotificationService());
    getIt.registerLazySingleton(() => ReviewService());
    
    // 프롬프트 관련 서비스
    getIt.registerLazySingleton<PromptBuilderService>(() => PromptBuilderService());
    getIt.registerLazySingleton<PromptTemplateService>(() => PromptTemplateService());
    
    // Enhanced 캐릭터 서비스
    getIt.registerLazySingleton<EnhancedCharacterService>(() => EnhancedCharacterService());
    
    // 인증 및 백업 서비스
    getIt.registerLazySingleton<AuthService>(() => AuthService(
      storageService: getIt<StorageService>(),
    ));
    getIt.registerLazySingleton<BackupService>(() => BackupService(
      authService: getIt<AuthService>(),
      storageService: getIt<StorageService>(),
    ));

    // 서비스 초기화
    await getIt<AdHelper>().initialize();
    
    // Series 서비스 등록
    getIt.registerLazySingleton<SeriesService>(() => SeriesService());
  }
}
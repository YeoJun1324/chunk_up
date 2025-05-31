// lib/di/modules/core_module.dart
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'package:chunk_up/infrastructure/logging/logging_service.dart';
import 'package:chunk_up/infrastructure/error/error_service.dart';
import 'package:chunk_up/infrastructure/network/network_service.dart';
import 'package:chunk_up/data/services/cache/cache_service.dart';
import 'package:chunk_up/infrastructure/navigation/navigation_service.dart';
import 'package:chunk_up/infrastructure/navigation/route_service.dart';
import 'package:chunk_up/data/services/notifications/notification_service.dart';
import 'package:chunk_up/domain/services/review/review_service.dart';
import 'package:chunk_up/data/services/subscription/subscription_service.dart';
import 'package:chunk_up/data/services/ads/ad_helper.dart';
import 'package:chunk_up/data/services/ads/ad_service.dart';
import 'package:chunk_up/core/config/app_config.dart';
import 'package:chunk_up/core/config/feature_flags.dart';
import 'package:chunk_up/data/services/storage/local_storage_service.dart';
import 'package:chunk_up/domain/services/prompt/prompt_builder_service.dart';
import 'package:chunk_up/domain/services/prompt/prompt_template_service.dart';
import 'package:chunk_up/data/services/auth/auth_service.dart';
import 'package:chunk_up/data/services/auth/auth_service_extended.dart';
import 'package:chunk_up/data/services/backup/backup_service.dart';
import 'package:chunk_up/domain/services/character/enhanced_character_service.dart';
import 'package:chunk_up/domain/services/series/series_service.dart';
import 'package:chunk_up/domain/services/sentence/unified_sentence_mapping_service.dart';
import 'package:chunk_up/domain/services/exam/unified_exam_generator.dart';
import 'package:chunk_up/data/services/pdf/pdf_coordinator.dart';
import 'package:chunk_up/domain/services/content/response_parser_service.dart';

/// 코어 모듈 - 기본 서비스 및 유틸리티를 등록합니다.
class CoreModule {
  static Future<void> register(GetIt getIt) async {
    // 외부 라이브러리 및 공통 객체 (dispose 가능하도록 등록)
    getIt.registerLazySingleton<http.Client>(
      () => http.Client(),
      dispose: (client) => client.close(),
    );

    // 스토리지 서비스
    getIt.registerLazySingleton<StorageService>(() => LocalStorageService());

    // 앱 설정 및 기능 플래그
    getIt.registerLazySingleton<AppConfig>(() => AppConfig());
    getIt.registerLazySingleton<FeatureFlags>(() => FeatureFlags());

    // 기본 서비스
    getIt.registerLazySingleton<LoggingService>(() => LoggingService());
    getIt.registerLazySingleton<ErrorService>(() => ErrorService());
    getIt.registerLazySingleton<NetworkService>(() {
      final service = NetworkService();
      // 백그라운드에서 초기화 (에러 무시)
      service.initialize().catchError((e) {
        debugPrint('NetworkService 초기화 실패: $e');
      });
      return service;
    });
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
    
    // 응답 파싱 서비스
    getIt.registerLazySingleton<ResponseParserService>(() => ResponseParserService());
    
    // Enhanced 캐릭터 서비스
    getIt.registerLazySingleton<EnhancedCharacterService>(() => EnhancedCharacterService());
    
    // 인증 및 백업 서비스
    getIt.registerLazySingleton<AuthService>(() => AuthService(
      storageService: getIt<StorageService>(),
    ));
    // AuthServiceExtended는 DataModule에서 Firebase 가용성에 따라 등록됨
    getIt.registerLazySingleton<BackupService>(() => BackupService(
      authService: getIt<AuthService>(),
      storageService: getIt<StorageService>(),
    ));

    // 서비스 초기화 (에러 처리)
    try {
      await getIt<AdHelper>().initialize();
      debugPrint('✅ AdHelper 초기화 완료');
    } catch (e) {
      debugPrint('❌ AdHelper 초기화 실패: $e');
    }
    
    // Series 서비스 등록
    getIt.registerLazySingleton<SeriesService>(() => SeriesService());
    
    // Sentence Mapping Service (최적화된 버전)
    getIt.registerLazySingleton<UnifiedSentenceMappingService>(() => UnifiedSentenceMappingService(
      maxCacheSize: 100, // LRU 캐시 크기 제한
      onError: (message) => getIt<LoggingService>().logError(message),
      onWarning: (message) => getIt<LoggingService>().logWarning(message),
    ));
    
    // Exam Services (Premium 전용)
    getIt.registerLazySingleton<UnifiedExamGenerator>(() => UnifiedExamGenerator(
      config: ExamGenerationConfig.premium,
    ));
    getIt.registerLazySingleton<PdfCoordinator>(() => PdfCoordinator(getIt<SubscriptionService>()));
  }
}
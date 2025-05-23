import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';

import 'app/app_initializer.dart';
import 'core/widgets/error_boundary.dart';
import 'domain/services/api_service_interface.dart';
import 'core/services/api_service.dart';
import 'core/services/cache_service_v2.dart';
import 'core/services/notification_service.dart';
import 'core/services/review_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/route_service.dart';
import 'core/services/logging_service.dart';
import 'core/utils/character_migration_helper.dart';
import 'presentation/providers/word_list_notifier.dart';
import 'presentation/providers/folder_notifier.dart';
import 'presentation/providers/theme_notifier.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/word_list_screen.dart';
import 'presentation/screens/create_chunk_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/word_list_detail_screen.dart';
import 'domain/models/word_list_info.dart';
import 'presentation/screens/learning_stats_screen.dart';
import 'presentation/screens/learning_selection_screen.dart';
import 'presentation/screens/test_screen.dart';
import 'presentation/screens/import_screen.dart';
import 'presentation/screens/api_key_setup_screen.dart';
import 'core/constants/route_names.dart';
import 'core/theme/app_theme.dart';
import 'di/dependency_injection.dart' as di;

void main() {
  // Run everything in the same zone
  runZonedGuarded(() async {
    // Initialize app with error handling
    await AppInitializer.initialize(
      environment: di.Environment.production,
    );

    // Load environment files
    try {
      await dotenv.load(fileName: ".env.local");
    } catch (e) {
      try {
        await dotenv.load(fileName: ".env");
      } catch (_) {
        // Continue without environment files
      }
    }

    // 추가 초기화 작업을 백그라운드에서 실행
    _initializeBackgroundServices();

    // API 키가 실제로 존재하는지 확인
    final apiService = GetIt.instance<ApiServiceInterface>();
    final apiKey = await apiService.getApiKey();
    final bool hasApiKey = apiKey != null && apiKey.isNotEmpty;

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => GetIt.instance<WordListNotifier>(),
          ),
          ChangeNotifierProvider(
            create: (context) => GetIt.instance<FolderNotifier>(),
          ),
          ChangeNotifierProvider(
            create: (context) => GetIt.instance<ThemeNotifier>(),
          ),
        ],
        child: ChunkVocabApp(hasApiKey: hasApiKey),
      ),
    );
  }, (error, stack) {
    // 처리되지 않은 에러 로깅
    print('Uncaught error: $error');
    print('Stack trace: $stack');
  });
}

/// 백그라운드에서 초기화 작업 수행
void _initializeBackgroundServices() async {
  // 캐시 서비스 정리 스케줄링
  try {
    if (GetIt.instance.isRegistered<CacheServiceV2>()) {
      final cacheService = GetIt.instance<CacheServiceV2>();
      // CacheServiceV2는 scheduleCleanup 메소드가 없으므로 주석 처리
      // cacheService.scheduleCleanup();
    }
  } catch (_) {}

  // 알림 서비스 초기화
  try {
    final notificationService = GetIt.instance<NotificationService>();
    await notificationService.initialize();
  } catch (_) {}

  // 복습 알림 확인
  try {
    final reviewService = GetIt.instance<ReviewService>();
    final hasTodayReminders = await reviewService.checkForTodaysReviews();

    if (hasTodayReminders) {
      await reviewService.sendDailyReviewNotifications();
    }
  } catch (_) {}

  // 구 캐릭터 데이터 정리
  await CharacterMigrationHelper.cleanupOldCharacterData();

  // API 서비스 테스트
  final apiService = GetIt.instance<ApiServiceInterface>();
  await _testApiService(apiService);
}

class ChunkVocabApp extends StatelessWidget {
  final bool hasApiKey;

  const ChunkVocabApp({super.key, required this.hasApiKey});

  @override
  Widget build(BuildContext context) {
    // 테마 프로바이더 구독
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'ChunkUp Vocab',
      theme: AppTheme.lightTheme,         // 라이트 모드 테마
      darkTheme: AppTheme.darkTheme,      // 다크 모드 테마
      themeMode: themeNotifier.themeMode, // 현재 테마 모드
      debugShowCheckedModeBanner: false,
      initialRoute: hasApiKey ? RouteNames.home : RouteNames.apiKeySetup,
      routes: RouteService.getAppRoutes(hasApiKey: hasApiKey),
      onUnknownRoute: RouteService.generateUnknownRoute,
      builder: (context, child) {
        // Wrap all routes with ErrorBoundary
        return ErrorBoundary(
          child: child ?? Container(),
        );
      },
    );
  }
}

// MainScreen은 RouteService로 이동됨

// API 서비스 테스트 함수
Future<void> _testApiService(ApiServiceInterface apiService) async {
  try {
    debugPrint('🧪 API 서비스 테스트 시작');

    // API 키 확인
    final apiKey = await apiService.getApiKey();
    debugPrint('🔍 API 키 확인: ${apiKey != null && apiKey.isNotEmpty ? "있음" : "없음"}');

    // 이제 API 키가 설정되었으니 테스트 진행
    final testApiKey = await apiService.getApiKey();
    if (testApiKey != null && testApiKey.isNotEmpty) {
      // 간단한 API 테스트
      final isConnected = await apiService.testApiConnection();
      debugPrint('🌐 API 연결 테스트: ${isConnected ? "성공" : "실패"}');
    } else {
      debugPrint('⚠️ API 키 설정 실패, 연결 테스트 생략');
    }
  } catch (e) {
    debugPrint('❌ API 테스트 중 오류 발생: $e');
  }
}

void _setupGlobalErrorHandler() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    final logger = GetIt.instance<LoggingService>();
    logger.logError(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
}
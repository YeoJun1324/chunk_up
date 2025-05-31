import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app/app_initializer.dart';
import 'core/widgets/error_boundary.dart';
import 'domain/services/api_service_interface.dart';
import 'data/services/cache/cache_service.dart';
import 'data/services/notifications/notification_service.dart';
import 'domain/services/review/review_service.dart';
import 'infrastructure/navigation/navigation_service.dart';
import 'infrastructure/navigation/route_service.dart';
import 'infrastructure/logging/logging_service.dart';
import 'presentation/providers/word_list_notifier.dart';
import 'presentation/providers/folder_notifier.dart';
import 'presentation/providers/theme_notifier.dart';
import 'core/constants/route_names.dart';
import 'core/theme/app_theme.dart';
import 'di/dependency_injection.dart' as di;

void main() {
  // Setup error widget for better error display
  _setupErrorWidget();
  
  // Run everything in the same zone
  runZonedGuarded(() async {
    // Flutter 바인딩 초기화 (Firebase 초기화 전에 필수)
    WidgetsFlutterBinding.ensureInitialized();
    
    // Firebase 초기화
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase 초기화 성공');
    } catch (e) {
      print('⚠️ Firebase 초기화 실패: $e');
      // Firebase 없이도 앱이 계속 실행되도록 함
    }
    
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
    // 처리되지 않은 에러는 AppInitializer의 PlatformDispatcher.onError에서 처리됨
    // 여기서는 기본 로깅만 수행
    debugPrint('Uncaught error in main zone: $error');
    if (kDebugMode) {
      debugPrint('Stack trace: $stack');
    }
  });
}

/// 백그라운드에서 초기화 작업 수행
void _initializeBackgroundServices() async {
  final logger = GetIt.instance.isRegistered<LoggingService>() 
      ? GetIt.instance<LoggingService>() 
      : null;

  // 캐시 서비스 정리 스케줄링
  try {
    if (GetIt.instance.isRegistered<CacheService>()) {
      final cacheService = GetIt.instance<CacheService>();
      // 즉시 한 번 정리
      await cacheService.cleanExpired();
      // 주기적 정리 시작
      cacheService.startPeriodicCleanup(interval: const Duration(hours: 6));
      logger?.logInfo('Cache cleanup scheduled successfully');
    }
  } catch (e) {
    logger?.logError('Cache service initialization failed', error: e);
    debugPrint('Cache service initialization failed: $e');
  }

  // 알림 서비스 초기화
  try {
    final notificationService = GetIt.instance<NotificationService>();
    await notificationService.initialize();
    logger?.logInfo('Notification service initialized');
  } catch (e) {
    logger?.logError('Notification service initialization failed', error: e);
    debugPrint('Notification service initialization failed: $e');
  }

  // 복습 알림 확인
  try {
    final reviewService = GetIt.instance<ReviewService>();
    final hasTodayReminders = await reviewService.checkForTodaysReviews();

    if (hasTodayReminders) {
      await reviewService.sendDailyReviewNotifications();
      logger?.logInfo('Daily review notifications sent');
    }
  } catch (e) {
    logger?.logError('Review service error', error: e);
    debugPrint('Review service error: $e');
  }


  // API 서비스 테스트
  try {
    final apiService = GetIt.instance<ApiServiceInterface>();
    await _testApiService(apiService);
  } catch (e) {
    logger?.logError('API service test failed', error: e);
    debugPrint('API service test failed: $e');
  }
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

// 이 함수는 AppInitializer에서 처리하므로 제거됨

/// 에러 위젯 설정 - UI 에러 시 더 나은 화면 표시
void _setupErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '오류가 발생했습니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kDebugMode 
                    ? details.exception.toString()
                    : '앱에서 예기치 않은 오류가 발생했습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade600,
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      details.stack.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  };
}
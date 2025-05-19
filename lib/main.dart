// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // 사용하지 않으므로 제거
import 'presentation/providers/word_list_notifier.dart';
import 'presentation/providers/folder_notifier.dart';
import 'presentation/providers/theme_notifier.dart'; // 테마 관리 프로바이더 추가
import 'main_riverpod.dart'; // Riverpod 컨테이너 추가
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/word_list_screen.dart';
import 'presentation/screens/create_chunk_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/word_list_detail_screen.dart';
import 'domain/models/word_list_info.dart';
import 'presentation/screens/character_creation_screen.dart';
import 'presentation/screens/learning_stats_screen.dart';
import 'presentation/screens/learning_selection_screen.dart';
import 'presentation/screens/test_screen.dart';
import 'presentation/screens/import_screen.dart';
import 'presentation/screens/api_key_setup_screen.dart';
import 'data/repositories/word_list_repository.dart';
import 'data/repositories/chunk_repository.dart';
import 'core/services/api_service.dart';
import 'core/services/error_service.dart';
import 'core/services/logging_service.dart';
import 'core/services/character_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/route_service.dart';
import 'core/services/review_service.dart'; // 복습 알림 서비스 추가
import 'core/services/notification_service.dart'; // 알림 서비스 추가
import 'core/services/embedded_api_service.dart'; // 내장 API 키 서비스 추가
import 'di/dependency_injection.dart'; // 다른 파일에서 참조하는 이름을 유지
import 'core/constants/route_names.dart';
import 'core/theme/app_theme.dart'; // 앱 테마 정의 추가
import 'data/services/storage/local_storage_service.dart'; // 로컬 스토리지 서비스 추가
import 'data/datasources/remote/api_service.dart' as remote_api; // 원격 API 서비스 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 내장 API 키 초기화 (출시 버전에서는 항상 API 키 자동 설정)
  await EmbeddedApiService.initializeApiSettings();

  // 의존성 주입 설정
  await setupServiceLocator();

  // 글로벌 에러 핸들러 설정
  _setupGlobalErrorHandler();

  // 알림 서비스 초기화
  try {
    final notificationService = getIt<NotificationService>();
    await notificationService.initialize();
    debugPrint('알림 서비스 초기화 완료');
  } catch (e) {
    debugPrint('알림 서비스 초기화 오류: $e');
  }

  // 복습 알림 확인
  try {
    final reviewService = getIt<ReviewService>();
    final hasTodayReminders = await reviewService.checkForTodaysReviews();

    if (hasTodayReminders) {
      debugPrint('오늘 예정된 복습이 있습니다!');
      // 앱 시작 시 알림 전송
      await reviewService.sendDailyReviewNotifications();
    }
  } catch (e) {
    debugPrint('복습 알림 확인 중 오류 발생: $e');
  }

  // 기본 캐릭터 초기화
  final characterService = getIt<CharacterService>();
  await characterService.initializeDefaultCharacters();

  // API 서비스 테스트
  final apiService = getIt<ApiService>();
  await _testApiService(apiService);

  // 글로벌 에러 처리 Zone
  runZonedGuarded(() async {
    // API 키가 실제로 존재하는지 확인
    final apiKey = await ApiService.getApiKey();
    final bool hasApiKey = apiKey != null && apiKey.isNotEmpty;

    runApp(
      // RiverpodContainer로 감싸서 Riverpod Provider 사용 가능하게 함
      RiverpodContainer(
        child: MultiProvider(
          providers: [
            // getIt을 사용하여 DI 인스턴스 제공
            ChangeNotifierProvider(
              create: (context) => getIt<WordListNotifier>(),
            ),
            ChangeNotifierProvider(
              create: (context) => getIt<FolderNotifier>(),
            ),
            // 테마 관리 프로바이더 추가
            ChangeNotifierProvider(
              create: (context) => ThemeNotifier(),
            ),
          ],
          child: ChunkVocabApp(hasApiKey: hasApiKey),
        ),
      ),
    );
  }, (error, stack) {
    // 처리되지 않은 에러 로깅
    print('Uncaught error: $error');
    print('Stack trace: $stack');
  });
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
    );
  }
}

// MainScreen은 RouteService로 이동됨

// API 서비스 테스트 함수
Future<void> _testApiService(ApiService apiService) async {
  try {
    debugPrint('🧪 API 서비스 테스트 시작');

    // 임베디드 API 키 다시 초기화 시도
    debugPrint('🔄 API 키 초기화 재시도');
    await EmbeddedApiService.initializeApiSettings();

    // LocalStorageService에서 직접 API 키 확인
    final localStorageService = LocalStorageService();
    final localApiKey = await localStorageService.getString('api_key');
    debugPrint('🔍 로컬 저장소 API 키 확인: ${localApiKey != null && localApiKey.isNotEmpty ? "있음" : "없음"}');

    // 보안 저장소에서 API 키 확인
    final secureApiKey = await remote_api.ApiService.apiKey;
    debugPrint('🔍 보안 저장소 API 키 확인: ${secureApiKey != null && secureApiKey.isNotEmpty ? "있음" : "없음"}');

    // API 키 확인 (ApiService 사용)
    final apiKey = await ApiService.getApiKey();
    debugPrint('🔍 API 키 확인: ${apiKey != null && apiKey.isNotEmpty ? "있음" : "없음"}');

    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('❌ API 키가 설정되지 않았습니다');
      // API 키가 없으면 임베디드 키 직접 가져와서 설정
      try {
        // 내장 API 키 서비스 초기화를 다시 시도하고 키를 가져오기
        await EmbeddedApiService.initializeApiSettings();
        final embeddedKey = await EmbeddedApiService.getApiKey();

        if (embeddedKey != null && embeddedKey.isNotEmpty) {
          debugPrint('🔑 임베디드 키 직접 사용: ${embeddedKey.substring(0, 15)}...');

          // API 키 직접 저장
          await ApiService.saveApiKeyStatic(embeddedKey);
          await remote_api.ApiService.saveApiKeyStatic(embeddedKey);
        } else {
          debugPrint('⚠️ 임베디드 키를 가져올 수 없음');
        }
      } catch (e) {
        debugPrint('⚠️ 임베디드 키 초기화 중 오류: $e');
      }

      // 저장 확인
      final savedApiKey = await ApiService.getApiKey();
      debugPrint('🔄 API 키 저장 후 확인: ${savedApiKey != null && savedApiKey.isNotEmpty ? "성공" : "실패"}');
    }

    // 이제 API 키가 설정되었으니 테스트 진행
    final testApiKey = await ApiService.getApiKey();
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
    final logger = LoggingService();
    logger.logError(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
      context: {'library': details.library},
    );
  };
}
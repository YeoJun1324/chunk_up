// lib/core/services/route_service.dart
import 'package:flutter/material.dart';
import '../constants/route_names.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/word_list_screen.dart';
import '../../presentation/screens/create_chunk_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/word_list_detail_screen.dart';
import '../../presentation/screens/enhanced_character_management_screen.dart';
import '../../presentation/screens/learning_stats_screen.dart';
import '../../presentation/screens/learning_selection_screen.dart';
import '../../presentation/screens/learning_history_screen.dart';
import '../../presentation/screens/test_screen.dart';
import '../../presentation/screens/import_screen.dart';
import '../../presentation/screens/api_key_setup_screen.dart';
import '../../presentation/screens/word_list_export_screen.dart';
import '../../presentation/screens/model_test_screen.dart'; // Added model test screen
import '../../presentation/screens/subscription_screen.dart'; // Add subscription screen
import '../../domain/models/word_list_info.dart';
import 'navigation_service.dart';

/// 라우팅을 관리하는 서비스
class RouteService {
  // Singleton pattern
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  /// 메인 화면 위젯 목록
  static final List<Widget> mainScreenWidgets = <Widget>[
    const HomeScreen(),
    const WordListScreen(),
    const CreateChunkScreen(),
    const TestScreen(),
    const SettingsScreen(),
  ];

  // MainScreen의 단일 인스턴스 유지
  static MainScreen? _mainScreenInstance;
  static MainScreen get mainScreenInstance {
    _mainScreenInstance ??= MainScreen(key: MainScreen.globalKey);
    return _mainScreenInstance!;
  }

  /// 앱 라우트 정의
  static Map<String, Widget Function(BuildContext)> getAppRoutes({required bool hasApiKey}) {
    return {
      RouteNames.home: (context) => mainScreenInstance,
      RouteNames.wordListDetail: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is WordListInfo) {
          return WordListDetailScreen(wordListInfo: args);
        }
        return mainScreenInstance;
      },
      RouteNames.createChunk: (context) => const CreateChunkScreen(),
      RouteNames.test: (context) => const TestScreen(),
      RouteNames.characterManagement: (context) => const EnhancedCharacterManagementScreen(),
      RouteNames.learningSelection: (context) => const LearningSelectionScreen(),
      RouteNames.learningHistory: (context) {
        // LearningHistoryScreen에 전달된 파라미터 처리 (알림에서 전달됨)
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          // 초기 탭 인덱스
          final initialTab = args['initialTab'] as int? ?? 0;
          // 리마인더 ID
          final reviewId = args['reviewId'] as String?;

          return LearningHistoryScreen(
            initialTab: initialTab,
            reviewId: reviewId,
          );
        }
        // 기본값
        return const LearningHistoryScreen();
      },
      RouteNames.stats: (context) => const LearningStatsScreen(),
      RouteNames.import: (context) => const ImportScreen(),
      // API 키 설정 화면은 유지하되, 출시 버전에서는 사용되지 않음
      // 개발 환경에서만 화면 이동이 가능하도록 함
      RouteNames.apiKeySetup: (context) => mainScreenInstance,
      RouteNames.wordListExport: (context) => const WordListExportScreen(),
      RouteNames.modelTest: (context) => const ModelTestScreen(), // Added model test route
      RouteNames.subscription: (context) => const SubscriptionScreen(), // Added subscription route
    };
  }

  /// 알 수 없는 라우트 처리
  static Route<dynamic> generateUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('경로를 찾을 수 없습니다'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('요청한 페이지를 찾을 수 없습니다.'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => NavigationService.goToRoot(),
                child: const Text('홈으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 모달 다이얼로그 표시
  static Future<T?> showAppDialog<T>(Widget dialog) {
    return showDialog<T>(
      context: NavigationService.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) => dialog,
    );
  }

  /// 바텀 시트 표시
  static Future<T?> showAppBottomSheet<T>(Widget bottomSheet) {
    return showModalBottomSheet<T>(
      context: NavigationService.currentContext!,
      isScrollControlled: true,
      builder: (BuildContext context) => bottomSheet,
    );
  }
}

/// 메인 화면 위젯
class MainScreen extends StatefulWidget {
  // GlobalKey를 optional로 만들고 기본값 제공
  static GlobalKey<_MainScreenState>? _globalKey;
  static GlobalKey<_MainScreenState> get globalKey {
    _globalKey ??= GlobalKey<_MainScreenState>();
    return _globalKey!;
  }

  const MainScreen({Key? key}) : super(key: key);

  // 탭 변경을 위한 정적 메서드
  static void navigateToTab(int index) {
    globalKey.currentState?.setTab(index);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 외부에서 탭을 설정할 수 있는 메서드
  void setTab(int index) {
    if (index >= 0 && index < RouteService.mainScreenWidgets.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RouteService.mainScreenWidgets.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          // 다크 모드 감지
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;

          return NavigationBar(
            onDestinationSelected: _onItemTapped,
            // 선택 색상 다크 모드에 맞게 조정
            indicatorColor: isDarkMode
                ? Colors.orange.withOpacity(0.2)
                : Colors.orange.shade100,
            // 배경색 다크 모드에 맞게 조정 - 배경과 구분되도록 약간 밝게
            backgroundColor: isDarkMode
                ? const Color(0xFF333333) // 약간 더 밝은 회색으로 변경 (#2A2A2A → #333333)
                : null,
            // 구분선 추가
            elevation: 2,
            // 상단에 구분선 추가
            surfaceTintColor: isDarkMode ? const Color(0xFF444444) : Colors.grey.shade300,
            // 아이콘 색상 설정
            selectedIndex: _selectedIndex,
            height: 75, // 네비게이션 바 높이 감소
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected, // 선택된 항목만 라벨 표시
            // 라벨 및 아이콘 색상 설정
            labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>((states) {
              if (states.contains(MaterialState.selected)) {
                return TextStyle(
                  color: isDarkMode ? Colors.white : Colors.orange,
                  fontWeight: FontWeight.bold,
                );
              }
              return TextStyle(
                color: isDarkMode ? Colors.grey : Colors.grey.shade700,
              );
            }),
            destinations: <Widget>[
              NavigationDestination(
                icon: Icon(
                  Icons.edit_outlined,
                  color: isDarkMode ? Colors.grey : null
                ),
                selectedIcon: Icon(
                  Icons.edit,
                  color: isDarkMode ? Colors.white : Colors.orange,
                ),
                label: '홈'
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.menu_book_outlined,
                  color: isDarkMode ? Colors.grey : null
                ),
                selectedIcon: Icon(
                  Icons.menu_book,
                  color: isDarkMode ? Colors.white : Colors.orange,
                ),
                label: '단어장'
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 30,
                  color: isDarkMode ? Colors.grey : null
                ),
                selectedIcon: Icon(
                  Icons.add_circle,
                  size: 30,
                  color: isDarkMode ? Colors.white : Colors.orange,
                ),
                label: '생성'
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.checklist_rtl_outlined,
                  color: isDarkMode ? Colors.grey : null
                ),
                selectedIcon: Icon(
                  Icons.checklist_rtl,
                  color: isDarkMode ? Colors.white : Colors.orange,
                ),
                label: '테스트'
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                  color: isDarkMode ? Colors.grey : null
                ),
                selectedIcon: Icon(
                  Icons.person,
                  color: isDarkMode ? Colors.white : Colors.orange,
                ),
                label: '설정'
              ),
            ],
          );
        },
      ),
    );
  }
}
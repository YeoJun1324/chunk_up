// lib/presentation/widgets/debug_panel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chunk_up/core/config/app_config.dart';
import 'package:chunk_up/core/config/feature_flags.dart';
import 'package:chunk_up/core/services/subscription_service.dart';
import 'package:chunk_up/di/service_locator.dart';

/// 내부 테스트용 디버그 패널
/// 
/// 개발 환경과 테스트 환경에서 다양한 기능을 쉽게 테스트할 수 있는 패널입니다.
/// production 환경에서는 표시되지 않습니다.
class DebugPanel extends StatefulWidget {
  const DebugPanel({Key? key}) : super(key: key);

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  final FeatureFlags _featureFlags = FeatureFlags();
  final AppConfig _appConfig = AppConfig();
  late SubscriptionService _subscriptionService;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    // DI에서 SubscriptionService 인스턴스 가져오기
    try {
      // 서비스가 등록되어 있는지 확인
      if (!getIt.isRegistered<SubscriptionService>()) {
        debugPrint('⚠️ SubscriptionService가 등록되어 있지 않음, 등록 시도...');
        getIt.registerLazySingleton<SubscriptionService>(() => SubscriptionService());
      }

      _subscriptionService = getIt<SubscriptionService>();
      debugPrint('✅ 디버그 패널: 구독 서비스 초기화 성공');

      // 구독 상태 변경 모니터링
      _subscriptionStreamSubscription = _subscriptionService.subscriptionStatusStream.listen((_) {
        // 상태가 변경되면 UI 갱신
        if (mounted) {
          setState(() {
            debugPrint('🔄 디버그 패널: 구독 상태 변경 감지됨');
          });
        }
      });
    } catch (e) {
      debugPrint('❌ 디버그 패널: 구독 서비스 초기화 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 프로덕션 환경에서는 표시하지 않음
    if (_appConfig.isProduction || !_featureFlags.showDebugPanel) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? 300 : 40,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목 바
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade800,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(8),
                  bottom: _isExpanded ? Radius.zero : Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🛠️ 디버그 패널 (내부 테스트용)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          
          // 패널 내용
          if (_isExpanded)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('환경 정보'),
                    _buildInfoRow('모드', _appConfig.environment.toString()),
                    _buildInfoRow('테스트 모드', _appConfig.isTestMode.toString()),
                    _buildInfoRow('광고 활성화', _appConfig.enableAds.toString()),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle('구독 상태'),
                    _buildInfoRow('현재 상태', _subscriptionService.status.toString()),
                    _buildInfoRow('프리미엄', _subscriptionService.isPremium.toString()),
                    _buildInfoRow('남은 크레딧', _subscriptionService.remainingCredits.toString()),
                    _buildInfoRow('사용 중인 AI 모델', _subscriptionService.getCurrentModel()),
                    
                    const SizedBox(height: 16),
                    _buildSectionTitle('테스트 기능'),
                    _buildActionRow(
                      '프리미엄 활성화',
                      () async {
                        await _subscriptionService.activateTestSubscription(isPremium: true);
                        setState(() {});
                      },
                    ),
                    _buildActionRow(
                      '기본 구독 활성화',
                      () async {
                        await _subscriptionService.activateTestSubscription(isPremium: false);
                        setState(() {});
                      },
                    ),
                    _buildActionRow(
                      '무료 상태로 초기화',
                      () async {
                        await _subscriptionService.reset();
                        setState(() {});
                      },
                    ),
                    _buildActionRow(
                      '크레딧 추가 (+5)',
                      () async {
                        await _subscriptionService.addFreeCredits(5);
                        setState(() {});
                      },
                    ),
                    _buildActionRow(
                      'API 키 정보 보기',
                      () async {
                        _showApiKeyDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // 섹션 제목 위젯
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
  
  // 정보 행 위젯
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 액션 행 위젯
  Widget _buildActionRow(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 30),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('실행'),
          ),
        ],
      ),
    );
  }
  
  // API 키 정보 대화상자
  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 키 정보'),
        content: FutureBuilder<String?>(
          future: getApiKey(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            
            final apiKey = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('API 키: ${apiKey ?? '없음'}'),
                const SizedBox(height: 8),
                const Text('🔒 이 정보는 개발 목적으로만 사용하세요'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
  
  // API 키 가져오기
  Future<String?> getApiKey() async {
    try {
      // 여러 경로를 통해 API 키 확인 시도
      final apiKey = await getIt<SubscriptionService>()
          .getCurrentModel(); // 실제로는 API 키가 아닌 모델 ID
      return apiKey;
    } catch (e) {
      debugPrint('API 키 가져오기 오류: $e');
      return null;
    }
  }

  // 구독 스트림 구독 관리용 변수
  StreamSubscription? _subscriptionStreamSubscription;

  @override
  void dispose() {
    // 구독 취소
    _subscriptionStreamSubscription?.cancel();
    super.dispose();
  }
}
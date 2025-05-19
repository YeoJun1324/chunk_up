// lib/presentation/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/core/services/subscription_service.dart';
import 'package:chunk_up/core/services/ad_service.dart';
import 'package:chunk_up/core/constants/subscription_constants.dart';
import 'package:chunk_up/domain/models/subscription_plan.dart' as domain;
import 'package:chunk_up/di/service_locator.dart';
import 'package:chunk_up/data/services/storage/local_storage_service.dart'; // StorageService 의존성 추가

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // late 대신 nullable로 선언하여 초기화 실패 시 null 상태 허용
  SubscriptionService? _subscriptionService;
  AdService? _adService;

  bool _isLoading = false;
  String _errorMessage = '';
  bool _servicesInitialized = false;

  // 서비스 초기화 실패 시 사용할 임시 기본 상태
  final domain.SubscriptionStatus _fallbackStatus = domain.SubscriptionStatus.defaultFree();
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  void _initializeServices() {
    try {
      // 서비스가 등록되었는지 먼저 확인
      if (!getIt.isRegistered<SubscriptionService>()) {
        // 서비스가 없으면 직접 등록 시도
        debugPrint('SubscriptionService가 등록되어 있지 않습니다. 등록 시도...');
        try {
          // 기본 생성자를 사용 (storageService 파라미터 없음)
          getIt.registerLazySingleton<SubscriptionService>(() => SubscriptionService());
          debugPrint('SubscriptionService 등록 성공!');
        } catch (e) {
          debugPrint('SubscriptionService 등록 실패: $e');
          throw Exception('SubscriptionService 등록 실패: $e');
        }
      }

      if (!getIt.isRegistered<AdService>()) {
        debugPrint('AdService가 등록되어 있지 않습니다. 등록 시도...');
        try {
          getIt.registerLazySingleton<AdService>(() => AdService());
          debugPrint('AdService 등록 성공!');
        } catch (e) {
          debugPrint('AdService 등록 실패: $e');
          throw Exception('AdService 등록 실패: $e');
        }
      }

      _subscriptionService = getIt<SubscriptionService>();
      _adService = getIt<AdService>();

      // AdService 초기화 (null-safety 처리)
      _adService?.initialize();

      // 초기화 성공
      setState(() {
        _servicesInitialized = true;
      });
    } catch (e) {
      debugPrint('서비스 초기화 오류: $e');
      setState(() {
        _errorMessage = '서비스 초기화 중 오류가 발생했습니다: $e\n\n개발자 정보: GetIt에 서비스가 등록되어 있지 않습니다.';
        _servicesInitialized = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구독 플랜'),
        backgroundColor: Colors.orange,
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (!_servicesInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage.isEmpty ? '서비스를 초기화하는 중입니다...' : _errorMessage),
            const SizedBox(height: 24),
            if (_errorMessage.isNotEmpty)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('돌아가기'),
              ),
          ],
        ),
      );
    }
    
    // 서비스가 초기화되지 않았을 경우 대비
    return StreamBuilder<domain.SubscriptionStatus>(
      stream: _subscriptionService?.subscriptionStatusStream,
      initialData: _subscriptionService?.currentStatus ?? _fallbackStatus,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('구독 상태를 불러오는 중 오류가 발생했습니다: ${snapshot.error}'),
          );
        }
        
        final currentStatus = snapshot.data ?? _subscriptionService?.currentStatus ?? _fallbackStatus;
        final currentPlan = domain.SubscriptionPlan.fromType(currentStatus.subscriptionType);
        
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 현재 구독 정보
                  _buildCurrentSubscriptionCard(currentStatus, currentPlan),
                  
                  const SizedBox(height: 24),
                  
                  // 구독 플랜 옵션들
                  const Text(
                    '구독 플랜 선택',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 플랜 카드들
                  _buildPlanCard(domain.SubscriptionPlan.free, currentStatus),
                  const SizedBox(height: 12),
                  _buildPlanCard(domain.SubscriptionPlan.basic, currentStatus),
                  const SizedBox(height: 12),
                  _buildPlanCard(domain.SubscriptionPlan.premium, currentStatus),
                  
                  const SizedBox(height: 24),
                  
                  // 무료 플랜 추가 생성 옵션 (광고 시청)
                  if (currentStatus.subscriptionType == domain.SubscriptionType.free)
                    ElevatedButton.icon(
                      onPressed: (_adService?.isRewardedAdLoaded ?? false) ? _watchAdForFreeGeneration : null,
                      icon: const Icon(Icons.video_library),
                      label: const Text('광고 시청하고 1회 생성 추가하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // 구독 복원 버튼
                  TextButton(
                    onPressed: _isLoading ? null : _restorePurchases,
                    child: const Text('구독 복원'),
                  ),
                  
                  if (_errorMessage.isNotEmpty) 
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // 주의사항 및 설명
                  const SizedBox(height: 24),
                  const Text(
                    '주의사항:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 구독은 1개월 단위로 자동 갱신됩니다.\n'
                    '• 갱신 24시간 이전에 해지하지 않으면 자동으로 결제됩니다.\n'
                    '• 결제는 iTunes 또는 Google Play 계정으로 청구됩니다.\n'
                    '• 구독은 앱스토어나 구글플레이 계정 설정에서 관리할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // 로딩 인디케이터
            if (_isLoading)
              Container(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildCurrentSubscriptionCard(domain.SubscriptionStatus status, domain.SubscriptionPlan currentPlan) {
    final expiryText = status.expiryDate != null 
        ? '만료일: ${_formatDate(status.expiryDate!)}'
        : '';
    
    final remainingGenerations = currentPlan.generationLimit - status.generationCount;
    
    return Card(
      elevation: 4,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.orange.shade900.withOpacity(0.3) // 다크 모드에서는 어두운 오렌지 배경
          : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    currentPlan.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (status.subscriptionType != domain.SubscriptionType.free && status.expiryDate != null)
                  Text(
                    expiryText,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.orange.shade300 // 다크 모드에서는 밝은 오렌지
                          : Colors.orange.shade800,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '이번 달 남은 생성 횟수: $remainingGenerations/${currentPlan.generationLimit}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                shadows: Theme.of(context).brightness == Brightness.dark
                    ? [Shadow(color: Colors.black, blurRadius: 2)] // 다크 모드에서는 텍스트 가독성을 위해 그림자 추가
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: remainingGenerations / currentPlan.generationLimit,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800 // 다크 모드에서는 더 어두운 배경색
                  : Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.orange.shade300 // 다크 모드에서는 밝은 오렌지
                    : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '현재 사용 중인 AI 모델: ${_getModelDisplayName(currentPlan.aiModel)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500, // 약간 더 두껍게
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                shadows: Theme.of(context).brightness == Brightness.dark
                    ? [Shadow(color: Colors.black, blurRadius: 1.5)] // 다크 모드에서는 텍스트 가독성을 위해 그림자 추가
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '단어 범위: ${currentPlan.wordMinLimit}~${currentPlan.wordMaxLimit}개',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500, // 약간 더 두껍게
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                shadows: Theme.of(context).brightness == Brightness.dark
                    ? [Shadow(color: Colors.black, blurRadius: 1.5)] // 다크 모드에서는 텍스트 가독성을 위해 그림자 추가
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlanCard(domain.SubscriptionPlan plan, domain.SubscriptionStatus currentStatus) {
    final isCurrentPlan = plan.type == currentStatus.subscriptionType;
    
    return Card(
      elevation: isCurrentPlan ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentPlan ? Colors.orange : Colors.grey.shade300,
          width: isCurrentPlan ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    plan.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            _buildPlanFeature(
              'AI 모델', 
              _getModelDisplayName(plan.aiModel)
            ),
            _buildPlanFeature(
              '월 출력 제한', 
              '${plan.generationLimit}회'
            ),
            _buildPlanFeature(
              '단어 범위', 
              '${plan.wordMinLimit}~${plan.wordMaxLimit}개'
            ),
            _buildPlanFeature(
              '광고', 
              plan.hasAds ? '있음' : '없음'
            ),
            _buildPlanFeature(
              '테스트 기능', 
              plan.allowsTest ? '사용 가능' : '사용 불가'
            ),
            _buildPlanFeature(
              'PDF 내보내기',
              plan.allowsPdfExport ? '사용 가능' : '사용 불가'
            ),
            _buildPlanFeature(
              '캐릭터 생성',
              plan.allowsCharacterCreation ? '사용 가능' : '사용 불가'
            ),
            
            const SizedBox(height: 16),
            
            // 구독 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan || _isLoading 
                    ? null 
                    : () => _subscribeToPlan(plan.type),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Text(
                  isCurrentPlan ? '현재 사용 중' : '구독하기',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlanFeature(String name, String value) {
    // 기능이 사용 불가한지 확인
    final bool isNotAvailable = value == '사용 불가' || value == '있음';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isNotAvailable ? Icons.cancel : Icons.check_circle_outline,
            size: 16,
            color: isNotAvailable ? Colors.red : Colors.green
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isNotAvailable ? Colors.red.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 구독 플랜 구매
  Future<void> _subscribeToPlan(domain.SubscriptionType planType) async {
    if (_subscriptionService == null) {
      setState(() {
        _errorMessage = '서비스가 초기화되지 않았습니다. 앱을 다시 시작해주세요.';
      });
      return;
    }

    if (planType == domain.SubscriptionType.free) {
      // 무료 플랜은 구매 필요 없음
      setState(() => _errorMessage = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('무료 플랜으로 전환되었습니다')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _subscriptionService!.purchaseSubscription(planType);
    } catch (e) {
      setState(() {
        _errorMessage = '구독 처리 중 오류가 발생했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 구독 복원
  Future<void> _restorePurchases() async {
    if (_subscriptionService == null) {
      setState(() {
        _errorMessage = '서비스가 초기화되지 않았습니다. 앱을 다시 시작해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _subscriptionService!.restorePurchases();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구독 복원이 요청되었습니다')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = '구독 복원 중 오류가 발생했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 광고 시청하고 무료 생성 추가
  Future<void> _watchAdForFreeGeneration() async {
    if (_adService == null || _subscriptionService == null) {
      setState(() {
        _errorMessage = '서비스가 초기화되지 않았습니다. 앱을 다시 시작해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _adService!.showRewardedAd(
        onRewarded: () async {
          await _subscriptionService!.addRewardedGeneration();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('축하합니다! 무료 생성 1회가 추가되었습니다')),
            );
          }
        },
        onFailed: () {
          if (mounted) {
            setState(() {
              _errorMessage = '광고 시청 중 오류가 발생했습니다';
            });
          }
        },
      );

      if (!result) {
        setState(() {
          _errorMessage = '현재 광고를 불러올 수 없습니다. 나중에 다시 시도해주세요.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '광고 시청 중 오류가 발생했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  /// 날짜 포맷 유틸리티
  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
  
  /// AI 모델 표시명 변환
  String _getModelDisplayName(String modelId) {
    if (modelId == SubscriptionConstants.basicAiModel) {
      return 'Claude 3.5 Haiku (기본)';
    } else if (modelId == SubscriptionConstants.premiumAiModel) {
      return 'Claude 3.7 Sonnet (고급)';
    } else if (modelId == SubscriptionConstants.freeAiModel) {
      return 'Claude 3 Haiku (무료)';
    }
    return modelId;
  }
}
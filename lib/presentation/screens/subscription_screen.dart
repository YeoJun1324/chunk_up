// lib/presentation/screens/subscription_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chunk_up/data/services/subscription/subscription_service.dart';
import 'package:chunk_up/data/services/ads/ad_service.dart';
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

  // 실제 크레딧 수를 관리하는 서비스
  SubscriptionService? _directSubscriptionService;
  
  // 구독 스트림 구독 관리용 변수
  StreamSubscription? _subscriptionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    // 구독 취소
    _subscriptionStreamSubscription?.cancel();
    super.dispose();
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
      _directSubscriptionService = getIt<SubscriptionService>();
      _adService = getIt<AdService>();

      // AdService 초기화 (null-safety 처리)
      _adService?.initialize();

      // 초기화 성공
      setState(() {
        _servicesInitialized = true;
      });

      // 구독 상태 변경 이벤트 리스닝 (UI 업데이트를 위함)
      _subscriptionStreamSubscription = _subscriptionService?.subscriptionStatusStream.listen((_) {
        if (mounted) setState(() {});
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
                  _buildPlanCard(domain.SubscriptionPlan.premium, currentStatus),
                  
                  const SizedBox(height: 24),
                  
                  
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
                    '• 구독은 구글플레이 계정 설정에서 관리할 수 있습니다.',
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
            // 무료 크레딧 또는 이번 달 남은 생성 횟수 표시
            currentPlan.type == domain.SubscriptionType.free
              ? Builder(
                  builder: (context) {
                    // 실제 남은 크레딧 수를 가져옴
                    final int realCredits = _directSubscriptionService?.remainingCredits ?? remainingGenerations;

                    // 유료 구독 상태인 경우 해당 플랜의 크레딧 표시
                    final isPaid = _directSubscriptionService?.isPaid ?? false;
                    final displayText = isPaid
                        ? '월간 크레딧: 100개'
                        : '평생 무료 생성: ${5 - (_directSubscriptionService?.remainingGenerations ?? 0)}회 사용';

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.credit_card, size: 20, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          displayText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.green.shade300  // 다크 모드에서 밝은 녹색
                                    : Colors.green.shade700) // 라이트 모드에서 어두운 녹색
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87),
                            shadows: Theme.of(context).brightness == Brightness.dark
                                ? [Shadow(color: Colors.black, blurRadius: 2)]
                                : null,
                          ),
                        ),
                      ],
                    );
                  }
                )
              : Text(
                  // Premium은 100개 크레딧 제공
                  currentPlan.type == domain.SubscriptionType.premium
                      ? '월간 크레딧: ${status.remainingCredits}/100개'
                      : '평생 무료 생성: ${status.generationCount}/5회 사용',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: currentPlan.type != domain.SubscriptionType.free
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.green.shade300  // 다크 모드에서 밝은 녹색
                            : Colors.green.shade700) // 라이트 모드에서 어두운 녹색
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87),
                    shadows: Theme.of(context).brightness == Brightness.dark
                        ? [Shadow(color: Colors.black, blurRadius: 2)] // 다크 모드에서는 텍스트 가독성을 위해 그림자 추가
                        : null,
                  ),
                ),
            const SizedBox(height: 8),
            // Premium 플랜은 크레딧 진행 표시줄, 무료 플랜은 실제 남은 비율 표시
            currentPlan.type != domain.SubscriptionType.free
                ? LinearProgressIndicator(
                    value: status.remainingCredits / 100.0, // 100개 중 남은 크레딧 비율
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800 // 다크 모드에서는 더 어두운 배경색
                        : Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade300 // 다크 모드에서는 밝은 파란색
                          : Colors.blue.shade600, // 라이트 모드에서는 어두운 파란색
                    ),
                  )
                : LinearProgressIndicator(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사용 가능한 AI 모델:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    shadows: Theme.of(context).brightness == Brightness.dark
                        ? [Shadow(color: Colors.black, blurRadius: 1.5)]
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                ..._getAvailableModels(currentPlan.type).map((model) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, size: 16, color: Colors.orange),
                        Text(
                          model,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              ],
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (plan.discountPrice != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '출시 3달간 할인!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            plan.price,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade800,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              plan.discountPrice!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
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
              plan.allowsModelSelection ? '2개 모델 선택 가능' : 'Gemini Flash'
            ),
            _buildPlanFeature(
              plan.type == domain.SubscriptionType.premium ? '월 크레딧' : '평생 생성 제한', 
              plan.type == domain.SubscriptionType.premium 
                  ? '${plan.creditLimit} 크레딧' 
                  : '${plan.generationLimit}회 (평생)'
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
            _buildPlanFeature(
              '시리즈 생성/편집',
              plan.allowsSeries ? '사용 가능' : '사용 불가'
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

    // 현재 구독 타입 확인
    final currentStatus = _subscriptionService!.currentStatus;
    final currentPlan = domain.SubscriptionPlan.fromType(currentStatus.subscriptionType);

    // 상위 구독에서 하위 구독으로 전환하려는 경우 메시지 표시
    if (_isDowngradeAttempt(currentStatus.subscriptionType, planType)) {
      setState(() => _errorMessage = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('상위 구독을 이용중입니다.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 무료 플랜은 결제 필요 없음
    if (planType == domain.SubscriptionType.free) {
      await _subscriptionService!.reset();
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
      // 구매 진행 시도
      await _subscriptionService!.purchaseSubscription(planType);

      // 구매 완료 또는 구매 처리 후 메시지 표시
      // 실제 구매가 완료되었는지 여부는 subscriptionStatusStream을 통해 확인됨
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${domain.SubscriptionPlan.fromType(planType).name} 구독 신청이 진행됩니다.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
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

  /// 상위 구독에서 하위 구독으로 전환하려는 시도인지 확인
  bool _isDowngradeAttempt(domain.SubscriptionType current, domain.SubscriptionType target) {
    // 구독 등급: premium > free
    if (current == domain.SubscriptionType.premium) {
      // 프리미엄에서 무료로 가려는 경우
      return target == domain.SubscriptionType.free;
    }
    // 무료에서는 다운그레이드가 없음
    return false;
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
          // 보상형 광고는 무료 사용자에게만 제공되며, 평생 5회 제한이므로 추가 불가
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('무료 생성은 평생 5회로 제한됩니다. 프리미엄을 구독해주세요!')),
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
  
  /// AI 모델 표시명 변환 - 오직 Gemini만 사용
  String _getModelDisplayName(String modelId) {
    return 'Gemini 2.5 Flash';
  }

  /// 플랜별 사용 가능한 AI 모델 목록
  List<String> _getAvailableModels(domain.SubscriptionType planType) {
    switch (planType) {
      case domain.SubscriptionType.free:
        return ['Gemini 2.5 Flash (1 크레딧)'];
      case domain.SubscriptionType.premium:
        return [
          'Gemini 2.5 Flash (1 크레딧)',
          'Claude Sonnet 4 (6 크레딧)',
        ];
      default:
        return ['알 수 없음'];
    }
  }
}
// lib/core/services/subscription_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/core/config/app_config.dart';
import 'package:chunk_up/core/config/feature_flags.dart';
import 'package:chunk_up/core/constants/subscription_constants.dart';
import 'package:chunk_up/domain/models/subscription_plan.dart' as domain;
import 'package:chunk_up/data/services/storage/local_storage_service.dart';

// 인앱 결제를 위한 패키지 임포트
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

/// 내부 테스트용 구독 상태 - 원래 모델과 충돌을 방지하기 위해 이름 변경
enum TestSubscriptionStatus {
  free,         // 무료
  premium,      // 프리미엄 구독
  testPremium,  // 테스트용 프리미엄
}

/// 내부 테스트용 간소화된 구독 서비스
/// 실제 인앱 결제 기능은 비활성화하고 테스트 모드로 동작
class SubscriptionService {
  // 싱글톤 인스턴스
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;

  // 의존성
  final AppConfig _appConfig = AppConfig();
  final FeatureFlags _featureFlags = FeatureFlags();
  final StorageService? _storageService; // 선택적 사용

  // 상태 변수
  TestSubscriptionStatus _currentStatus = TestSubscriptionStatus.free;
  // AI 모델 선택 관련 코드 삭제 - 오직 Gemini만 사용

  // status는 이미 아래에 정의되어 있음
  int _remainingCredits = 0; // 프리미엄 사용자의 크레디트
  int _generationCount = 0; // 무료 사용자의 생성 횟수
  DateTime? _subscriptionExpiryDate;
  DateTime _lastGenerationResetDate = DateTime.now();
  DateTime? _lastCreditResetDate;

  // 구독 상태 변경 이벤트를 위한 스트림 컨트롤러
  final _subscriptionStatusController = StreamController<domain.SubscriptionStatus>.broadcast();
  Stream<domain.SubscriptionStatus> get subscriptionStatusStream => _subscriptionStatusController.stream;

  // 외부 코드와의 호환성을 위한 속성
  domain.SubscriptionStatus? _currentExternalStatus;
  domain.SubscriptionStatus get currentStatus => _currentExternalStatus ?? domain.SubscriptionStatus.defaultFree();

  // 설정 키
  static const String _keySubscriptionStatus = 'subscription_status';
  static const String _keyCredits = 'remaining_credits';
  static const String _keyGenerationCount = 'generation_count';
  static const String _keyExpiryDate = 'subscription_expiry';
  static const String _keyLastGenerationReset = 'last_generation_reset';
  static const String _keyLastCreditReset = 'last_credit_reset';
  // static const String _keySelectedModel = 'selected_ai_model'; // 삭제

  // 내부 생성자
  SubscriptionService._internal() : _storageService = null {
    // 서비스 초기화
    _initializeAsync();
  }


  // Factory 생성자 (DI 방식)
  SubscriptionService.withStorage({
    required StorageService storageService,
  }) : _storageService = storageService {
    _initializeAsync();
  }
  
  // 비동기 초기화 시작
  void _initializeAsync() {
    // 비동기 초기화 실행
    _initialize().then((_) {
      debugPrint('✅ 구독 서비스 초기화 완료');
    }).catchError((error) {
      debugPrint('❌ 구독 서비스 초기화 오류: $error');
    });
  }

  /// 서비스 초기화
  Future<void> _initialize() async {
    // 테스트 모드 설정
    if (_featureFlags.enablePremiumFeatures) {
      _currentStatus = TestSubscriptionStatus.testPremium;
      _remainingCredits = SubscriptionConstants.premiumCreditLimit;
      _subscriptionExpiryDate = DateTime.now().add(const Duration(days: 365));
      _lastCreditResetDate = DateTime.now();

      // 외부 상태 생성 및 스트림 업데이트
      _updateExternalStatusAndNotify();

      debugPrint('👑 테스트 프리미엄 모드 활성화');

      // 인앱 결제 초기화는 테스트 모드에서도 필요
      await _initializeInAppPurchase();
      return;
    }

    // 일반 모드 - SharedPreferences에서 상태 로드
    try {
      final prefs = await SharedPreferences.getInstance();

      // 구독 상태 로드
      final statusStr = prefs.getString(_keySubscriptionStatus);
      if (statusStr != null) {
        final statusIndex = int.tryParse(statusStr);
        if (statusIndex != null && statusIndex >= 0 && statusIndex < TestSubscriptionStatus.values.length) {
          _currentStatus = TestSubscriptionStatus.values[statusIndex];
        }
      }

      // 남은 크레딧 및 생성 횟수 로드
      _remainingCredits = prefs.getInt(_keyCredits) ?? 0;
      _generationCount = prefs.getInt(_keyGenerationCount) ?? 0;
      
      // AI 모델 로드 제거 - 오직 Gemini만 사용
      
      // 리셋 날짜 로드
      final genResetStr = prefs.getString(_keyLastGenerationReset);
      if (genResetStr != null) {
        _lastGenerationResetDate = DateTime.parse(genResetStr);
      }
      
      final creditResetStr = prefs.getString(_keyLastCreditReset);
      if (creditResetStr != null) {
        _lastCreditResetDate = DateTime.parse(creditResetStr);
      }

      // 만료일 로드
      final expiryStr = prefs.getString(_keyExpiryDate);
      if (expiryStr != null) {
        _subscriptionExpiryDate = DateTime.parse(expiryStr);

        // 만료 확인
        if (_subscriptionExpiryDate!.isBefore(DateTime.now())) {
          _currentStatus = TestSubscriptionStatus.free;
          _subscriptionExpiryDate = null;
        }
      }

      // 외부 상태 생성 및 스트림 업데이트
      _updateExternalStatusAndNotify();

      // 월별/일별 리셋 확인
      _checkAndResetIfNeeded();
      
      debugPrint('💳 구독 상태 로드: $_currentStatus, 크레딧: $_remainingCredits, 생성횟수: $_generationCount');
    } catch (e) {
      debugPrint('⚠️ 구독 정보 로드 실패: $e');
      _currentStatus = TestSubscriptionStatus.free;
      _remainingCredits = 0;
      _generationCount = 0;

      // 외부 상태 생성 및 스트림 업데이트
      _updateExternalStatusAndNotify();
    }

    // 인앱 결제 초기화
    await _initializeInAppPurchase();
  }

  /// 내부 상태를 외부 SubscriptionStatus로 변환하여 스트림에 알림
  void _updateExternalStatusAndNotify() {
    // 내부 상태를 외부 상태 형식으로 변환
    domain.SubscriptionType externalType;
    switch (_currentStatus) {
      case TestSubscriptionStatus.premium:
      case TestSubscriptionStatus.testPremium:
        externalType = domain.SubscriptionType.premium;
        break;
      case TestSubscriptionStatus.free:
      default:
        externalType = domain.SubscriptionType.free;
        break;
    }

    // 외부 상태 객체 생성
    _currentExternalStatus = domain.SubscriptionStatus(
      subscriptionType: externalType,
      expiryDate: _subscriptionExpiryDate,
      remainingCredits: _remainingCredits,
      generationCount: _generationCount,
      lastGenerationResetDate: _lastGenerationResetDate,
      lastCreditResetDate: _lastCreditResetDate,
    );

    // 스트림 업데이트
    _subscriptionStatusController.add(_currentExternalStatus!);
  }
  
  // 상태 접근자
  TestSubscriptionStatus get status => _currentStatus;

  // 프리미엄 유료 구독 여부 확인
  bool get isPremium => _currentStatus == TestSubscriptionStatus.premium ||
                        _currentStatus == TestSubscriptionStatus.testPremium;
  bool get isPaid => isPremium; // 유료 구독 여부 (Premium만)
  bool get isFree => _currentStatus == TestSubscriptionStatus.free;

  // 남은 크레딧 수
  int get remainingCredits => _remainingCredits;
  
  // 무료 사용자의 남은 생성 횟수
  int get remainingGenerations => isFree ? 
    SubscriptionConstants.freeGenerationLimit - _generationCount : 0;
    
  DateTime? get expiryDate => _subscriptionExpiryDate;
  
  // AI 모델 관련 메서드 삭제 - 오직 Gemini만 사용

  // 청크 생성 가능 여부 확인 (크레디트 또는 생성 횟수)
  Future<bool> canGenerateChunk() async {
    // 테스트 모드에서 무제한 청크 생성이 활성화된 경우
    if (_featureFlags.unlimitedChunkGeneration) {
      debugPrint('♾️ 무제한 생성 모드 활성화 (테스트 기능)');
      return true;
    }
    
    // 월별/일별 리셋 확인
    _checkAndResetIfNeeded();
    
    if (isPremium) {
      // 프리미엄 사용자: 크레디트 확인 (모든 생성은 1 크레디트)
      final hasCredits = _remainingCredits >= 1;
      if (!hasCredits) {
        debugPrint('⚠️ 크레디트 부족: 필요 1개, 남은 $_remainingCredits개');
      }
      return hasCredits;
    } else {
      // 무료 사용자: 생성 횟수 확인
      final hasGenerations = _generationCount < SubscriptionConstants.freeGenerationLimit;
      if (!hasGenerations) {
        debugPrint('⚠️ 무료 생성 횟수를 모두 사용했습니다. 프리미엄 구독을 고려해주세요.');
      }
      return hasGenerations;
    }
  }
  
  // 청크 생성 시 크레디트/횟수 차감
  Future<bool> useGeneration() async {
    if (!(await canGenerateChunk())) {
      return false;
    }
    
    if (isPremium) {
      // 프리미엄 사용자: 크레디트 차감 (항상 1 크레디트)
      _remainingCredits -= 1;
      await _saveRemainingCredits();
      debugPrint('💸 Gemini 사용: 1 크레디트 차감 (남은 크레디트: $_remainingCredits)');
    } else {
      // 무료 사용자: 생성 횟수 증가
      _generationCount++;
      await _saveGenerationCount();
      debugPrint('📈 무료 생성 $_generationCount/${SubscriptionConstants.freeGenerationLimit}회 사용 (평생)');
    }
    
    _updateExternalStatusAndNotify();
    return true;
  }

  // 구독 확인 (테스트용)
  Future<bool> checkSubscription() async {
    // 테스트 모드
    if (_appConfig.isTestMode && _featureFlags.enablePremiumFeatures) {
      debugPrint('🧪 테스트 모드: 구독 활성화 상태');
      return true;
    }

    // 만료 확인
    if (_subscriptionExpiryDate != null &&
        _subscriptionExpiryDate!.isAfter(DateTime.now())) {
      return true;
    }

    return isPremium;
  }

  // 테스트 구독 활성화
  Future<bool> activateTestSubscription({bool isPremium = true}) async {
    if (!_appConfig.isTestMode) {
      debugPrint('⚠️ 프로덕션 환경에서 테스트 구독 활성화 시도');
      return false;
    }

    _currentStatus = isPremium
      ? TestSubscriptionStatus.testPremium
      : TestSubscriptionStatus.free;

    if (isPremium) {
      // 프리미엄 구독 설정
      _subscriptionExpiryDate = DateTime.now().add(const Duration(days: 30));
      _remainingCredits = SubscriptionConstants.premiumCreditLimit;
      _lastCreditResetDate = DateTime.now();
      await _saveSubscriptionStatus();
      await _saveRemainingCredits();
      await _saveCreditResetDate();
      debugPrint('⭐ 프리미엄 모드 활성화: ${SubscriptionConstants.premiumCreditLimit} 크레디트');
    } else {
      // 무료로 전환
      await reset();
    }

    // 외부 상태 업데이트 및 스트림 알림
    _updateExternalStatusAndNotify();

    debugPrint('✅ 테스트 ${isPremium ? "프리미엄" : "무료"} 계정으로 활성화');
    return true;
  }

  // 상태 저장
  Future<void> _saveSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySubscriptionStatus, _currentStatus.index.toString());

      if (_subscriptionExpiryDate != null) {
        await prefs.setString(
          _keyExpiryDate,
          _subscriptionExpiryDate!.toIso8601String()
        );
      }
    } catch (e) {
      debugPrint('⚠️ 구독 상태 저장 실패: $e');
    }
  }

  // 크레딧 저장
  Future<void> _saveRemainingCredits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyCredits, _remainingCredits);
    } catch (e) {
      debugPrint('⚠️ 크레딧 저장 실패: $e');
    }
  }

  // 리셋 (테스트용)
  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySubscriptionStatus);
      await prefs.remove(_keyCredits);
      await prefs.remove(_keyExpiryDate);
      await prefs.remove(_keyGenerationCount);
      await prefs.remove(_keyLastGenerationReset);
      await prefs.remove(_keyLastCreditReset);
      // AI 모델 설정 제거

      _currentStatus = TestSubscriptionStatus.free;
      _remainingCredits = 0;
      _generationCount = 0;
      _subscriptionExpiryDate = null;
      _lastGenerationResetDate = DateTime.now();
      _lastCreditResetDate = null;
      // AI 모델 초기화 제거

      debugPrint('💳 무료 계정으로 초기화: 평생 생성 횟수 $_generationCount/${SubscriptionConstants.freeGenerationLimit}');

      // 외부 상태 업데이트 및 스트림 알림
      _updateExternalStatusAndNotify();

      debugPrint('🔄 구독 상태 리셋 완료');
    } catch (e) {
      debugPrint('⚠️ 구독 상태 리셋 실패: $e');
    }
  }

  // 현재 사용 중인 AI 모델 가져오기 - 항상 Gemini 2.5 Flash
  String getCurrentModel() {
    debugPrint('🤖 현재 AI 모델: Gemini 2.5 Flash (1 크레디트)');
    return 'gemini-2.5-flash-preview-05-20';
  }

  // 리소스 해제
  void dispose() {
    _purchaseSubscription?.cancel();
    _subscriptionStatusController.close();
  }

  // 테스트 기능: 크레디트 추가
  Future<void> addCredits(int count) async {
    if (!_appConfig.isTestMode) {
      debugPrint('⚠️ 프로덕션 환경에서 크레디트 추가 시도');
      return;
    }

    _remainingCredits += count;
    await _saveRemainingCredits();
    _updateExternalStatusAndNotify();
    debugPrint('✅ $count 크레디트 추가됨. 현재: $_remainingCredits');
  }
  
  // 월별 리셋 확인 및 처리
  void _checkAndResetIfNeeded() {
    final now = DateTime.now();
    
    // 프리미엄 사용자의 월별 크레디트 리셋
    if (isPremium && _lastCreditResetDate != null) {
      final nextResetDate = DateTime(
        _lastCreditResetDate!.year,
        _lastCreditResetDate!.month + 1,
        1
      );
      
      if (now.isAfter(nextResetDate)) {
        _remainingCredits = SubscriptionConstants.premiumCreditLimit;
        _lastCreditResetDate = now;
        _saveRemainingCredits();
        _saveCreditResetDate();
        debugPrint('🔄 월별 크레디트 리셋: ${SubscriptionConstants.premiumCreditLimit} 크레디트');
      }
    }
    
    // 무료 사용자는 리셋 없음 - 평생 5개
  }
  
  // 저장 메서드들
  Future<void> _saveGenerationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyGenerationCount, _generationCount);
    } catch (e) {
      debugPrint('⚠️ 생성 횟수 저장 실패: $e');
    }
  }
  
  Future<void> _saveGenerationResetDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastGenerationReset, _lastGenerationResetDate.toIso8601String());
    } catch (e) {
      debugPrint('⚠️ 생성 리셋 날짜 저장 실패: $e');
    }
  }
  
  Future<void> _saveCreditResetDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastCreditResetDate != null) {
        await prefs.setString(_keyLastCreditReset, _lastCreditResetDate!.toIso8601String());
      }
    } catch (e) {
      debugPrint('⚠️ 크레디트 리셋 날짜 저장 실패: $e');
    }
  }
  
  // AI 모델 저장 메서드 제거 - 오직 Gemini만 사용

  // 구독 관련 변수
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  bool _isStoreAvailable = false;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  /// 인앱 결제 초기화 - 서비스 초기화 시 호출되도록 추가
  Future<void> _initializeInAppPurchase() async {
    try {
      _isStoreAvailable = await _inAppPurchase.isAvailable();

      if (!_isStoreAvailable) {
        debugPrint('⚠️ 스토어를 사용할 수 없습니다.');
        return;
      }

      // 구독 상품 ID 목록 설정
      final Set<String> productIds = {
        SubscriptionConstants.premiumMonthlyProductId,
      };

      // 상품 정보 로드
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('⚠️ 찾을 수 없는 상품 ID: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      debugPrint('✅ 상품 정보 로드 완료: ${_products.length}개 상품');

      // 구매 업데이트 리스너 설정
      _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
        _listenToPurchaseUpdates,
        onDone: () {
          _purchaseSubscription?.cancel();
        },
        onError: (error) {
          debugPrint('🚨 구매 스트림 오류: $error');
        }
      );

    } catch (e) {
      debugPrint('🚨 인앱 결제 초기화 오류: $e');
    }
  }

  /// 구매 업데이트 처리
  void _listenToPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 구매 진행 중
        debugPrint('⌛ 구매 진행 중: ${purchaseDetails.productID}');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // 구매 오류
          debugPrint('🚨 구매 오류: ${purchaseDetails.error?.message}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
          // 구매 또는 복원 완료 - 구독 활성화
          await _handleSuccessfulPurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          // 구매 취소
          debugPrint('🚫 구매 취소됨: ${purchaseDetails.productID}');
        }

        // 거래 완료 처리
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
          debugPrint('✅ 구매 완료 처리: ${purchaseDetails.productID}');
        }
      }
    }
  }

  /// 성공적인 구매 처리
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    // 구독 유형 확인
    domain.SubscriptionType? subscriptionType;

    if (purchase.productID == SubscriptionConstants.premiumMonthlyProductId) {
      subscriptionType = domain.SubscriptionType.premium;
    }

    if (subscriptionType != null) {
      // 현재는 테스트 구독 활성화 사용, 실제 출시 시 구독 정보 저장 로직 구현
      await activateTestSubscription(isPremium: true);

      debugPrint('✅ 구독 활성화: ${subscriptionType.name}');
    }
  }

  /// 구독 구매 시작
  Future<void> purchaseSubscription(domain.SubscriptionType type) async {
    // 테스트 환경에서도 바로 구독 활성화를 하지 않고 시뮬레이션만 진행
    debugPrint('🧪 ${type.name} 플랜 구독 요청 받음');

    // 디버그 모드가 활성화된 경우에만 테스트 구독 활성화 (개발자 옵션)
    if (_appConfig.isTestMode && _featureFlags.isDebugMode) {
      debugPrint('🔧 개발자 모드에서 ${type.name} 플랜 구독 시뮬레이션');

      switch (type) {
        case domain.SubscriptionType.premium:
          await activateTestSubscription(isPremium: true);
          break;
        case domain.SubscriptionType.free:
        default:
          await reset();
          break;
      }
      return;
    }

    // 스토어 사용 가능 여부 확인
    if (!_isStoreAvailable) {
      debugPrint('⚠️ 스토어를 사용할 수 없습니다.');
      throw Exception('스토어를 사용할 수 없습니다. 인터넷 연결을 확인하세요.');
    }

    // 상품 ID 결정
    String productId;
    switch (type) {
      case domain.SubscriptionType.premium:
        productId = SubscriptionConstants.premiumMonthlyProductId;
        break;
      default:
        throw Exception('무료 플랜은 구독 구매가 필요하지 않습니다.');
    }

    // 상품 정보 찾기
    final productDetails = _products.firstWhere(
      (product) => product.id == productId,
      orElse: () => throw Exception('구독 상품을 찾을 수 없습니다: $productId')
    );

    // 구매 요청 생성
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
      applicationUserName: null,
    );

    // 구매 요청 시작
    try {
      final bool launchedPurchase = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam
      );

      debugPrint(launchedPurchase
        ? '🚀 구매 프로세스 시작: $productId'
        : '⚠️ 구매 프로세스 시작 실패: $productId');

    } catch (e) {
      debugPrint('🚨 구매 요청 중 오류 발생: $e');
      rethrow;
    }
  }

  // 구독 복원
  Future<void> restorePurchases() async {
    if (_appConfig.isTestMode) {
      debugPrint('🧪 테스트 환경에서 구독 복원 시뮬레이션');
      // 테스트 환경에서는 임의로 프리미엄 구독을 활성화
      await activateTestSubscription(isPremium: true);
      return;
    }

    // 스토어 사용 가능 여부 확인
    if (!_isStoreAvailable) {
      debugPrint('⚠️ 스토어를 사용할 수 없어 구독 복원을 진행할 수 없습니다.');
      throw Exception('스토어를 사용할 수 없습니다. 인터넷 연결을 확인하세요.');
    }

    try {
      debugPrint('🔄 구독 복원 시작...');
      // 구매 복원 시작
      await _inAppPurchase.restorePurchases();

      // 복원 결과는 purchaseStream의 이벤트로 전달됨
      // _listenToPurchaseUpdates 메서드에서 처리됨
      debugPrint('✅ 구독 복원 요청 완료');
    } catch (e) {
      debugPrint('🚨 구독 복원 중 오류 발생: $e');
      rethrow;
    }
  }

}

/// 유틸리티 헬퍼 함수들
extension SubscriptionServiceExtensions on SubscriptionService {
  /// 무료 출력 횟수가 남아있는지 확인
  bool get hasFreeGenerationsLeft {
    // 테스트 모드에서는 항상 true
    if (_featureFlags.unlimitedChunkGeneration) {
      debugPrint('🔄 무제한 청크 생성 모드: 항상 true 반환');
      return true;
    }

    // 프리미엄 사용자는 크레디트 확인
    if (isPremium) {
      debugPrint('🔄 프리미엄 사용자: 크레디트 $_remainingCredits개 남음');
      return _remainingCredits > 0;
    }

    // 무료 사용자는 생성 횟수 확인
    final hasGenerations = _generationCount < SubscriptionConstants.freeGenerationLimit;
    debugPrint('🔄 무료 생성 회수: $_generationCount/${SubscriptionConstants.freeGenerationLimit} (평생)');
    return hasGenerations;
  }

  /// 사용자가 테스트 기능을 사용할 수 있는지 확인
  bool get canUseTestFeature {
    // 테스트 모드에서는 항상 true
    if (_appConfig.isTestMode && _featureFlags.enablePremiumFeatures) {
      debugPrint('🧪 테스트 모드에서 테스트 기능 사용 가능');
      return true;
    }

    // 프리미엄 사용자에게만 허용
    final canUse = isPremium;

    debugPrint(canUse
      ? '✅ 프리미엄 사용자: 테스트 기능 사용 가능'
      : '❌ 무료 사용자: 테스트 기능 사용 불가');

    return canUse;
  }

  /// 사용자가 PDF 내보내기 기능을 사용할 수 있는지 확인
  bool get canUsePdfExport {
    // 테스트 모드에서는 항상 true
    if (_appConfig.isTestMode && _featureFlags.enablePremiumFeatures) {
      debugPrint('🧪 테스트 모드에서 PDF 내보내기 기능 사용 가능');
      return true;
    }

    // 프리미엄 사용자에게만 허용
    final canUse = isPremium;

    debugPrint(canUse
      ? '✅ 프리미엄 사용자: PDF 내보내기 기능 사용 가능'
      : '❌ 무료 사용자: PDF 내보내기 기능 사용 불가');

    return canUse;
  }

  /// 광고가 표시되어야 하는지 확인
  bool get shouldShowAds {
    // 테스트 모드 또는 광고 비활성화 모드
    if (!_appConfig.enableAds) {
      debugPrint('🚫 앱 설정에서 광고 비활성화됨');
      return false;
    }

    if (_featureFlags.enablePremiumFeatures && isPremium) {
      debugPrint('🚫 프리미엄 기능 활성화 - 광고 비활성화됨');
      return false;
    }

    // 프리미엄 사용자는 광고 없음, 무료 사용자는 광고 표시
    final shouldShow = _currentStatus == TestSubscriptionStatus.free;
    if (shouldShow) {
      debugPrint('📱 무료 사용자 - 광고 표시');
    } else {
      debugPrint('🚫 구독 사용자 - 광고 비활성화');
    }
    return shouldShow;
  }

  /// 캐릭터 생성 기능을 사용할 수 있는지 확인
  bool get canCreateCharacter {
    // 테스트 모드에서는 항상 true
    if (_appConfig.isTestMode && _featureFlags.enablePremiumFeatures) {
      debugPrint('🧪 테스트 모드에서 캐릭터 생성 기능 사용 가능');
      return true;
    }

    // 프리미엄 사용자에게만 허용
    final canUse = isPremium;

    debugPrint(canUse
      ? '✅ 프리미엄 사용자: 캐릭터 생성 기능 사용 가능'
      : '❌ 무료 사용자: 캐릭터 생성 기능 사용 불가');

    return canUse;
  }

  /// 단어 갯수 제한 확인
  int get minWordLimit => 5; // 모든 사용자 공통

  int get maxWordLimit {
    // 테스트 모드에서는 최대치
    if (_appConfig.isTestMode && _featureFlags.enablePremiumFeatures) {
      debugPrint('🧪 테스트 모드에서 단어 수 최대 제한 없음: 25개');
      return 25;
    }

    // 구독 유형에 따라 다른 제한
    int limit;
    switch (_currentStatus) {
      case TestSubscriptionStatus.premium:
      case TestSubscriptionStatus.testPremium:
        limit = SubscriptionConstants.premiumWordMaxLimit;
        debugPrint('📚 프리미엄 사용자: 단어 수 제한 $limit개');
        break;
      case TestSubscriptionStatus.free:
      default:
        limit = SubscriptionConstants.freeWordMaxLimit;
        debugPrint('📚 무료 사용자: 단어 수 제한 $limit개');
        break;
    }

    return limit;
  }
}
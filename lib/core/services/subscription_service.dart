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
  basic,        // 기본 구독
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

  // status는 이미 아래에 정의되어 있음
  int _remainingCredits = 5;
  DateTime? _subscriptionExpiryDate;

  // 구독 상태 변경 이벤트를 위한 스트림 컨트롤러
  final _subscriptionStatusController = StreamController<domain.SubscriptionStatus>.broadcast();
  Stream<domain.SubscriptionStatus> get subscriptionStatusStream => _subscriptionStatusController.stream;

  // 외부 코드와의 호환성을 위한 속성
  domain.SubscriptionStatus? _currentExternalStatus;
  domain.SubscriptionStatus get currentStatus => _currentExternalStatus ?? domain.SubscriptionStatus.defaultFree();

  // 설정 키
  static const String _keySubscriptionStatus = 'subscription_status';
  static const String _keyCredits = 'remaining_credits';
  static const String _keyExpiryDate = 'subscription_expiry';

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
      _remainingCredits = _appConfig.freeCreditsForTesters;
      _subscriptionExpiryDate = DateTime.now().add(const Duration(days: 365));

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

      // 남은 크레딧 로드
      _remainingCredits = prefs.getInt(_keyCredits) ?? 5;

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

      debugPrint('💳 구독 상태 로드: $_currentStatus, 남은 크레딧: $_remainingCredits');
    } catch (e) {
      debugPrint('⚠️ 구독 정보 로드 실패: $e');
      _currentStatus = TestSubscriptionStatus.free;
      _remainingCredits = 5;

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
      case TestSubscriptionStatus.basic:
        externalType = domain.SubscriptionType.basic;
        break;
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
      generationCount: isPremium ? 0 : 5 - _remainingCredits,
      lastGenerationResetDate: DateTime.now(),
    );

    // 스트림 업데이트
    _subscriptionStatusController.add(_currentExternalStatus!);
  }
  
  // 상태 접근자
  TestSubscriptionStatus get status => _currentStatus;

  // 프리미엄 또는 Basic 유료 구독 여부 확인
  bool get isPremium => _currentStatus == TestSubscriptionStatus.premium ||
                        _currentStatus == TestSubscriptionStatus.testPremium;
  bool get isBasic => _currentStatus == TestSubscriptionStatus.basic;
  bool get isPaid => isPremium || isBasic; // 유료 구독 여부 (Basic 또는 Premium)

  // 남은 크레딧 수
  // Basic은 60개, Premium은 100개, 무료는 기본 크레딧 사용
  int get remainingCredits {
    if (isPremium) return 100;
    if (isBasic) return 60;
    return _remainingCredits;
  }
  DateTime? get expiryDate => _subscriptionExpiryDate;

  // 크레딧 사용
  Future<bool> useCredit({int count = 1}) async {
    // 유료 구독자(Basic 또는 Premium)도 월간 크레딧 사용 가능
    if (isPaid) {
      // 월간 크레딧이 남아있는지 확인
      final monthlyCreditsLeft = isPremium ? 100 : 60; // 나중에 실제 사용량 추적 필요

      if (monthlyCreditsLeft > 0) {
        final planType = isPremium ? "프리미엄" : "베이직";
        debugPrint('✨ $planType 사용자: 월간 크레딧 사용 ($monthlyCreditsLeft개 남음)');
        return true;
      } else {
        debugPrint('⚠️ 이번 달 크레딧을 모두 사용했습니다.');
        return false;
      }
    }

    // 테스트 모드에서 무제한 청크 생성이 활성화된 경우
    if (_featureFlags.unlimitedChunkGeneration) {
      debugPrint('♾️ 무제한 크레딧 모드 활성화 (테스트 기능)');
      return true;
    }

    // 무료 사용자의 크레딧 확인
    if (_remainingCredits < count) {
      debugPrint('⚠️ 크레딧 부족: 필요 $count개, 남은 $_remainingCredits개');
      return false;
    }

    // 크레딧 차감
    _remainingCredits -= count;
    await _saveRemainingCredits();
    debugPrint('💸 크레딧 $count개 차감됨: 남은 개수 $_remainingCredits');
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
      : TestSubscriptionStatus.basic; // 기본(Basic) 구독으로 변경

    // 두 타입 모두 만료일 설정 (Basic도 유료 구독)
    _subscriptionExpiryDate = DateTime.now().add(const Duration(days: 30));

    await _saveSubscriptionStatus();

    // Basic 사용자는 제한된 크레딧, Premium은 무제한
    if (!isPremium) {
      _remainingCredits = SubscriptionConstants.basicGenerationLimit;
      await _saveRemainingCredits();
      debugPrint('🔄 Basic 구독 모드로 전환됨: 크레딧 ${SubscriptionConstants.basicGenerationLimit}개로 설정됨');
    } else {
      debugPrint('⭐ 프리미엄 모드 활성화: 무제한 크레딧');
    }

    // 외부 상태 업데이트 및 스트림 알림
    _updateExternalStatusAndNotify();

    debugPrint('✅ 테스트 ${isPremium ? "프리미엄" : "Basic"} 계정으로 활성화');
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

      _currentStatus = TestSubscriptionStatus.free;
      _remainingCredits = 5;
      _subscriptionExpiryDate = null;

      // API로 남은 크레딧 수 확인 메시지 표시
      debugPrint('💳 무료 계정으로 초기화: 크레딧 $_remainingCredits개 남음');

      // 외부 상태 업데이트 및 스트림 알림
      _updateExternalStatusAndNotify();

      debugPrint('🔄 구독 상태 리셋 완료');
    } catch (e) {
      debugPrint('⚠️ 구독 상태 리셋 실패: $e');
    }
  }

  // 현재 사용 중인 AI 모델 가져오기
  String getCurrentModel() {
    debugPrint('📊 현재 구독 상태: $_currentStatus');
    
    // 현재 구독 상태에 따라 모델 결정
    switch (_currentStatus) {
      case TestSubscriptionStatus.premium:
      case TestSubscriptionStatus.testPremium:
        final model = SubscriptionConstants.premiumAiModel; // Claude Sonnet 4
        debugPrint('🤖 프리미엄 모델 사용 중: $model (상태: $_currentStatus)');
        return model;

      case TestSubscriptionStatus.basic:
        final model = SubscriptionConstants.basicAiModel; // Claude 3.5 Haiku
        debugPrint('🤖 베이직 모델 사용 중: $model (상태: $_currentStatus)');
        return model;

      case TestSubscriptionStatus.free:
      default:
        final model = SubscriptionConstants.freeAiModel; // Claude 3 Haiku
        debugPrint('🤖 무료 모델 사용 중: $model (상태: $_currentStatus)');
        return model;
    }
  }

  // 리소스 해제
  void dispose() {
    _purchaseSubscription?.cancel();
    _subscriptionStatusController.close();
  }

  // 테스트 기능: 무료 크레딧 추가
  Future<void> addFreeCredits(int count) async {
    if (!_appConfig.isTestMode) {
      debugPrint('⚠️ 프로덕션 환경에서 크레딧 추가 시도');
      return;
    }

    _remainingCredits += count;
    await _saveRemainingCredits();
    _updateExternalStatusAndNotify();
    debugPrint('✅ $count 크레딧 추가됨. 현재: $_remainingCredits');
  }

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
        SubscriptionConstants.basicMonthlyProductId,
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

    if (purchase.productID == SubscriptionConstants.basicMonthlyProductId) {
      subscriptionType = domain.SubscriptionType.basic;
    } else if (purchase.productID == SubscriptionConstants.premiumMonthlyProductId) {
      subscriptionType = domain.SubscriptionType.premium;
    }

    if (subscriptionType != null) {
      // 현재는 테스트 구독 활성화 사용, 실제 출시 시 구독 정보 저장 로직 구현
      if (subscriptionType == domain.SubscriptionType.basic) {
        await activateTestSubscription(isPremium: false);
      } else {
        await activateTestSubscription(isPremium: true);
      }

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
        case domain.SubscriptionType.basic:
          await activateTestSubscription(isPremium: false);
          break;
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
      case domain.SubscriptionType.basic:
        productId = SubscriptionConstants.basicMonthlyProductId;
        break;
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

  // 리워드 광고로 무료 생성권 추가 (subscription_screen.dart와의 호환성을 위한 메서드)
  Future<void> addRewardedGeneration() async {
    _remainingCredits += 1;
    await _saveRemainingCredits();
    _updateExternalStatusAndNotify();
    debugPrint('💰 리워드 광고로 1회 생성권 추가됨. 현재: $_remainingCredits');
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

    // 유료 구독(Basic, Premium)은 월 100개 크레딧 제공
    if (isPaid) {
      // 월간 크레딧이 남아있는지 확인
      final monthlyCreditsLeft = 100; // 나중에 실제 사용량 추적 필요

      final planType = isPremium ? "프리미엄" : "베이직";
      debugPrint('🔄 $planType 사용자: 월간 크레딧 $monthlyCreditsLeft개 남음');
      return monthlyCreditsLeft > 0;
    }

    // 크레딧이 남아있는지 확인
    final hasCredits = remainingCredits > 0;
    debugPrint('🔄 남은 크레딧 확인: $remainingCredits개 ${hasCredits ? "있음" : "없음"}');
    return hasCredits;
  }

  /// 사용자가 테스트 기능을 사용할 수 있는지 확인
  bool get canUseTestFeature {
    // 테스트 모드에서는 항상 true
    if (_appConfig.isTestMode && _featureFlags.enablePremiumFeatures) {
      debugPrint('🧪 테스트 모드에서 테스트 기능 사용 가능');
      return true;
    }

    // 유료 구독자(Basic, Premium)에게 허용
    final canUse = isPaid; // 위에서 정의한 isPaid 속성 활용

    if (canUse) {
      if (_currentStatus == TestSubscriptionStatus.basic) {
        debugPrint('✅ Basic 구독 사용자: 테스트 기능 사용 가능');
      } else {
        debugPrint('✅ 프리미엄 사용자: 테스트 기능 사용 가능');
      }
    } else {
      debugPrint('❌ 무료 사용자: 테스트 기능 사용 불가');
    }

    return canUse;
  }

  /// 사용자가 PDF 내보내기 기능을 사용할 수 있는지 확인
  bool get canUsePdfExport {
    // 테스트 모드에서는 항상 true
    if (_appConfig.isTestMode && _featureFlags.enablePremiumFeatures) {
      debugPrint('🧪 테스트 모드에서 PDF 내보내기 기능 사용 가능');
      return true;
    }

    // 유료 구독에게만 허용 (Basic, Premium)
    final canUse = isPaid; // 위에서 정의한 isPaid 속성 활용

    debugPrint(canUse
      ? '✅ 유료 구독 사용자: PDF 내보내기 기능 사용 가능'
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

    // 무료 사용자는 캐릭터 생성 불가 (Basic, Premium만 가능)
    final canUse = isPaid; // 위에서 정의한 isPaid 속성 활용

    debugPrint(canUse
      ? '✅ 유료 구독 사용자: 캐릭터 생성 기능 사용 가능'
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
      case TestSubscriptionStatus.basic:
        limit = SubscriptionConstants.basicWordMaxLimit;
        debugPrint('📚 기본 구독 사용자: 단어 수 제한 $limit개');
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
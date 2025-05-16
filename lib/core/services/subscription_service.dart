// lib/core/services/subscription_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:chunk_up/core/constants/subscription_constants.dart';
import 'package:chunk_up/domain/models/subscription_plan.dart';
import 'package:chunk_up/data/services/storage/local_storage_service.dart';

/// 구독 서비스
/// 인앱 구매, 구독 상태 관리, 사용량 제한 등을 처리
class SubscriptionService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final StorageService _storageService;
  
  // 구독 상태 변경 이벤트를 위한 스트림 컨트롤러
  final _subscriptionStatusController = StreamController<SubscriptionStatus>.broadcast();
  Stream<SubscriptionStatus> get subscriptionStatusStream => _subscriptionStatusController.stream;
  
  // 구독 상품 정보
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;
  
  // 현재 구독 상태
  SubscriptionStatus _currentStatus = SubscriptionStatus.defaultFree();
  SubscriptionStatus get currentStatus => _currentStatus;
  
  // 구독 구매 관련 스트림 구독
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  
  // 구독의 월간 리셋을 위한 타이머
  Timer? _monthlyResetTimer;
  
  SubscriptionService({
    required StorageService storageService,
  }) : _storageService = storageService {
    _initialize();
  }
  
  /// 서비스 초기화
  Future<void> _initialize() async {
    // 저장된 구독 상태 로드
    await _loadSubscriptionStatus();
    
    // 월간 리셋 타이머 설정
    _setupMonthlyResetTimer();
    
    // 인앱 구매 초기화
    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      debugPrint('❌ 인앱 구매를 사용할 수 없습니다.');
      _currentStatus = SubscriptionStatus.defaultFree();
      _subscriptionStatusController.add(_currentStatus);
      return;
    }
    
    // iOS에서 보류 중인 트랜잭션 완료
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }
    
    // 구독 상품 정보 로드
    await _loadProductDetails();
    
    // 구매 이벤트 리스너 설정
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (error) {
        debugPrint('⚠️ 구매 스트림 오류: $error');
      },
    );
  }
  
  /// 구독 상품 정보 로드
  Future<void> _loadProductDetails() async {
    try {
      final Set<String> productIds = {
        SubscriptionConstants.basicMonthlyProductId,
        SubscriptionConstants.premiumMonthlyProductId,
      };
      
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('⚠️ 찾을 수 없는 상품 ID: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      debugPrint('✅ 로드된 상품 수: ${_products.length}');
      
      for (final product in _products) {
        debugPrint('📦 상품 정보: ${product.id} - ${product.title} - ${product.price}');
      }
    } catch (e) {
      debugPrint('❌ 상품 정보 로드 중 오류: $e');
    }
  }
  
  /// 저장된 구독 상태 로드
  Future<void> _loadSubscriptionStatus() async {
    try {
      final statusJson = await _storageService.getString(SubscriptionConstants.subscriptionStatusKey);
      
      if (statusJson != null) {
        final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(
          jsonDecode(statusJson) as Map
        );
        _currentStatus = SubscriptionStatus.fromJson(jsonMap);
      } else {
        _currentStatus = SubscriptionStatus.defaultFree();
      }
      
      // 만료된 구독 확인 및 처리
      if (_currentStatus.subscriptionType != SubscriptionType.free &&
          _currentStatus.expiryDate != null &&
          _currentStatus.expiryDate!.isBefore(DateTime.now())) {
        // 구독이 만료된 경우 무료 플랜으로 변경
        _currentStatus = SubscriptionStatus.defaultFree();
        await _saveSubscriptionStatus();
      }
      
      // 월간 리셋 확인
      final now = DateTime.now();
      final lastReset = _currentStatus.lastGenerationResetDate;
      if (now.year > lastReset.year || now.month > lastReset.month) {
        // 새로운 달이 시작되었으므로 출력 횟수 리셋
        _currentStatus = SubscriptionStatus(
          subscriptionType: _currentStatus.subscriptionType,
          expiryDate: _currentStatus.expiryDate,
          generationCount: 0,
          lastGenerationResetDate: now,
        );
        await _saveSubscriptionStatus();
      }
      
      // 스트림을 통해 초기 상태 전달
      _subscriptionStatusController.add(_currentStatus);
    } catch (e) {
      debugPrint('❌ 구독 상태 로드 중 오류: $e');
      _currentStatus = SubscriptionStatus.defaultFree();
      _subscriptionStatusController.add(_currentStatus);
    }
  }
  
  /// 구독 상태 저장
  Future<void> _saveSubscriptionStatus() async {
    try {
      final jsonMap = _currentStatus.toJson();
      await _storageService.setString(
        SubscriptionConstants.subscriptionStatusKey,
        jsonEncode(jsonMap),
      );
    } catch (e) {
      debugPrint('❌ 구독 상태 저장 중 오류: $e');
    }
  }
  
  /// 월간 리셋 타이머 설정
  void _setupMonthlyResetTimer() {
    _monthlyResetTimer?.cancel();
    
    // 다음 달 1일 0시 계산
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final timeUntilNextMonth = nextMonth.difference(now);
    
    _monthlyResetTimer = Timer(timeUntilNextMonth, () {
      // 월간 리셋 수행
      _currentStatus = SubscriptionStatus(
        subscriptionType: _currentStatus.subscriptionType,
        expiryDate: _currentStatus.expiryDate,
        generationCount: 0,
        lastGenerationResetDate: DateTime.now(),
      );
      _saveSubscriptionStatus();
      _subscriptionStatusController.add(_currentStatus);
      
      // 다음 달을 위한 타이머 재설정
      _setupMonthlyResetTimer();
    });
  }
  
  /// 구매 이벤트 처리
  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('🔄 구매 진행 중...');
          break;
        
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // 영수증 검증 (서버 측에서 수행하는 것이 좋음)
          bool valid = await _verifyPurchase(purchaseDetails);
          
          if (valid) {
            // 구독 상태 업데이트
            await _processPurchase(purchaseDetails);
          } else {
            // 검증 실패 시 오류 처리
            debugPrint('❌ 구매 검증 실패');
          }
          break;
        
        case PurchaseStatus.error:
          debugPrint('❌ 구매 오류: ${purchaseDetails.error?.message}');
          break;
        
        case PurchaseStatus.canceled:
          debugPrint('🚫 구매 취소됨');
          break;
      }
      
      // Google Play 캐시 문제를 방지하기 위해 완료 처리
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  /// 구매 검증 (실제 구현에서는 서버측 검증이 필요)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: 서버 측 검증 구현 필요
    // 여기서는 단순 예시로 true 반환
    return true;
  }
  
  /// 구매 처리
  Future<void> _processPurchase(PurchaseDetails purchaseDetails) async {
    final String productId = purchaseDetails.productID;
    
    SubscriptionType? subscriptionType;
    if (productId == SubscriptionConstants.basicMonthlyProductId) {
      subscriptionType = SubscriptionType.basic;
    } else if (productId == SubscriptionConstants.premiumMonthlyProductId) {
      subscriptionType = SubscriptionType.premium;
    }
    
    if (subscriptionType != null) {
      // 만료 날짜 계산 (1개월 후)
      final now = DateTime.now();
      final expiryDate = DateTime(now.year, now.month + 1, now.day);
      
      // 구독 상태 업데이트
      _currentStatus = _currentStatus.updateSubscription(subscriptionType, expiryDate);
      await _saveSubscriptionStatus();
      _subscriptionStatusController.add(_currentStatus);
      
      debugPrint('✅ 구독 업데이트 성공: $subscriptionType');
    } else {
      debugPrint('⚠️ 알 수 없는 제품 ID: $productId');
    }
  }
  
  /// 구독 구매 시작
  Future<void> purchaseSubscription(SubscriptionType type) async {
    try {
      String productId;
      switch (type) {
        case SubscriptionType.basic:
          productId = SubscriptionConstants.basicMonthlyProductId;
          break;
        case SubscriptionType.premium:
          productId = SubscriptionConstants.premiumMonthlyProductId;
          break;
        default:
          debugPrint('❌ 무료 플랜은 구매할 수 없습니다');
          return;
      }
      
      // 상품 찾기
      final productDetails = _products.firstWhere(
        (product) => product.id == productId,
        orElse: () => throw Exception('상품을 찾을 수 없습니다: $productId'),
      );
      
      // 구매 요청
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );
      
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('🔄 구독 구매 요청 시작됨: $productId');
    } catch (e) {
      debugPrint('❌ 구독 구매 시작 중 오류: $e');
    }
  }
  
  /// 구독 복원
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('🔄 구독 복원 요청됨');
    } catch (e) {
      debugPrint('❌ 구독 복원 중 오류: $e');
    }
  }
  
  /// 출력 횟수 증가
  Future<void> incrementGenerationCount() async {
    _currentStatus = _currentStatus.incrementGenerationCount();
    await _saveSubscriptionStatus();
    _subscriptionStatusController.add(_currentStatus);
  }
  
  /// 리워드 광고로 무료 출력 추가
  Future<void> addRewardedGeneration() async {
    _currentStatus = _currentStatus.addRewardedGeneration();
    await _saveSubscriptionStatus();
    _subscriptionStatusController.add(_currentStatus);
  }
  
  /// 현재 AI 모델 가져오기
  String getCurrentAiModel() {
    final plan = SubscriptionPlan.fromType(_currentStatus.subscriptionType);
    return plan.aiModel;
  }
  
  /// 리소스 해제
  void dispose() {
    _purchaseSubscription?.cancel();
    _monthlyResetTimer?.cancel();
    _subscriptionStatusController.close();
  }
}

/// iOS 스토어킷 결제 큐 델리게이트
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}

/// 유틸리티 헬퍼 함수들
extension SubscriptionServiceExtensions on SubscriptionService {
  /// 무료 출력 횟수가 남아있는지 확인
  bool get hasFreeGenerationsLeft {
    if (_currentStatus.subscriptionType != SubscriptionType.free) {
      return true; // 유료 구독은 제한 없음
    }
    return _currentStatus.generationCount < SubscriptionConstants.freeGenerationLimit;
  }
  
  /// 사용자가 테스트 기능을 사용할 수 있는지 확인
  bool get canUseTestFeature {
    final plan = SubscriptionPlan.fromType(_currentStatus.subscriptionType);
    return plan.allowsTest;
  }
  
  /// 사용자가 PDF 내보내기 기능을 사용할 수 있는지 확인
  bool get canUsePdfExport {
    final plan = SubscriptionPlan.fromType(_currentStatus.subscriptionType);
    return plan.allowsPdfExport;
  }
  
  /// 광고가 표시되어야 하는지 확인
  bool get shouldShowAds {
    final plan = SubscriptionPlan.fromType(_currentStatus.subscriptionType);
    return plan.hasAds;
  }
  
  /// 단어 갯수 제한 확인
  int get minWordLimit {
    final plan = SubscriptionPlan.fromType(_currentStatus.subscriptionType);
    return plan.wordMinLimit;
  }
  
  int get maxWordLimit {
    final plan = SubscriptionPlan.fromType(_currentStatus.subscriptionType);
    return plan.wordMaxLimit;
  }
}
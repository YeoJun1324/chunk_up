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

// 내부 테스트를 위한 추가 임포트
// import 'package:in_app_purchase/in_app_purchase.dart'; // 테스트 시 주석 해제
// import 'package:in_app_purchase_android/in_app_purchase_android.dart'; // 테스트 시 주석 해제
// import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart'; // 테스트 시 주석 해제
// import 'package:in_app_purchase_storekit/store_kit_wrappers.dart'; // 테스트 시 주석 해제

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
  bool get isPremium => _currentStatus == TestSubscriptionStatus.premium ||
                        _currentStatus == TestSubscriptionStatus.testPremium;
  int get remainingCredits => isPremium ? 999 : _remainingCredits;
  DateTime? get expiryDate => _subscriptionExpiryDate;

  // 크레딧 사용
  Future<bool> useCredit() async {
    // 프리미엄 사용자는 크레딧 무제한
    if (isPremium) return true;

    // 테스트 모드에서 무제한 청크 생성이 활성화된 경우
    if (_featureFlags.unlimitedChunkGeneration) {
      debugPrint('♾️ 무제한 크레딧 모드 활성화');
      return true;
    }

    // 무료 사용자의 크레딧 확인
    if (_remainingCredits <= 0) {
      debugPrint('⚠️ 남은 크레딧 없음');
      return false;
    }

    // 크레딧 차감
    _remainingCredits--;
    await _saveRemainingCredits();
    debugPrint('💰 크레딧 사용: 남은 개수 $_remainingCredits');
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

    _currentStatus = isPremium ?
      TestSubscriptionStatus.testPremium : TestSubscriptionStatus.basic;

    _subscriptionExpiryDate = DateTime.now().add(const Duration(days: 30));
    await _saveSubscriptionStatus();

    // 외부 상태 업데이트 및 스트림 알림
    _updateExternalStatusAndNotify();

    debugPrint('✅ 테스트 ${isPremium ? "프리미엄" : "기본"} 구독 활성화');
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

      // 외부 상태 업데이트 및 스트림 알림
      _updateExternalStatusAndNotify();

      debugPrint('🔄 구독 상태 리셋 완료');
    } catch (e) {
      debugPrint('⚠️ 구독 상태 리셋 실패: $e');
    }
  }

  // 현재 사용 중인 AI 모델 가져오기
  String getCurrentModel() {
    switch (_currentStatus) {
      case TestSubscriptionStatus.premium:
      case TestSubscriptionStatus.testPremium:
        debugPrint('🤖 프리미엄 모델 사용 중: ${SubscriptionConstants.premiumAiModel}');
        return SubscriptionConstants.premiumAiModel;
      case TestSubscriptionStatus.basic:
        debugPrint('🤖 기본 모델 사용 중: ${SubscriptionConstants.basicAiModel}');
        return SubscriptionConstants.basicAiModel;
      case TestSubscriptionStatus.free:
      default:
        debugPrint('🤖 무료 모델 사용 중: ${SubscriptionConstants.freeAiModel}');
        return SubscriptionConstants.freeAiModel; // 수정: 무료 계정은 무료 모델 사용
    }
  }

  // 리소스 해제
  void dispose() {
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

  // 구독 구매 (subscription_screen.dart와의 호환성을 위한 메서드)
  Future<void> purchaseSubscription(domain.SubscriptionType type) async {
    // 테스트 환경에서는 즉시 구독 활성화
    if (_appConfig.isTestMode) {
      debugPrint('🧪 테스트 환경에서 ${type.name} 플랜 구독 시뮬레이션');

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

    // 테스트 환경이 아닌 경우 미구현 오류
    throw UnimplementedError('실제 구독 구매 기능은 테스트 빌드에서 비활성화되었습니다.');
  }

  // 구독 복원 (subscription_screen.dart와의 호환성을 위한 메서드)
  Future<void> restorePurchases() async {
    if (_appConfig.isTestMode) {
      debugPrint('🧪 테스트 환경에서 구독 복원 시뮬레이션');
      // 테스트 환경에서는 임의로 프리미엄 구독을 활성화
      await activateTestSubscription(isPremium: true);
      return;
    }

    // 테스트 환경이 아닌 경우 미구현 오류
    throw UnimplementedError('실제 구독 복원 기능은 테스트 빌드에서 비활성화되었습니다.');
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
      return true;
    }

    // 유료 구독은 제한 없음
    if (isPremium) {
      return true;
    }

    // 크레딧이 남아있는지 확인
    return remainingCredits > 0;
  }

  /// 사용자가 테스트 기능을 사용할 수 있는지 확인
  bool get canUseTestFeature {
    // 테스트 모드에서는 항상 true
    if (_appConfig.isTestMode) {
      return true;
    }

    // 프리미엄 사용자에게만 허용
    return _currentStatus == TestSubscriptionStatus.premium;
  }

  /// 사용자가 PDF 내보내기 기능을 사용할 수 있는지 확인
  bool get canUsePdfExport {
    // 테스트 모드에서는 항상 true
    if (_featureFlags.enablePremiumFeatures) {
      return true;
    }

    // 유료 구독에게만 허용
    return _currentStatus == TestSubscriptionStatus.premium ||
           _currentStatus == TestSubscriptionStatus.testPremium ||
           _currentStatus == TestSubscriptionStatus.basic;
  }

  /// 광고가 표시되어야 하는지 확인
  bool get shouldShowAds {
    // 테스트 모드 또는 광고 비활성화 모드
    if (!_appConfig.enableAds || _featureFlags.enablePremiumFeatures) {
      return false;
    }

    // 프리미엄 사용자는 광고 없음
    return _currentStatus == TestSubscriptionStatus.free;
  }

  /// 캐릭터 생성 기능을 사용할 수 있는지 확인
  bool get canCreateCharacter {
    // 테스트 모드에서는 항상 true
    if (_featureFlags.enablePremiumFeatures) {
      return true;
    }

    // 무료 사용자는 캐릭터 생성 불가
    return _currentStatus != TestSubscriptionStatus.free;
  }

  /// 단어 갯수 제한 확인
  int get minWordLimit => 5; // 모든 사용자 공통

  int get maxWordLimit {
    // 테스트 모드에서는 최대치
    if (_featureFlags.enablePremiumFeatures) {
      return 25;
    }

    // 구독 유형에 따라 다른 제한
    switch (_currentStatus) {
      case TestSubscriptionStatus.premium:
      case TestSubscriptionStatus.testPremium:
        return SubscriptionConstants.premiumWordMaxLimit;
      case TestSubscriptionStatus.basic:
        return SubscriptionConstants.basicWordMaxLimit;
      case TestSubscriptionStatus.free:
      default:
        return SubscriptionConstants.freeWordMaxLimit;
    }
  }
}
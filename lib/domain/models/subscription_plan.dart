// lib/domain/models/subscription_plan.dart
import 'package:chunk_up/core/constants/subscription_constants.dart';

/// 구독 플랜 타입 (enum)
enum SubscriptionType {
  free,
  premium
}

/// 구독 플랜 정보 클래스
class SubscriptionPlan {
  final SubscriptionType type;
  final String name;
  final String description;
  final String price;
  final String? discountPrice; // 할인 가격
  final String aiModel;
  final int creditLimit; // 월 크레딧 제한
  final int generationLimit; // 청크 생성 제한 (무료 사용자)
  final int wordMinLimit;
  final int wordMaxLimit;
  final bool hasAds;
  final bool allowsTest;
  final bool allowsPdfExport;
  final bool allowsCharacterCreation;
  final bool allowsSeries; // 시리즈 생성/편집 가능 여부
  final bool allowsModelSelection; // AI 모델 선택 가능 여부
  final String productId;

  const SubscriptionPlan({
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.aiModel,
    required this.creditLimit,
    required this.generationLimit,
    required this.wordMinLimit,
    required this.wordMaxLimit,
    required this.hasAds,
    required this.allowsTest,
    required this.allowsPdfExport,
    required this.allowsCharacterCreation,
    required this.allowsSeries,
    required this.allowsModelSelection,
    required this.productId,
  });
  
  /// 무료 플랜
  static const SubscriptionPlan free = SubscriptionPlan(
    type: SubscriptionType.free,
    name: 'FREE',
    description: '평생 5개 청크 생성',
    price: '무료',
    aiModel: SubscriptionConstants.freeAiModel,
    creditLimit: 0,
    generationLimit: SubscriptionConstants.freeGenerationLimit,
    wordMinLimit: SubscriptionConstants.freeWordMinLimit,
    wordMaxLimit: SubscriptionConstants.freeWordMaxLimit,
    hasAds: true,
    allowsTest: false,
    allowsPdfExport: false,
    allowsCharacterCreation: false,
    allowsSeries: false,
    allowsModelSelection: false,
    productId: SubscriptionConstants.freePlanId,
  );
  
  
  /// Premium 플랜
  static const SubscriptionPlan premium = SubscriptionPlan(
    type: SubscriptionType.premium,
    name: 'PREMIUM',
    description: '모든 기능 사용 가능',
    price: SubscriptionConstants.premiumMonthlyPrice,
    discountPrice: SubscriptionConstants.premiumMonthlyDiscountPrice,
    aiModel: SubscriptionConstants.premiumAiModel,
    creditLimit: SubscriptionConstants.premiumCreditLimit,
    generationLimit: 0, // 크레딧 기반이므로 무제한
    wordMinLimit: SubscriptionConstants.premiumWordMinLimit,
    wordMaxLimit: SubscriptionConstants.premiumWordMaxLimit,
    hasAds: false,
    allowsTest: true,
    allowsPdfExport: true,
    allowsCharacterCreation: true,
    allowsSeries: true,
    allowsModelSelection: true,
    productId: SubscriptionConstants.premiumMonthlyProductId,
  );
  
  /// 구독 타입으로 플랜 조회
  static SubscriptionPlan fromType(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.free:
        return free;
      case SubscriptionType.premium:
        return premium;
    }
  }
  
  /// 제품 ID로 플랜 조회
  static SubscriptionPlan? fromProductId(String productId) {
    if (productId == SubscriptionConstants.freePlanId) {
      return free;
    } else if (productId == SubscriptionConstants.premiumMonthlyProductId) {
      return premium;
    }
    return null;
  }
}

// AI 모델 관련 코드 삭제 - 오직 Gemini만 사용

/// 사용자의 구독 상태 클래스 (Freezed로 변환 예정)
class SubscriptionStatus {
  final SubscriptionType subscriptionType;
  final DateTime? expiryDate;
  final int remainingCredits; // 프리미엄 사용자의 남은 크레딧
  final int generationCount; // 무료 사용자의 생성 횟수
  final DateTime lastGenerationResetDate;
  final DateTime? lastCreditResetDate; // 크레딧 리셋 날짜
  
  const SubscriptionStatus({
    required this.subscriptionType,
    this.expiryDate,
    this.remainingCredits = 0,
    this.generationCount = 0,
    required this.lastGenerationResetDate,
    this.lastCreditResetDate,
  });
  
  /// 기본 무료 구독 상태
  factory SubscriptionStatus.defaultFree() {
    return SubscriptionStatus(
      subscriptionType: SubscriptionType.free,
      lastGenerationResetDate: DateTime.now(),
      remainingCredits: 0,
      generationCount: 0,
    );
  }
  
  /// 생성이 가능한지 확인
  bool get canGenerate {
    if (subscriptionType == SubscriptionType.premium) {
      return remainingCredits > 0;
    } else {
      final plan = SubscriptionPlan.fromType(subscriptionType);
      return generationCount < plan.generationLimit;
    }
  }
  
  // AI 모델 관련 메서드 제거 - 오직 Gemini만 사용
  
  /// 현재 구독이 유효한지 확인
  bool get isSubscriptionActive {
    if (subscriptionType == SubscriptionType.free) {
      return true; // 무료 플랜은 항상 유효
    }
    
    if (expiryDate == null) {
      return false;
    }
    
    return expiryDate!.isAfter(DateTime.now());
  }
  
  /// 크레디트 사용 (프리미엄 사용자)
  SubscriptionStatus useCredits(int amount) {
    if (subscriptionType != SubscriptionType.premium) {
      return this;
    }
    
    return SubscriptionStatus(
      subscriptionType: subscriptionType,
      expiryDate: expiryDate,
      remainingCredits: remainingCredits - amount,
      generationCount: generationCount,
      lastGenerationResetDate: lastGenerationResetDate,
      lastCreditResetDate: lastCreditResetDate,
    );
  }
  
  /// 출력 횟수 증가 (무료 사용자)
  SubscriptionStatus incrementGenerationCount() {
    return SubscriptionStatus(
      subscriptionType: subscriptionType,
      expiryDate: expiryDate,
      remainingCredits: remainingCredits,
      generationCount: generationCount + 1,
      lastGenerationResetDate: lastGenerationResetDate,
      lastCreditResetDate: lastCreditResetDate,
    );
  }
  
  /// 새로운 구독 상태로 업데이트
  SubscriptionStatus updateSubscription(SubscriptionType newType, DateTime? newExpiryDate) {
    final plan = SubscriptionPlan.fromType(newType);
    return SubscriptionStatus(
      subscriptionType: newType,
      expiryDate: newExpiryDate,
      remainingCredits: newType == SubscriptionType.premium ? plan.creditLimit : 0,
      generationCount: 0,
      lastGenerationResetDate: DateTime.now(),
      lastCreditResetDate: DateTime.now(),
    );
  }
  
  /// 월별 리셋 확인 및 처리
  SubscriptionStatus checkAndResetMonthly() {
    final now = DateTime.now();
    
    // 프리미엄 사용자의 크레디트 리셋
    if (subscriptionType == SubscriptionType.premium && lastCreditResetDate != null) {
      final nextResetDate = DateTime(lastCreditResetDate!.year, lastCreditResetDate!.month + 1, 1);
      if (now.isAfter(nextResetDate)) {
        final plan = SubscriptionPlan.fromType(subscriptionType);
        return SubscriptionStatus(
          subscriptionType: subscriptionType,
          expiryDate: expiryDate,
          remainingCredits: plan.creditLimit,
          generationCount: generationCount,
          lastGenerationResetDate: lastGenerationResetDate,
          lastCreditResetDate: now,
        );
      }
    }
    
    // 무료 사용자는 리셋 없음 - 평생 5개
    
    return this;
  }
  
  /// JSON 변환 메서드
  Map<String, dynamic> toJson() {
    return {
      'subscriptionType': subscriptionType.index,
      'expiryDate': expiryDate?.toIso8601String(),
      'remainingCredits': remainingCredits,
      'generationCount': generationCount,
      'lastGenerationResetDate': lastGenerationResetDate.toIso8601String(),
      'lastCreditResetDate': lastCreditResetDate?.toIso8601String(),
    };
  }
  
  /// JSON에서 객체 생성
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      subscriptionType: SubscriptionType.values[json['subscriptionType'] ?? 0],
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      remainingCredits: json['remainingCredits'] ?? 0,
      generationCount: json['generationCount'] ?? 0,
      lastGenerationResetDate: json['lastGenerationResetDate'] != null 
          ? DateTime.parse(json['lastGenerationResetDate']) 
          : DateTime.now(),
      lastCreditResetDate: json['lastCreditResetDate'] != null
          ? DateTime.parse(json['lastCreditResetDate'])
          : null,
    );
  }
}
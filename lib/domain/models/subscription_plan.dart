// lib/domain/models/subscription_plan.dart
import 'package:chunk_up/core/constants/subscription_constants.dart';

/// 구독 플랜 타입 (enum)
enum SubscriptionType {
  free,
  basic,
  premium
}

/// 구독 플랜 정보 클래스
class SubscriptionPlan {
  final SubscriptionType type;
  final String name;
  final String description;
  final String price;
  final String aiModel;
  final int generationLimit;
  final int wordMinLimit;
  final int wordMaxLimit;
  final bool hasAds;
  final bool allowsTest;
  final bool allowsPdfExport;
  final String productId;
  
  const SubscriptionPlan({
    required this.type,
    required this.name,
    required this.description,
    required this.price,
    required this.aiModel,
    required this.generationLimit,
    required this.wordMinLimit,
    required this.wordMaxLimit,
    required this.hasAds,
    required this.allowsTest,
    required this.allowsPdfExport,
    required this.productId,
  });
  
  /// 무료 플랜
  static const SubscriptionPlan free = SubscriptionPlan(
    type: SubscriptionType.free,
    name: 'FREE',
    description: '기본 기능 무료 체험',
    price: '무료',
    aiModel: SubscriptionConstants.freeAiModel,
    generationLimit: SubscriptionConstants.freeGenerationLimit,
    wordMinLimit: SubscriptionConstants.freeWordMinLimit,
    wordMaxLimit: SubscriptionConstants.freeWordMaxLimit,
    hasAds: true,
    allowsTest: false,
    allowsPdfExport: false,
    productId: SubscriptionConstants.freePlanId,
  );
  
  /// Basic 플랜
  static const SubscriptionPlan basic = SubscriptionPlan(
    type: SubscriptionType.basic,
    name: 'BASIC',
    description: '기본 기능 모두 사용 가능',
    price: SubscriptionConstants.basicMonthlyPrice,
    aiModel: SubscriptionConstants.basicAiModel,
    generationLimit: SubscriptionConstants.basicGenerationLimit,
    wordMinLimit: SubscriptionConstants.basicWordMinLimit,
    wordMaxLimit: SubscriptionConstants.basicWordMaxLimit,
    hasAds: false,
    allowsTest: true,
    allowsPdfExport: true,
    productId: SubscriptionConstants.basicMonthlyProductId,
  );
  
  /// Premium 플랜
  static const SubscriptionPlan premium = SubscriptionPlan(
    type: SubscriptionType.premium,
    name: 'PREMIUM',
    description: '고급 AI 모델 및 추가 기능',
    price: SubscriptionConstants.premiumMonthlyPrice,
    aiModel: SubscriptionConstants.premiumAiModel,
    generationLimit: SubscriptionConstants.premiumGenerationLimit,
    wordMinLimit: SubscriptionConstants.premiumWordMinLimit,
    wordMaxLimit: SubscriptionConstants.premiumWordMaxLimit,
    hasAds: false,
    allowsTest: true,
    allowsPdfExport: true,
    productId: SubscriptionConstants.premiumMonthlyProductId,
  );
  
  /// 구독 타입으로 플랜 조회
  static SubscriptionPlan fromType(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.free:
        return free;
      case SubscriptionType.basic:
        return basic;
      case SubscriptionType.premium:
        return premium;
    }
  }
  
  /// 제품 ID로 플랜 조회
  static SubscriptionPlan? fromProductId(String productId) {
    if (productId == SubscriptionConstants.freePlanId) {
      return free;
    } else if (productId == SubscriptionConstants.basicMonthlyProductId) {
      return basic;
    } else if (productId == SubscriptionConstants.premiumMonthlyProductId) {
      return premium;
    }
    return null;
  }
}

/// 사용자의 구독 상태 클래스 (Freezed로 변환 예정)
class SubscriptionStatus {
  final SubscriptionType subscriptionType;
  final DateTime? expiryDate;
  final int generationCount;
  final DateTime lastGenerationResetDate;
  
  const SubscriptionStatus({
    required this.subscriptionType,
    this.expiryDate,
    this.generationCount = 0,
    required this.lastGenerationResetDate,
  });
  
  /// 기본 무료 구독 상태
  factory SubscriptionStatus.defaultFree() {
    return SubscriptionStatus(
      subscriptionType: SubscriptionType.free,
      lastGenerationResetDate: DateTime.now(),
    );
  }
  
  /// 월 출력 횟수가 남아있는지 확인
  bool get hasGenerationsLeft {
    final plan = SubscriptionPlan.fromType(subscriptionType);
    return generationCount < plan.generationLimit;
  }
  
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
  
  /// 리워드 광고 시청으로 무료 출력 횟수 추가
  SubscriptionStatus addRewardedGeneration() {
    if (subscriptionType != SubscriptionType.free) {
      return this; // 유료 구독자는 리워드 광고 적용 안 함
    }
    
    return SubscriptionStatus(
      subscriptionType: subscriptionType,
      expiryDate: expiryDate,
      generationCount: generationCount,
      lastGenerationResetDate: lastGenerationResetDate,
    );
  }
  
  /// 출력 횟수 증가
  SubscriptionStatus incrementGenerationCount() {
    return SubscriptionStatus(
      subscriptionType: subscriptionType,
      expiryDate: expiryDate,
      generationCount: generationCount + 1,
      lastGenerationResetDate: lastGenerationResetDate,
    );
  }
  
  /// 새로운 구독 상태로 업데이트
  SubscriptionStatus updateSubscription(SubscriptionType newType, DateTime? newExpiryDate) {
    return SubscriptionStatus(
      subscriptionType: newType,
      expiryDate: newExpiryDate,
      generationCount: 0, // 구독 변경 시 출력 횟수 리셋
      lastGenerationResetDate: DateTime.now(),
    );
  }
  
  /// JSON 변환 메서드
  Map<String, dynamic> toJson() {
    return {
      'subscriptionType': subscriptionType.index,
      'expiryDate': expiryDate?.toIso8601String(),
      'generationCount': generationCount,
      'lastGenerationResetDate': lastGenerationResetDate.toIso8601String(),
    };
  }
  
  /// JSON에서 객체 생성
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      subscriptionType: SubscriptionType.values[json['subscriptionType'] ?? 0],
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      generationCount: json['generationCount'] ?? 0,
      lastGenerationResetDate: json['lastGenerationResetDate'] != null 
          ? DateTime.parse(json['lastGenerationResetDate']) 
          : DateTime.now(),
    );
  }
}
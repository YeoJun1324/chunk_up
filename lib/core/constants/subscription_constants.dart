// lib/core/constants/subscription_constants.dart
class SubscriptionConstants {
  // 구독 플랜 ID
  static const String freePlanId = 'free_plan';
  static const String premiumPlanId = 'premium_plan';
  
  // 인앱 결제 제품 ID (앱스토어/플레이스토어에 등록할 ID)
  static const String premiumMonthlyProductId = 'com.chunkup.subscription.premium_monthly';
  
  // 애드몹 광고 ID
  static const String androidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // 테스트 ID
  static const String iosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716'; // 테스트 ID
  static const String androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // 테스트 ID
  static const String iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313'; // 테스트 ID
  static const String androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // 테스트 ID
  static const String iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910'; // 테스트 ID
  
  // AI 모델 ID - 오직 Gemini 2.5 Flash만 사용
  static const String defaultAiModel = 'gemini-2.5-flash-preview-05-20'; // 모든 사용자를 위한 단일 모델
  static const String freeAiModel = 'gemini-2.5-flash-preview-05-20'; // 호환성을 위해 남겨둠
  static const String premiumAiModel = 'gemini-2.5-flash-preview-05-20'; // 호환성을 위해 남겨둠
  
  // 구독 플랜별 제한
  static const int freeGenerationLimit = 5; // 무료 청크 생성 제한 횟수 (평생)
  static const int freeWordMinLimit = 5; // 무료 최소 단어 수 제한
  static const int freeWordMaxLimit = 10; // 무료 최대 단어 수 제한

  static const int premiumCreditLimit = 100; // Premium 월 크레디트 제공
  static const int premiumWordMinLimit = 5; // Premium 최소 단어 수 제한
  static const int premiumWordMaxLimit = 20; // Premium 최대 단어 수 제한
  
  // 크레딧 비용 - 모든 생성은 동일하게 1 크레딧
  static const int defaultCreditCost = 1; // 모든 생성은 1 크레딧
  
  // 가격 표시용 (실제 과금은 스토어를 통해)
  static const String premiumMonthlyPrice = '₩5,990';
  static const String premiumMonthlyDiscountPrice = '₩3,990'; // 출시 3개월 할인!
  
  // 구독 관리 저장소 키
  static const String subscriptionStatusKey = 'subscription_status';
  static const String generationCountKey = 'generation_count';
  static const String generationResetDateKey = 'generation_reset_date';
  static const String remainingCreditsKey = 'remaining_credits';
  static const String creditResetDateKey = 'credit_reset_date';
  static const String userIdKey = 'user_id';
  
  // 광고 캐시 키
  static const String rewardedAdCacheKey = 'rewarded_ad_cache';
}
// lib/core/constants/subscription_constants.dart
class SubscriptionConstants {
  // 구독 플랜 ID
  static const String freePlanId = 'free_plan';
  static const String basicPlanId = 'basic_plan';
  static const String premiumPlanId = 'premium_plan';
  
  // 인앱 결제 제품 ID (앱스토어/플레이스토어에 등록할 ID)
  static const String basicMonthlyProductId = 'com.chunkup.subscription.basic_monthly';
  static const String premiumMonthlyProductId = 'com.chunkup.subscription.premium_monthly';
  
  // 애드몹 광고 ID
  static const String androidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // 테스트 ID
  static const String iosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716'; // 테스트 ID
  static const String androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // 테스트 ID
  static const String iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313'; // 테스트 ID
  static const String androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // 테스트 ID
  static const String iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910'; // 테스트 ID
  
  // AI 모델 ID
  static const String freeAiModel = 'claude-3-haiku-20240307'; // 무료 버전용 모델
  static const String basicAiModel = 'claude-3-5-haiku-20241022';
  static const String premiumAiModel = 'claude-3-7-sonnet-20250219';
  
  // 구독 플랜별 제한
  static const int freeGenerationLimit = 5; // 무료 출력 제한 횟수
  static const int freeWordMinLimit = 5; // 무료 최소 단어 수 제한
  static const int freeWordMaxLimit = 10; // 무료 최대 단어 수 제한
  
  static const int basicGenerationLimit = 100; // Basic 월 출력 제한 횟수
  static const int basicWordMinLimit = 5; // Basic 최소 단어 수 제한
  static const int basicWordMaxLimit = 15; // Basic 최대 단어 수 제한
  
  static const int premiumGenerationLimit = 100; // Premium 월 출력 제한 횟수
  static const int premiumWordMinLimit = 5; // Premium 최소 단어 수 제한
  static const int premiumWordMaxLimit = 20; // Premium 최대 단어 수 제한
  
  // 가격 표시용 (실제 과금은 스토어를 통해)
  static const String basicMonthlyPrice = '₩2,990';
  static const String premiumMonthlyPrice = '₩5,990';
  
  // 구독 관리 저장소 키
  static const String subscriptionStatusKey = 'subscription_status';
  static const String generationCountKey = 'generation_count';
  static const String generationResetDateKey = 'generation_reset_date';
  static const String userIdKey = 'user_id';
  
  // 광고 캐시 키
  static const String rewardedAdCacheKey = 'rewarded_ad_cache';
}
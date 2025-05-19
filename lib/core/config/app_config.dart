// lib/core/config/app_config.dart
import 'package:flutter/foundation.dart';

/// 앱 환경 설정
enum Environment { development, staging, production }

/// 앱 설정 싱글톤 클래스
class AppConfig {
  // 싱글톤 인스턴스
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;

  // 환경 설정
  final Environment environment;
  
  // 기능 설정 
  final bool enableAds;
  final bool enableSubscriptions;
  final bool useTestInAppPurchase;
  final int freeCreditsForTesters;
  final bool enablePremiumForTesters;
  final bool useEmbeddedApiKey;
  
  // 디버그 설정
  final bool showPerformanceOverlay;
  final bool showDebugBanner;

  // 내부 생성자 - 테스트 환경 기본값 설정
  AppConfig._internal()
      : environment = Environment.development,   // 개발 환경
        enableAds = true,                        // 광고 활성화
        enableSubscriptions = true,              // 구독 기능 활성화
        useTestInAppPurchase = true,             // 테스트 결제 사용
        freeCreditsForTesters = 100,             // 테스터용 크레딧
        enablePremiumForTesters = true,          // 테스터에게 프리미엄 기능 활성화
        useEmbeddedApiKey = true,                // 내장 API 키 사용
        showPerformanceOverlay = false,          // 성능 오버레이 비활성화
        showDebugBanner = false;                 // 디버그 배너 비활성화

  // 헬퍼 메서드들
  bool get isProduction => environment == Environment.production;
  bool get isStaging => environment == Environment.staging;
  bool get isDevelopment => environment == Environment.development;
  bool get isTestMode => environment != Environment.production;
  
  // 설정값 로깅
  void logConfig() {
    debugPrint('⚙️ AppConfig:');
    debugPrint('   Environment: $environment');
    debugPrint('   Ads Enabled: $enableAds');
    debugPrint('   Subscriptions Enabled: $enableSubscriptions');
    debugPrint('   Test IAP: $useTestInAppPurchase');
    debugPrint('   Premium for Testers: $enablePremiumForTesters');
    debugPrint('   Embedded API Key: $useEmbeddedApiKey');
  }
}
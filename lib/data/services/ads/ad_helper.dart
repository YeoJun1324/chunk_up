// lib/core/services/ad_helper.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:chunk_up/core/config/app_config.dart';
import 'package:chunk_up/core/config/feature_flags.dart';

/// 광고 관련 기능을 제공하는 헬퍼 클래스
class AdHelper {
  // 싱글톤 인스턴스
  static final AdHelper _instance = AdHelper._internal();
  factory AdHelper() => _instance;
  
  // 의존성
  final AppConfig _appConfig = AppConfig();
  final FeatureFlags _featureFlags = FeatureFlags();
  
  // 상태 변수
  bool _initialized = false;
  bool _adsEnabled = false;
  
  // 내부 생성자
  AdHelper._internal();
  
  // 광고 활성화 여부
  bool get isEnabled => _adsEnabled && _appConfig.enableAds;
  
  // 초기화 메서드
  Future<void> initialize() async {
    if (_initialized) return;
    
    // 테스트 모드에서는 광고를 비활성화
    _adsEnabled = !_appConfig.isTestMode && _appConfig.enableAds;
    
    // 실제 구현에서는 MobileAds.instance.initialize() 호출
    debugPrint('📱 광고 시스템 초기화: ${_adsEnabled ? "활성화" : "비활성화"}');
    
    _initialized = true;
  }
  
  // 테스트 광고 ID 반환
  String getBannerAdUnitId() {
    if (_appConfig.isProduction) {
      // 프로덕션 광고 ID
      return Platform.isAndroid 
          ? 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY' // 실제 Android 광고 ID
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // 실제 iOS 광고 ID
    } else {
      // 테스트 광고 ID
      return Platform.isAndroid 
          ? 'ca-app-pub-3940256099942544/6300978111' // Android 테스트 ID
          : 'ca-app-pub-3940256099942544/2934735716'; // iOS 테스트 ID
    }
  }
  
  // 전면 광고 ID 반환
  String getInterstitialAdUnitId() {
    if (_appConfig.isProduction) {
      // 프로덕션 광고 ID
      return Platform.isAndroid 
          ? 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY' // 실제 Android 광고 ID
          : 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'; // 실제 iOS 광고 ID
    } else {
      // 테스트 광고 ID
      return Platform.isAndroid 
          ? 'ca-app-pub-3940256099942544/1033173712' // Android 테스트 ID
          : 'ca-app-pub-3940256099942544/4411468910'; // iOS 테스트 ID
    }
  }
  
  // 광고 로딩 가능 여부 확인
  bool canLoadAd() {
    // 프리미엄 기능이 활성화된 경우 광고 비활성화
    if (_featureFlags.enablePremiumFeatures) {
      debugPrint('👑 프리미엄 모드: 광고 비활성화됨');
      return false;
    }
    
    // 테스트 모드 또는 광고 비활성화된 경우
    if (!isEnabled) {
      debugPrint('🚫 광고 비활성화 상태');
      return false;
    }
    
    return true;
  }
  
  // 테스트 메서드 - 가상으로 광고 로드 성공 반환
  Future<bool> loadTestAd() async {
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('🧪 테스트 광고 로드됨 (가상)');
    return true;
  }
}
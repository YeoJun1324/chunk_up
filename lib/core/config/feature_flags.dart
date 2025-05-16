// lib/core/config/feature_flags.dart
import 'package:flutter/foundation.dart';
import 'app_config.dart';

/// 기능 플래그 시스템 - 특정 기능의 활성화/비활성화를 관리
class FeatureFlags {
  // 싱글톤 인스턴스
  static final FeatureFlags _instance = FeatureFlags._internal();
  factory FeatureFlags() => _instance;
  
  // 앱 설정 참조
  final AppConfig appConfig = AppConfig();
  
  // 기능 플래그들
  late final bool unlimitedChunkGeneration;
  late final bool skipApiKeySetup;
  late final bool enablePremiumFeatures;
  late final bool showDebugPanel;
  late final bool enableModelTesting;
  late final bool enableCustomPrompts;
  late final bool enableAutoBackup;
  
  // 내부 생성자
  FeatureFlags._internal() {
    _initializeFlags();
  }
  
  // 플래그 초기화
  void _initializeFlags() {
    // 앱 설정에 따라 플래그 설정
    final isTestMode = appConfig.isTestMode;
    
    // 테스트 모드에서 활성화되는 기능들
    unlimitedChunkGeneration = isTestMode || appConfig.enablePremiumForTesters;
    skipApiKeySetup = isTestMode || appConfig.useEmbeddedApiKey;
    enablePremiumFeatures = isTestMode || appConfig.enablePremiumForTesters;
    
    // 개발 전용 기능들
    showDebugPanel = appConfig.isDevelopment;
    enableModelTesting = appConfig.isDevelopment;
    
    // 모든 환경에서 활성화된 기능들
    enableCustomPrompts = true;
    enableAutoBackup = true;
  }
  
  // 설정값 로깅
  void logFeatureFlags() {
    debugPrint('🚩 Feature Flags:');
    debugPrint('   Unlimited Chunks: $unlimitedChunkGeneration');
    debugPrint('   Skip API Setup: $skipApiKeySetup');
    debugPrint('   Premium Features: $enablePremiumFeatures');
    debugPrint('   Debug Panel: $showDebugPanel');
    debugPrint('   Model Testing: $enableModelTesting');
    debugPrint('   Custom Prompts: $enableCustomPrompts');
    debugPrint('   Auto Backup: $enableAutoBackup');
  }
}
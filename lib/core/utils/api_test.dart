// lib/core/utils/api_test.dart
import 'package:flutter/material.dart';
import 'api_key_tester.dart';
import 'package:chunk_up/domain/services/api_service_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:chunk_up/data/services/api/unified_api_service.dart';

/// API 키 테스트 유틸리티
class ApiTest {
  /// 모든 가능한 API 키를 테스트하고 작동하는 키를 반환
  static Future<void> testAllApiKeys() async {
    // 로깅을 위한 카운터
    int successCount = 0;
    int failCount = 0;
    
    debugPrint('🔍 API 키 테스트 시작 - 모든 소스 확인');
    
    // 1. 환경 변수에서 키 테스트
    final String? envKey = String.fromEnvironment('ANTHROPIC_API_KEY');
    
    if (envKey != null && envKey.isNotEmpty) {
      debugPrint('🧪 환경 변수 API 키 테스트 중...');
      final envKeyResult = await ApiKeyTester.testApiKey(envKey);
      if (envKeyResult['success'] == true) {
        debugPrint('✅ 환경 변수 API 키 테스트 성공');
        successCount++;
      } else {
        debugPrint('❌ 환경 변수 API 키 테스트 실패: ${envKeyResult['error']}');
        if (envKeyResult['status_code'] != null) {
          debugPrint('📋 상태 코드: ${envKeyResult['status_code']}');
        }
        failCount++;
      }
    } else {
      debugPrint('⚠️ 환경 변수에서 API 키를 찾을 수 없음');
      failCount++;
    }
    
    // 2. API 서비스에서 키 가져와서 테스트
    debugPrint('🧪 API 서비스에서 API 키 가져오는 중...');
    try {
      final apiService = GetIt.instance<ApiServiceInterface>();
      final apiServiceKey = await apiService.getApiKey();
    
    if (apiServiceKey != null && apiServiceKey.isNotEmpty) {
      debugPrint('🧪 API 서비스의 API 키 테스트 중...');
      final apiServiceKeyResult = await ApiKeyTester.testApiKey(apiServiceKey);
      if (apiServiceKeyResult['success'] == true) {
        debugPrint('✅ API 서비스의 API 키 테스트 성공');
        successCount++;
      } else {
        debugPrint('❌ API 서비스의 API 키 테스트 실패: ${apiServiceKeyResult['error']}');
        if (apiServiceKeyResult['status_code'] != null) {
          debugPrint('📋 상태 코드: ${apiServiceKeyResult['status_code']}');
        }
        failCount++;
      }
    } else {
        debugPrint('⚠️ API 서비스에서 API 키를 가져오지 못함');
        failCount++;
      }
    } catch (e) {
      debugPrint('⚠️ API 서비스 접근 실패: $e');
      failCount++;
    }
    
    // 3. UnifiedApiService에서 키 가져와서 테스트
    debugPrint('🧪 통합 API 서비스에서 API 키 가져오는 중...');
    final embeddedKey = await UnifiedApiService.getEmbeddedApiKey();
    
    if (embeddedKey != null && embeddedKey.isNotEmpty) {
      debugPrint('🧪 통합 API 서비스의 API 키 테스트 중...');
      final embeddedKeyResult = await ApiKeyTester.testApiKey(embeddedKey);
      if (embeddedKeyResult['success'] == true) {
        debugPrint('✅ 통합 API 서비스의 API 키 테스트 성공');
        successCount++;
      } else {
        debugPrint('❌ 통합 API 서비스의 API 키 테스트 실패: ${embeddedKeyResult['error']}');
        if (embeddedKeyResult['status_code'] != null) {
          debugPrint('📋 상태 코드: ${embeddedKeyResult['status_code']}');
        }
        failCount++;
      }
    } else {
      debugPrint('⚠️ 통합 API 서비스에서 API 키를 가져오지 못함');
      failCount++;
    }
    
    // 결과 요약
    debugPrint('📊 API 키 테스트 요약:');
    debugPrint('✅ 성공: $successCount');
    debugPrint('❌ 실패: $failCount');
    
    // 최종 결론
    if (successCount > 0) {
      debugPrint('🎉 적어도 하나의 API 키가 작동합니다!');
    } else {
      debugPrint('⚠️ 모든 API 키 테스트가 실패했습니다.');
    }
  }
}
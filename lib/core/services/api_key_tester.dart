// lib/core/services/api_key_tester.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// API 키 테스트 전용 클래스
/// API 키 인증 문제를 디버깅하기 위한 도구로, 다양한 헤더 조합으로 시도합니다.
class ApiKeyTester {
  static const String _baseUrl = 'https://api.anthropic.com';

  /// 다양한 헤더 조합으로 API 키 테스트
  static Future<Map<String, bool>> testApiKey(String apiKey) async {
    final results = <String, bool>{};
    
    // 테스트할 헤더 조합 목록
    final headerCombinations = [
      {
        'name': 'x-api-key 헤더',
        'headers': {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
      },
      {
        'name': 'anthropic-api-key 헤더',
        'headers': {
          'Content-Type': 'application/json',
          'anthropic-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
      },
      {
        'name': 'Authorization Bearer 헤더',
        'headers': {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'anthropic-version': '2023-06-01',
        },
      },
      {
        'name': 'anthropic-api-key + Authorization Bearer 헤더',
        'headers': {
          'Content-Type': 'application/json',
          'anthropic-api-key': apiKey,
          'Authorization': 'Bearer $apiKey',
          'anthropic-version': '2023-06-01',
        },
      },
    ];

    // 모든 헤더 조합 테스트
    for (final combination in headerCombinations) {
      try {
        debugPrint('🧪 테스트: ${combination['name']} 방식');
        final headers = combination['headers'] as Map<String, String>;
        
        // 실제 API 요청
        final response = await http.post(
          Uri.parse('$_baseUrl/v1/messages'),
          headers: headers,
          body: jsonEncode({
            'model': 'claude-3-7-sonnet-20250219',
            'max_tokens': 10,
            'messages': [
              {'role': 'user', 'content': 'Say hello'}
            ],
          }),
        ).timeout(const Duration(seconds: 10));
        
        // 응답 로그
        debugPrint('📡 상태 코드: ${response.statusCode}');
        debugPrint('📡 응답: ${response.body.substring(0, min(200, response.body.length))}...');
        
        // 결과 저장
        results[combination['name'] as String] = response.statusCode == 200;
      } catch (e) {
        debugPrint('❌ 테스트 실패: ${combination['name']} - $e');
        results[combination['name'] as String] = false;
      }
    }
    
    // 결과 요약
    debugPrint('📊 API 키 테스트 결과 요약:');
    results.forEach((name, success) {
      debugPrint('   $name: ${success ? "✅ 성공" : "❌ 실패"}');
    });
    
    return results;
  }
  
  // 헬퍼 함수
  static int min(int a, int b) => a < b ? a : b;
}
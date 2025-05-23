// lib/core/utils/api_key_tester.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiKeyTester {
  static const String _baseUrl = 'https://api.anthropic.com';
  
  /// Tests if the API key can successfully connect to the Claude API
  static Future<Map<String, dynamic>> testApiKey(String apiKey) async {
    debugPrint('🧪 API 키 테스트 시작: ${apiKey.substring(0, min(10, apiKey.length))}...');
    
    try {
      final headers = {
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
        'x-api-key': apiKey,
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/messages'),
        headers: headers,
        body: jsonEncode({
          'model': 'claude-3-7-sonnet-20250219',
          'max_tokens': 10,
          'messages': [
            {'role': 'user', 'content': 'Say "API test successful"'}
          ],
        }),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('API request timed out after 5 seconds');
        },
      );
      
      // Log full response for debugging
      debugPrint('🧪 API 테스트 응답 코드: ${response.statusCode}');
      debugPrint('🧪 API 테스트 응답 헤더: ${response.headers}');
      debugPrint('🧪 API 테스트 응답 내용: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success
        return {
          'success': true,
          'status_code': response.statusCode,
          'response': jsonDecode(response.body),
        };
      } else {
        // Error
        return {
          'success': false,
          'status_code': response.statusCode,
          'error': response.body,
        };
      }
    } catch (e) {
      debugPrint('❌ API 테스트 중 오류 발생: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Helper function to get minimum of two integers
  static int min(int a, int b) => a < b ? a : b;
}
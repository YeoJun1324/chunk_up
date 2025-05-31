// lib/core/services/response_parser_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:chunk_up/core/utils/business_exception.dart';

/// API 응답 파싱을 담당하는 서비스
class ResponseParserService {
  /// API 응답을 표준 JSON 형태로 파싱
  Map<String, dynamic> parseApiResponse(dynamic apiResponse) {
    try {
      // 1. 이미 올바른 형식인지 확인
      if (_isDirectJsonFormat(apiResponse)) {
        return _extractDirectJson(apiResponse);
      }
      
      // 2. Claude API 응답 형식 확인
      if (_isClaudeApiFormat(apiResponse)) {
        return _extractFromClaudeResponse(apiResponse);
      }
      
      // 3. 알 수 없는 형식
      throw BusinessException(
        type: BusinessErrorType.dataFormatError,
        message: 'Unknown API response format',
      );
    } catch (e) {
      if (e is BusinessException) rethrow;
      
      debugPrint('JSON parsing error: $e');
      throw BusinessException(
        type: BusinessErrorType.dataFormatError,
        message: 'Failed to parse AI response: ${e.toString()}',
      );
    }
  }

  /// 직접 JSON 형식인지 확인
  bool _isDirectJsonFormat(dynamic response) {
    return response is Map && 
           (response.containsKey('englishContent') || response.containsKey('english_chunk'));
  }

  /// Claude API 형식인지 확인
  bool _isClaudeApiFormat(dynamic response) {
    return response is Map &&
           response.containsKey('content') &&
           response['content'] is List &&
           response['content'].isNotEmpty;
  }

  /// 직접 JSON에서 데이터 추출
  Map<String, dynamic> _extractDirectJson(Map<String, dynamic> response) {
    return {
      'title': response['title'] ?? 'Generated Chunk',
      'englishContent': response['englishContent'] ?? response['english_chunk'] ?? '',
      'koreanTranslation': response['koreanTranslation'] ?? response['korean_translation'] ?? '',
      'wordExplanations': Map<String, dynamic>.from(response['wordExplanations'] ?? {}),
      'wordMappings': Map<String, dynamic>.from(response['wordMappings'] ?? {}),
    };
  }

  /// Claude API 응답에서 JSON 추출
  Map<String, dynamic> _extractFromClaudeResponse(Map<String, dynamic> response) {
    final String responseText = response['content'][0]['text'] ?? '';
    debugPrint('Response text (first 100 chars): ${responseText.substring(0, min(100, responseText.length))}...');

    // JSON 추출 시도
    final jsonString = _extractJsonString(responseText);
    if (jsonString == null) {
      throw BusinessException(
        type: BusinessErrorType.invalidPrompt,
        message: 'Failed to extract JSON from response',
      );
    }

    final dynamic decodedJson = json.decode(jsonString);
    if (decodedJson is! Map) {
      throw BusinessException(
        type: BusinessErrorType.dataFormatError,
        message: 'Decoded JSON is not a Map',
      );
    }

    return _normalizeJsonKeys(Map<String, dynamic>.from(decodedJson));
  }

  /// 응답에서 JSON 문자열 추출
  String? _extractJsonString(String responseText) {
    final jsonStart = responseText.indexOf('{');
    final jsonEnd = responseText.lastIndexOf('}');

    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      return responseText.substring(jsonStart, jsonEnd + 1);
    }
    return null;
  }

  /// JSON 키를 표준 형식으로 정규화
  Map<String, dynamic> _normalizeJsonKeys(Map<String, dynamic> parsedJson) {
    return {
      'title': parsedJson['title'] ?? 'Generated Chunk',
      'englishContent': parsedJson['englishContent'] ?? '',
      'koreanTranslation': parsedJson['koreanTranslation'] ?? '',
      'wordExplanations': Map<String, dynamic>.from(parsedJson['wordExplanations'] ?? {}),
      'wordMappings': Map<String, dynamic>.from(parsedJson['wordMappings'] ?? {}),
    };
  }

  /// 단어 설명을 정규화 (소문자 키)
  Map<String, String> normalizeWordExplanations(Map<String, dynamic> explanations) {
    final Map<String, String> normalized = {};
    explanations.forEach((key, value) {
      if (key is String) {
        normalized[key.toLowerCase()] = value.toString();
      }
    });
    return normalized;
  }

  /// 단어 매핑을 정규화 (소문자 키)
  Map<String, String>? normalizeWordMappings(dynamic mappingsData) {
    if (mappingsData == null) return null;

    final Map<String, String> mappings = {};
    if (mappingsData is Map) {
      mappingsData.forEach((key, value) {
        if (key is String) {
          mappings[key.toLowerCase()] = value.toString();
        }
      });
    }
    return mappings.isNotEmpty ? mappings : null;
  }
}
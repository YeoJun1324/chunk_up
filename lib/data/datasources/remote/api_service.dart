// lib/data/datasources/remote/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/api_exception.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/error_messages.dart';
import 'package:chunk_up/core/services/embedded_api_service.dart';
import 'package:chunk_up/core/services/api_service.dart' as core_api;

/// API 서비스 클래스
/// Claude API와의 통신을 담당하며, API 키 관리, 검증, 청크 생성 등의 기능 제공
class ApiService {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final NetworkService _networkService = NetworkService();

  /// API 키 가져오기
  static Future<String?> get apiKey async {
    return await _secureStorage.read(key: ApiConstants.secureStorageApiKeyKey);
  }

  /// API 키 저장하기
  static Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: ApiConstants.secureStorageApiKeyKey, value: apiKey);
  }

  /// API 키 저장하기 (정적 메서드 - 이름 표준화를 위한 별칭)
  static Future<void> saveApiKeyStatic(String apiKey) async {
    await saveApiKey(apiKey);
  }

  /// API URL 가져오기
  static String get apiUrl => ApiConstants.apiUrl;
  
  /// API 버전 가져오기
  static String get apiVersion => ApiConstants.apiVersion;
  
  /// API 모델 가져오기
  static String get apiModel => ApiConstants.apiModel;

  /// API 키 검증 메서드
  static Future<void> validateApiKey(String apiKey) async {
    try {
      final response = await _makeApiRequest(
        apiKey: apiKey,
        prompt: 'Test',
        maxTokens: 10,
      );
      
      // 상태 코드 확인은 _makeApiRequest에서 처리됨
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'API 키 검증 중 오류 발생',
        originalError: e,
      );
    }
  }

  /// 청크 생성 메서드
  static Future<Map<String, dynamic>> generateChunk(String prompt) async {
    // API 키 가져오기 시도
    var key = await apiKey;

    // API 키가 없으면 내장 API 키 가져오기 시도
    if (key == null || key.isEmpty) {
      debugPrint('⚠️ API 키가 없습니다. 내장 API 키 가져오기 시도...');

      // EmbeddedApiService에서 키 가져오기 시도
      try {
        // 내장 API 키 초기화 및 가져오기 시도
        await EmbeddedApiService.initializeApiSettings();
        key = await EmbeddedApiService.getApiKey();

        // 키를 가져왔으면 저장
        if (key != null && key.isNotEmpty) {
          debugPrint('✅ 내장 API 키 가져오기 성공');
          // 보안 저장소에 저장
          await saveApiKey(key);
          // 코어 API 서비스에도 저장
          await core_api.ApiService.saveApiKeyStatic(key);
        } else {
          debugPrint('⚠️ 내장 API 키를 가져올 수 없음');
        }
      } catch (e) {
        debugPrint('❌ 내장 API 키 가져오기 실패: $e');
      }
    }

    // 최종 확인
    if (key == null || key.isEmpty) {
      throw ApiException(ErrorMessages.apiKeyNotSet);
    }

    // 네트워크 연결 확인
    if (!await _networkService.isConnected()) {
      throw NetworkException(ErrorMessages.networkError);
    }

    // 프롬프트에서 단어 수 계산
    int wordCount = _calculateWordCount(prompt);
    
    // 단어 수에 따라 토큰 수 조정 (기본 1500 + 단어당 100토큰 추가)
    final dynamicMaxTokens = ApiConstants.maxTokens + (wordCount * 100);

    try {
      final responseData = await _makeApiRequest(
        apiKey: key,
        prompt: prompt,
        maxTokens: dynamicMaxTokens,
      );
      
      // JSON 파싱 및 정규화
      return _normalizeChunkResponse(responseData);
    } catch (e) {
      // _makeApiRequest에서 이미 재시도 및 기본 예외 처리를 했으므로 여기서는 그대로 전달
      rethrow;
    }
  }

  /// 단어 설명 생성 메서드
  static Future<String> generateWordExplanation(String word, String paragraph) async {
    // API 키 가져오기 시도
    var key = await apiKey;

    // API 키가 없으면 내장 API 키 가져오기 시도
    if (key == null || key.isEmpty) {
      debugPrint('⚠️ API 키가 없습니다. 내장 API 키 가져오기 시도...');

      // EmbeddedApiService에서 키 가져오기 시도
      try {
        await EmbeddedApiService.initializeApiSettings();
        key = await EmbeddedApiService.getApiKey();

        // 키를 가져왔으면 저장
        if (key != null && key.isNotEmpty) {
          debugPrint('✅ 내장 API 키 가져오기 성공');
          await saveApiKey(key);
          await core_api.ApiService.saveApiKeyStatic(key);
        } else {
          debugPrint('⚠️ 내장 API 키를 가져올 수 없음');
        }
      } catch (e) {
        debugPrint('❌ 내장 API 키 가져오기 실패: $e');
      }
    }

    // 최종 확인
    if (key == null || key.isEmpty) {
      throw ApiException(ErrorMessages.apiKeyNotSet);
    }

    // 네트워크 연결 확인
    if (!await _networkService.isConnected()) {
      throw NetworkException(ErrorMessages.networkError);
    }

    final prompt = """
Please analyze how the word "$word" is used in the following paragraph:

$paragraph

Explain in natural, native-sounding Korean (not translationese):
1. The meaning of "$word" in this specific context
2. How the word contributes to the paragraph
3. Any useful collocations or patterns demonstrated

Guidelines for your Korean explanation:
- Write in clear, natural Korean as if originally written by a native speaker
- Keep your explanation concise - 2-3 short sentences is ideal
- Use appropriate Korean expressions and sentence structures
- Avoid awkward direct translations of English phrases
- Prioritize brevity and clarity without losing natural Korean expression
- Focus on the most important information about how the word is used
- Begin your explanation with: "단어에 대한 한국어 설명: 이 단어는..."

Provide your response as plain text without any special formatting or headers.
""";

    try {
      final responseData = await _makeApiRequest(
        apiKey: key,
        prompt: prompt,
        maxTokens: ApiConstants.maxExplanationTokens,
      );

      // 텍스트 응답 추출
      if (responseData['content'] != null &&
          responseData['content'] is List &&
          responseData['content'].isNotEmpty &&
          responseData['content'][0]['type'] == 'text') {
        return responseData['content'][0]['text'];
      } else {
        throw Exception(ErrorMessages.unexpectedApiResponse);
      }
    } catch (e) {
      // _makeApiRequest에서 이미 재시도 및 기본 예외 처리를 했으므로 여기서는 그대로 전달
      rethrow;
    }
  }

  /// 프롬프트에서 단어 수 계산
  static int _calculateWordCount(String prompt) {
    try {
      if (prompt.contains('following English words:')) {
        final wordsPart = prompt.split('following English words:')[1];
        final wordsString = wordsPart.split('.')[0];
        return wordsString.split(',').length;
      }
    } catch (e) {
      // 계산 실패 시 기본값 사용
    }
    return 0;
  }
  
  /// API 요청 수행 (중복 코드 제거를 위한 공통 메서드)
  static Future<Map<String, dynamic>> _makeApiRequest({
    required String apiKey,
    required String prompt,
    required int maxTokens,
    int maxRetries = ApiConstants.maxRetries,
  }) async {
    int retryCount = 0;
    Duration retryDelay = const Duration(seconds: 1);

    while (retryCount <= maxRetries) {
      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'anthropic-version': apiVersion,
            'x-api-key': apiKey,  // x-api-key 헤더를 마지막에 배치하여 우선순위 부여
          },
          body: jsonEncode({
            'model': ApiConstants.apiModel,
            'max_tokens': maxTokens,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
          }),
        ).timeout(
          ApiConstants.readTimeout,
          onTimeout: () {
            throw TimeoutException(ErrorMessages.apiTimeout);
          },
        );

        if (response.statusCode == 200) {
          return jsonDecode(utf8.decode(response.bodyBytes));
        } else if (response.statusCode == 401) {
          throw ApiException(
            ErrorMessages.invalidApiKey,
            statusCode: 401,
          );
        } else {
          throw InvalidResponseException(
            '${ErrorMessages.apiRequestFailed}: ${_getErrorMessage(response.statusCode)}',
            statusCode: response.statusCode,
          );
        }
      } on TimeoutException {
        rethrow;
      } on ApiException {
        rethrow;
      } catch (e) {
        retryCount++;
        if (retryCount > maxRetries) {
          throw ApiException(
            'API 호출 실패: ${e.toString()}',
            originalError: e,
          );
        }

        // 지수 백오프
        await Future.delayed(retryDelay);
        retryDelay *= 2;
      }
    }

    throw ApiException('${ErrorMessages.apiRequestFailed}: 최대 재시도 횟수 초과');
  }

  /// 청크 응답 정규화
  static Map<String, dynamic> _normalizeChunkResponse(Map<String, dynamic> responseData) {
    try {
      if (responseData['content'] != null &&
          responseData['content'] is List &&
          responseData['content'].isNotEmpty &&
          responseData['content'][0]['type'] == 'text') {

        String resultJsonString = responseData['content'][0]['text'];
        resultJsonString = _cleanJsonString(resultJsonString);

        try {
          final parsedJson = jsonDecode(resultJsonString);

          // 필수 필드 검증
          if (parsedJson is Map<String, dynamic> &&
              parsedJson.containsKey('english_chunk') || 
              parsedJson.containsKey('englishContent') &&
              parsedJson.containsKey('korean_translation') || 
              parsedJson.containsKey('koreanTranslation')) {
            
            // 필드 이름 정규화
            return {
              'english_chunk': parsedJson['englishContent'] ?? parsedJson['english_chunk'] ?? '',
              'korean_translation': parsedJson['koreanTranslation'] ?? parsedJson['korean_translation'] ?? '',
              'title': parsedJson['title'] ?? 'Generated Chunk',
              'wordExplanations': parsedJson['wordExplanations'] ?? parsedJson['word_explanations'] ?? {},
            };
          } else {
            throw FormatException('Required fields missing in JSON response');
          }
        } catch (jsonError) {
          // JSON 파싱 실패 시 더 자세한 로깅
          debugPrint('JSON 파싱 실패: $jsonError');
          
          // 응답이 이미 올바른 형식인지 재확인
          if (resultJsonString.contains('"english_chunk"') ||
              resultJsonString.contains('"englishContent"') &&
              resultJsonString.contains('"korean_translation"') ||
              resultJsonString.contains('"koreanTranslation"')) {
            
            // JSON 형식으로 보이지만 파싱이 실패한 경우, 수동으로 추출 시도
            try {
              final Map<String, dynamic> manuallyParsed = _extractJsonManually(resultJsonString);
              if (manuallyParsed.isNotEmpty) {
                return manuallyParsed;
              }
            } catch (e) {
              debugPrint('수동 JSON 추출도 실패: $e');
            }
          }

          // 최종 fallback
          throw ApiException(
            'JSON 파싱 실패: 응답 형식이 올바르지 않습니다.',
            originalError: jsonError,
          );
        }
      } else {
        throw Exception(ErrorMessages.unexpectedApiResponse);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('응답 처리 중 오류: ${e.toString()}', originalError: e);
    }
  }

  /// JSON 문자열 정제
  static String _cleanJsonString(String jsonString) {
    // 문자열 정제 - 백틱이나 추가 문자 제거
    jsonString = jsonString.trim();

    // 백틱으로 둘러싸인 JSON 처리
    if (jsonString.startsWith('```json') && jsonString.endsWith('```')) {
      jsonString = jsonString
          .replaceFirst('```json', '')
          .replaceFirst('```', '');
    } else if (jsonString.startsWith('```') && jsonString.endsWith('```')) {
      jsonString = jsonString
          .replaceFirst('```', '')
          .replaceFirst('```', '');
    }

    // 추가 공백 제거
    return jsonString.trim();
  }

  /// 수동 JSON 추출 메서드
  static Map<String, dynamic> _extractJsonManually(String jsonString) {
    try {
      // 일반적인 JSON 파싱 문제 해결 시도
      jsonString = jsonString
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r')
          .replaceAll('\t', '\\t');

      // 다시 파싱 시도
      return jsonDecode(jsonString);
    } catch (e) {
      // 정규 표현식으로 필드 추출 시도
      Map<String, dynamic> result = {};

      // english_chunk 추출
      final englishMatch = RegExp(r'"english(?:_chunk|Content)"\s*:\s*"([^"]*)"').firstMatch(jsonString);
      if (englishMatch != null) {
        result['english_chunk'] = englishMatch.group(1);
      }

      // korean_translation 추출
      final koreanMatch = RegExp(r'"korean(?:_translation|Translation)"\s*:\s*"([^"]*)"').firstMatch(jsonString);
      if (koreanMatch != null) {
        result['korean_translation'] = koreanMatch.group(1);
      }

      // title 추출
      final titleMatch = RegExp(r'"title"\s*:\s*"([^"]*)"').firstMatch(jsonString);
      if (titleMatch != null) {
        result['title'] = titleMatch.group(1);
      } else {
        result['title'] = 'Generated Chunk';
      }

      // word_explanations 추출 (간단한 케이스만)
      if (jsonString.contains('"word_explanations"') || jsonString.contains('"wordExplanations"')) {
        result['wordExplanations'] = {};
      }

      if (result.containsKey('english_chunk') && result.containsKey('korean_translation')) {
        return result;
      }

      throw Exception('수동 추출 실패: 필수 필드를 찾을 수 없습니다.');
    }
  }

  /// 에러 메시지 매핑 함수
  static String _getErrorMessage(int statusCode) {
    return ErrorMessages.getHttpErrorMessage(statusCode);
  }

  /// API 오류의 원인을 분석하는 디버깅 함수
  static String analyzeApiError(String errorResponse) {
    try {
      // JSON 파싱 시도
      final errorData = jsonDecode(errorResponse);

      // 일반적인 Claude API 오류 형식 확인
      if (errorData.containsKey('error')) {
        final error = errorData['error'];

        if (error is Map) {
          return '🔍 API 오류 분석: 타입=${error['type'] ?? "알 수 없음"}, '
              '메시지=${error['message'] ?? "없음"}';
        }
      }

      return '🔍 API 오류 구조 분석 실패: $errorResponse';
    } catch (e) {
      return '🔍 API 오류 분석 실패 (JSON 파싱 오류): $e';
    }
  }
}
// lib/data/services/api_service_impl.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:get_it/get_it.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/error_messages.dart';
import '../../core/constants/subscription_constants.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/embedded_api_service.dart';
import '../../core/services/network_service.dart';
import '../../core/services/subscription_service.dart';
import '../../core/utils/api_exception.dart';
import '../../domain/services/api_service_interface.dart' hide TimeoutException;

/// API 서비스 구현체
///
/// 통합된 API 서비스로, 코어 및 데이터 레이어의 기능을 모두 제공합니다.
class ApiServiceImpl implements ApiServiceInterface {
  // 정적 인스턴스 및 필드
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static String? _cachedApiKey;

  // 인스턴스 필드
  final http.Client _httpClient;
  final NetworkService _networkService;
  final CacheService _cacheService;

  // 캐시 관련 설정
  static const bool enableApiCaching = true;
  static const int apiCacheTTL = 30 * 60 * 1000; // 30분 캐시

  // 재시도 관련 설정
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // 생성자
  ApiServiceImpl({
    required http.Client httpClient,
    required NetworkService networkService,
    required CacheService cacheService,
  })  : _httpClient = httpClient,
        _networkService = networkService,
        _cacheService = cacheService;

  /// API 서비스 초기화
  @override
  Future<void> initialize() async {
    // API 키 캐시 초기화
    await _initializeApiKey();
  }

  /// API 키 초기화
  Future<void> _initializeApiKey() async {
    if (_cachedApiKey != null) return;

    // 보안 저장소에서 키 가져오기 시도
    _cachedApiKey = await _secureStorage.read(key: ApiConstants.secureStorageApiKeyKey);

    // 보안 저장소에 없으면 내장 API 키 가져오기 시도
    if (_cachedApiKey == null || _cachedApiKey!.isEmpty) {
      try {
        await EmbeddedApiService.initializeApiSettings();
        _cachedApiKey = await EmbeddedApiService.getApiKey();

        // 가져온 키가 있으면 보안 저장소에 저장
        if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
          await _secureStorage.write(
            key: ApiConstants.secureStorageApiKeyKey, 
            value: _cachedApiKey
          );
        }
      } catch (e) {
        // 초기화 실패 시 로그만 기록하고 계속 진행
      }
    }
  }

  /// API 키 가져오기
  @override
  Future<String?> getApiKey() async {
    // 캐시된 키가 있으면 반환
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey;
    }

    // 초기화 시도
    await _initializeApiKey();
    return _cachedApiKey;
  }

  /// API 키 저장하기
  @override
  Future<void> saveApiKey(String apiKey) async {
    // 캐시 업데이트
    _cachedApiKey = apiKey;

    // 보안 저장소에 저장
    await _secureStorage.write(
      key: ApiConstants.secureStorageApiKeyKey,
      value: apiKey
    );
  }

  /// API 키 검증하기
  @override
  Future<bool> validateApiKey(String apiKey) async {
    try {
      // 간단한 API 요청으로 키 검증
      final response = await _httpClient.post(
        Uri.parse('${ApiConstants.apiUrl}/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'anthropic-version': ApiConstants.apiVersion,
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'model': ApiConstants.apiModel,
          'max_tokens': 10,
          'messages': [
            {'role': 'user', 'content': 'Test API key'}
          ],
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// API 연결 테스트하기
  @override
  Future<bool> testApiConnection() async {
    try {
      // API 키 가져오기
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return false;
      }

      // 네트워크 연결 확인
      if (!await _networkService.isConnected()) {
        return false;
      }

      // 간단한 API 요청 테스트
      return await validateApiKey(apiKey);
    } catch (e) {
      return false;
    }
  }

  /// 캐시 키 생성
  String _createCacheKey(String endpoint, Map<String, dynamic> body) {
    final requestString = '$endpoint:${jsonEncode(body)}';
    final bytes = utf8.encode(requestString);
    final hash = crypto.sha256.convert(bytes);
    return 'api_cache_${hash.toString()}';
  }

  /// API 요청 수행
  Future<Map<String, dynamic>> _executeRequest(
    String endpoint,
    Map<String, dynamic> body,
    String apiKey, {
    int retryCount = 0,
  }) async {
    try {
      // 헤더 설정
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'anthropic-version': ApiConstants.apiVersion,
        'x-api-key': apiKey,
      };

      // API 요청 (전체 URL 사용)
      final url = '${ApiConstants.apiUrl}/$endpoint';
      debugPrint('📡 API 요청 URL: $url');
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ApiException('API request timeout after 30 seconds', statusCode: 408);
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        // 재시도 가능한 상태 코드인지 확인 (429, 500, 502, 503, 504)
        final retriableStatusCodes = [429, 500, 502, 503, 504];
        if (retriableStatusCodes.contains(response.statusCode) && retryCount < maxRetries) {
          // 지수 백오프를 사용한 재시도 지연 계산
          final delay = Duration(milliseconds: retryDelay.inMilliseconds * (1 << retryCount));
          await Future.delayed(delay);
          return _executeRequest(endpoint, body, apiKey, retryCount: retryCount + 1);
        }

        // 재시도 횟수 초과 또는 재시도할 수 없는 오류인 경우
        throw ApiException(
          'API Error: ${response.statusCode}',
          details: response.body,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // 네트워크 오류이고 재시도 횟수가 남아있으면 재시도
      if (e is! ApiException && retryCount < maxRetries) {
        final delay = Duration(milliseconds: retryDelay.inMilliseconds * (1 << retryCount));
        await Future.delayed(delay);
        return _executeRequest(endpoint, body, apiKey, retryCount: retryCount + 1);
      }
      
      // 재시도가 불가능하거나 모든 재시도 실패 시 예외 발생
      if (e is ApiException) {
        rethrow;
      }
      
      // 기타 에러는 ApiException으로 변환
      throw ApiException(
        'Network error',
        details: e.toString(),
        statusCode: 0,
      );
    }
  }

  /// 청크 생성하기
  @override
  Future<Map<String, dynamic>> generateChunk(
    String prompt, {
    String? modelOverride,
    bool useCache = true,
    bool trackPerformance = false,
  }) async {
    // 성능 측정
    final stopwatch = trackPerformance ? (Stopwatch()..start()) : null;

    // API 키 가져오기
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw ApiException(
        ErrorMessages.apiKeyNotSet,
        statusCode: 401,
      );
    }

    // 네트워크 연결 확인
    if (!await _networkService.isConnected()) {
      throw ApiException(
        ErrorMessages.networkError,
        statusCode: 0,
      );
    }

    // SubscriptionService에서 적절한 모델 가져오기 시도
    String selectedModel;

    try {
      // 1. 모델 오버라이드가 있으면 우선 적용
      if (modelOverride != null) {
        selectedModel = modelOverride;
        debugPrint('🤖 오버라이드된 모델 사용: $selectedModel');
      }
      // 2. 없으면 GetIt에서 SubscriptionService 가져와서 모델 결정
      else {
        try {
          if (GetIt.instance.isRegistered<SubscriptionService>()) {
            final subscriptionService = GetIt.instance<SubscriptionService>();
            selectedModel = subscriptionService.getCurrentModel();

            // 구독 상태 로깅
            final statusStr = subscriptionService.status.toString().split('.').last;
            debugPrint('🤖 구독 서비스에서 가져온 모델: $selectedModel (구독 상태: $statusStr)');
          } else {
            selectedModel = ApiConstants.apiModel; // 무료 모델 폴백
            debugPrint('⚠️ 구독 서비스를 찾을 수 없음, 기본 무료 모델 사용');
          }
        } catch (e) {
          selectedModel = ApiConstants.apiModel; // 무료 모델 폴백
          debugPrint('⚠️ 구독 서비스 접근 실패, 기본 무료 모델 사용: $e');
        }
      }
    } catch (e) {
      selectedModel = ApiConstants.apiModel; // 오류 시 무료 모델로 폴백
      debugPrint('⚠️ 모델 선택 오류, 기본 무료 모델 사용: $e');
    }

    debugPrint('🤖 최종 API 요청에 사용될 모델: $selectedModel');

    final body = {
      'model': selectedModel,
      'max_tokens': 2500,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': prompt
            }
          ]
        }
      ]
    };

    try {
      // 캐싱이 활성화되어 있고 캐시를 사용할 수 있는 경우
      if (enableApiCaching && useCache) {
        final cacheKey = _createCacheKey('v1/messages', body);
        
        // 캐시에서 데이터 가져오기 시도
        if (await _cacheService.has(cacheKey)) {
          final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
          if (cachedData != null) {
            return cachedData;
          }
        }
      }

      // API 요청 수행 (v1/messages 엔드포인트 사용)
      debugPrint('🔄 청크 생성 API 요청 시작 - 모델: ${body['model']}');
      final responseData = await _executeRequest('v1/messages', body, apiKey);

      // 응답 처리
      final result = _normalizeChunkResponse(responseData);
      
      // 캐싱이 활성화되어 있고 캐시를 사용할 수 있는 경우 응답 캐싱
      if (enableApiCaching && useCache) {
        final cacheKey = _createCacheKey('v1/messages', body);
        await _cacheService.set(cacheKey, result, ttlMs: apiCacheTTL);
      }
      
      // 성능 측정 결과 기록
      if (trackPerformance && stopwatch != null) {
        stopwatch.stop();
        debugPrint('📊 API 응답 시간: ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return result;
    } catch (e) {
      if (trackPerformance && stopwatch != null) {
        stopwatch.stop();
        debugPrint('⚠️ API 오류 발생 시간: ${stopwatch.elapsedMilliseconds}ms');
      }
      
      rethrow;
    }
  }

  /// 단어 설명 생성하기
  @override
  Future<String> generateWordExplanation(String word, String paragraph) async {
    // API 키 가져오기
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw ApiException(
        ErrorMessages.apiKeyNotSet,
        statusCode: 401,
      );
    }

    // 네트워크 연결 확인
    if (!await _networkService.isConnected()) {
      throw ApiException(
        ErrorMessages.networkError,
        statusCode: 0,
      );
    }

    // 프롬프트 구성
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

    // 요청 바디 구성
    final body = {
      'model': ApiConstants.apiModel,
      'max_tokens': ApiConstants.maxExplanationTokens,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': prompt
            }
          ]
        }
      ]
    };

    try {
      // API 요청 수행 (단어 설명)
      debugPrint('🔄 단어 설명 생성 API 요청 시작');
      final responseData = await _executeRequest('v1/messages', body, apiKey);
      
      // 텍스트 응답 추출
      if (responseData['content'] != null &&
          responseData['content'] is List &&
          responseData['content'].isNotEmpty &&
          responseData['content'][0]['type'] == 'text') {
        return responseData['content'][0]['text'];
      } else {
        throw ApiException(
          ErrorMessages.unexpectedApiResponse,
          statusCode: 0,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Word explanation generation failed',
        details: e.toString(),
        statusCode: 0,
      );
    }
  }

  /// 청크 응답 정규화
  Map<String, dynamic> _normalizeChunkResponse(Map<String, dynamic> responseData) {
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
              (parsedJson.containsKey('english_chunk') || 
              parsedJson.containsKey('englishContent')) &&
              (parsedJson.containsKey('korean_translation') || 
              parsedJson.containsKey('koreanTranslation'))) {
            
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
          if ((resultJsonString.contains('"english_chunk"') ||
              resultJsonString.contains('"englishContent"')) &&
              (resultJsonString.contains('"korean_translation"') ||
              resultJsonString.contains('"koreanTranslation"'))) {
            
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
            details: jsonError.toString(),
            statusCode: 0,
          );
        }
      } else {
        throw ApiException(
          ErrorMessages.unexpectedApiResponse,
          statusCode: 0,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        '응답 처리 중 오류',
        details: e.toString(),
        statusCode: 0,
      );
    }
  }

  /// JSON 문자열 정제
  String _cleanJsonString(String jsonString) {
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
  Map<String, dynamic> _extractJsonManually(String jsonString) {
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

  /// 단어 목록에 대한 청크 생성하기
  @override
  Future<List<Map<String, dynamic>>> generateChunksForWords(
    List<dynamic> words, {
    String? modelOverride,
    bool trackPerformance = true
  }) async {
    final stopwatch = trackPerformance ? (Stopwatch()..start()) : null;
    final List<Map<String, dynamic>> results = [];

    // 단어들을 영어 텍스트로 변환
    final wordText = words.map((w) => w.english).join("\n");
    final prompt = """
    Generate an engaging English passage using these words:

    $wordText

    Instructions:
    - Make it a natural paragraph
    - Use each word properly in context
    - Create a natural, native-sounding Korean translation
    - Return content as valid JSON with title, english_chunk, and korean_translation fields
    """;

    final result = await generateChunk(
      prompt,
      modelOverride: modelOverride,
      trackPerformance: trackPerformance
    );
    results.add(result);

    if (trackPerformance && stopwatch != null) {
      stopwatch.stop();
      debugPrint('📊 generateChunksForWords 총 시간: ${stopwatch.elapsedMilliseconds}ms');
    }

    return results;
  }
}
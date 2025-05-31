// lib/core/services/api/unified_api_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:get_it/get_it.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:chunk_up/core/constants/api_constants.dart';
import 'package:chunk_up/core/constants/error_messages.dart';
import 'package:chunk_up/core/constants/subscription_constants.dart';
import 'package:chunk_up/data/services/cache/cache_service.dart';
import 'package:chunk_up/infrastructure/network/network_service.dart';
import 'package:chunk_up/data/services/subscription/subscription_service.dart';
import 'package:chunk_up/core/utils/api_exception.dart';
import '../../../domain/services/api_service_interface.dart' hide TimeoutException;
import '../../../data/services/storage/local_storage_service.dart';

/// 통합된 API 서비스 - 모든 API 관련 기능을 중앙화
/// 
/// 기존의 EmbeddedApiService, ApiServiceImpl, ApiServiceBase 기능을 통합
class UnifiedApiService implements ApiServiceInterface {
  // 정적 인스턴스 및 필드
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static String? _cachedApiKey;

  // 인스턴스 필드
  final http.Client _httpClient;
  final NetworkService _networkService;
  final CacheService _cacheService;

  // API 키 내장 설정
  static const bool useEmbeddedKey = true;

  // 캐시 관련 설정
  static const bool enableApiCaching = true;
  static const int apiCacheTTL = 30 * 60 * 1000; // 30분 캐시

  // 재시도 관련 설정
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  // 생성자
  UnifiedApiService({
    required http.Client httpClient,
    required NetworkService networkService,
    required CacheService cacheService,
  })  : _httpClient = httpClient,
        _networkService = networkService,
        _cacheService = cacheService;

  @override
  Future<void> initialize() async {
    await _initializeApiKey();
  }

  /// API 키 초기화 - Gemini API만 사용
  Future<void> _initializeApiKey() async {
    // Gemini API는 직접 URL에 키를 포함하므로 별도 초기화 불필요
    debugPrint('✅ Gemini API 사용 - API 키 초기화 스킵');
  }

  /// 내장된 API 키 복호화 - Gemini만 사용하므로 제거
  String? _decryptEmbeddedKey() {
    // Gemini API 키는 URL에 포함되므로 필요 없음
    return null;
  }

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

  /// 정적 메서드로 내장된 API 키 가져오기 (하위 호환성)
  static Future<String?> getEmbeddedApiKey() async {
    try {
      // .env 파일에서 API 키 로드 시도
      final envApiKey = dotenv.env['CLAUDE_API_KEY'] ??
                        dotenv.env['API_KEY'] ??
                        dotenv.env['ANTHROPIC_API_KEY'];

      if (envApiKey != null && envApiKey.isNotEmpty) {
        return envApiKey;
      }

      // API 키가 없으면 null 반환
      return null;
    } catch (e) {
      debugPrint('❌ getEmbeddedApiKey 오류: $e');
      return null;
    }
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    // Gemini API는 URL에 키를 포함하므로 저장 불필요
    debugPrint('ℹ️ Gemini API 키는 URL에 직접 포함되므로 별도 저장하지 않음');
  }

  @override
  Future<void> setApiKey(String apiKey) async {
    await saveApiKey(apiKey);
  }

  /// 로컬 저장소에 API 키 저장
  Future<void> _saveToLocalStorage(String apiKey) async {
    const String apiKeyStorageKey = 'api_key';

    try {
      final service = LocalStorageService();
      await service.setString(apiKeyStorageKey, apiKey);
      debugPrint('✅ API 키가 로컬 저장소에 저장됨');
    } catch (e) {
      debugPrint('❌ 로컬 저장소에 API 키 저장 실패: $e');
    }
  }

  @override
  Future<bool> validateApiKey(String apiKey) async {
    // Gemini API는 URL에 키를 포함하므로 별도 검증 불필요
    // 항상 true 반환
    return true;
  }

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

  /// API 요청 수행 - 재시도 로직 포함
  Future<Map<String, dynamic>> _executeRequest(
    String endpoint,
    Map<String, dynamic> body,
    String apiKey, {
    int retryCount = 0,
  }) async {
    try {
      // 항상 Gemini API만 사용
      return await _executeGeminiRequest(body, retryCount: retryCount);
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

  @override
  Future<Map<String, dynamic>> generateChunk(
    String prompt, {
    String? modelOverride,
    bool useCache = true,
    bool trackPerformance = false,
  }) async {
    // 성능 측정
    final stopwatch = trackPerformance ? (Stopwatch()..start()) : null;

    // 구독 서비스 확인 및 크레딧/생성 횟수 체크
    if (GetIt.instance.isRegistered<SubscriptionService>()) {
      final subscriptionService = GetIt.instance<SubscriptionService>();
      
      // 생성 가능 여부 확인
      if (!await subscriptionService.canGenerateChunk()) {
        throw ApiException(
          subscriptionService.isPremium 
            ? '크레딧이 부족합니다. 프리미엄 플랜은 매월 100 크레딧이 제공됩니다.'
            : '무료 생성 횟수(5개)를 모두 사용했습니다. 프리미엄 구독을 이용해주세요.',
          statusCode: 403,
        );
      }
    }

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

    // 깊은 생각 모드 감지
    if (_containsDeepThinkingPatterns(prompt)) {
      debugPrint('⚠️ Deep thinking patterns detected in prompt - these may incur additional costs');
    }
    
    // 적절한 모델 선택
    String selectedModel = _selectModel(modelOverride);

    // Gemini 모델인지 확인하여 특별한 프롬프트 적용
    final isGeminiModel = selectedModel.contains('gemini');
    String finalPrompt = prompt;
    
    if (isGeminiModel) {
      // Gemini에서 wordExplanations 생성을 보장하기 위한 강화된 프롬프트
      finalPrompt = _enhancePromptForGemini(prompt);
    }

    final body = {
      'model': selectedModel,
      'max_tokens': 2500,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': finalPrompt
            }
          ]
        }
      ]
    };

    try {
      bool fromCache = false;
      
      // 캐싱이 활성화되어 있고 캐시를 사용할 수 있는 경우
      if (enableApiCaching && useCache) {
        final cacheKey = _createCacheKey('v1/messages', body);
        
        // 캐시에서 데이터 가져오기 시도
        if (await _cacheService.has(cacheKey)) {
          final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
          if (cachedData != null) {
            fromCache = true;
            debugPrint('💾 캐시에서 청크 데이터 반환');
            return cachedData;
          }
        }
      }

      // API 요청 수행
      debugPrint('🔄 청크 생성 API 요청 시작 - 모델: ${body['model']}');
      final responseData = await _executeRequest('v1/messages', body, apiKey);

      // 응답 처리
      final result = _normalizeChunkResponse(responseData);
      
      // 캐싱이 활성화되어 있고 캐시를 사용할 수 있는 경우 응답 캐싱
      if (enableApiCaching && useCache) {
        final cacheKey = _createCacheKey('v1/messages', body);
        await _cacheService.set(cacheKey, result, duration: Duration(milliseconds: apiCacheTTL));
      }
      
      // 크레딧/생성 횟수 차감 (캐시에서 가져온 경우는 제외)
      if (GetIt.instance.isRegistered<SubscriptionService>() && !fromCache) {
        final subscriptionService = GetIt.instance<SubscriptionService>();
        await subscriptionService.useGeneration();
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

  /// 모델 선택 로직 - 구독 서비스와 연동
  String _selectModel(String? modelOverride) {
    try {
      // 1. 모델 오버라이드가 있으면 우선 적용
      if (modelOverride != null) {
        debugPrint('🤖 오버라이드된 모델 사용: $modelOverride');
        return modelOverride;
      }
      
      // 2. 구독 서비스에서 모델 결정
      if (GetIt.instance.isRegistered<SubscriptionService>()) {
        final subscriptionService = GetIt.instance<SubscriptionService>();
        final selectedModel = subscriptionService.getCurrentModel();

        // 구독 상태 로깅
        final statusStr = subscriptionService.status.toString().split('.').last;
        debugPrint('🤖 구독 서비스에서 가져온 모델: $selectedModel (구독 상태: $statusStr)');
        return selectedModel;
      } else {
        debugPrint('⚠️ 구독 서비스를 찾을 수 없음, 기본 무료 모델 사용');
        return SubscriptionConstants.freeAiModel;
      }
    } catch (e) {
      debugPrint('⚠️ 모델 선택 오류, 기본 무료 모델 사용: $e');
      return SubscriptionConstants.freeAiModel;
    }
  }

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
    
    // 캐시 키 생성 (단어와 문단의 처음 100자를 사용)
    final cacheKey = _createCacheKey(
      'word_explanation',
      {
        'word': word,
        'context': paragraph.length > 100 ? paragraph.substring(0, 100) : paragraph,
      },
    );
    
    // 캐시 확인
    final cachedResponse = await _cacheService.get(cacheKey);
    if (cachedResponse != null) {
      debugPrint('💾 캐시에서 단어 설명 반환: $word');
      return cachedResponse as String;
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
      'model': SubscriptionConstants.freeAiModel,
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
        final explanation = responseData['content'][0]['text'] as String;
        
        // 캐시에 저장 (24시간 TTL)
        await _cacheService.set(
          cacheKey,
          explanation,
          duration: const Duration(hours: 24),
        );
        debugPrint('💾 단어 설명 캐시에 저장: $word');
        
        return explanation;
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
    - Create a concise, creative title that captures the essence of the content (3-7 words)
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

  @override
  Future<Map<String, dynamic>> compareModels(String prompt) async {
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

    // Basic과 Premium 모델로 동일한 프롬프트 실행
    final Map<String, dynamic> results = {
      'basic': {},
      'premium': {},
    };

    // Gemini Flash 모델 테스트
    debugPrint('🔄 Gemini Flash 모델 테스트 시작');
    final basicStopwatch = Stopwatch()..start();
    try {
      final basicBody = {
        'model': 'gemini-1.5-flash',
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

      final basicResponse = await _executeRequest('v1/messages', basicBody, apiKey);
      basicStopwatch.stop();
      
      results['basic'] = {
        'response_time_ms': basicStopwatch.elapsedMilliseconds,
        'result': basicResponse,
      };
      debugPrint('✅ Basic 모델 응답 시간: ${basicStopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      basicStopwatch.stop();
      results['basic'] = {
        'response_time_ms': basicStopwatch.elapsedMilliseconds,
        'error': e.toString(),
      };
      debugPrint('❌ Basic 모델 오류: $e');
    }

    // Premium 모델 테스트
    debugPrint('🔄 Premium 모델 테스트 시작');
    final premiumStopwatch = Stopwatch()..start();
    try {
      final premiumBody = {
        'model': SubscriptionConstants.premiumAiModel,
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

      final premiumResponse = await _executeRequest('v1/messages', premiumBody, apiKey);
      premiumStopwatch.stop();
      
      results['premium'] = {
        'response_time_ms': premiumStopwatch.elapsedMilliseconds,
        'result': premiumResponse,
      };
      debugPrint('✅ Premium 모델 응답 시간: ${premiumStopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      premiumStopwatch.stop();
      results['premium'] = {
        'response_time_ms': premiumStopwatch.elapsedMilliseconds,
        'error': e.toString(),
      };
      debugPrint('❌ Premium 모델 오류: $e');
    }

    return results;
  }

  /// Gemini API 요청 실행
  Future<Map<String, dynamic>> _executeGeminiRequest(
    Map<String, dynamic> body, {
    int retryCount = 0,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    try {
      // Gemini API용 요청 본문 변환
      final messages = body['messages'] as List;
      final userContent = messages[0]['content'][0]['text'];
      
      final geminiBody = {
        'contents': [{
          'parts': [{
            'text': userContent
          }]
        }],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 1,
          'topP': 1,
          'maxOutputTokens': body['max_tokens'] ?? 2500,
        },
      };
      
      // Gemini API URL 구성
      final model = body['model'] as String;
      // TODO: 프로덕션에서는 서버 측 프록시나 환경 변수 사용 필요
      const geminiApiKey = 'AIzaSyDPPWkUNF6M9Wnv4Ue-9h_CDE3P0nmD7tk'; // 임시 하드코딩
      final url = '${ApiConstants.geminiApiUrl}/models/$model:generateContent?key=$geminiApiKey';
      debugPrint('📡 Gemini API 요청 URL: $url');
      
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(geminiBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw ApiException('API request timeout after 60 seconds', statusCode: 408);
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Gemini 응답을 Claude 형식으로 변환
        if (responseData['candidates'] != null && responseData['candidates'].isNotEmpty) {
          final content = responseData['candidates'][0]['content']['parts'][0]['text'];
          return {
            'content': [{
              'type': 'text',
              'text': content
            }]
          };
        } else {
          throw ApiException('Invalid Gemini API response', statusCode: response.statusCode);
        }
      } else {
        // 재시도 가능한 상태 코드인지 확인
        final retriableStatusCodes = [429, 500, 502, 503, 504];
        if (retriableStatusCodes.contains(response.statusCode) && retryCount < maxRetries) {
          final delay = Duration(milliseconds: retryDelay.inMilliseconds * (1 << retryCount));
          await Future.delayed(delay);
          return _executeGeminiRequest(body, retryCount: retryCount + 1);
        }
        
        throw ApiException(
          'Gemini API Error: ${response.statusCode}',
          details: response.body,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is! ApiException && retryCount < maxRetries) {
        final delay = Duration(milliseconds: retryDelay.inMilliseconds * (1 << retryCount));
        await Future.delayed(delay);
        return _executeGeminiRequest(body, retryCount: retryCount + 1);
      }
      
      if (e is ApiException) {
        rethrow;
      } else {
        throw ApiException(
          'Gemini API Error',
          details: e.toString(),
        );
      }
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
        
        // Gemini의 ** 포맷팅 제거
        resultJsonString = _removeGeminiFormatting(resultJsonString);
        resultJsonString = _cleanJsonString(resultJsonString);

        try {
          final dynamic decodedJson = jsonDecode(resultJsonString);
          
          // Map으로 캐스팅
          if (decodedJson is Map) {
            final Map<String, dynamic> parsedJson = Map<String, dynamic>.from(decodedJson);
            
            // 필수 필드 검증
            if ((parsedJson.containsKey('english_chunk') || 
                parsedJson.containsKey('englishContent')) &&
                (parsedJson.containsKey('korean_translation') || 
                parsedJson.containsKey('koreanTranslation'))) {
              
              // wordExplanations 검증 및 보정
              Map<String, dynamic> wordExplanations = Map<String, dynamic>.from(
                parsedJson['wordExplanations'] ?? 
                parsedJson['word_explanations'] ?? 
                parsedJson['wordMappings'] ?? 
                {}
              );
              
              // Gemini가 wordExplanations을 누락한 경우 경고
              if (wordExplanations.isEmpty) {
                debugPrint('⚠️ Gemini가 wordExplanations을 생성하지 않았습니다.');
              }
              
              // 필드 이름 정규화
              return {
                'english_chunk': _cleanContent(parsedJson['englishContent'] ?? parsedJson['english_chunk'] ?? ''),
                'korean_translation': parsedJson['koreanTranslation'] ?? parsedJson['korean_translation'] ?? '',
                'title': parsedJson['title'] ?? 'Generated Chunk',
                'wordExplanations': wordExplanations,
              };
            }
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
    
    // 이 코드는 실행되지 않지만 컴파일러 경고를 방지하기 위해 추가
    throw ApiException(
      'Unexpected error in response normalization',
      statusCode: 0,
    );
  }

  /// JSON 문자열 정제
  String _cleanJsonString(String jsonString) {
    // 문자열 정제 - 백틱이나 추가 문자 제거
    jsonString = jsonString.trim();

    // Gemini 2.5 Pro에서 발생하는 다양한 응답 패턴 처리
    
    // 1. 코드 블록으로 둘러싸인 JSON 처리
    if (jsonString.startsWith('```json') && jsonString.endsWith('```')) {
      // ```json{ 형태 처리 - 줄바꿈 없이 바로 JSON이 시작되는 경우
      jsonString = jsonString.substring(7); // ```json 제거 (7글자)
      if (jsonString.endsWith('```')) {
        jsonString = jsonString.substring(0, jsonString.length - 3); // 마지막 ``` 제거
      }
    } else if (jsonString.startsWith('```') && jsonString.endsWith('```')) {
      jsonString = jsonString
          .replaceFirst('```', '')
          .replaceFirst('```', '');
    }

    // 2. 설명 텍스트와 함께 JSON이 포함된 경우 처리
    // JSON 블록을 찾아서 추출
    final jsonBlockMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(jsonString);
    if (jsonBlockMatch != null) {
      jsonString = jsonBlockMatch.group(0)!;
    }

    // 3. 줄바꿈과 탭 문자 정리 (Gemini 2.5 Pro가 자주 사용)
    jsonString = jsonString
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .replaceAll('\t', ' ')
        .replaceAll(RegExp(r'\s+'), ' '); // 여러 공백을 하나로

    // 4. 잘못된 따옴표 수정 (Gemini가 가끔 사용하는 스마트 따옴표)
    jsonString = jsonString
        .replaceAll('"', '"')
        .replaceAll('"', '"')
        .replaceAll(''', "'")
        .replaceAll(''', "'");

    // 5. JSON 앞뒤의 설명 텍스트 제거
    final lines = jsonString.split('\n');
    int startIndex = -1;
    int endIndex = -1;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('{')) {
        startIndex = i;
        break;
      }
    }
    
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].trim();
      if (line.endsWith('}')) {
        endIndex = i;
        break;
      }
    }
    
    if (startIndex != -1 && endIndex != -1 && startIndex <= endIndex) {
      jsonString = lines.sublist(startIndex, endIndex + 1).join('\n');
    }

    return jsonString.trim();
  }

  /// Gemini 응답에서 ** 포맷팅 제거
  String _removeGeminiFormatting(String content) {
    // Gemini가 자주 사용하는 ** 포맷팅 제거
    return content
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')  // **word** -> word
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')      // *word* -> word
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1')      // __word__ -> word
        .replaceAll(RegExp(r'_([^_]+)_'), r'$1');       // _word_ -> word
  }
  
  /// 콘텐츠에서 포맷팅 정리
  String _cleanContent(String content) {
    // 1. Gemini 포맷팅 제거
    String cleaned = _removeGeminiFormatting(content);
    
    // 2. 구분자 정규화 (||| 뒤에 공백 추가)
    cleaned = _normalizeDelimiters(cleaned);
    
    return cleaned;
  }

  /// 구분자 정규화 - ||| 뒤에 공백이 없으면 추가
  String _normalizeDelimiters(String content) {
    return content
        // ||| 뒤에 공백이 없으면 추가
        .replaceAll(RegExp(r'\|\|\|(?!\s)'), '||| ')
        // 중복 공백 정리
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 수동 JSON 추출 메서드 (Gemini 2.5 Pro 특화)
  Map<String, dynamic> _extractJsonManually(String jsonString) {
    debugPrint('🔧 수동 JSON 추출 시작, 원본 길이: ${jsonString.length}');
    
    try {
      // 1단계: 이스케이프 문자 처리
      String cleaned = jsonString
          .replaceAll('\\n', '\n')
          .replaceAll('\\r', '\r')
          .replaceAll('\\t', '\t')
          .replaceAll('\\"', '"');

      // 2단계: 다시 파싱 시도
      final dynamic decoded = jsonDecode(cleaned);
      if (decoded is Map) {
        debugPrint('✅ 이스케이프 처리 후 파싱 성공');
        return Map<String, dynamic>.from(decoded);
      }
      throw FormatException('Decoded JSON is not a Map');
    } catch (e) {
      debugPrint('⚠️ 표준 파싱 실패, 정규식 추출 시도: $e');
      
      // 3단계: 강화된 정규 표현식으로 필드 추출
      Map<String, dynamic> result = {};

      // Gemini 2.5 Pro가 사용하는 다양한 필드명 패턴 처리
      final fieldPatterns = {
        'english_chunk': [
          r'"english_chunk"\s*:\s*"((?:[^"\\]|\\.)*)\"',
          r'"englishContent"\s*:\s*"((?:[^"\\]|\\.)*)\"',
          r'"english"\s*:\s*"((?:[^"\\]|\\.)*)\"',
          r'"content"\s*:\s*"((?:[^"\\]|\\.)*)"',
        ],
        'korean_translation': [
          r'"korean_translation"\s*:\s*"((?:[^"\\]|\\.)*)\"',
          r'"koreanTranslation"\s*:\s*"((?:[^"\\]|\\.)*)\"',
          r'"korean"\s*:\s*"((?:[^"\\]|\\.)*)\"',
          r'"translation"\s*:\s*"((?:[^"\\]|\\.)*)"',
        ],
        'title': [
          r'"title"\s*:\s*"((?:[^"\\]|\\.)*)\"',
          r'"name"\s*:\s*"((?:[^"\\]|\\.)*)"',
        ],
      };

      // 각 필드를 순차적으로 추출 시도
      for (final entry in fieldPatterns.entries) {
        final fieldName = entry.key;
        final patterns = entry.value;
        
        bool found = false;
        for (final pattern in patterns) {
          final match = RegExp(pattern, multiLine: true, dotAll: true).firstMatch(jsonString);
          if (match != null) {
            String value = match.group(1)!;
            // 이스케이프된 문자 복원
            value = value
                .replaceAll('\\"', '"')
                .replaceAll('\\n', '\n')
                .replaceAll('\\r', '\r')
                .replaceAll('\\t', '\t')
                .replaceAll('\\\\', '\\');
            result[fieldName] = value;
            debugPrint('✅ $fieldName 추출 성공: ${value.substring(0, value.length.clamp(0, 50))}...');
            found = true;
            break;
          }
        }
        
        if (!found) {
          debugPrint('❌ $fieldName 필드 추출 실패 - 모든 패턴 시도했으나 매치되지 않음');
        }
      }

      // 기본값 설정
      if (!result.containsKey('title')) {
        result['title'] = 'Generated Chunk';
      }

      // word_explanations 처리 (더 강화된 방식)
      if (jsonString.contains('"word_explanations"') || 
          jsonString.contains('"wordExplanations"') ||
          jsonString.contains('"explanations"')) {
        
        // 간단한 객체 추출 시도
        final explanationMatch = RegExp(
          r'"(?:word_explanations|wordExplanations|explanations)"\s*:\s*(\{[^}]*\})',
          multiLine: true,
          dotAll: true,
        ).firstMatch(jsonString);
        
        if (explanationMatch != null) {
          try {
            final explanationsJson = explanationMatch.group(1)!;
            result['wordExplanations'] = jsonDecode(explanationsJson);
            debugPrint('✅ wordExplanations 추출 성공');
          } catch (e) {
            debugPrint('⚠️ wordExplanations 파싱 실패, 빈 객체 사용');
            result['wordExplanations'] = {};
          }
        } else {
          result['wordExplanations'] = {};
        }
      } else {
        result['wordExplanations'] = {};
      }

      // 필수 필드 검증
      if (result.containsKey('english_chunk') && result.containsKey('korean_translation')) {
        debugPrint('✅ 수동 추출 성공: ${result.keys.join(', ')}');
        return result;
      }

      debugPrint('❌ 수동 추출 실패: 필수 필드 누락');
      debugPrint('발견된 필드: ${result.keys.join(', ')}');
      debugPrint('원본 텍스트 샘플: ${jsonString.substring(0, jsonString.length.clamp(0, 500))}...');
      
      throw Exception('수동 추출 실패: 필수 필드(english_chunk, korean_translation)를 찾을 수 없습니다.');
    }
  }

  /// API 설정 초기화 (정적 메서드 - 기존 호환성 유지)
  static Future<void> initializeApiSettings() async {
    try {
      final service = UnifiedApiService(
        httpClient: http.Client(),
        networkService: GetIt.instance<NetworkService>(),
        cacheService: GetIt.instance<CacheService>(),
      );
      
      await service.initialize();
      debugPrint('✅ API 키 초기화 완료');
    } catch (e) {
      debugPrint('❌ API 키 초기화 실패: $e');
    }
  }

  /// API 키 검증 (정적 메서드 - 기존 호환성 유지)
  static Future<bool> verifyApiKey(String apiKey) async {
    // 개발 중에만 사용하는 확인 기능
    if (!kReleaseMode) {
      try {
        final service = UnifiedApiService(
          httpClient: http.Client(),
          networkService: GetIt.instance<NetworkService>(),
          cacheService: GetIt.instance<CacheService>(),
        );
        
        return await service.validateApiKey(apiKey);
      } catch (e) {
        debugPrint('API 키 검증 오류: $e');
        return false;
      }
    }
    
    // 릴리즈 모드에서는 항상 true 반환
    return true;
  }

  /// API 키 가져오기 (정적 메서드 - 기존 호환성 유지)
  static Future<String?> getStaticApiKey() async {
    try {
      final service = UnifiedApiService(
        httpClient: http.Client(),
        networkService: GetIt.instance<NetworkService>(),
        cacheService: GetIt.instance<CacheService>(),
      );
      
      return await service.getApiKey();
    } catch (e) {
      debugPrint('API 키 가져오기 오류: $e');
      return null;
    }
  }
  
  /// Gemini용 프롬프트 강화
  String _enhancePromptForGemini(String prompt) {
    // Gemini에서 wordExplanations가 누락되는 문제를 해결하기 위한 특별 처리
    if (!prompt.contains('wordExplanations')) {
      return prompt;
    }
    
    // Gemini 특화 추가 지시사항
    final geminiEnhancement = '''

🚨 CRITICAL FOR GEMINI: You MUST include the wordExplanations field in your JSON response.

📋 GEMINI-SPECIFIC REQUIREMENTS:
• ALWAYS include wordExplanations in the JSON output
• Do NOT use ** or any markdown formatting around words in the content
• Use plain text for all vocabulary words in the englishContent
• Ensure wordExplanations contains entries for ALL vocabulary words provided
• Format wordExplanations as: "word": "한국어 뜻: 이 문맥에서 어떻게 사용되었는지 설명"

⚠️ FORMATTING RULES FOR GEMINI:
• NO bold (**word**) or italic (*word*) formatting in englishContent
• NO special markers around vocabulary words
• Plain text only in the story content
• Keep vocabulary words natural and unformatted

✅ EXAMPLE of correct wordExplanations format:
{
  "wordExplanations": {
    "comprehensive": "포괄적인: 이 문맥에서는 보고서가 모든 세부사항을 빠짐없이 포함한다는 의미로 사용되었습니다",
    "meticulous": "세심한: 여기서는 작업을 매우 꼼꼼하고 정확하게 수행한다는 뜻으로 사용되었습니다"
  }
}

🔄 RESPONSE CHECKLIST:
☐ JSON format is valid
☐ englishContent has NO ** formatting
☐ koreanTranslation is complete
☐ wordExplanations field exists
☐ wordExplanations has entries for all words
☐ wordExplanations uses Korean format
''';
    
    return prompt + geminiEnhancement;
  }

  /// 깊은 생각 모드 패턴 감지
  bool _containsDeepThinkingPatterns(String prompt) {
    final deepThinkingPatterns = [
      // 직접적인 사고 요청
      RegExp(r'<thinking>.*?</thinking>', caseSensitive: false, dotAll: true),
      RegExp(r'think\s+step\s+by\s+step', caseSensitive: false),
      RegExp(r'think\s+carefully', caseSensitive: false),
      RegExp(r'think\s+deeply', caseSensitive: false),
      RegExp(r'reason\s+through', caseSensitive: false),
      RegExp(r'reasoning\s+process', caseSensitive: false),
      RegExp(r"let'?s\s+think", caseSensitive: false),
      RegExp(r'show\s+your\s+(reasoning|thinking|work)', caseSensitive: false),
      
      // 단계별 사고 요청
      RegExp(r'step[\s-]by[\s-]step', caseSensitive: false),
      RegExp(r'break\s+down\s+your\s+thinking', caseSensitive: false),
      RegExp(r'walk\s+me\s+through', caseSensitive: false),
      
      // Chain of Thought 관련
      RegExp(r'chain\s+of\s+thought', caseSensitive: false),
      RegExp(r'CoT', caseSensitive: true),
      
      // 특수 토큰/마커
      RegExp(r'</?think>', caseSensitive: false),
      RegExp(r'</?reasoning>', caseSensitive: false),
    ];
    
    for (final pattern in deepThinkingPatterns) {
      if (pattern.hasMatch(prompt)) {
        return true;
      }
    }
    
    return false;
  }

  @override
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    // UnifiedApiService에서는 구독 기능 미지원
    throw ApiException('구독 기능은 Firebase 서비스에서만 지원됩니다');
  }

  @override
  Future<String> upgradeSubscription({
    required String subscriptionTier,
    required Map<String, dynamic> paymentInfo,
  }) async {
    // UnifiedApiService에서는 구독 기능 미지원
    throw ApiException('구독 업그레이드는 Firebase 서비스에서만 지원됩니다');
  }
}
// lib/core/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chunk_up/data/services/storage/local_storage_service.dart';
import 'package:chunk_up/core/utils/api_exception.dart';
import 'package:chunk_up/core/utils/business_exception.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:flutter/material.dart';
import 'package:chunk_up/data/datasources/remote/api_service.dart' as remote_api;
import 'package:chunk_up/core/services/cache_service.dart';
import 'package:crypto/crypto.dart';
import 'package:chunk_up/core/constants/subscription_constants.dart';
import 'package:chunk_up/core/services/embedded_api_service.dart';
import 'dart:math';
import 'package:chunk_up/core/services/subscription_service.dart';
import 'package:get_it/get_it.dart';

class ApiService {
  static const String _apiKeyStorageKey = 'api_key';
  static const String _baseUrl = 'https://api.anthropic.com';

  final StorageService _storageService;
  final http.Client _httpClient;
  final CacheService _cacheService;
  SubscriptionService? _subscriptionService;

  // 캐시 관련 설정
  static const bool enableApiCaching = true;
  static const int apiCacheTTL = 30 * 60 * 1000; // 30분 캐시

  // 재시도 관련 설정
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Factory constructor with dependency injection
  factory ApiService({
    StorageService? storageService,
    http.Client? httpClient,
    CacheService? cacheService,
  }) {
    return ApiService._internal(
      storageService ?? LocalStorageService(),
      httpClient ?? http.Client(),
      cacheService ?? CacheService(),
    );
  }

  ApiService._internal(this._storageService, this._httpClient, this._cacheService) {
    // SubscriptionService 인스턴스 초기화 시도
    try {
      if (!GetIt.I.isRegistered<SubscriptionService>()) {
        debugPrint('⚠️ API 서비스 생성자에서 SubscriptionService가 등록되지 않음, 등록 시도...');
        GetIt.I.registerLazySingleton<SubscriptionService>(() => SubscriptionService());
      }
      _subscriptionService = GetIt.I<SubscriptionService>();
      debugPrint('✅ API 서비스에서 SubscriptionService 초기화 성공');
    } catch (e) {
      debugPrint('❌ API 서비스에서 SubscriptionService 초기화 실패: $e');
    }
  }

  /// Get the API key from storage (non-static for instance method)
  Future<String?> get apiKey async {
    return await _storageService.getString(_apiKeyStorageKey);
  }

  /// Get the API key from storage (static convenience method)
  static Future<String?> getApiKey() async {
    try {
      // 먼저 내장 API 키 서비스에서 키 가져오기 시도
      final embeddedKey = await EmbeddedApiService.getApiKey();
      if (embeddedKey != null && embeddedKey.isNotEmpty) {
        return embeddedKey;
      }

      // 내장 키가 없으면 스토리지에서 가져오기
      final service = LocalStorageService();
      return await service.getString(_apiKeyStorageKey);
    } catch (e) {
      debugPrint('API 키 가져오기 오류: $e');
      // 오류 발생 시 null 반환하여 API 키 없음 상태로 처리
      return null;
    }
  }

  /// Save the API key to storage - static version
  static Future<void> saveApiKeyStatic(String key) async {
    debugPrint('🔑 API 키 저장 중... (정적 메서드)');
    // 로컬 스토리지에 저장
    final service = LocalStorageService();
    await service.setString(_apiKeyStorageKey, key);

    // 보안 저장소에도 저장 (data/datasources/remote/api_service.dart에서 사용)
    try {
      await remote_api.ApiService.saveApiKeyStatic(key);
      debugPrint('✅ API 키가 로컬 및 보안 저장소에 저장됨');
    } catch (e) {
      debugPrint('⚠️ 보안 저장소 저장 실패: $e');
    }
  }

  /// 인스턴스에서 API 키 저장 (인스턴스 메서드)
  Future<void> saveApiKey(String key) async {
    debugPrint('🔑 API 키 저장 중... (인스턴스 메서드)');
    await _storageService.setString(_apiKeyStorageKey, key);

    // 보안 저장소에도 저장
    try {
      await remote_api.ApiService.saveApiKeyStatic(key);
    } catch (e) {
      debugPrint('⚠️ 보안 저장소 저장 실패: $e');
    }
  }

  /// Clear the API key from storage
  static Future<void> clearApiKey() async {
    final service = LocalStorageService();
    await service.remove(_apiKeyStorageKey);
  }

  /// 캐시 키 생성 메서드
  String _createCacheKey(String endpoint, Map<String, dynamic> body) {
    final requestString = '$endpoint:${jsonEncode(body)}';
    final bytes = utf8.encode(requestString);
    final hash = sha256.convert(bytes);
    return 'api_cache_${hash.toString()}';
  }

  /// 재시도 로직이 포함된 API 요청 메서드
  Future<Map<String, dynamic>> _executeRequest(
    String endpoint,
    Map<String, dynamic> body,
    String apiKey,
    {int retryCount = 0}
  ) async {
    try {
      // API 요청 로깅 (민감한 정보는 제외)
      final sanitizedBody = Map<String, dynamic>.from(body);
      if (retryCount == 0) {
        debugPrint('📤 API 요청: ${jsonEncode(sanitizedBody)}');
        debugPrint('🌐 API URL: $_baseUrl/$endpoint');
      } else {
        debugPrint('🔄 API 요청 재시도 #$retryCount: $_baseUrl/$endpoint');
      }

      // anthropic-version 헤더 추가
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01', // API 버전 헤더 추가
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 45), // API 요청 타임아웃 설정
        onTimeout: () {
          throw ApiException(
            'API request timeout after 45 seconds',
            statusCode: 408,
            details: 'The request took too long to complete',
          );
        },
      );

      // 응답 상태 코드 로깅
      debugPrint('📥 API 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse = jsonDecode(response.body);
        // 응답 일부만 로깅 (너무 길 수 있음)
        final responseString = jsonEncode(decodedResponse);
        final responsePreview = responseString.substring(
          0,
          responseString.length > 300 ? 300 : responseString.length
        );
        debugPrint('✅ API 응답 (일부): $responsePreview...');
        return decodedResponse;
      } else {
        // 오류 응답 전체 로깅 및 상세 분석
        final errorBody = response.body;
        debugPrint('❌ API 오류 응답: $errorBody');
        
        // 오류 응답 구문 분석 시도
        try {
          final errorJson = jsonDecode(errorBody);
          if (errorJson.containsKey('error')) {
            final error = errorJson['error'];
            if (error is Map) {
              final errorType = error['type'];
              final errorMessage = error['message'];
              debugPrint('🚨 API 오류 타입: $errorType');
              debugPrint('🚨 API 오류 메시지: $errorMessage');
            }
          }
        } catch (e) {
          debugPrint('🚨 API 오류 구문 분석 실패: $e');
        }
        
        // 재시도 가능한 상태 코드인지 확인 (429, 500, 502, 503, 504)
        final retriableStatusCodes = [429, 500, 502, 503, 504];
        if (retriableStatusCodes.contains(response.statusCode) && retryCount < maxRetries) {
          // 지수 백오프를 사용한 재시도 지연 계산 (2초, 4초, 8초...)
          final delay = Duration(milliseconds: retryDelay.inMilliseconds * (1 << retryCount));
          debugPrint('⏱️ ${delay.inSeconds}초 후 재시도합니다...');
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
        debugPrint('⏱️ 네트워크 오류 발생, ${delay.inSeconds}초 후 재시도합니다...');
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

  /// Send a request to the Anthropic API (with caching and retry)
  Future<Map<String, dynamic>> sendRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    bool useCache = true,
  }) async {
    final key = await this.apiKey;
    debugPrint('🔍 API 키 확인: ${key != null ? "API 키 있음 (${key.substring(0, min(10, key.length))}...)" : "API 키 없음"}');

    if (key == null || key.isEmpty) {
      debugPrint('❌ API 키가 설정되지 않았습니다');
      throw BusinessException(
        type: BusinessErrorType.apiKeyNotSet,
        message: 'API key not found, please set your API key in settings',
      );
    }

    try {
      // 캐싱이 활성화되어 있고 캐시를 사용할 수 있는 경우
      if (enableApiCaching && useCache) {
        final cacheKey = _createCacheKey(endpoint, body);
        
        // 캐시에서 데이터 가져오기 시도
        if (await _cacheService.has(cacheKey)) {
          debugPrint('🗃️ 캐시된 응답 사용: $cacheKey');
          final cachedData = await _cacheService.get<Map<String, dynamic>>(cacheKey);
          if (cachedData != null) {
            return cachedData;
          }
        }
      }

      // API 요청 실행 (재시도 로직 포함)
      final responseData = await _executeRequest(endpoint, body, key);
      
      // 캐싱이 활성화되어 있고 캐시를 사용할 수 있는 경우 응답 캐싱
      if (enableApiCaching && useCache) {
        final cacheKey = _createCacheKey(endpoint, body);
        await _cacheService.set(cacheKey, responseData, ttlMs: apiCacheTTL);
        debugPrint('💾 API 응답 캐시됨: $cacheKey');
      }
      
      return responseData;
    } catch (e) {
      if (e is ApiException) {
        debugPrint('🚨 API 예외: ${e.message}, 상태 코드: ${e.statusCode}, 상세: ${e.details}');
      } else {
        debugPrint('🚨 네트워크 오류: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Generate a chunk for the given words
  Future<Map<String, dynamic>> generateChunk(String prompt, {
    String? modelOverride,
    bool trackPerformance = true
  }) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('🚀 generateChunk 호출됨 - 프롬프트 길이: ${prompt.length}');
    debugPrint('📄 프롬프트 시작 부분: ${prompt.substring(0, prompt.length > 100 ? 100 : prompt.length)}...');

    try {
      debugPrint('🔄 직접 API 구현 사용');

      // API 키 직접 확인
      final apiKey = await this.apiKey;
      debugPrint('🔑 API 키 확인: ${apiKey != null ? "유효함" : "없음"}');

      // 모델 선택 (구독 상태에 따라 모델 결정)
      String model;
      if (modelOverride != null) {
        // 명시적으로 지정된 모델이 있으면 사용
        model = modelOverride;
        debugPrint('🤖 명시적으로 지정된 모델 사용: $model');
      } else {
        // 없으면 현재 구독 상태에 따라 모델 결정
        try {
          // 1. 먼저 내부 인스턴스 사용 시도
          if (_subscriptionService != null) {
            model = _subscriptionService!.getCurrentModel();
            debugPrint('🤖 내부 구독 서비스로부터 모델 가져옴: $model');
          }
          // 2. 내부 인스턴스가 없으면 GetIt 사용 시도
          else {
            // 서비스 등록 여부 확인 및 필요시 등록
            if (!GetIt.I.isRegistered<SubscriptionService>()) {
              debugPrint('⚠️ SubscriptionService가 등록되지 않음, 등록 시도...');
              GetIt.I.registerLazySingleton<SubscriptionService>(() => SubscriptionService());
            }

            final subscriptionService = GetIt.I<SubscriptionService>();
            model = subscriptionService.getCurrentModel();

            // 향후 사용을 위해 내부 인스턴스에 저장
            _subscriptionService = subscriptionService;

            debugPrint('🤖 GetIt에서 구독 서비스로부터 모델 가져옴: $model');
          }
        } catch (e) {
          debugPrint('⚠️ 구독 서비스 접근 실패, 기본 모델 사용: $e');
          model = SubscriptionConstants.freeAiModel; // 오류 시 무료 모델로 폴백
        }
      }
      debugPrint('🤖 사용 모델: $model');

      // 디버그를 위해 전체 프롬프트 출력 (개발 모드에서만 표시)
      debugPrint('📝 전체 프롬프트 내용:');
      debugPrint('==========================================================');
      debugPrint(prompt);
      debugPrint('==========================================================');

      // 응답 로깅
      final response = await sendRequest(
        endpoint: 'v1/messages',
        body: {
          'model': model,
          'max_tokens': 2500,
          'temperature': 0.7, // 적절한 temperature 추가
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
        },
      );

      debugPrint('✅ API 호출 성공');

      // 결과 디버깅을 위해 응답의 주요 부분 출력
      try {
        // 성능 측정 중지 및 로깅
        stopwatch.stop();
        final elapsedMs = stopwatch.elapsedMilliseconds;

        debugPrint('⏱️ 응답 시간: ${elapsedMs}ms (${(elapsedMs / 1000).toStringAsFixed(2)}초)');
        debugPrint('🤖 사용 모델: $model');
        debugPrint('📐 프롬프트 길이: ${prompt.length} 문자');

        final responseJson = jsonEncode(response);
        debugPrint('📊 응답 요약:');
        debugPrint('==========================================================');

        // 응답에서 주요 필드 추출 시도
        if (response.containsKey('content') && response['content'] is List && response['content'].isNotEmpty) {
          final content = response['content'][0]['text'];
          if (content != null) {
            // JSON 형식의 응답인지 확인하고 파싱
            if (content.contains('{') && content.contains('}')) {
              final jsonStart = content.indexOf('{');
              final jsonEnd = content.lastIndexOf('}');
              if (jsonStart >= 0 && jsonEnd > jsonStart) {
                final jsonContent = content.substring(jsonStart, jsonEnd + 1);
                // JSON 파싱 시도
                try {
                  final parsedJson = jsonDecode(jsonContent);
                  if (parsedJson.containsKey('title')) debugPrint('제목: ${parsedJson['title']}');
                  if (parsedJson.containsKey('englishContent') || parsedJson.containsKey('english_chunk')) {
                    final englishText = parsedJson['englishContent'] ?? parsedJson['english_chunk'];
                    debugPrint('영어 내용 (일부): ${englishText.substring(0, min(100, englishText.length))}...');
                  }
                } catch (e) {
                  debugPrint('JSON 파싱 실패: $e');
                  debugPrint('내용 일부: ${content.substring(0, min(300, content.length))}...');
                }
              } else {
                debugPrint('내용 일부: ${content.substring(0, min(300, content.length))}...');
              }
            } else {
              debugPrint('내용 일부: ${content.substring(0, min(300, content.length))}...');
            }
          }
        } else {
          debugPrint('응답 전체 (일부): ${responseJson.substring(0, min(300, responseJson.length))}...');
        }

        debugPrint('==========================================================');
      } catch (e) {
        debugPrint('응답 디버깅 중 오류: $e');
      }

      return response;
    } catch (e) {
      debugPrint('❌ generateChunk 실패: ${e.toString()}');
      if (e is ApiException) {
        debugPrint('🔍 API 오류 상세: 상태 코드=${e.statusCode}, 메시지=${e.message}');
        debugPrint('🔍 API 오류 상세 내용: ${e.details}');
      }
      rethrow;
    }
  }

  /// 간단한 API 테스트 함수 (디버깅용)
  Future<bool> testApiConnection() async {
    try {
      debugPrint('🧪 API 연결 테스트 시작');

      // 인스턴스의 apiKey 메서드로 키 가져오기
      var key = await this.apiKey;

      // 키가 없으면 EmbeddedApiService에서 직접 가져오기 시도
      if (key == null || key.isEmpty) {
        debugPrint('⚠️ 인스턴스 API 키 없음, 내장 키 시도 중...');
        try {
          // 내장 API 키 초기화 및 가져오기 시도
          await EmbeddedApiService.initializeApiSettings();
          key = await EmbeddedApiService.getApiKey();

          // 키를 성공적으로 가져왔으면 저장
          if (key != null && key.isNotEmpty) {
            debugPrint('✅ 내장 API 키 가져오기 성공');
            await saveApiKeyStatic(key); // 현재 인스턴스에 저장
          }
        } catch (e) {
          debugPrint('❌ 내장 API 키 가져오기 실패: $e');
        }
      }

      // 최종 확인
      if (key == null || key.isEmpty) {
        debugPrint('❌ API 키가 없어 테스트 불가');
        return false;
      }

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': key,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-7-sonnet-20250219',
          'max_tokens': 100,
          'messages': [
            {'role': 'user', 'content': 'Say "API connection test successful"'}
          ],
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw ApiException(
            'API test connection timeout',
            statusCode: 408,
            details: 'Connection test timed out after 10 seconds',
          );
        },
      );

      debugPrint('🧪 API 테스트 응답 코드: ${response.statusCode}');
      debugPrint('🧪 API 테스트 응답 내용: ${response.body.substring(0, min(response.body.length, 200))}...');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ API 테스트 실패: $e');
      return false;
    }
  }

  /// Generate multiple chunks for a list of words
  Future<List<Map<String, dynamic>>> generateChunksForWords(List<Word> words, {
    String? modelOverride,
    bool trackPerformance = true
  }) async {
    debugPrint('📚 generateChunksForWords 호출됨 - 단어 수: ${words.length}');
    debugPrint('🤖 사용 모델: ${modelOverride ?? "기본 모델 (구독 플랜에 따라 다름)"}');
    final List<Map<String, dynamic>> results = [];

    // 먼저 API 연결 테스트
    final isApiConnected = await testApiConnection();
    debugPrint('🔌 API 연결 테스트 결과: ${isApiConnected ? "성공" : "실패"}');

    // Build prompt with words
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

    return results;
  }

  // 유틸리티 함수: 최소값 계산
  int min(int a, int b) => a < b ? a : b;

  /// 모델 성능 비교 테스트
  /// 같은 프롬프트로 두 모델(Basic/Premium)의 성능을 비교합니다.
  Future<Map<String, dynamic>> compareModels(String prompt) async {
    debugPrint('🔬 모델 성능 비교 테스트 시작');

    // SubscriptionService 이용하여 설정된 모델 가져오기 시도
    String? basicModel;
    String? premiumModel;

    try {
      // 모델 ID 확인
      if (_subscriptionService != null) {
        // 현재 상태 백업
        final originalStatus = _subscriptionService!.status;

        // 기본 구독 상태로 변경
        await _subscriptionService!.activateTestSubscription(isPremium: false);
        basicModel = _subscriptionService!.getCurrentModel();

        // 프리미엄 구독 상태로 변경
        await _subscriptionService!.activateTestSubscription(isPremium: true);
        premiumModel = _subscriptionService!.getCurrentModel();

        // 원래 상태로 복원
        if (originalStatus == TestSubscriptionStatus.premium ||
            originalStatus == TestSubscriptionStatus.testPremium) {
          await _subscriptionService!.activateTestSubscription(isPremium: true);
        } else if (originalStatus == TestSubscriptionStatus.basic) {
          await _subscriptionService!.activateTestSubscription(isPremium: false);
        } else {
          await _subscriptionService!.reset();
        }
      }
    } catch (e) {
      debugPrint('⚠️ 구독 서비스에서 모델 정보 가져오기 실패: $e');
    }

    // 가져온 모델이 없으면 기본값 사용
    basicModel ??= SubscriptionConstants.basicAiModel;
    premiumModel ??= SubscriptionConstants.premiumAiModel;

    // 시간 측정용 Stopwatch
    final basicStopwatch = Stopwatch()..start();
    final premiumStopwatch = Stopwatch()..start();

    // 1. Basic 모델 테스트
    debugPrint('🧪 기본 모델 ($basicModel) 테스트 시작');
    final basicResult = await generateChunk(
      prompt,
      modelOverride: basicModel,
      trackPerformance: true
    );
    basicStopwatch.stop();

    // 잠시 대기 (API 요청 간 간격 유지)
    await Future.delayed(const Duration(seconds: 1));

    // 2. Premium 모델 테스트
    debugPrint('🧪 프리미엄 모델 ($premiumModel) 테스트 시작');
    final premiumResult = await generateChunk(
      prompt,
      modelOverride: premiumModel,
      trackPerformance: true
    );
    premiumStopwatch.stop();

    // 결과 요약
    debugPrint('📊 모델 성능 비교 결과:');
    debugPrint('==========================================================');
    debugPrint('⏱️ Basic 모델 응답 시간: ${basicStopwatch.elapsedMilliseconds}ms (${(basicStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}초)');
    debugPrint('⏱️ Premium 모델 응답 시간: ${premiumStopwatch.elapsedMilliseconds}ms (${(premiumStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}초)');
    debugPrint('🏆 속도 차이: ${(basicStopwatch.elapsedMilliseconds - premiumStopwatch.elapsedMilliseconds).abs()}ms');
    debugPrint('==========================================================');

    return {
      'basic': {
        'model': basicModel,
        'response_time_ms': basicStopwatch.elapsedMilliseconds,
        'result': basicResult,
      },
      'premium': {
        'model': premiumModel,
        'response_time_ms': premiumStopwatch.elapsedMilliseconds,
        'result': premiumResult,
      },
    };
  }
}
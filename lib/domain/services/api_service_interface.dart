// lib/domain/services/api_service_interface.dart
import 'dart:async';
import '../../core/utils/api_exception.dart';

/// API 서비스 인터페이스
/// 
/// 외부 API 서비스와의 상호작용을 위한 추상 인터페이스를 정의합니다.
/// 이를 통해 구현체를 쉽게 교체하고 테스트할 수 있습니다.
abstract class ApiServiceInterface {
  /// API 키 가져오기
  Future<String?> getApiKey();
  
  /// API 키 저장하기
  Future<void> saveApiKey(String apiKey);
  
  /// API 키 검증하기
  Future<bool> validateApiKey(String apiKey);
  
  /// API 연결 테스트하기
  Future<bool> testApiConnection();
  
  /// 청크 생성하기
  /// 
  /// [prompt]에 기반한 청크를 생성합니다.
  /// 
  /// [useCache]가 true이면 캐시된 응답을 반환할 수 있습니다.
  /// [trackPerformance]가 true이면 성능 측정 결과가 로그에 기록됩니다.
  Future<Map<String, dynamic>> generateChunk(
    String prompt, {
    String? modelOverride,
    bool useCache = true,
    bool trackPerformance = false,
  });
  
  /// 단어 설명 생성하기
  /// 
  /// [word]에 대한 설명을 [paragraph] 컨텍스트를 기반으로 생성합니다.
  Future<String> generateWordExplanation(String word, String paragraph);
  
  /// 단어 목록에 대한 청크 생성하기
  /// 
  /// [words] 목록에 기반한 청크를 생성합니다.
  Future<List<Map<String, dynamic>>> generateChunksForWords(
    List<dynamic> words, {
    String? modelOverride,
    bool trackPerformance = true
  });
  
  /// API 서비스 초기화
  Future<void> initialize();
}

/// 네트워크 관련 예외 클래스
class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

/// API 응답 처리 중 시간 초과 예외
class TimeoutException extends ApiException {
  final Object? source;
  
  TimeoutException(String message, this.source) : super(message);
}
// lib/core/constants/api_constants.dart
class ApiConstants {
  // Anthropic API 제거 - 오직 Gemini만 사용
  
  // Gemini API
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta';
  // Gemini API 키는 서버에서 관리하거나 환경 변수로 설정해야 함
  static const String geminiApiKeyStorageKey = 'gemini_api_key';

  // Model names - 오직 Gemini 2.5 Flash만 사용
  static const String defaultModel = 'gemini-2.5-flash-preview-05-20'; // 모든 사용자를 위한 단일 모델

  static const Duration connectionTimeout = Duration(seconds: 20);
  static const Duration readTimeout = Duration(seconds: 90);

  static const int maxRetries = 3;
  static const int maxTokens = 2500;
  static const int maxExplanationTokens = 500;

  // API 키 저장소 키 제거 - Gemini는 URL에 키 포함
  
  // Free tier limits
  static const int freeApiCallsTotal = 5; // 5회 무료 이용 후 결제 필요
  static const int premiumApiCallsPerMonth = 100; // Premium 월 100회
}
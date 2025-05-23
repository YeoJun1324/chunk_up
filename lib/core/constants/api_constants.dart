// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String apiUrl = 'https://api.anthropic.com';
  static const String apiVersion = '2023-06-01';

  // 기본 모델은 무료 버전 모델로 설정 (구독 서비스에서 적절한 모델을 선택함)
  static const String apiModel = 'claude-3-haiku-20240307'; // 기본적으로 무료 모델 사용
  static const String premiumModel = 'claude-3-7-sonnet-20250219';

  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration readTimeout = Duration(seconds: 60);

  static const int maxRetries = 3;
  static const int maxTokens = 2500;
  static const int maxExplanationTokens = 500;

  static const String secureStorageApiKeyKey = 'claude_api_key';
}
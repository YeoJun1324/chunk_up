// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String apiVersion = '2023-06-01';

  // 최신 모델 버전 사용
  static const String apiModel = 'claude-3-7-sonnet-20250219';
  static const String alternativeModel = 'claude-3-haiku-20240307';

  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration readTimeout = Duration(seconds: 60);

  static const int maxRetries = 3;
  static const int maxTokens = 2500;
  static const int maxExplanationTokens = 500;

  static const String secureStorageApiKeyKey = 'claude_api_key';
}
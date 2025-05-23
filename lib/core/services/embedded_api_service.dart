// lib/core/services/embedded_api_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chunk_up/data/services/storage/local_storage_service.dart';
import 'package:chunk_up/core/services/api_service.dart' as core_api;

/// 내장된 API 키를 관리하는 서비스
/// 
/// 앱에 내장된 API 키를 안전하게 관리하고 제공합니다.
/// 앱 사용자가 직접 API 키를 입력하지 않아도 되도록 API 키를 앱 내부에 내장합니다.
class EmbeddedApiService {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // 앱 내장 API 키 (암호화된 형태)
  // 실제 배포 전에 적절한 키로 교체 필요
  static const String _embeddedKey = "RNKCv7fL+NbxYyQAhD9MCPmR1rTfzjvxGZHr5gYqnYQg1JwB6X1+dIGSK7h1Q5SQTzuSKYt8GxCE5vC+IuxYcw==";
  static const String _embeddedIV = "8u7v6D5s4A3z2E1q";
  
  // API 키 내장 여부 설정 플래그
  static const bool useEmbeddedKey = true;
  
  /// API 키 가져오기 (보안 저장소나 내장 키에서)
  static Future<String?> getApiKey() async {
    if (useEmbeddedKey) {
      try {
        return _decryptEmbeddedKey();
      } catch (e) {
        debugPrint('내장 API 키 복호화 오류: $e');
        // 내장 키 복호화 실패 시 보안 저장소 확인
      }
    }
    
    // 보안 저장소에서 키 확인
    return await _secureStorage.read(key: ApiConstants.secureStorageApiKeyKey);
  }
  
  /// API 키 가져오기
  static String _decryptEmbeddedKey() {
    try {
      // .env 파일에서 API 키 로드 시도 (여러 키 이름 지원)
      final envApiKey = dotenv.env['CLAUDE_API_KEY'] ??
                        dotenv.env['API_KEY'] ??
                        dotenv.env['ANTHROPIC_API_KEY'];

      debugPrint('🔍 환경 변수 내용: ${dotenv.env}');
      debugPrint('🔑 API 키 환경 변수 값: $envApiKey');

      if (envApiKey != null && envApiKey.isNotEmpty) {
        debugPrint('✅ .env 파일에서 API 키 로드 성공: ${envApiKey.substring(0, 15)}...');
        return envApiKey;
      }

      // 하드코딩된 API 키 (새로 발급받은 키 사용)
      debugPrint('⚠️ 환경 변수에서 API 키 로드 실패, 하드코딩된 키 사용');
      return "";
    } catch (e) {
      debugPrint('❌ API 키 로드 오류: $e');
      // 예외 발생 시에도 하드코딩된 키 반환
      return "";
    }
  }
  
  /// API 키 검증 (개발 모드에서만 사용)
  static Future<bool> verifyApiKey(String apiKey) async {
    // 개발 중에만 사용하는 확인 기능
    // 프로덕션에서는 사용자가 API 키를 검증할 필요가 없음
    if (!kReleaseMode) {
      try {
        // 입력된 키와 내장된 키 비교
        final embeddedKey = _decryptEmbeddedKey();
        return apiKey.trim() == embeddedKey.trim();
      } catch (e) {
        debugPrint('API 키 검증 오류: $e');
        return false;
      }
    }
    
    // 릴리즈 모드에서는 항상 true 반환
    return true;
  }
  
  /// API 설정 초기화
  static Future<void> initializeApiSettings() async {
    try {
      final embeddedKey = _decryptEmbeddedKey();

      // 보안을 위해 키의 일부만 로그로 표시
      if (embeddedKey.length > 20) {
        debugPrint('💡 API 키: ${embeddedKey.substring(0, 10)}...${embeddedKey.substring(embeddedKey.length - 5)}');
      } else {
        debugPrint('⚠️ API 키가 너무 짧거나 잘못됨');
      }

      // 보안 저장소에 저장
      await _secureStorage.write(
        key: ApiConstants.secureStorageApiKeyKey,
        value: embeddedKey
      );

      // API 키가 성공적으로 저장되었는지 확인
      final savedKey = await _secureStorage.read(
        key: ApiConstants.secureStorageApiKeyKey
      );

      if (savedKey != null && savedKey.isNotEmpty) {
        debugPrint('✅ API 키가 보안 저장소에 성공적으로 저장됨');
      } else {
        debugPrint('⚠️ API 키가 보안 저장소에 저장되지 않음');
      }

      // LocalStorageService와 ApiService에도 저장
      try {
        await saveToLocalStorage(embeddedKey);
        await core_api.ApiService.saveApiKeyStatic(embeddedKey);
        debugPrint('✅ API 키가 모든 저장소에 저장됨');

        // API 서비스의 키 확인
        final apiService = core_api.ApiService();
        final apiKey = await apiService.apiKey;
        if (apiKey != null && apiKey.isNotEmpty) {
          debugPrint('✅ API 서비스에서 키 확인 성공: ${apiKey.substring(0, 10)}...');
        } else {
          debugPrint('⚠️ API 서비스에서 키를 찾을 수 없음');
        }
      } catch (storageError) {
        debugPrint('⚠️ 저장소 오류: $storageError');
      }

      debugPrint('✅ API 키 초기화 완료');
    } catch (e) {
      debugPrint('❌ API 키 초기화 실패: $e');
    }
  }

  /// 로컬 저장소에도 API 키 저장 (ApiService와 동기화)
  static Future<void> saveToLocalStorage(String apiKey) async {
    // ApiService에서 사용하는 상수와 동일한 키로 저장
    const String apiKeyStorageKey = 'api_key';

    // local_storage_service.dart 직접 사용
    try {
      final service = LocalStorageService();
      await service.setString(apiKeyStorageKey, apiKey);
    } catch (e) {
      debugPrint('❌ 로컬 저장소에 API 키 저장 실패: $e');
      rethrow;
    }
  }
}
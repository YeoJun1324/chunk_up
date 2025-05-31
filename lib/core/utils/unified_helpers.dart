// lib/core/utils/unified_helpers.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// 통합된 헬퍼 클래스 - 공통 유틸리티 함수들을 중앙화
/// 
/// 프로젝트 전체에서 사용되는 중복된 유틸리티 함수들을 통합
class UnifiedHelpers {
  
  // =============================================================================
  // JSON 및 문자열 처리
  // =============================================================================
  
  /// JSON 문자열 정제 및 검증
  static String cleanJsonString(String jsonString) {
    if (jsonString.isEmpty) return jsonString;
    
    // 공백 제거
    jsonString = jsonString.trim();
    
    // 마크다운 코드 블록 제거
    if (jsonString.startsWith('```json') && jsonString.endsWith('```')) {
      // ```json{ 형태 처리 - 줄바꿈 없이 바로 JSON이 시작되는 경우 포함
      jsonString = jsonString
          .replaceFirst(RegExp(r'^```json\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '');
    } else if (jsonString.startsWith('```') && jsonString.endsWith('```')) {
      jsonString = jsonString
          .replaceFirst(RegExp(r'^```\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '');
    }
    
    // 추가 공백 제거
    return jsonString.trim();
  }
  
  /// 안전한 JSON 파싱
  static Map<String, dynamic>? safeJsonDecode(String jsonString) {
    try {
      final cleaned = cleanJsonString(jsonString);
      if (cleaned.isEmpty) return null;
      
      final decoded = jsonDecode(cleaned);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      debugPrint('JSON 파싱 실패: $e');
      return null;
    }
  }
  
  /// JSON에서 특정 필드 안전하게 추출
  static T? safeExtractField<T>(Map<String, dynamic>? json, String key, {T? defaultValue}) {
    if (json == null || !json.containsKey(key)) return defaultValue;
    
    final value = json[key];
    if (value is T) return value;
    
    // 타입 변환 시도
    if (T == String && value != null) {
      return value.toString() as T;
    } else if (T == int && value is num) {
      return value.toInt() as T;
    } else if (T == double && value is num) {
      return value.toDouble() as T;
    } else if (T == bool) {
      if (value is String) {
        return (value.toLowerCase() == 'true') as T;
      } else if (value is num) {
        return (value != 0) as T;
      }
    }
    
    return defaultValue;
  }
  
  /// 정규 표현식을 사용한 수동 JSON 필드 추출
  static Map<String, dynamic> extractJsonFieldsManually(String jsonString, List<String> fieldNames) {
    final result = <String, dynamic>{};
    
    for (final fieldName in fieldNames) {
      // 다양한 JSON 필드 패턴 지원
      final patterns = [
        RegExp('"$fieldName"\\s*:\\s*"([^"]*)"'),  // 문자열 값
        RegExp('"$fieldName"\\s*:\\s*([^,}\\]]+)'), // 숫자/불린 값
      ];
      
      for (final pattern in patterns) {
        final match = pattern.firstMatch(jsonString);
        if (match != null && match.group(1) != null) {
          var value = match.group(1)!.trim();
          
          // 값 타입 추론
          if (value.startsWith('"') && value.endsWith('"')) {
            value = value.substring(1, value.length - 1);
          } else if (value == 'true' || value == 'false') {
            result[fieldName] = value == 'true';
            break;
          } else if (RegExp(r'^\d+$').hasMatch(value)) {
            result[fieldName] = int.tryParse(value);
            break;
          } else if (RegExp(r'^\d+\.\d+$').hasMatch(value)) {
            result[fieldName] = double.tryParse(value);
            break;
          }
          
          result[fieldName] = value;
          break;
        }
      }
    }
    
    return result;
  }

  // =============================================================================
  // 텍스트 처리
  // =============================================================================
  
  /// 마크다운을 일반 텍스트로 변환 (향상된 버전)
  static String convertMarkdownToPlainText(String text) {
    if (text.isEmpty) return text;
    
    // HTML 태그 제거
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // 마크다운 강조 표시 제거
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) => match.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (match) => match.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'_([^_]+)_'), (match) => match.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1) ?? '');
    text = text.replaceAllMapped(RegExp(r'~~([^~]+)~~'), (match) => match.group(1) ?? '');
    
    // 링크 제거 [텍스트](URL) -> 텍스트
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (match) => match.group(1) ?? '');
    
    // 이미지 제거 ![alt](URL) -> alt
    text = text.replaceAllMapped(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), (match) => match.group(1) ?? '');
    
    // 헤더 마크다운 제거
    text = text.replaceAll(RegExp(r'^#+\s*'), '');
    
    // 리스트 마커 제거
    text = text.replaceAll(RegExp(r'^[\s]*[-*+]\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\s*\d+\.\s*', multiLine: true), '');
    
    // 인용문 마커 제거
    text = text.replaceAll(RegExp(r'^>\s*', multiLine: true), '');
    
    // 줄바꿈 정리
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    text = text.replaceAll(RegExp(r'^\s+|\s+$'), '');
    
    return text;
  }
  
  /// 텍스트에서 특정 단어 포함 여부 확인 (단어 경계 고려)
  static bool containsWord(String text, String word, {bool caseSensitive = false}) {
    if (text.isEmpty || word.isEmpty) return false;
    
    final pattern = RegExp(
      r'\b' + RegExp.escape(word) + r'\b',
      caseSensitive: caseSensitive,
    );
    
    return pattern.hasMatch(text);
  }
  
  /// 텍스트에서 모든 단어 추출
  static List<String> extractWords(String text, {bool removeCommon = true}) {
    if (text.isEmpty) return [];
    
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    
    if (removeCommon) {
      const commonWords = {
        'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
        'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'be',
        'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
        'would', 'could', 'should', 'may', 'might', 'can', 'must', 'this',
        'that', 'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they'
      };
      
      return words.where((word) => !commonWords.contains(word)).toList();
    }
    
    return words;
  }
  
  /// 텍스트 유사도 계산 (레벤슈타인 거리 기반)
  static double calculateTextSimilarity(String text1, String text2) {
    if (text1 == text2) return 1.0;
    if (text1.isEmpty || text2.isEmpty) return 0.0;
    
    final distance = levenshteinDistance(text1.toLowerCase(), text2.toLowerCase());
    final maxLength = max(text1.length, text2.length);
    
    return 1.0 - (distance / maxLength);
  }
  
  /// 레벤슈타인 거리 계산
  static int levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    
    final matrix = List.generate(
      a.length + 1,
      (i) => List<int>.filled(b.length + 1, 0),
    );
    
    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce(min);
      }
    }
    
    return matrix[a.length][b.length];
  }

  // =============================================================================
  // 날짜 및 시간 처리
  // =============================================================================
  
  /// 한국식 날짜 포맷 (YYYY.MM.DD)
  static String formatDateKorean(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 시간 포맷 (HH:MM)
  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// 날짜시간 포맷 (YYYY.MM.DD HH:MM)
  static String formatDateTime(DateTime dateTime) {
    return '${formatDateKorean(dateTime)} ${formatTime(dateTime)}';
  }
  
  /// 상대적 시간 표시 (예: "2분 전", "1시간 전")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else {
      return '${(difference.inDays / 365).floor()}년 전';
    }
  }

  // =============================================================================
  // 해시 및 암호화
  // =============================================================================
  
  /// 문자열의 MD5 해시 생성
  static String generateMD5Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
  
  /// 문자열의 SHA256 해시 생성
  static String generateSHA256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// 캐시 키 생성 (엔드포인트와 파라미터 기반)
  static String generateCacheKey(String endpoint, Map<String, dynamic> parameters) {
    final paramString = parameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final fullString = '$endpoint?$paramString';
    return generateSHA256Hash(fullString);
  }

  // =============================================================================
  // 검증 및 유효성 검사
  // =============================================================================
  
  /// 이메일 주소 유효성 검사
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
  
  /// URL 유효성 검사
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  /// JSON 형식 유효성 검사
  static bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 문자열이 숫자인지 확인
  static bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }
  
  /// 문자열이 정수인지 확인
  static bool isInteger(String str) {
    return int.tryParse(str) != null;
  }

  // =============================================================================
  // 컬렉션 유틸리티
  // =============================================================================
  
  /// 리스트를 청크 단위로 분할
  static List<List<T>> chunkList<T>(List<T> list, int chunkSize) {
    if (chunkSize <= 0) throw ArgumentError('Chunk size must be positive');
    
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }
  
  /// 리스트에서 중복 제거 (순서 유지)
  static List<T> removeDuplicates<T>(List<T> list) {
    final seen = <T>{};
    return list.where((item) => seen.add(item)).toList();
  }
  
  /// 두 리스트의 교집합
  static List<T> intersection<T>(List<T> list1, List<T> list2) {
    final set2 = list2.toSet();
    return list1.where((item) => set2.contains(item)).toList();
  }
  
  /// 두 리스트의 차집합 (list1 - list2)
  static List<T> difference<T>(List<T> list1, List<T> list2) {
    final set2 = list2.toSet();
    return list1.where((item) => !set2.contains(item)).toList();
  }
  
  /// 맵에서 null 값 제거
  static Map<K, V> removeNullValues<K, V>(Map<K, V?> map) {
    final result = <K, V>{};
    for (final entry in map.entries) {
      if (entry.value != null) {
        result[entry.key] = entry.value!;
      }
    }
    return result;
  }

  // =============================================================================
  // 파일 및 크기 유틸리티
  // =============================================================================
  
  /// 바이트 크기를 사람이 읽기 쉬운 형태로 변환
  static String formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int index = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }
    
    return '${size.toStringAsFixed(index == 0 ? 0 : 1)} ${suffixes[index]}';
  }
  
  /// 파일 확장자 추출
  static String getFileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }
  
  /// 파일명에서 확장자를 제외한 이름 추출
  static String getFileNameWithoutExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) {
      return fileName;
    }
    return fileName.substring(0, dotIndex);
  }

  // =============================================================================
  // 수학 및 통계 유틸리티
  // =============================================================================
  
  /// 숫자를 지정된 범위로 제한
  static T clamp<T extends num>(T value, T min, T max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
  
  /// 백분율 계산
  static double calculatePercentage(num value, num total) {
    if (total == 0) return 0.0;
    return (value / total) * 100;
  }
  
  /// 리스트의 평균 계산
  static double calculateAverage(List<num> numbers) {
    if (numbers.isEmpty) return 0.0;
    final sum = numbers.reduce((a, b) => a + b);
    return sum / numbers.length;
  }
  
  /// 리스트의 중앙값 계산
  static double calculateMedian(List<num> numbers) {
    if (numbers.isEmpty) return 0.0;
    
    final sorted = List<num>.from(numbers)..sort();
    final middle = sorted.length ~/ 2;
    
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle].toDouble();
    }
  }
  
  /// 표준 편차 계산
  static double calculateStandardDeviation(List<num> numbers) {
    if (numbers.isEmpty) return 0.0;
    
    final mean = calculateAverage(numbers);
    final squaredDifferences = numbers.map((x) => pow(x - mean, 2));
    final variance = calculateAverage(squaredDifferences.toList());
    
    return sqrt(variance);
  }

  // =============================================================================
  // 디버깅 및 로깅 유틸리티
  // =============================================================================
  
  /// 개발 모드에서만 출력하는 디버그 프린트
  static void debugPrintDev(String message) {
    if (kDebugMode) {
      debugPrint('[DEV] $message');
    }
  }
  
  /// 객체를 JSON 형태로 예쁘게 출력
  static void debugPrintJson(Object? object, {String? label}) {
    if (kDebugMode) {
      final prefix = label != null ? '[$label] ' : '';
      try {
        final jsonString = jsonEncode(object);
        final prettyJson = JsonEncoder.withIndent('  ').convert(jsonDecode(jsonString));
        debugPrint('${prefix}JSON:\n$prettyJson');
      } catch (e) {
        debugPrint('${prefix}Object: $object (JSON encoding failed: $e)');
      }
    }
  }
  
  /// 실행 시간 측정
  static Future<T> measureExecutionTime<T>(
    Future<T> Function() operation, {
    String? operationName,
    void Function(Duration duration)? onComplete,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      if (kDebugMode) {
        final name = operationName ?? 'Operation';
        debugPrint('⏱️ $name took ${stopwatch.elapsedMilliseconds}ms');
      }
      
      onComplete?.call(stopwatch.elapsed);
      return result;
    } catch (e) {
      stopwatch.stop();
      
      if (kDebugMode) {
        final name = operationName ?? 'Operation';
        debugPrint('❌ $name failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      }
      
      onComplete?.call(stopwatch.elapsed);
      rethrow;
    }
  }

  // =============================================================================
  // 색상 및 UI 유틸리티
  // =============================================================================
  
  /// HEX 색상 문자열을 정수로 변환
  static int? hexToInt(String hex) {
    try {
      hex = hex.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // 알파 채널 추가
      }
      return int.parse(hex, radix: 16);
    } catch (e) {
      return null;
    }
  }
  
  /// 정수 색상을 HEX 문자열로 변환
  static String intToHex(int color) {
    return '#${color.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
  
  /// 색상의 밝기 계산 (0.0 - 1.0)
  static double calculateColorBrightness(int color) {
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;
    
    // ITU-R BT.709 luma calculation
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  }
  
  /// 색상이 어두운지 밝은지 판단
  static bool isColorDark(int color) {
    return calculateColorBrightness(color) < 0.5;
  }

  // =============================================================================
  // 플랫폼 및 환경 유틸리티
  // =============================================================================
  
  /// 현재 플랫폼 정보 가져오기
  static String getPlatformInfo() {
    if (kIsWeb) return 'Web';
    
    // 실제 플랫폼 정보는 platform 패키지나 dart:io를 사용해야 함
    // 여기서는 기본적인 정보만 제공
    return 'Mobile/Desktop';
  }
  
  /// 디버그 모드 여부 확인
  static bool get isDebugMode => kDebugMode;
  
  /// 프로파일 모드 여부 확인
  static bool get isProfileMode => kProfileMode;
  
  /// 릴리즈 모드 여부 확인
  static bool get isReleaseMode => kReleaseMode;

  // =============================================================================
  // 에러 처리 유틸리티
  // =============================================================================
  
  /// 안전한 비동기 작업 실행
  static Future<T?> safeAsyncOperation<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    void Function(Object error)? onError,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      onError?.call(e);
      
      if (kDebugMode) {
        debugPrint('Safe async operation failed: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      
      return fallbackValue;
    }
  }
  
  /// 안전한 동기 작업 실행
  static T? safeSyncOperation<T>(
    T Function() operation, {
    T? fallbackValue,
    void Function(Object error)? onError,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      onError?.call(e);
      
      if (kDebugMode) {
        debugPrint('Safe sync operation failed: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      
      return fallbackValue;
    }
  }
}
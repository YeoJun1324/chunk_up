// lib/core/utils/business_exception.dart

/// 비즈니스 로직 에러의 심각도 수준
enum ErrorSeverity {
  normal,   // 일반적인 오류
  warning,  // 경고 수준의 오류
  critical, // 심각한 오류
}

/// 비즈니스 로직 에러 유형
enum BusinessErrorType {
  unknown(ErrorSeverity.normal, false),

  // 단어장 관련 오류
  duplicateWordList(ErrorSeverity.normal, false),
  duplicateWord(ErrorSeverity.normal, false),
  emptyWordList(ErrorSeverity.normal, false),
  invalidWordCount(ErrorSeverity.normal, false),
  wordNotFound(ErrorSeverity.normal, false),

  // 청크 생성 관련 오류
  chunkGenerationFailed(ErrorSeverity.normal, true),
  invalidPrompt(ErrorSeverity.normal, false),

  // API 관련 오류
  apiKeyNotSet(ErrorSeverity.normal, false),
  apiKeyInvalid(ErrorSeverity.normal, false),
  apiQuotaExceeded(ErrorSeverity.warning, true),

  // 네트워크 관련 오류
  networkError(ErrorSeverity.warning, true),
  timeout(ErrorSeverity.warning, true),

  // 파일 처리 관련 오류
  fileImportError(ErrorSeverity.normal, true),
  fileExportError(ErrorSeverity.normal, true),
  dataFormatError(ErrorSeverity.normal, true),

  // 테스트 관련 오류
  testNotStarted(ErrorSeverity.normal, false),
  testAlreadyCompleted(ErrorSeverity.normal, false),

  // 데이터 관련 오류
  insufficientData(ErrorSeverity.normal, false),
  dataCorrupted(ErrorSeverity.critical, false),

  // 기타 오류
  validationError(ErrorSeverity.normal, false),
  permissionDenied(ErrorSeverity.warning, false);

  // properties
  final ErrorSeverity severity;
  final bool isRetryable;

  const BusinessErrorType(this.severity, this.isRetryable);
}

/// 비즈니스 로직 에러 클래스
class BusinessException implements Exception {
  final BusinessErrorType type;
  final String message;
  final Map<String, dynamic>? data;

  /// 생성자
  BusinessException({
    required this.type,
    required this.message,
    this.data,
  });

  /// 기본 에러 메시지를 반환
  String getDefaultMessage() {
    switch (type) {
      case BusinessErrorType.duplicateWordList:
        return '동일한 이름의 단어장이 이미 존재합니다.';
      case BusinessErrorType.emptyWordList:
        return '단어장에 단어가 없습니다.';
      case BusinessErrorType.invalidWordCount:
        return '단어 개수가 유효하지 않습니다.';
      case BusinessErrorType.wordNotFound:
        return '단어를 찾을 수 없습니다.';
      case BusinessErrorType.chunkGenerationFailed:
        return '청크 생성에 실패했습니다.';
      case BusinessErrorType.invalidPrompt:
        return '유효하지 않은 프롬프트입니다.';
      case BusinessErrorType.apiKeyNotSet:
        return 'API 키가 설정되지 않았습니다.';
      case BusinessErrorType.apiKeyInvalid:
        return 'API 키가 유효하지 않습니다.';
      case BusinessErrorType.apiQuotaExceeded:
        return 'API 할당량을 초과했습니다.';
      case BusinessErrorType.networkError:
        return '네트워크 연결에 문제가 있습니다.';
      case BusinessErrorType.timeout:
        return '응답 시간이 초과되었습니다.';
      case BusinessErrorType.fileImportError:
        return '파일 가져오기에 실패했습니다.';
      case BusinessErrorType.fileExportError:
        return '파일 내보내기에 실패했습니다.';
      case BusinessErrorType.dataFormatError:
        return '데이터 형식이 올바르지 않습니다.';
      case BusinessErrorType.testNotStarted:
        return '테스트가 시작되지 않았습니다.';
      case BusinessErrorType.testAlreadyCompleted:
        return '테스트가 이미 완료되었습니다.';
      case BusinessErrorType.insufficientData:
        return '데이터가 충분하지 않습니다.';
      case BusinessErrorType.dataCorrupted:
        return '데이터가 손상되었습니다.';
      case BusinessErrorType.validationError:
        return '입력 값이 유효하지 않습니다.';
      case BusinessErrorType.permissionDenied:
        return '권한이 없습니다.';
      case BusinessErrorType.unknown:
      default:
        return '알 수 없는 오류가 발생했습니다.';
    }
  }

  /// 사용자에게 보여줄 메시지 반환
  String getUserMessage() {
    return message.isEmpty ? getDefaultMessage() : message;
  }

  @override
  String toString() {
    return 'BusinessException: ${getUserMessage()}';
  }
}
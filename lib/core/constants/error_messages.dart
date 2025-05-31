// lib/core/constants/error_messages.dart
class ErrorMessages {
  // API 에러 메시지
  static const String apiKeyNotSet = 'API 키가 설정되지 않았습니다. 앱 설정에서 API 키를 입력해주세요.';
  static const String invalidApiKey = 'API 키가 유효하지 않습니다.';
  static const String apiRequestFailed = 'API 요청 실패';
  static const String apiTimeout = 'API 요청 시간이 초과되었습니다.';
  static const String networkError = '인터넷 연결을 확인해주세요.';
  static const String unexpectedApiResponse = '예상치 못한 API 응답 형식입니다.';

  // 검증 에러 메시지
  static const String selectWordListFirst = '단어장을 먼저 선택하세요.';
  static const String selectWordsFirst = '단어장을 선택하고, 생성할 단어를 선택해주세요.';
  static const String wordCountOutOfRange = '단어는 5개 이상 25개 이하로 선택해주세요.';
  static const String tooManyWordsWarning = '단어가 많을수록 생성에 시간이 오래 걸릴 수 있습니다.';
  static const String emptyWordListName = '단어장 이름을 입력해주세요.';
  static const String duplicateWordListName = '이미 존재하는 단어장 이름입니다.';

  // 파일 처리 에러 메시지
  static const String fileProcessingError = '파일 처리 중 오류가 발생했습니다.';
  static const String excelParsingError = '엑셀 파일을 읽을 수 없습니다.';
  static const String csvParsingError = 'CSV 파일을 읽을 수 없습니다.';

  // 일반 에러 메시지
  static const String unknownError = '알 수 없는 오류가 발생했습니다.';
  static const String dataLoadError = '데이터를 불러오는 중 오류가 발생했습니다.';
  static const String dataSaveError = '데이터를 저장하는 중 오류가 발생했습니다.';

  // HTTP 상태 코드별 메시지
  static String getHttpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다.';
      case 401:
        return 'API 키가 유효하지 않습니다.';
      case 403:
        return '접근이 거부되었습니다.';
      case 404:
        return 'API 엔드포인트를 찾을 수 없습니다.';
      case 429:
        return 'API 요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요.';
      case 500:
        return '서버 오류가 발생했습니다.';
      default:
        return '알 수 없는 오류가 발생했습니다. (상태 코드: $statusCode)';
    }
  }
}
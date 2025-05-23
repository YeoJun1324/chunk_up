// lib/core/utils/api_exception.dart
import 'business_exception.dart';
import 'package:http/http.dart' as http;

/// API 에러 타입
enum ApiErrorType {
  noInternet,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  timeout,
  badRequest,
  tooManyRequests,
  unknown,
}

/// API 호출 중 발생하는 예외 기본 클래스
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String details;
  final Map<String, dynamic>? data;
  final dynamic originalError;
  final ApiErrorType type;
  final http.Response? response;

  ApiException(
      this.message, {
        this.statusCode = 0,
        this.details = '',
        this.data,
        this.originalError,
        ApiErrorType? type,
        this.response,
      }) : type = type ?? _getTypeFromStatusCode(statusCode);
      
  static ApiErrorType _getTypeFromStatusCode(int statusCode) {
    switch (statusCode) {
      case 0:
        return ApiErrorType.noInternet;
      case 400:
        return ApiErrorType.badRequest;
      case 401:
        return ApiErrorType.unauthorized;
      case 403:
        return ApiErrorType.forbidden;
      case 404:
        return ApiErrorType.notFound;
      case 408:
        return ApiErrorType.timeout;
      case 429:
        return ApiErrorType.tooManyRequests;
      case 500:
      case 501:
      case 502:
      case 503:
      case 504:
        return ApiErrorType.serverError;
      default:
        return ApiErrorType.unknown;
    }
  }

  /// 비즈니스 예외로 변환
  BusinessException toBusinessException() {
    // HTTP 상태 코드에 따라 적절한 비즈니스 예외 타입 결정
    final type = _getBusinessErrorType();

    return BusinessException(
      type: type,
      message: message,
      data: data,
    );
  }

  /// HTTP 상태 코드를 비즈니스 에러 타입으로 변환
  BusinessErrorType _getBusinessErrorType() {
    if (statusCode == 0) {
      return BusinessErrorType.networkError;
    }

    switch (statusCode) {
      case 400:
        return BusinessErrorType.validationError;
      case 401:
      case 403:
        return BusinessErrorType.apiKeyInvalid;
      case 404:
        return BusinessErrorType.wordNotFound;
      case 408:
        return BusinessErrorType.timeout;
      case 429:
        return BusinessErrorType.apiQuotaExceeded;
      case 500:
      case 502:
      case 503:
      case 504:
        return BusinessErrorType.chunkGenerationFailed;
      default:
        return BusinessErrorType.unknown;
    }
  }

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)\nDetails: $details';
  }
}

/// 잘못된 응답 예외
class InvalidResponseException extends ApiException {
  InvalidResponseException(
      String message, {
        String details = '',
        int statusCode = 400,
      }) : super(
    message,
    details: details,
    statusCode: statusCode,
  );
}

/// 네트워크 연결 실패
class NetworkException extends ApiException {
  NetworkException([String message = '네트워크 연결에 실패했습니다.'])
      : super(
    message,
    statusCode: 0,
    details: '',
  );
}

/// 서버 응답 제한시간 초과
class TimeoutException extends ApiException {
  TimeoutException([String message = '서버 응답 시간이 초과되었습니다.'])
      : super(
    message,
    statusCode: 408,
    details: '',
  );
}

/// 인증 관련 예외
class AuthException extends ApiException {
  AuthException([String message = 'API 인증에 실패했습니다.'])
      : super(
    message,
    statusCode: 401,
    details: '',
  );
}

/// 서버 오류
class ServerException extends ApiException {
  ServerException([String message = '서버 오류가 발생했습니다.'])
      : super(
    message,
    statusCode: 500,
    details: '',
  );
}

/// API 요청 형식 오류
class BadRequestException extends ApiException {
  BadRequestException([String message = '잘못된 요청입니다.'])
      : super(
    message,
    statusCode: 400,
    details: '',
  );
}

/// API 할당량 초과
class QuotaExceededException extends ApiException {
  QuotaExceededException([String message = 'API 호출 할당량을 초과했습니다.'])
      : super(
    message,
    statusCode: 429,
    details: '',
  );
}
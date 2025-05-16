// lib/core/services/error_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/api_exception.dart';
import '../utils/business_exception.dart';
import 'logging_service.dart';
import 'navigation_service.dart';

/// UI 에러 타입
enum ErrorType {
  general,
  api,
  network,
  timeout,
  critical,
}

/// 에러 심각도 레벨
enum ErrorLevel {
  info,    // 사용자에게 정보만 표시
  warning, // 경고 메시지 표시
  error,   // 에러 메시지 표시
  critical // 치명적 에러, 로그 전송
}

/// 서비스 에러 타입
enum ServiceErrorType {
  general,
  api,
  network,
  timeout,
  business,
  critical,
}

/// 애플리케이션의 에러 처리를 관리하는 서비스
class ErrorService {
  // Singleton pattern
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  final LoggingService _logger = LoggingService();

  /// 에러를 일관되게 처리하는 메인 메서드
  Future<T> handleError<T>({
    required Future<T> Function() action,
    required BuildContext context,
    String? operation,
    T? fallbackValue,
    bool showDialog = true,
    bool shouldRethrow = false,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      _processError(
        error: error,
        stackTrace: stackTrace,
        context: context,
        operation: operation,
        showDialog: showDialog,
      );

      if (shouldRethrow) rethrow;
      if (fallbackValue != null) return fallbackValue;

      rethrow;
    }
  }

  /// 에러 처리만 수행하는 메서드 (반환값 없음)
  Future<void> handleVoidError({
    required Future<void> Function() action,
    required BuildContext context,
    String? operation,
    bool showDialog = true,
    VoidCallback? onRetry,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      _processError(
        error: error,
        stackTrace: stackTrace,
        context: context,
        operation: operation,
        showDialog: showDialog,
      );
    }
  }

  /// 에러 처리 프로세스
  void _processError({
    required dynamic error,
    required StackTrace stackTrace,
    required BuildContext context,
    String? operation,
    bool showDialog = true,
  }) {
    final errorInfo = _analyzeError(error);

    // 로깅
    _logError(error, stackTrace, operation, errorInfo);

    // UI 표시
    if (showDialog && context.mounted) {
      _showErrorToUser(context, errorInfo);
    }
  }

  /// 단순 에러 로깅
  void logError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    bool fatal = false,
  }) {
    _logger.logError(
      'Error occurred${context != null ? " in $context" : ""}',
      error: error,
      stackTrace: stackTrace,
      context: {
        'fatal': fatal,
        if (context != null) 'context': context,
      },
    );
    
    // Re-throw in debug mode to see the error in the console
    if (kDebugMode && fatal) {
      throw error;
    }
  }

  /// 에러 분석
  _ErrorInfo _analyzeError(dynamic error) {
    if (error is BusinessException) {
      return _ErrorInfo(
        title: _getTitleForBusinessError(error.type),
        message: error.getUserMessage(),
        level: _getLevelForBusinessError(error.type),
        type: ServiceErrorType.business,
        isRetryable: error.type.isRetryable,
      );
    }

    if (error is ApiException) {
      return _ErrorInfo(
        title: 'API 오류',
        message: error.message,
        level: ErrorLevel.error,
        type: ServiceErrorType.api,
        isRetryable: error is NetworkException || error is TimeoutException,
      );
    }

    // 기타 에러
    return _ErrorInfo(
      title: '오류',
      message: error.toString().replaceAll('Exception: ', ''),
      level: ErrorLevel.error,
      type: ServiceErrorType.general,
      isRetryable: false,
    );
  }

  /// 에러 로깅
  void _logError(
    dynamic error,
    StackTrace stackTrace,
    String? operation,
    _ErrorInfo errorInfo,
  ) {
    final context = {
      if (operation != null) 'operation': operation,
      'errorType': errorInfo.type.toString(),
      'level': errorInfo.level.toString(),
    };

    if (errorInfo.level == ErrorLevel.critical) {
      _logger.logError(
        errorInfo.title,
        error: error,
        stackTrace: stackTrace,
        context: context,
      );
    } else if (errorInfo.level == ErrorLevel.warning) {
      _logger.logWarning(
        errorInfo.title,
        context: context,
      );
    } else {
      _logger.logError(
        errorInfo.message,
        error: error,
        stackTrace: stackTrace,
        context: context,
      );
    }
  }

  /// 사용자에게 에러 표시
  void _showErrorToUser(BuildContext context, _ErrorInfo errorInfo) {
    switch (errorInfo.level) {
      case ErrorLevel.info:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorInfo.message),
            backgroundColor: Colors.blue,
          ),
        );
        break;

      case ErrorLevel.warning:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorInfo.message),
            backgroundColor: Colors.orange,
            action: errorInfo.isRetryable
                ? SnackBarAction(
              label: '재시도',
              onPressed: () {
                // 재시도는 호출하는 쪽에서 처리
              },
            )
                : null,
          ),
        );
        break;

      case ErrorLevel.error:
      case ErrorLevel.critical:
        showDialog(
          context: context,
          builder: (context) => _buildErrorDialog(
            title: errorInfo.title,
            message: errorInfo.message,
            type: _convertToWidgetErrorType(errorInfo.type),
          ),
        );
        break;
    }
  }

  /// 간단한 에러 메시지 표시 (컨텍스트 없을 때)
  void showErrorToUser(String message) {
    debugPrint('ERROR TO USER: $message');
  }

  /// 에러 다이얼로그 생성
  Widget _buildErrorDialog({
    required String title,
    required String message,
    required ErrorType type,
  }) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _getErrorIcon(type),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(NavigationService.navigatorKey.currentContext!).pop(),
          child: const Text('확인'),
        ),
      ],
    );
  }

  /// 에러 아이콘 가져오기
  Widget _getErrorIcon(ErrorType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case ErrorType.api:
        iconData = Icons.cloud_off;
        iconColor = Colors.blue;
        break;
      case ErrorType.network:
        iconData = Icons.wifi_off;
        iconColor = Colors.orange;
        break;
      case ErrorType.timeout:
        iconData = Icons.timer_off;
        iconColor = Colors.orange;
        break;
      case ErrorType.critical:
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
      case ErrorType.general:
      default:
        iconData = Icons.warning;
        iconColor = Colors.amber;
        break;
    }

    return Icon(
      iconData,
      color: iconColor,
      size: 48,
    );
  }

  /// ServiceErrorType을 ErrorDialog에서 사용하는 ErrorType으로 변환
  ErrorType _convertToWidgetErrorType(ServiceErrorType type) {
    switch (type) {
      case ServiceErrorType.api:
        return ErrorType.api;
      case ServiceErrorType.network:
        return ErrorType.network;
      case ServiceErrorType.timeout:
        return ErrorType.timeout;
      case ServiceErrorType.critical:
        return ErrorType.critical;
      case ServiceErrorType.business:
      case ServiceErrorType.general:
      default:
        return ErrorType.general;
    }
  }

  String _getTitleForBusinessError(BusinessErrorType type) {
    switch (type) {
      case BusinessErrorType.duplicateWordList:
      case BusinessErrorType.invalidWordCount:
      case BusinessErrorType.emptyWordList:
      case BusinessErrorType.wordNotFound:
        return '데이터 오류';

      case BusinessErrorType.chunkGenerationFailed:
      case BusinessErrorType.invalidPrompt:
        return '생성 오류';

      case BusinessErrorType.apiKeyInvalid:
      case BusinessErrorType.apiKeyNotSet:
      case BusinessErrorType.apiQuotaExceeded:
        return 'API 오류';

      case BusinessErrorType.networkError:
      case BusinessErrorType.timeout:
        return '네트워크 오류';

      case BusinessErrorType.fileImportError:
      case BusinessErrorType.fileExportError:
      case BusinessErrorType.dataFormatError:
        return '파일 오류';

      case BusinessErrorType.testNotStarted:
      case BusinessErrorType.testAlreadyCompleted:
        return '테스트 오류';

      case BusinessErrorType.insufficientData:
      case BusinessErrorType.dataCorrupted:
        return '데이터 오류';

      case BusinessErrorType.validationError:
        return '입력 오류';

      case BusinessErrorType.permissionDenied:
        return '권한 오류';

      case BusinessErrorType.unknown:
      default:
        return '오류';
    }
  }

  ErrorLevel _getLevelForBusinessError(BusinessErrorType type) {
    switch (type.severity) {
      case ErrorSeverity.critical:
        return ErrorLevel.critical;
      case ErrorSeverity.warning:
        return ErrorLevel.warning;
      case ErrorSeverity.normal:
      default:
        return ErrorLevel.error;
    }
  }
}

/// 내부 에러 정보 클래스
class _ErrorInfo {
  final String title;
  final String message;
  final ErrorLevel level;
  final ServiceErrorType type;
  final bool isRetryable;

  _ErrorInfo({
    required this.title,
    required this.message,
    required this.level,
    required this.type,
    required this.isRetryable,
  });
}
import 'package:flutter/material.dart';
import 'package:chunk_up/core/utils/api_exception.dart';
import 'package:chunk_up/core/utils/business_exception.dart';
import 'package:chunk_up/core/services/logging_service.dart';
import 'package:get_it/get_it.dart';

/// Centralized error handling
class ErrorHandler {
  static final LoggingService _loggingService = GetIt.instance<LoggingService>();

  /// Handle error and return user-friendly message
  static String handleError(dynamic error, {String? context}) {
    _loggingService.logError(
      'Error occurred${context != null ? ' in $context' : ''}',
      error: error,
    );

    if (error is ApiException) {
      return _handleApiException(error);
    } else if (error is BusinessException) {
      return _handleBusinessException(error);
    } else if (error is FormatException) {
      return '데이터 형식이 올바르지 않습니다.';
    } else if (error is TypeError) {
      return '데이터 처리 중 오류가 발생했습니다.';
    } else {
      return '알 수 없는 오류가 발생했습니다.';
    }
  }

  static String _handleApiException(ApiException error) {
    switch (error.type) {
      case ApiErrorType.noInternet:
        return '인터넷 연결을 확인해주세요.';
      case ApiErrorType.unauthorized:
        return '인증이 필요합니다. 다시 로그인해주세요.';
      case ApiErrorType.forbidden:
        return '접근 권한이 없습니다.';
      case ApiErrorType.notFound:
        return '요청한 정보를 찾을 수 없습니다.';
      case ApiErrorType.serverError:
        return '서버에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case ApiErrorType.timeout:
        return '요청 시간이 초과되었습니다. 다시 시도해주세요.';
      case ApiErrorType.badRequest:
        return '잘못된 요청입니다.';
      case ApiErrorType.tooManyRequests:
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      default:
        return error.message;
    }
  }

  static String _handleBusinessException(BusinessException error) {
    switch (error.type) {
      case BusinessErrorType.validationError:
        return '입력한 정보를 다시 확인해주세요.';
      case BusinessErrorType.permissionDenied:
        return '이 작업을 수행할 권한이 없습니다.';
      case BusinessErrorType.wordNotFound:
        return '요청한 단어를 찾을 수 없습니다.';
      case BusinessErrorType.duplicateWord:
        return '이미 존재하는 단어입니다.';
      case BusinessErrorType.invalidPrompt:
        return '프롬프트가 유효하지 않습니다.';
      case BusinessErrorType.chunkGenerationFailed:
        return '청크 생성에 실패했습니다.';
      case BusinessErrorType.dataFormatError:
        return '데이터 형식이 올바르지 않습니다.';
      default:
        return error.message;
    }
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error, {
    String? title,
    String? errorContext,
    VoidCallback? onRetry,
  }) async {
    final message = handleError(error, context: errorContext);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? '오류'),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('다시 시도'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    String? errorContext,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final message = handleError(error, context: errorContext);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
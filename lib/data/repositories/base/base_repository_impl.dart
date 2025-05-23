import 'package:chunk_up/core/utils/api_exception.dart';
import 'package:chunk_up/core/utils/business_exception.dart';
import 'package:chunk_up/core/services/logging_service.dart';
import 'package:get_it/get_it.dart';

/// Base repository implementation with common error handling
abstract class BaseRepositoryImpl {
  final LoggingService _loggingService = GetIt.instance<LoggingService>();

  /// Execute operation with error handling
  Future<T> executeOperation<T>({
    required Future<T> Function() operation,
    required String operationName,
    T Function()? fallback,
  }) async {
    try {
      _loggingService.logInfo('Starting operation: $operationName');
      final result = await operation();
      _loggingService.logInfo('Completed operation: $operationName');
      return result;
    } on ApiException catch (e, stackTrace) {
      _loggingService.logError(
        'API error in $operationName',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (fallback != null && e.type == ApiErrorType.noInternet) {
        return fallback();
      }
      
      throw BusinessException(
        message: 'Failed to $operationName: ${e.message}',
        type: BusinessErrorType.dataFormatError,
      );
    } on BusinessException {
      rethrow;
    } catch (e, stackTrace) {
      _loggingService.logError(
        'Unexpected error in $operationName',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (fallback != null) {
        try {
          return fallback();
        } catch (fallbackError) {
          _loggingService.logError(
            'Fallback also failed for $operationName',
            error: fallbackError,
          );
        }
      }
      
      throw BusinessException(
        message: 'Unexpected error during $operationName',
        type: BusinessErrorType.dataFormatError,
      );
    }
  }

  /// Execute operation with retry logic
  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await executeOperation(
          operation: operation,
          operationName: '$operationName (attempt ${attempts + 1})',
        );
      } on BusinessException catch (e) {
        attempts++;
        
        if (attempts >= maxRetries || 
            e.type == BusinessErrorType.validationError ||
            e.type == BusinessErrorType.wordNotFound) {
          rethrow;
        }
        
        _loggingService.logWarning(
          'Retrying $operationName after ${retryDelay.inSeconds}s',
        );
        
        await Future.delayed(retryDelay);
      }
    }
    
    throw BusinessException(
      message: 'Failed after $maxRetries attempts',
      type: BusinessErrorType.dataFormatError,
    );
  }
}
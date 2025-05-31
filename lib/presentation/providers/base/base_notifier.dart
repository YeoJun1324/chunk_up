import 'package:flutter/foundation.dart';
import 'package:chunk_up/core/error/error_handler.dart';
import 'package:chunk_up/infrastructure/logging/logging_service.dart';
import 'package:get_it/get_it.dart';

/// Base class for all notifiers with common functionality
abstract class BaseNotifier extends ChangeNotifier {
  final LoggingService _loggingService = GetIt.instance<LoggingService>();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error message
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Execute operation with loading and error handling
  Future<T?> executeAsync<T>({
    required Future<T> Function() operation,
    required String operationName,
    bool showLoading = true,
    Function(T)? onSuccess,
    Function(dynamic)? onError,
  }) async {
    try {
      if (showLoading) setLoading(true);
      clearError();

      _loggingService.logInfo('Starting $operationName');
      final result = await operation();
      
      _loggingService.logInfo('Completed $operationName');
      onSuccess?.call(result);
      
      return result;
    } catch (error, stackTrace) {
      _loggingService.logError(
        'Error in $operationName',
        error: error,
        stackTrace: stackTrace,
      );
      
      final errorMessage = ErrorHandler.handleError(error, context: operationName);
      setError(errorMessage);
      
      onError?.call(error);
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  /// Execute operation without loading indicator
  Future<T?> executeSilently<T>({
    required Future<T> Function() operation,
    required String operationName,
    Function(T)? onSuccess,
    Function(dynamic)? onError,
  }) {
    return executeAsync(
      operation: operation,
      operationName: operationName,
      showLoading: false,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Update state safely
  void updateState(VoidCallback update) {
    if (!_isDisposed) {
      update();
      notifyListeners();
    }
  }
}
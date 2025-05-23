import 'package:flutter/material.dart';
import 'package:chunk_up/core/services/error_service.dart';
import 'package:chunk_up/core/services/logging_service.dart';
import 'package:get_it/get_it.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;
  final VoidCallback? onRetry;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
    this.onRetry,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;
  final _errorService = GetIt.instance<ErrorService>();
  final _loggingService = GetIt.instance<LoggingService>();

  @override
  void initState() {
    super.initState();
    // Set up error handling for this subtree
    FlutterError.onError = (FlutterErrorDetails details) {
      _loggingService.logError(
        'Flutter error caught by ErrorBoundary',
        error: details.exception,
        stackTrace: details.stack,
      );
      // Defer setState to avoid calling it during build
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorDetails = details;
            });
          }
        });
      }
    };
  }

  void _resetError() {
    setState(() {
      _errorDetails = null;
    });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_errorDetails!);
      }

      return _DefaultErrorWidget(
        errorDetails: _errorDetails!,
        onRetry: _resetError,
      );
    }

    return widget.child;
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;
  final VoidCallback onRetry;

  const _DefaultErrorWidget({
    Key? key,
    required this.errorDetails,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if we have Material directives available
    final hasDirectionality = Directionality.maybeOf(context) != null;
    
    if (hasDirectionality) {
      // If we're inside MaterialApp, use full error UI
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  '오류가 발생했습니다',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _getErrorMessage(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // If we're above MaterialApp, use a simple error UI
      return Container(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '오류가 발생했습니다',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getErrorMessage(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '다시 시도',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  String _getErrorMessage() {
    final error = errorDetails.exception;
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return '알 수 없는 오류가 발생했습니다.';
  }
}

// Widget extension for easy error boundary wrapping
extension ErrorBoundaryExtension on Widget {
  Widget withErrorBoundary({
    Widget Function(FlutterErrorDetails)? errorBuilder,
    VoidCallback? onRetry,
  }) {
    return ErrorBoundary(
      child: this,
      errorBuilder: errorBuilder,
      onRetry: onRetry,
    );
  }
}
// lib/core/services/logging_service.dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 로그 레벨 정의
enum LogLevel {
  info,
  warning,
  error,
  debug,
}

/// 로깅 서비스 - 애플리케이션 전체에서 로그를 관리
class LoggingService {
  // Singleton pattern
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();
  
  /// 정보 로그 기록
  void logInfo(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.info, message, context: context);
  }
  
  /// 정보 로그 기록 (별칭)
  void info(String message, {Map<String, dynamic>? context}) {
    logInfo(message, context: context);
  }
  
  /// 경고 로그 기록
  void logWarning(String message, {Map<String, dynamic>? context}) {
    _log(LogLevel.warning, message, context: context);
  }
  
  /// 에러 로그 기록
  void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }
  
  /// 에러 로그 기록 (별칭)
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    logError(message, error: error, stackTrace: stackTrace, context: context);
  }
  
  /// 디버그 로그 기록 (디버그 모드에서만)
  void logDebug(String message, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, context: context);
    }
  }
  
  /// 내부 로깅 구현
  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = {
      'timestamp': timestamp,
      'level': level.name,
      'message': message,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      if (context != null) 'context': context,
    };

    // 개발 모드에서는 콘솔에 출력
    if (kDebugMode) {
      _printToConsole(level, logEntry);
    }

    // developer log 사용
    developer.log(
      message,
      name: 'ChunkUp',
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );

    // 프로덕션에서는 외부 로깅 서비스에 전송
    if (!kDebugMode) {
      _sendToExternalService(logEntry);
    }
  }

  /// 콘솔에 로그 출력
  void _printToConsole(LogLevel level, Map<String, dynamic> logEntry) {
    final String prefix = _getLogPrefix(level);
    final String message = logEntry['message'];
    final context = logEntry['context'];

    print('$prefix$message');

    if (context != null) {
      print('  Context: $context');
    }

    if (logEntry.containsKey('error')) {
      print('  Error: ${logEntry['error']}');
    }

    if (kDebugMode && logEntry.containsKey('stackTrace')) {
      print('  Stack trace:\n${logEntry['stackTrace']}');
    }
  }

  /// 로그 접두사 가져오기
  String _getLogPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return '📘 INFO: ';
      case LogLevel.warning:
        return '⚠️ WARNING: ';
      case LogLevel.error:
        return '❌ ERROR: ';
      case LogLevel.debug:
        return '🔍 DEBUG: ';
    }
  }

  /// 외부 로깅 서비스에 전송
  void _sendToExternalService(Map<String, dynamic> logEntry) {
    // TODO: 외부 로깅 서비스 구현
    // 예: Firebase Crashlytics, Sentry, Custom Analytics 등
  }
}
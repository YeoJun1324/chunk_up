import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:chunk_up/di/dependency_injection.dart' as di;
import 'package:chunk_up/infrastructure/logging/logging_service.dart';
import 'package:chunk_up/infrastructure/error/error_service.dart';
import 'package:chunk_up/domain/services/character/enhanced_character_service.dart';
import 'package:get_it/get_it.dart';

/// Handles app initialization and configuration
class AppInitializer {
  static bool _isInitialized = false;

  /// Initialize the app with proper error handling
  static Future<void> initialize({
    di.Environment environment = di.Environment.production,
  }) async {
    if (_isInitialized) return;

    try {
      // Ensure Flutter binding is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Set up error handling early
      _setupErrorHandling();

      // Configure system UI
      await _configureSystemUI();

      // Set up dependency injection
      await di.setupServiceLocator(environment: environment);

      // Initialize core services
      await _initializeCoreServices();

      _isInitialized = true;
    } catch (error, stackTrace) {
      // Log error but don't crash the app
      debugPrint('App initialization error: $error');
      debugPrint('Stack trace: $stackTrace');
      
      // Attempt minimal initialization
      await _minimalInitialization();
    }
  }

  /// Set up global error handling
  static void _setupErrorHandling() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log to console in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      
      // Log to service if available
      try {
        final loggingService = GetIt.instance<LoggingService>();
        loggingService.logError(
          'Flutter framework error',
          error: details.exception,
          stackTrace: details.stack,
        );
      } catch (_) {
        // Logging service not available yet
      }
    };

    // Handle errors outside Flutter framework  
    PlatformDispatcher.instance.onError = (error, stack) {
      try {
        // 서비스가 등록되어 있으면 사용
        if (GetIt.instance.isRegistered<ErrorService>()) {
          final errorService = GetIt.instance<ErrorService>();
          errorService.handleError(error, stack);
        } else if (GetIt.instance.isRegistered<LoggingService>()) {
          final loggingService = GetIt.instance<LoggingService>();
          loggingService.logError('Platform error', error: error, stackTrace: stack);
        } else {
          debugPrint('Unhandled platform error: $error');
          if (kDebugMode) {
            debugPrint('Stack trace: $stack');
          }
        }
      } catch (e) {
        debugPrint('Error handler failed: $e');
        debugPrint('Original error: $error');
      }
      return true; // Prevent app crash
    };
  }

  /// Configure system UI settings
  static Future<void> _configureSystemUI() async {
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Configure system overlay style (다크모드 고려)
    final brightness = PlatformDispatcher.instance.platformBrightness;
    final isDark = brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  /// Initialize core services that need early setup
  static Future<void> _initializeCoreServices() async {
    final getIt = GetIt.instance;

    // Initialize logging service
    final loggingService = getIt<LoggingService>();
    loggingService.logInfo('App initialization started');

    // Initialize error service (별도의 initialize 메소드가 없음)
    getIt<ErrorService>();

    // Initialize enhanced character service
    try {
      final enhancedCharacterService = getIt<EnhancedCharacterService>();
      await enhancedCharacterService.initializeDefaultCharacters();
      loggingService.logInfo('Enhanced character service initialized');
    } catch (e) {
      loggingService.logError('Failed to initialize enhanced character service', error: e);
    }
    

    // Add more service initializations as needed
    loggingService.logInfo('App initialization completed');
  }

  /// Minimal initialization for error scenarios
  static Future<void> _minimalInitialization() async {
    // Set up basic UI
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Register minimal services
    if (!GetIt.instance.isRegistered<LoggingService>()) {
      GetIt.instance.registerSingleton<LoggingService>(LoggingService());
    }
  }

  /// Clean up resources
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      // Dispose dependencies
      await di.dispose();
      
      _isInitialized = false;
    } catch (error) {
      debugPrint('Error during app disposal: $error');
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chunk_up/core/utils/api_exception.dart';
import 'package:chunk_up/core/services/logging_service.dart';
import 'package:chunk_up/core/services/cache_service_v2.dart';
import 'package:chunk_up/core/services/network_service.dart';

abstract class ApiServiceBase {
  final http.Client httpClient;
  final NetworkService networkService;
  final CacheServiceV2 cacheService;
  final LoggingService loggingService;
  final String baseUrl;

  ApiServiceBase({
    required this.httpClient,
    required this.networkService,
    required this.cacheService,
    required this.loggingService,
    required this.baseUrl,
  });

  Future<T> performRequest<T>({
    required String endpoint,
    required String method,
    required T Function(Map<String, dynamic>) parser,
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    String? cacheKey,
    Duration? cacheDuration,
  }) async {
    try {
      // Check network connectivity
      if (!await networkService.isConnected()) {
        if (cacheKey != null) {
          final cachedData = await cacheService.get(cacheKey);
          if (cachedData != null) {
            loggingService.logInfo('Using cached data for $endpoint');
            return parser(cachedData);
          }
        }
        throw ApiException(
          'No internet connection',
          type: ApiErrorType.noInternet,
        );
      }

      // Check cache first
      if (method == 'GET' && cacheKey != null) {
        final cachedData = await cacheService.get(cacheKey);
        if (cachedData != null) {
          loggingService.logInfo('Cache hit for $endpoint');
          return parser(cachedData);
        }
      }

      // Prepare request
      final uri = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = {
        'Content-Type': 'application/json',
        ...?headers,
      };

      // Log request
      loggingService.logInfo('API Request: $method $endpoint');
      if (body != null) {
        loggingService.logDebug('Request body: ${jsonEncode(body)}');
      }

      // Make request
      http.Response response;
      switch (method) {
        case 'GET':
          response = await httpClient.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await httpClient.post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await httpClient.put(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await httpClient.delete(uri, headers: requestHeaders);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }

      // Log response
      loggingService.logInfo('API Response: ${response.statusCode} from $endpoint');
      loggingService.logDebug('Response body: ${response.body}');

      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        // Cache successful GET responses
        if (method == 'GET' && cacheKey != null) {
          await cacheService.set(
            cacheKey,
            responseData,
            duration: cacheDuration ?? const Duration(minutes: 5),
          );
        }

        return parser(responseData);
      } else {
        final errorType = _getErrorTypeFromStatusCode(response.statusCode);
        throw ApiException(
          'Request failed: ${response.reasonPhrase}',
          type: errorType,
          response: response,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e, stackTrace) {
      loggingService.logError('API request failed', error: e, stackTrace: stackTrace);
      throw ApiException(
        'Unexpected error: ${e.toString()}',
        type: ApiErrorType.unknown,
      );
    }
  }
  
  ApiErrorType _getErrorTypeFromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return ApiErrorType.badRequest;
      case 401:
        return ApiErrorType.unauthorized;
      case 403:
        return ApiErrorType.forbidden;
      case 404:
        return ApiErrorType.notFound;
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
}
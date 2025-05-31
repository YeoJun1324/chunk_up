# SOLID Principles Refactoring Guide

## Overview

This guide documents the refactoring of the ChunkUp codebase to better adhere to SOLID principles, particularly the Single Responsibility Principle (SRP).

## Major Refactoring: UnifiedApiService

The `UnifiedApiService` was the largest violator of SRP with 1263 lines handling 10+ different responsibilities. It has been broken down into specialized services:

### Before (Monolithic Service)
```
UnifiedApiService (1263 lines)
├── API key management
├── HTTP request execution
├── Cache management
├── Response parsing
├── Model selection
├── Retry logic
├── Multiple AI provider support
├── Performance tracking
├── JSON cleaning
└── Static utility methods
```

### After (Specialized Services)

1. **ApiKeyService** (`lib/core/services/api/api_key_service.dart`)
   - Responsibility: API key storage, encryption, and validation
   - Key methods:
     - `storeApiKey()` - Encrypts and stores API keys
     - `getApiKey()` - Retrieves and decrypts API keys
     - `validateApiKeyFormat()` - Validates key format per provider

2. **HttpClientService** (`lib/core/services/api/http_client_service.dart`)
   - Responsibility: HTTP request execution with retry logic
   - Key methods:
     - `post()` - Executes POST requests with automatic retry
     - `postStream()` - Handles streaming responses
   - Features: Exponential backoff, rate limit handling

3. **ApiCacheService** (`lib/core/services/api/api_cache_service.dart`)
   - Responsibility: Response caching with LRU eviction
   - Key methods:
     - `get()` - Retrieves cached responses
     - `put()` - Stores responses with TTL
     - `evictExpired()` - Removes stale entries
   - Features: SHA256 cache keys, configurable TTL

4. **ModelSelectionService** (`lib/core/services/api/model_selection_service.dart`)
   - Responsibility: AI model selection based on subscription
   - Key methods:
     - `selectModel()` - Chooses best available model
     - `canUseModel()` - Validates model availability
     - `hasEnoughCredits()` - Checks credit sufficiency

5. **ResponseParserService** (`lib/core/services/api/response_parser_service.dart`)
   - Responsibility: Response parsing and normalization
   - Key methods:
     - `parseJsonResponse()` - Parses JSON with fallback
     - `extractContent()` - Provider-specific content extraction
     - `cleanContent()` - Removes thinking patterns

6. **UnifiedApiServiceRefactored** (`lib/core/services/api/unified_api_service_refactored.dart`)
   - Responsibility: Orchestration of specialized services
   - Delegates specific tasks to appropriate services
   - Maintains the same public API for backward compatibility

## Migration Guide

### Step 1: Update Service Registration

Replace the old service registration:

```dart
// Old
getIt.registerSingleton<UnifiedApiService>(
  UnifiedApiService(
    prefs: prefs,
    subscriptionService: getIt<SubscriptionService>(),
  ),
);

// New
getIt.registerSingleton<UnifiedApiServiceRefactored>(
  UnifiedApiServiceRefactored(
    prefs: prefs,
    subscriptionService: getIt<SubscriptionService>(),
  ),
);
```

### Step 2: Update Imports

Replace imports throughout the codebase:

```dart
// Old
import 'package:chunk_up/core/services/api/unified_api_service.dart';

// New
import 'package:chunk_up/core/services/api/unified_api_service_refactored.dart';
```

### Step 3: Update Type References

If you have explicit type references, update them:

```dart
// Old
final UnifiedApiService apiService;

// New
final UnifiedApiServiceRefactored apiService;
```

### Step 4: Testing Individual Services

Each service can now be tested independently:

```dart
// Test API key encryption
test('ApiKeyService encrypts and decrypts keys', () {
  final service = ApiKeyService(mockPrefs);
  await service.storeApiKey(AiModel.gemini25Flash, 'test-key');
  expect(service.getApiKey(AiModel.gemini25Flash), 'test-key');
});

// Test cache eviction
test('ApiCacheService evicts old entries', () {
  final cache = ApiCacheService(maxSize: 2);
  cache.put('prompt1', 'model', 'response1');
  cache.put('prompt2', 'model', 'response2');
  cache.put('prompt3', 'model', 'response3');
  expect(cache.get('prompt1', 'model'), isNull);
});
```

## Benefits Achieved

1. **Improved Testability**
   - Each service can be unit tested independently
   - Mocking is simpler with focused interfaces

2. **Better Maintainability**
   - Changes to caching don't affect API key management
   - New AI providers can be added without touching cache logic

3. **Enhanced Reusability**
   - `HttpClientService` can be used for other API calls
   - `ApiCacheService` can cache any string-based responses

4. **Clearer Responsibilities**
   - Each service has a single, well-defined purpose
   - Easier to understand and modify

## Next Refactoring Targets

### 1. SubscriptionService
Split into:
- `SubscriptionStateManager` - Business logic
- `SubscriptionRepository` - Persistence
- `CreditManager` - Credit tracking
- `FeatureAccessService` - Feature gating

### 2. Screen Classes
Extract business logic into:
- ViewModels for state management
- Use cases for business operations
- Navigation services for routing

### 3. Firebase Services
Separate:
- Repository interfaces (domain layer)
- Firebase implementations (data layer)
- Caching decorators

## Best Practices Applied

1. **Dependency Injection**
   - All services receive dependencies through constructors
   - Easy to mock for testing

2. **Interface Segregation**
   - Each service exposes only necessary methods
   - Clients depend on what they need

3. **Open/Closed Principle**
   - New AI providers can be added without modifying existing code
   - Cache strategies can be swapped via inheritance

4. **Composition over Inheritance**
   - UnifiedApiServiceRefactored composes specialized services
   - Flexible and maintainable

## Metrics Improvement

- **Lines per class**: Reduced from 1263 to ~200 max
- **Methods per class**: Reduced from 30+ to ~10 max
- **Responsibilities per class**: Reduced from 10+ to 1
- **Test complexity**: Significantly simplified
- **Code duplication**: Eliminated through focused services
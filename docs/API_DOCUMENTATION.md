# ChunkUp API Documentation

## Table of Contents
1. [Overview](#overview)
2. [Core Services](#core-services)
3. [Domain Models](#domain-models)
4. [API Endpoints](#api-endpoints)
5. [Authentication](#authentication)
6. [Error Handling](#error-handling)

## Overview

ChunkUp is a language learning application that helps users learn vocabulary through contextual learning. The application follows clean architecture principles with clear separation between presentation, domain, and data layers.

## Core Services

### SubscriptionService

Manages user subscription state and credit usage.

```dart
class SubscriptionService {
  // Check if user has premium subscription
  bool get isPremium;
  
  // Check if user can create a chunk
  bool get canCreateChunk;
  
  // Track chunk creation for free users
  Future<void> trackChunkCreation();
  
  // Deduct credits for AI model usage
  Future<bool> deductCredits(int credits);
  
  // Get remaining credits
  int get remainingCredits;
}
```

### UnifiedApiService

Handles all AI model interactions with retry logic and caching.

```dart
class UnifiedApiService {
  // Generate content using AI models
  Future<String> generateContent({
    required String prompt,
    required AiModel model,
    String? userId,
  });
  
  // Chat completion with streaming support
  Stream<String> chatCompletion({
    required List<Map<String, String>> messages,
    required AiModel model,
  });
}
```

### FirebaseApiService

Enhanced Firebase service with caching and retry logic.

```dart
class FirebaseApiServiceEnhanced extends FirebaseApiService {
  // Create document with retry logic
  Future<String> createDocument({
    required String collection,
    required Map<String, dynamic> data,
  });
  
  // Read document with caching
  Future<Map<String, dynamic>?> readDocument({
    required String collection,
    required String documentId,
  });
  
  // Update document
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  });
  
  // Delete document
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  });
}
```

### PdfCoordinator

Manages PDF generation for exams and learning materials.

```dart
class PdfCoordinator {
  // Generate exam PDF
  Future<void> generateExamPdf({
    required List<WordListInfo> wordLists,
    required List<Chunk> chunks,
    required ExamConfig config,
    required String fileName,
  });
  
  // Generate material PDF
  Future<void> generateMaterialPdf({
    required List<WordListInfo> wordLists,
    required MaterialConfig config,
    required String fileName,
  });
}
```

## Domain Models

### Subscription Models

```dart
enum SubscriptionType {
  free,
  premium,
}

class SubscriptionPlan {
  final SubscriptionType type;
  final String name;
  final int monthlyPrice;
  final int? discountedPrice;
  final List<AiModel> availableModels;
  final int? monthlyCredits;
  final int? freeChunkLimit;
  final bool hasAds;
  final bool canExportPdf;
}

class SubscriptionStatus {
  final SubscriptionType type;
  final DateTime? expiresAt;
  final int creditsUsed;
  final int creditsRemaining;
  final int freeChunksCreated;
}
```

### AI Model

```dart
enum AiModel {
  gemini25Flash,  // 1 credit per use
  claudeSonnet4,  // 6 credits per use
}
```

### Exam Models

```dart
enum QuestionType {
  fillInBlanks,        // 빈칸 채우기
  contextMeaning,      // 문맥상 단어 의미 서술
  korToEngTranslation, // 한영 번역
}

class ExamQuestion {
  final String id;
  final QuestionType type;
  final String question;
  final String answer;
  final String? targetWord;
  final String? sourceChunkId;
}

class ExamConfig {
  final Map<QuestionType, int> questionCounts;
  final bool includeAnswerKey;
  final bool shuffleQuestions;
  final String title;
}
```

### Content Models

```dart
class Word {
  final String id;
  final String english;
  final String korean;
  final String? exampleSentence;
  final bool isInChunk;
  final DateTime createdAt;
}

class Chunk {
  final String id;
  final String displayContent;
  final String jsonContent;
  final List<String> wordIds;
  final DateTime createdAt;
  final String? modelUsed;
}

class WordListInfo {
  final String name;
  final List<Word> words;
  final List<Chunk>? chunks;
  final int chunkCount;
}
```

## API Endpoints

### Firestore Collections

#### Users Collection
```
/users/{userId}
  - subscriptionStatus: SubscriptionStatus
  - profile: UserProfile
  - settings: UserSettings
```

#### Word Lists Collection
```
/users/{userId}/wordLists/{listId}
  - name: string
  - createdAt: timestamp
  - wordCount: number
```

#### Words Collection
```
/users/{userId}/wordLists/{listId}/words/{wordId}
  - english: string
  - korean: string
  - exampleSentence: string?
  - isInChunk: boolean
  - createdAt: timestamp
```

#### Chunks Collection
```
/users/{userId}/chunks/{chunkId}
  - displayContent: string
  - jsonContent: string
  - wordIds: string[]
  - wordListId: string
  - createdAt: timestamp
  - modelUsed: string
```

## Authentication

ChunkUp uses Firebase Authentication for user management.

### Supported Authentication Methods
- Email/Password
- Google Sign-In
- Apple Sign-In

### Authentication Flow
```dart
// Sign in with email
Future<User?> signInWithEmail(String email, String password);

// Sign in with Google
Future<User?> signInWithGoogle();

// Sign out
Future<void> signOut();

// Get current user
User? get currentUser;

// Auth state changes
Stream<User?> get authStateChanges;
```

## Error Handling

### Error Types

```dart
class ApiException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
}

class SubscriptionException implements Exception {
  final String message;
  final SubscriptionError type;
}

enum SubscriptionError {
  insufficientCredits,
  chunkLimitExceeded,
  subscriptionExpired,
  modelNotAvailable,
}
```

### Error Response Format

```json
{
  "error": {
    "code": "INSUFFICIENT_CREDITS",
    "message": "Not enough credits to perform this action",
    "details": {
      "required": 6,
      "available": 2
    }
  }
}
```

### Retry Logic

The API service implements exponential backoff for transient errors:
- Max retries: 3
- Initial delay: 1 second
- Max delay: 8 seconds
- Backoff multiplier: 2

### Rate Limiting

- Gemini 2.5 Flash: 60 requests per minute
- Claude Sonnet 4: 20 requests per minute
- Firestore: Standard Firebase quotas apply

## Usage Examples

### Creating a Chunk

```dart
// Check if user can create chunk
if (subscriptionService.canCreateChunk) {
  // Deduct credits for the selected model
  final success = await subscriptionService.deductCredits(
    model.creditCost
  );
  
  if (success) {
    // Generate content
    final content = await apiService.generateContent(
      prompt: prompt,
      model: model,
      userId: userId,
    );
    
    // Save to Firestore
    final chunkId = await firebaseService.createDocument(
      collection: 'users/$userId/chunks',
      data: {
        'displayContent': content,
        'wordIds': wordIds,
        'createdAt': FieldValue.serverTimestamp(),
        'modelUsed': model.name,
      },
    );
    
    // Track chunk creation for free users
    if (!subscriptionService.isPremium) {
      await subscriptionService.trackChunkCreation();
    }
  }
}
```

### Generating an Exam PDF

```dart
// Configure exam
final config = ExamConfig(
  questionCounts: {
    QuestionType.fillInBlanks: 10,
    QuestionType.contextMeaning: 5,
    QuestionType.korToEngTranslation: 5,
  },
  includeAnswerKey: true,
  shuffleQuestions: true,
  title: 'ChunkUp Exam',
);

// Generate PDF
await pdfCoordinator.generateExamPdf(
  wordLists: selectedWordLists,
  chunks: chunks,
  config: config,
  fileName: 'exam_${DateTime.now().millisecondsSinceEpoch}.pdf',
);
```

## Best Practices

1. **Always check subscription status** before performing premium actions
2. **Handle errors gracefully** with user-friendly messages
3. **Use caching** for frequently accessed data
4. **Implement retry logic** for network operations
5. **Track usage metrics** for credit consumption
6. **Validate input data** before API calls
7. **Use streaming** for real-time AI responses
8. **Batch operations** when possible to reduce API calls
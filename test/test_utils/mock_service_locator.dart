import 'package:chunk_up/core/services/api_service.dart';
import 'package:chunk_up/core/services/character_service.dart';
import 'package:chunk_up/core/services/error_service.dart';
import 'package:chunk_up/core/services/logging_service.dart';
import 'package:chunk_up/core/services/review_service.dart';
import 'package:chunk_up/core/services/notification_service.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/domain/usecases/create_word_list_use_case.dart';
import 'package:chunk_up/di/dependency_injection.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/presentation/providers/folder_notifier.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/chunk.dart';

/// 테스트에서 사용할 수 있는 목(mock) 서비스 로케이터 설정
Future<void> setupTestServiceLocator() async {
  // 기존 서비스 로케이터 재설정
  getIt.reset();

  // 테스트용 간단 구현체 등록
  getIt.registerSingleton<ApiService>(MockApiService());
  getIt.registerSingleton<ErrorService>(MockErrorService());
  getIt.registerSingleton<LoggingService>(MockLoggingService());
  getIt.registerSingleton<CharacterService>(MockCharacterService());
  getIt.registerSingleton<ReviewService>(MockReviewService());
  getIt.registerSingleton<NotificationService>(MockNotificationService());

  // 리포지토리 등록
  final mockWordListRepo = MockWordListRepository();
  final mockChunkRepo = MockChunkRepository();

  getIt.registerSingleton<WordListRepositoryInterface>(mockWordListRepo);
  getIt.registerSingleton<ChunkRepositoryInterface>(mockChunkRepo);

  // UseCase 등록
  final mockCreateWordListUseCase = MockCreateWordListUseCase(
    wordListRepository: mockWordListRepo
  );
  getIt.registerSingleton<CreateWordListUseCase>(mockCreateWordListUseCase);

  // 프로바이더 등록
  getIt.registerFactory<WordListNotifier>(() => WordListNotifier(
    wordListRepository: mockWordListRepo,
    chunkRepository: mockChunkRepo,
    createWordListUseCase: mockCreateWordListUseCase,
  ));
  getIt.registerFactory<FolderNotifier>(() => FolderNotifier());
}

/// 모의 API 서비스
class MockApiService implements ApiService {
  @override
  Future<bool> testApiConnection() async => true;
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

/// 모의 에러 서비스
class MockErrorService implements ErrorService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

/// 모의 로깅 서비스
class MockLoggingService implements LoggingService {
  @override
  void log(String message) {}
  
  @override
  void logError(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? context}) {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

/// 모의 캐릭터 서비스
class MockCharacterService implements CharacterService {
  @override
  Future<void> initializeDefaultCharacters() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

/// 모의 리뷰 서비스
class MockReviewService implements ReviewService {
  @override
  Future<bool> checkForTodaysReviews() async => false;
  
  @override
  Future<void> sendDailyReviewNotifications() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

/// 모의 알림 서비스
class MockNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

/// 모의 단어장 리포지토리
class MockWordListRepository implements WordListRepositoryInterface {
  final List<WordListInfo> _wordLists = [];

  @override
  Future<List<WordListInfo>> getAllWordLists() async {
    return _wordLists;
  }

  @override
  Future<WordListInfo?> getWordListById(String id) async {
    return null;
  }

  @override
  Future<WordListInfo> createWordList(WordListInfo wordList) async {
    _wordLists.add(wordList);
    return wordList;
  }

  @override
  Future<WordListInfo> updateWordList(WordListInfo wordList) async {
    return wordList;
  }

  @override
  Future<bool> deleteWordList(String id) async {
    return true;
  }

  @override
  Future<WordListInfo> addWordToList(WordListInfo wordList, Word word) async {
    return wordList;
  }
}

/// 모의 청크 리포지토리
class MockChunkRepository implements ChunkRepositoryInterface {
  @override
  Future<List<Chunk>> generateChunks(String wordListId) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> generateChunk(String prompt) async {
    return {'content': 'Sample content'};
  }

  @override
  Future<List<Chunk>> getChunksForWordList(String wordListId) async {
    return [];
  }

  @override
  Future<Chunk?> getChunkById(String id) async {
    return null;
  }

  @override
  Future<Chunk> saveChunk(Chunk chunk) async {
    return chunk;
  }

  @override
  Future<bool> deleteChunk(String id) async {
    return true;
  }
}

/// 모의 단어장 생성 UseCase
class MockCreateWordListUseCase extends CreateWordListUseCase {
  MockCreateWordListUseCase({required super.wordListRepository});

  @override
  Future<WordListInfo> execute(WordListInfo wordList) async {
    return wordList;
  }

  @override
  Future<WordListInfo> call(CreateWordListParams params) async {
    final wordList = WordListInfo(
      name: params.name,
      words: params.words ?? [],
      chunks: [],
      chunkCount: 0,
    );
    return await wordListRepository.createWordList(wordList);
  }
}
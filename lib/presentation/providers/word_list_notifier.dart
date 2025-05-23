// lib/presentation/providers/word_list_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/domain/usecases/create_word_list_use_case.dart';
import 'package:chunk_up/core/utils/business_exception.dart';
import 'package:chunk_up/core/services/error_service.dart';
import 'package:chunk_up/core/services/logging_service.dart';

/// 단어장 데이터를 관리하는 Provider
/// 
/// 불변성 원칙을 적용하여 단어장 데이터를 안전하게 관리합니다.
/// 모든 데이터 수정은 새 객체를 생성하는 방식으로 이루어집니다.
class WordListNotifier with ChangeNotifier {
  final ErrorService _errorService = ErrorService();
  final LoggingService _loggingService = LoggingService();
  final WordListRepositoryInterface _wordListRepository;
  final ChunkRepositoryInterface _chunkRepository;
  final CreateWordListUseCase _createWordListUseCase;

  /// 단어장 목록
  List<WordListInfo> _wordLists = [];
  
  /// 로딩 상태
  bool _isLoading = true;

  WordListNotifier({
    required WordListRepositoryInterface wordListRepository,
    required ChunkRepositoryInterface chunkRepository,
    required CreateWordListUseCase createWordListUseCase,
  })  : _wordListRepository = wordListRepository,
        _chunkRepository = chunkRepository,
        _createWordListUseCase = createWordListUseCase {
    _loadData();
  }

  /// 단어장 목록 (수정 불가능한 목록으로 반환)
  List<WordListInfo> get wordLists => List.unmodifiable(_wordLists);
  
  /// 로딩 상태
  bool get isLoading => _isLoading;

  // 로딩 상태 변경
  bool _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 데이터 로드
  Future<void> _loadData() async {
    try {
      _setLoading(true);

      await _handleProviderError(
        operation: '_loadData',
        action: () async {
          // 불변성 원칙 적용 - 새 목록 할당
          final loadedWordLists = await _wordListRepository.getAllWordLists();

          // 내용이 변경된 경우에만 상태 업데이트 및 알림
          if (!_areListsEqual(_wordLists, loadedWordLists)) {
            _wordLists = List<WordListInfo>.from(loadedWordLists);
          }
        },
      );
    } catch (e) {
      _loggingService.logError('단어장 로딩 중 오류', error: e);
    } finally {
      _setLoading(false);
    }
  }

  /// 두 목록이 동일한지 확인 (내용 비교)
  bool _areListsEqual(List<WordListInfo> list1, List<WordListInfo> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i].name != list2[i].name ||
          list1[i].words.length != list2[i].words.length ||
          list1[i].chunkCount != list2[i].chunkCount) {
        return false;
      }
    }

    return true;
  }

  /// 새 단어장 추가
  Future<void> addNewWordList(String name) async {
    await _handleProviderError(
      operation: 'addNewWordList',
      action: () async {
        if (name.isEmpty) {
          throw BusinessException(
            type: BusinessErrorType.validationError,
            message: '단어장 이름을 입력해주세요.',
          );
        }

        final params = CreateWordListParams(name: name);
        final newWordList = await _createWordListUseCase.call(params);
        
        // 불변성 원칙 적용 - 새 목록 생성
        _wordLists = [..._wordLists, newWordList];
        notifyListeners();
      },
    );
  }

  /// 에러 처리 핸들러
  Future<T> _handleProviderError<T>({
    required Future<T> Function() action,
    String? operation,
  }) async {
    try {
      return await action();
    } catch (e, stackTrace) {
      _loggingService.logError(
        'Provider error',
        error: e,
        stackTrace: stackTrace,
        context: {'operation': operation},
      );
      rethrow;
    }
  }

  /// 특정 단어장에 단어 추가
  Future<void> addWordToSpecificList(String listName, Word newWord) async {
    await _handleProviderError(
      operation: 'addWordToSpecificList',
      action: () async {
        // 단어장 찾기
        final wordList = await _wordListRepository.getWordListById(listName);
        if (wordList == null) {
          throw BusinessException(
            type: BusinessErrorType.wordNotFound,
            message: '해당 이름의 단어장을 찾을 수 없습니다: $listName',
          );
        }
        
        // 단어 추가
        await _wordListRepository.addWordToList(wordList, newWord);
        
        // 목록 새로고침 (저장소에서 최신 데이터 로드)
        await _loadData();
      },
    );
  }

  /// 단어장에 청크 추가
  Future<void> addChunkToWordList(String listName, Chunk newChunk) async {
    await _handleProviderError(
      operation: 'addChunkToWordList',
      action: () async {
        // 단어장 찾기
        final existingListIndex = _wordLists.indexWhere((list) => list.name == listName);
        if (existingListIndex == -1) {
          throw BusinessException(
            type: BusinessErrorType.wordNotFound,
            message: '해당 이름의 단어장을 찾을 수 없습니다: $listName',
          );
        }
        
        final existingList = _wordLists[existingListIndex];

        // 중복 청크 확인
        if (existingList.chunks != null) {
          final existingChunk = existingList.chunks!.any(
            (chunk) => chunk.id == newChunk.id
          );

          if (existingChunk) {
            debugPrint('이미 존재하는 청크입니다 (ID: ${newChunk.id}). 중복 저장을 방지합니다.');
            return;
          }
        }

        // 청크 저장
        await _chunkRepository.saveChunk(newChunk);

        // 불변성 원칙 적용 - 단어 목록 복사 및 수정
        final updatedWords = existingList.words.map((word) {
          // 해당 단어가 새 청크에 포함되어 있고, 아직 isInChunk가 false인 경우에만 업데이트
          final isIncluded = newChunk.includedWords.any((w) => w.english == word.english);
          
          if (isIncluded && !word.isInChunk) {
            // 새 Word 객체 생성 (불변성 유지)
            return Word(
              english: word.english,
              korean: word.korean,
              isInChunk: true,
              testAccuracy: word.testAccuracy,
              addedDate: word.addedDate,
            );
          }
          
          return word; // 변경이 필요 없는 경우 원래 단어 반환
        }).toList();

        // 불변성 원칙 적용 - 청크 목록 복사 및 추가
        final List<Chunk> updatedChunks = [
          ...(existingList.chunks ?? []),
          newChunk
        ];

        // 불변성 원칙 적용 - 새 WordListInfo 객체 생성
        final updatedWordList = WordListInfo(
          name: existingList.name,
          words: updatedWords,
          chunks: updatedChunks,
          chunkCount: updatedChunks.length,
        );

        // 워드리스트 업데이트 및 목록 새로고침
        await _wordListRepository.updateWordList(updatedWordList);
        await _loadData();
      },
    );
  }

  /// 단어장 삭제
  Future<void> deleteWordList(WordListInfo listInfo) async {
    await _handleProviderError(
      operation: 'deleteWordList',
      action: () async {
        await _wordListRepository.deleteWordList(listInfo.name);
        
        // 불변성 원칙 적용 - 새 목록 생성 (필터링)
        _wordLists = _wordLists.where((list) => list.name != listInfo.name).toList();
        notifyListeners();
      },
    );
  }

  /// 모든 데이터 초기화
  Future<void> resetAllData() async {
    await _handleProviderError(
      operation: 'resetAllData',
      action: () async {
        // 모든 단어장 삭제
        for (final wordList in _wordLists) {
          await _wordListRepository.deleteWordList(wordList.name);
        }
        await _loadData();
      },
    );
  }

  /// 청크 삭제
  Future<void> deleteChunk(String listName, Chunk chunk) async {
    await _handleProviderError(
      operation: 'deleteChunk',
      action: () async {
        // 청크 삭제
        await _chunkRepository.deleteChunk(chunk.id);

        // 워드리스트에서 해당 청크 제거
        final wordList = await _wordListRepository.getWordListById(listName);
        if (wordList != null && wordList.chunks != null) {
          // 불변성 원칙 적용 - 청크 목록 필터링
          final updatedChunks = wordList.chunks!
            .where((c) => c.id != chunk.id)
            .toList();

          // 불변성 원칙 적용 - 단어 상태 업데이트
          final updatedWords = wordList.words.map((word) {
            // 이 단어가 삭제된 청크에 포함되어 있었는지 확인
            if (chunk.includedWords.any((w) => w.english == word.english)) {
              // 이 단어가 다른 청크들 중 하나라도 포함되어 있는지 확인
              final isInOtherChunks = updatedChunks.any((c) =>
                c.includedWords.any((w) => w.english == word.english)
              );

              // 다른 청크에 포함되지 않은 경우, isInChunk를 false로 설정한 새 객체 생성
              if (!isInOtherChunks) {
                return Word(
                  english: word.english,
                  korean: word.korean,
                  isInChunk: false,
                  testAccuracy: word.testAccuracy,
                  addedDate: word.addedDate,
                );
              }
            }
            
            return word; // 변경이 필요 없는 경우 원래 단어 반환
          }).toList();

          // 불변성 원칙 적용 - 새 WordListInfo 객체 생성
          final updatedWordList = WordListInfo(
            name: wordList.name,
            words: updatedWords,
            chunks: updatedChunks,
            chunkCount: updatedChunks.length,
          );

          await _wordListRepository.updateWordList(updatedWordList);
        }

        await _loadData();
      },
    );
  }

  /// 단어장 이름 수정
  Future<void> editWordListName(WordListInfo listInfo, String newName) async {
    await _handleProviderError(
      operation: 'editWordListName',
      action: () async {
        if (newName.isEmpty) {
          throw BusinessException(
            type: BusinessErrorType.validationError,
            message: '단어장 이름을 입력해주세요.',
          );
        }

        // 기존 단어장 가져오기
        final existingWordList = await _wordListRepository.getWordListById(listInfo.name);
        if (existingWordList == null) {
          throw BusinessException(
            type: BusinessErrorType.wordNotFound,
            message: '해당 이름의 단어장을 찾을 수 없습니다: ${listInfo.name}',
          );
        }

        // 불변성 원칙 적용 - 새 WordListInfo 객체 생성
        final updatedWordList = WordListInfo(
          name: newName,
          words: List<Word>.from(existingWordList.words),
          chunks: existingWordList.chunks != null 
            ? List<Chunk>.from(existingWordList.chunks!) 
            : null,
          chunkCount: existingWordList.chunkCount,
        );

        // 새 단어장 저장
        await _wordListRepository.createWordList(updatedWordList);

        // 기존 단어장 삭제
        await _wordListRepository.deleteWordList(listInfo.name);

        await _loadData();
      },
    );
  }

  /// 단어 삭제
  Future<void> deleteWord(String wordListName, Word wordToDelete) async {
    await _handleProviderError(
      operation: 'deleteWord',
      action: () async {
        // 단어장 가져오기
        final wordList = await _wordListRepository.getWordListById(wordListName);
        if (wordList == null) {
          throw BusinessException(
            type: BusinessErrorType.wordNotFound,
            message: '해당 이름의 단어장을 찾을 수 없습니다: $wordListName',
          );
        }

        // 단어가 청크에 포함되어 있는지 확인
        final isUsedInChunks = wordToDelete.isInChunk;

        // 불변성 원칙 적용 - 단어 목록 필터링
        final updatedWords = wordList.words
          .where((w) => w.english != wordToDelete.english || w.korean != wordToDelete.korean)
          .toList();

        // 삭제할 단어를 찾지 못한 경우
        if (updatedWords.length == wordList.words.length) {
          throw BusinessException(
            type: BusinessErrorType.wordNotFound,
            message: '해당 단어를 찾을 수 없습니다: ${wordToDelete.english}',
          );
        }

        // 불변성 원칙 적용 - 새 WordListInfo 객체 생성
        final updatedWordList = WordListInfo(
          name: wordList.name,
          words: updatedWords,
          chunks: wordList.chunks != null
            ? List<Chunk>.from(wordList.chunks!)
            : null,
          chunkCount: wordList.chunkCount,
        );

        // 단어장 업데이트
        await _wordListRepository.updateWordList(updatedWordList);

        // 데이터 새로고침
        await _loadData();

        // 청크에 포함된 단어였다면 경고 로그 남기기
        if (isUsedInChunks) {
          _loggingService.logWarning(
            '청크에 포함된 단어 삭제됨',
            context: {
              'word': wordToDelete.english,
              'wordListName': wordListName,
            },
          );
        }
      },
    );
  }

  /// 단어 수정
  ///
  /// 단어장 내의 특정 단어를 업데이트합니다.
  /// 불변성 원칙에 따라 새로운 객체를 생성하여 업데이트합니다.
  Future<void> updateWord(String wordListName, Word oldWord, Word newWord) async {
    await _handleProviderError(
      operation: 'updateWord',
      action: () async {
        // 단어장 가져오기
        final wordList = await _wordListRepository.getWordListById(wordListName);
        if (wordList == null) {
          throw BusinessException(
            type: BusinessErrorType.wordNotFound,
            message: '해당 이름의 단어장을 찾을 수 없습니다: $wordListName',
          );
        }

        // 기존 단어 찾기
        final wordIndex = wordList.words.indexWhere(
          (w) => w.english == oldWord.english && w.korean == oldWord.korean
        );

        // 수정할 단어를 찾지 못한 경우
        if (wordIndex == -1) {
          throw BusinessException(
            type: BusinessErrorType.wordNotFound,
            message: '해당 단어를 찾을 수 없습니다: ${oldWord.english}',
          );
        }

        // 청크에 포함된 단어인지 확인 (기존 상태 유지)
        final isInChunk = wordList.words[wordIndex].isInChunk;

        // 불변성 원칙 적용 - 테스트 정확도와 추가 날짜 보존
        final updatedWord = Word(
          english: newWord.english,
          korean: newWord.korean,
          isInChunk: isInChunk,
          testAccuracy: oldWord.testAccuracy,
          addedDate: oldWord.addedDate,
        );

        // 불변성 원칙 적용 - 단어 목록 복사 및 수정
        final List<Word> updatedWords = List.from(wordList.words);
        updatedWords[wordIndex] = updatedWord;

        // 불변성 원칙 적용 - 새 WordListInfo 객체 생성
        final updatedWordList = WordListInfo(
          name: wordList.name,
          words: updatedWords,
          chunks: wordList.chunks != null
            ? List<Chunk>.from(wordList.chunks!)
            : null,
          chunkCount: wordList.chunkCount,
        );

        // 단어장 업데이트
        await _wordListRepository.updateWordList(updatedWordList);

        // 데이터 새로고침
        await _loadData();

        // 청크에 포함된 단어가 수정되었다면 로그 남기기
        if (isInChunk) {
          _loggingService.logInfo(
            '청크에 포함된 단어 수정됨',
            context: {
              'oldWord': '${oldWord.english} (${oldWord.korean})',
              'newWord': '${newWord.english} (${newWord.korean})',
              'wordListName': wordListName,
            },
          );
        }
      },
    );
  }

  /// 오답 노트 단어장 생성 또는 가져오기
  Future<WordListInfo> getOrCreateMistakeWordList() async {
    const String mistakeListName = '오답 노트';

    return await _handleProviderError(
      operation: 'getOrCreateMistakeWordList',
      action: () async {
        // 이미 오답 노트 단어장이 있는지 확인
        final existingMistakeList = _wordLists.where((list) => list.name == mistakeListName).toList();

        if (existingMistakeList.isNotEmpty) {
          return existingMistakeList.first;
        }

        // 없으면 새로운 오답 노트 단어장 생성
        final params = CreateWordListParams(name: mistakeListName);
        final newWordList = await _createWordListUseCase.call(params);

        // 불변성 원칙 적용 - 새 목록 생성
        _wordLists = [..._wordLists, newWordList];
        notifyListeners();

        return newWordList;
      },
    );
  }

  /// 오답 노트에 틀린 단어들 추가
  Future<void> addMistakesToWordList(List<Word> mistakeWords) async {
    await _handleProviderError(
      operation: 'addMistakesToWordList',
      action: () async {
        if (mistakeWords.isEmpty) {
          return; // 틀린 단어가 없으면 작업 수행하지 않음
        }

        // 오답 노트 단어장 가져오기 또는 생성
        final mistakeWordList = await getOrCreateMistakeWordList();

        // 현재 오답 노트에 있는 단어들
        final existingWords = mistakeWordList.words;

        // 중복되지 않는 새 단어들만 필터링
        final newWords = mistakeWords.where((newWord) {
          return !existingWords.any((existing) =>
            existing.english == newWord.english &&
            existing.korean == newWord.korean
          );
        }).toList();

        if (newWords.isEmpty) {
          return; // 추가할 새 단어가 없음
        }

        // 불변성 원칙 적용 - 새 단어 목록 생성
        final updatedWords = [...existingWords, ...newWords];

        // 불변성 원칙 적용 - 새 WordListInfo 객체 생성
        final updatedWordList = WordListInfo(
          name: mistakeWordList.name,
          words: updatedWords,
          chunks: mistakeWordList.chunks,
          chunkCount: mistakeWordList.chunkCount,
        );

        // 단어장 업데이트
        await _wordListRepository.updateWordList(updatedWordList);

        // 데이터 새로고침
        await _loadData();

        _loggingService.logInfo(
          '오답 노트에 단어 추가됨',
          context: {
            'count': newWords.length,
            'words': newWords.map((w) => w.english).toList(),
          },
        );
      },
    );
  }
}
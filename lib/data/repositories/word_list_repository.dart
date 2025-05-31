// lib/data/repositories/word_list_repository.dart
import 'package:chunk_up/core/utils/business_exception.dart';
import 'package:chunk_up/data/repositories/base/unified_base_repository.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/data/datasources/local/storage_service.dart';

class WordListRepositoryImpl extends UnifiedBaseRepository<WordListInfo> implements WordListRepositoryInterface {
  static const String _storageKey = 'word_lists';

  WordListRepositoryImpl();

  @override
  String get storageKey => _storageKey;

  @override
  String getId(WordListInfo entity) => entity.name;

  @override
  WordListInfo fromJson(Map<String, dynamic> json) => WordListInfo.fromJson(json);

  @override
  Map<String, dynamic> toJson(WordListInfo entity) => entity.toJson();

  @override
  Future<List<WordListInfo>> getAllWordLists() async {
    // StorageService를 사용하여 초기 데이터 포함하여 로드
    return await StorageService.loadWordLists();
  }

  @override
  Future<WordListInfo?> getWordListById(String id) async {
    try {
      final wordLists = await getAllWordLists();
      return wordLists.firstWhere(
        (wl) => wl.name == id,
        orElse: () => throw BusinessException(
          type: BusinessErrorType.wordNotFound,
          message: 'No word list with the name $id was found',
        ),
      );
    } catch (e) {
      if (e is BusinessException) rethrow;
      throw BusinessException(
        type: BusinessErrorType.wordNotFound,
        message: 'No word list with the name $id was found',
      );
    }
  }

  @override
  Future<WordListInfo> createWordList(WordListInfo wordList) async {
    final wordLists = await getAllWordLists();

    // Check if a word list with the same name already exists
    if (wordLists.any((wl) => wl.name == wordList.name)) {
      throw BusinessException(
        type: BusinessErrorType.duplicateWordList,
        message: 'A word list with the name ${wordList.name} already exists',
      );
    }

    // Add to the list and save using StorageService
    final updatedLists = [...wordLists, wordList];
    await StorageService.saveWordLists(updatedLists);
    return wordList;
  }

  @override
  Future<WordListInfo> updateWordList(WordListInfo wordList) async {
    final wordLists = await getAllWordLists();
    final index = wordLists.indexWhere((wl) => wl.name == wordList.name);
    
    if (index == -1) {
      throw BusinessException(
        type: BusinessErrorType.wordNotFound,
        message: 'Word list not found',
      );
    }
    
    wordLists[index] = wordList;
    await StorageService.saveWordLists(wordLists);
    return wordList;
  }

  @override
  Future<bool> deleteWordList(String id) async {
    final wordLists = await getAllWordLists();
    final initialLength = wordLists.length;
    
    wordLists.removeWhere((wl) => wl.name == id);
    
    if (wordLists.length == initialLength) {
      return false;
    }
    
    await StorageService.saveWordLists(wordLists);
    return true;
  }
  
  @override
  Future<WordListInfo> addWordToList(WordListInfo wordList, Word word) async {
    // Clone the word list to avoid direct modification
    final updatedWords = [...wordList.words, word];
    final updatedWordList = WordListInfo(
      name: wordList.name,
      words: updatedWords,
      chunks: wordList.chunks,
      chunkCount: wordList.chunkCount,
    );
    
    return await updateWordList(updatedWordList);
  }
}
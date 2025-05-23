// lib/data/repositories/word_list_repository.dart
import 'package:chunk_up/core/utils/business_exception.dart';
import 'package:chunk_up/data/repositories/base_repository.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';
import 'package:chunk_up/domain/models/word.dart';

class WordListRepositoryImpl extends BaseRepository<WordListInfo> implements WordListRepositoryInterface {
  static const String _storageKey = 'word_lists';

  WordListRepositoryImpl();

  @override
  String get storageKey => _storageKey;

  @override
  WordListInfo fromJson(Map<String, dynamic> json) => WordListInfo.fromJson(json);

  @override
  Map<String, dynamic> toJson(WordListInfo entity) => entity.toJson();

  @override
  Future<List<WordListInfo>> getAllWordLists() => getAll();

  @override
  Future<WordListInfo?> getWordListById(String id) async {
    try {
      return await findBy((wl) => wl.name == id);
    } catch (e) {
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

    return await create(wordList);
  }

  @override
  Future<WordListInfo> updateWordList(WordListInfo wordList) async {
    return await update(wordList, (wl) => wl.name == wordList.name);
  }

  @override
  Future<bool> deleteWordList(String id) async {
    return await delete((wl) => wl.name == id);
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
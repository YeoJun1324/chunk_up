// lib/domain/repositories/word_list_repository_interface.dart
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/models/word.dart';

/// Interface for the word list repository
abstract class WordListRepositoryInterface {
  /// Get all word lists
  Future<List<WordListInfo>> getAllWordLists();
  
  /// Get word list by id
  Future<WordListInfo?> getWordListById(String id);
  
  /// Create a new word list
  Future<WordListInfo> createWordList(WordListInfo wordList);
  
  /// Update an existing word list
  Future<WordListInfo> updateWordList(WordListInfo wordList);
  
  /// Delete a word list
  Future<bool> deleteWordList(String id);

  /// Add a word to a word list
  Future<WordListInfo> addWordToList(WordListInfo wordList, Word word);
}
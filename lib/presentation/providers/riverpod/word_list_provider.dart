import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/domain/models/freezed/word.dart';
import 'package:chunk_up/domain/models/freezed/chunk.dart';
import 'word_list_state.dart';

/// 단어장 Riverpod 상태 제공자
final wordListProvider = StateNotifierProvider<WordListNotifier, WordListState>((ref) {
  return WordListNotifier();
});

/// 단어장 관리 Notifier 클래스
class WordListNotifier extends StateNotifier<WordListState> {
  WordListNotifier() : super(const WordListState.loading()) {
    _loadWordLists();
  }

  /// 단어장 목록 로드
  Future<void> _loadWordLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('word_lists') ?? [];
      
      if (jsonList.isEmpty) {
        state = const WordListState.loaded(wordLists: []);
        return;
      }

      final loadedLists = <WordListInfo>[];

      for (final json in jsonList) {
        try {
          final Map<String, dynamic> data = jsonDecode(json);
          loadedLists.add(WordListInfo.fromJson(data));
        } catch (e) {
          // 개별 단어장 파싱 오류 처리
          print('단어장 파싱 오류: $e');
        }
      }

      // 선택된 단어장 이름 로드
      final selectedName = prefs.getString('selected_word_list');

      state = WordListState.loaded(
        wordLists: loadedLists,
        selectedWordListName: selectedName,
      );
    } catch (e) {
      // 전체 로드 오류 처리
      state = WordListState.error(
        message: '단어장을 로드하는 중 오류가 발생했습니다: $e',
        wordLists: const <WordListInfo>[],
      );
    }
  }

  /// 단어장 목록 저장
  Future<void> _saveWordLists() async {
    final lists = state.wordLists;
    if (lists.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = lists.map((list) => jsonEncode(list.toJson())).toList();
      await prefs.setStringList('word_lists', jsonList);

      // 선택된 단어장 이름 저장
      if (state.selectedWordListName != null) {
        await prefs.setString('selected_word_list', state.selectedWordListName!);
      }
    } catch (e) {
      // 저장 오류 처리
      state = WordListState.error(
        message: '단어장을 저장하는 중 오류가 발생했습니다: $e',
        wordLists: lists,
      );
    }
  }

  /// 단어장 선택
  void selectWordList(String? name) {
    state.maybeMap(
      loaded: (loadedState) {
        state = WordListState.loaded(
          wordLists: loadedState.wordLists,
          selectedWordListName: name,
        );
        _saveWordLists();
      },
      orElse: () {},
    );
  }

  /// 단어장 추가
  Future<void> addWordList(WordListInfo wordList) async {
    final currentLists = state.wordLists;
    final updatedLists = [...currentLists, wordList];

    state = WordListState.loaded(
      wordLists: updatedLists,
      selectedWordListName: state.selectedWordListName,
    );
    await _saveWordLists();
  }

  /// 단어장 업데이트
  Future<void> updateWordList(WordListInfo updatedList) async {
    final currentLists = state.wordLists;
    final index = currentLists.indexWhere((list) => list.name == updatedList.name);

    if (index == -1) return;

    final updatedLists = [...currentLists];
    updatedLists[index] = updatedList;

    state = WordListState.loaded(
      wordLists: updatedLists,
      selectedWordListName: state.selectedWordListName,
    );
    await _saveWordLists();
  }

  /// 단어장 삭제
  Future<void> deleteWordList(String name) async {
    final currentLists = state.wordLists;
    final updatedLists = currentLists.where((list) => list.name != name).toList();

    // 선택된 단어장이 삭제되는 경우, 선택 해제
    final selectedName = state.selectedWordListName == name
        ? null
        : state.selectedWordListName;

    state = WordListState.loaded(
      wordLists: updatedLists,
      selectedWordListName: selectedName,
    );
    await _saveWordLists();
  }

  /// 단어장에 단어 추가
  Future<void> addWordToList(String listName, Word word) async {
    final currentLists = state.wordLists;
    final index = currentLists.indexWhere((list) => list.name == listName);

    if (index == -1) return;

    final targetList = currentLists[index];
    final updatedWords = [...targetList.words, word];

    final updatedList = targetList.copyWith(words: updatedWords);
    final updatedLists = [...currentLists];
    updatedLists[index] = updatedList;

    state = WordListState.loaded(
      wordLists: updatedLists,
      selectedWordListName: state.selectedWordListName,
    );
    await _saveWordLists();
  }

  /// 단어장에서 단어 제거
  Future<void> removeWordFromList(String listName, String englishWord) async {
    final currentLists = state.wordLists;
    final index = currentLists.indexWhere((list) => list.name == listName);

    if (index == -1) return;

    final targetList = currentLists[index];
    final updatedWords = targetList.words
        .where((word) => word.english != englishWord)
        .toList();

    final updatedList = targetList.copyWith(words: updatedWords);
    final updatedLists = [...currentLists];
    updatedLists[index] = updatedList;

    state = WordListState.loaded(
      wordLists: updatedLists,
      selectedWordListName: state.selectedWordListName,
    );
    await _saveWordLists();
  }

  /// 단락 추가
  Future<void> addChunkToList(String listName, Chunk chunk) async {
    final currentLists = state.wordLists;
    final index = currentLists.indexWhere((list) => list.name == listName);

    if (index == -1) return;

    final targetList = currentLists[index];
    final updatedChunks = [...targetList.chunks, chunk];
    final updatedChunkCount = targetList.chunkCount + 1;

    // 청크에 포함된 단어들의 isInChunk 상태를 업데이트
    final wordMap = {for (var w in targetList.words) w.english: w};
    for (final word in chunk.includedWords) {
      final existing = wordMap[word.english];
      if (existing != null && !existing.isInChunk) {
        wordMap[word.english] = existing.copyWith(isInChunk: true);
      }
    }

    final updatedList = targetList.copyWith(
      chunks: updatedChunks,
      chunkCount: updatedChunkCount,
      words: wordMap.values.toList(),
    );

    final updatedLists = [...currentLists];
    updatedLists[index] = updatedList;

    state = WordListState.loaded(
      wordLists: updatedLists,
      selectedWordListName: state.selectedWordListName,
    );
    await _saveWordLists();
  }

  /// 단락 업데이트
  Future<void> updateChunk(String listName, Chunk updatedChunk) async {
    final currentLists = state.wordLists;
    final listIndex = currentLists.indexWhere((list) => list.name == listName);

    if (listIndex == -1) return;

    final targetList = currentLists[listIndex];
    final chunkIndex = targetList.chunks.indexWhere((c) => c.id == updatedChunk.id);

    if (chunkIndex == -1) return;

    final updatedChunks = [...targetList.chunks];
    updatedChunks[chunkIndex] = updatedChunk;

    final updatedList = targetList.copyWith(chunks: updatedChunks);
    final updatedLists = [...currentLists];
    updatedLists[listIndex] = updatedList;

    state = WordListState.loaded(
      wordLists: updatedLists,
      selectedWordListName: state.selectedWordListName,
    );
    await _saveWordLists();
  }

  /// 모든 데이터 초기화
  Future<void> resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('word_lists');
      await prefs.remove('selected_word_list');
      
      state = const WordListState.loaded(wordLists: []);
    } catch (e) {
      state = WordListState.error(
        message: '데이터 초기화 중 오류가 발생했습니다: $e',
        wordLists: state.wordLists,
      );
    }
  }
}
// lib/domain/usecases/create_word_list_use_case.dart
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/repositories/word_list_repository_interface.dart';

/// 단어장 생성을 위한 파라미터 클래스
class CreateWordListParams {
  final String name;
  final List<Word>? words;

  CreateWordListParams({
    required this.name,
    this.words,
  });
}

class CreateWordListUseCase {
  final WordListRepositoryInterface wordListRepository;

  CreateWordListUseCase({required this.wordListRepository});

  // Legacy method
  Future<WordListInfo> execute(WordListInfo wordList) async {
    return await wordListRepository.createWordList(wordList);
  }

  // New method using params
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
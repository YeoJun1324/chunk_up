import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:chunk_up/domain/models/freezed/word.dart';
import 'package:chunk_up/domain/models/freezed/chunk.dart';

/*
코드 생성이 완료되었습니다.
추가 수정이 필요한 경우 다음 명령어를 실행하세요:

flutter pub run build_runner build --delete-conflicting-outputs
*/
part 'word_list_state.freezed.dart';
part 'word_list_state.g.dart';

/// 단어장 정보 모델
@freezed
class WordListInfo with _$WordListInfo {
  const WordListInfo._();

  const factory WordListInfo({
    required String name,
    @Default([]) List<Word> words,
    @Default([]) List<Chunk> chunks,
    @Default(0) int chunkCount,
  }) = _WordListInfo;

  factory WordListInfo.fromJson(Map<String, dynamic> json) => _$WordListInfoFromJson(json);

  /// 단어 총 개수
  int get wordCount => words.length;

  /// 맥락화된 단어 개수 (청크에 포함된 단어 수)
  int get contextualizedWordCount => words.where((word) => word.isInChunk).length;

  /// 맥락화 진행률 (0.0 ~ 1.0)
  double get contextProgress => words.isEmpty ? 0.0 : contextualizedWordCount / words.length;

  /// 맥락화 진행률 퍼센트 (0 ~ 100)
  int get contextProgressPercent => (contextProgress * 100).toInt();
}

/// 단어장 관리자 상태
@freezed
class WordListState with _$WordListState {
  const WordListState._();

  /// 초기 로딩 중
  const factory WordListState.loading() = _Loading;

  /// 로딩 에러
  const factory WordListState.error({
    required String message,
    @Default([]) List<WordListInfo> wordLists,
  }) = _Error;

  /// 정상 로드 완료
  const factory WordListState.loaded({
    required List<WordListInfo> wordLists,
    String? selectedWordListName,
  }) = _Loaded;

  /// 상태 메시지 반환
  String get stateMessage {
    return map(
      loading: (_) => '단어장을 로드하는 중입니다...',
      error: (state) => '오류: ${state.message}',
      loaded: (state) => '${state.wordLists.length}개의 단어장이 로드되었습니다',
    );
  }

  /// 단어장 목록 반환 (로딩 중이면 빈 리스트, 에러 상태면 에러 시점 목록)
  List<WordListInfo> get wordLists {
    return map(
      loading: (_) => const [],
      error: (state) => state.wordLists,
      loaded: (state) => state.wordLists,
    );
  }

  /// 선택된 단어장 이름 반환
  String? get selectedWordListName {
    return maybeMap(
      loaded: (state) => state.selectedWordListName,
      orElse: () => null,
    );
  }

  /// 선택된 단어장 반환
  WordListInfo? get selectedWordList {
    final name = selectedWordListName;
    if (name == null) return null;
    
    try {
      return wordLists.firstWhere(
        (list) => list.name == name,
      );
    } catch (_) {
      return null;
    }
  }
}
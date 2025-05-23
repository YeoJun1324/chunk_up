import 'word.dart';
import 'chunk.dart';
import 'package:chunk_up/core/utils/memorized_getter.dart';

/// 메모이제이션을 적용한 향상된 단어장 정보 모델 클래스
///
/// WordListInfo 클래스를 기반으로 성능을 최적화한 버전입니다.
class EnhancedWordListInfo with MemoizedGetter {
  final String name;
  final List<Word> words;
  final List<Chunk>? chunks;
  final int chunkCount;

  EnhancedWordListInfo({
    required this.name,
    List<Word>? words,
    this.chunks,
    this.chunkCount = 0
  }) : words = List.unmodifiable(words ?? []);

  /// 불변성 패턴을 위한 복사 생성 메서드
  /// 
  /// 특정 속성만 변경한 새 EnhancedWordListInfo 객체를 생성합니다.
  EnhancedWordListInfo copyWith({
    String? name,
    List<Word>? words,
    List<Chunk>? chunks,
    int? chunkCount,
  }) {
    // 새 객체를 생성할 때 캐시 무효화를 알리기 위해 clearCache 호출
    clearCache();
    
    return EnhancedWordListInfo(
      name: name ?? this.name,
      words: words ?? List<Word>.from(this.words),
      chunks: chunks ?? (this.chunks != null ? List<Chunk>.from(this.chunks!) : null),
      chunkCount: chunkCount ?? this.chunkCount,
    );
  }

  /// 단어 총 개수 (메모이제이션 적용)
  int get wordCount => memoize('wordCount', () => words.length);

  /// 맥락화된 단어 개수 (메모이제이션 적용)
  int get contextualizedWordCount => memoize('contextualizedWordCount', 
    () => words.where((word) => word.isInChunk).length);

  /// 맥락화 진행률 (0.0 ~ 1.0) (메모이제이션 적용)
  double get contextProgress => memoize('contextProgress', 
    () => words.isEmpty ? 0.0 : contextualizedWordCount / words.length);

  /// 맥락화 진행률 퍼센트 (0 ~ 100) (메모이제이션 적용)
  int get contextProgressPercent => memoize('contextProgressPercent',
    () => (contextProgress * 100).toInt());

  /// 단어장 난이도 계산 (메모이제이션 적용)
  /// 
  /// 단어당 평균 글자 수를 기준으로 난이도를 계산합니다.
  String get difficultyLevel => memoize('difficultyLevel', () {
    if (words.isEmpty) return '정보 없음';
    
    final avgWordLength = words.fold<double>(
      0, (sum, word) => sum + word.english.length) / words.length;
    
    if (avgWordLength < 4) return '쉬움';
    if (avgWordLength < 7) return '보통';
    if (avgWordLength < 10) return '어려움';
    return '매우 어려움';
  });

  /// 최근에 추가된 단어들 (메모이제이션 적용)
  List<Word> get recentlyAddedWords => memoize('recentlyAddedWords', () {
    // 단어들이 최근에 추가된 순서대로 정렬되어 있다고 가정
    final recentWords = words.take(5).toList();
    return List.unmodifiable(recentWords);
  });

  // 직렬화를 위한 메서드
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'words': words.map((w) => w.toJson()).toList(),
      'chunks': chunks?.map((c) => c.toJson()).toList() ?? [],
      'chunkCount': chunkCount,
    };
  }

  // 역직렬화를 위한 팩토리 메서드
  factory EnhancedWordListInfo.fromJson(Map<String, dynamic> json) {
    final List<dynamic> wordsJson = json['words'] ?? [];
    final List<dynamic> chunksJson = json['chunks'] ?? [];

    return EnhancedWordListInfo(
      name: json['name'],
      words: wordsJson.map((w) => Word.fromJson(w)).toList(),
      chunks: chunksJson.isNotEmpty ?
        List<Chunk>.from(chunksJson.map((c) => Chunk.fromJson(c)).toList()) :
        [],
      chunkCount: json['chunkCount'] ?? 0,
    );
  }
}
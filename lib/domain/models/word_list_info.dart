import 'word.dart';
import 'chunk.dart';

/// 단어장 정보 모델 클래스
///
/// 단어장과 관련된 단어, 청크 등의 정보를 관리합니다.
class WordListInfo {
  final String name;
  final List<Word> words;
  final List<Chunk>? chunks;
  final int chunkCount;

  WordListInfo({
    required this.name,
    List<Word>? words,
    this.chunks,
    this.chunkCount = 0
  }) : words = words ?? [];

  /// 불변성 패턴을 위한 복사 생성 메서드
  /// 
  /// 특정 속성만 변경한 새 WordListInfo 객체를 생성합니다.
  WordListInfo copyWith({
    String? name,
    List<Word>? words,
    List<Chunk>? chunks,
    int? chunkCount,
  }) {
    return WordListInfo(
      name: name ?? this.name,
      words: words ?? List<Word>.from(this.words),
      chunks: chunks ?? (this.chunks != null ? List<Chunk>.from(this.chunks!) : null),
      chunkCount: chunkCount ?? this.chunkCount,
    );
  }

  /// 단어 총 개수
  int get wordCount => words.length;

  /// 맥락화된 단어 개수 (청크에 포함된 단어 수)
  int get contextualizedWordCount => words.where((word) => word.isInChunk).length;

  /// 맥락화 진행률 (0.0 ~ 1.0)
  double get contextProgress => words.isEmpty ? 0.0 : contextualizedWordCount / words.length;

  /// 맥락화 진행률 퍼센트 (0 ~ 100)
  int get contextProgressPercent => (contextProgress * 100).toInt();

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
  factory WordListInfo.fromJson(Map<String, dynamic> json) {
    final List<dynamic> wordsJson = json['words'] ?? [];
    final List<dynamic> chunksJson = json['chunks'] ?? [];

    return WordListInfo(
      name: json['name'],
      words: wordsJson.map((w) => Word.fromJson(w)).toList(),
      chunks: chunksJson.isNotEmpty ?
        List<Chunk>.from(chunksJson.map((c) => Chunk.fromJson(c)).toList()) :
        [],
      chunkCount: json['chunkCount'] ?? 0,
    );
  }
}
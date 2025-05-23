// lib/domain/models/learning_session.dart
import 'package:chunk_up/domain/models/chunk.dart';

/// 학습 세션 상태를 관리하는 불변 클래스
/// 학습 화면의 상태를 불변성 패턴으로 관리합니다.
class LearningSession {
  /// 학습 중인 모든 청크 목록 (불변)
  final List<Chunk> chunks;
  
  /// 현재 청크 인덱스
  final int currentChunkIndex;
  
  /// 현재 문장 인덱스
  final int currentSentenceIndex;
  
  /// 현재 청크의 영어 문장 목록 (불변)
  final List<String> currentSentences;
  
  /// 현재 청크의 한국어 번역 문장 목록 (불변)
  final List<String> translatedSentences;
  
  /// 문장 모드 여부 (true: 문장 모드, false: 전체 텍스트 모드)
  final bool isSentenceMode;
  
  /// 학습 시작 시간
  final DateTime startTime;
  
  /// 학습 이력 데이터 (불변)
  final List<Map<String, dynamic>> learningHistory;

  /// 생성자
  LearningSession({
    required this.chunks,
    this.currentChunkIndex = 0,
    this.currentSentenceIndex = 0,
    List<String>? currentSentences,
    List<String>? translatedSentences,
    this.isSentenceMode = true,
    DateTime? startTime,
    List<Map<String, dynamic>>? learningHistory,
  }) : 
    currentSentences = List.unmodifiable(currentSentences ?? []),
    translatedSentences = List.unmodifiable(translatedSentences ?? []),
    startTime = startTime ?? DateTime.now(),
    learningHistory = List.unmodifiable(learningHistory ?? []);

  /// 불변성 패턴을 위한 복사 생성 메서드
  LearningSession copyWith({
    List<Chunk>? chunks,
    int? currentChunkIndex,
    int? currentSentenceIndex,
    List<String>? currentSentences,
    List<String>? translatedSentences,
    bool? isSentenceMode,
    DateTime? startTime,
    List<Map<String, dynamic>>? learningHistory,
  }) {
    return LearningSession(
      chunks: chunks ?? this.chunks,
      currentChunkIndex: currentChunkIndex ?? this.currentChunkIndex,
      currentSentenceIndex: currentSentenceIndex ?? this.currentSentenceIndex,
      currentSentences: currentSentences ?? this.currentSentences,
      translatedSentences: translatedSentences ?? this.translatedSentences,
      isSentenceMode: isSentenceMode ?? this.isSentenceMode,
      startTime: startTime ?? this.startTime,
      learningHistory: learningHistory ?? this.learningHistory,
    );
  }

  /// 다음 문장으로 이동한 새 세션 반환
  LearningSession moveToNextSentence() {
    if (currentSentenceIndex >= currentSentences.length - 1) {
      return moveToNextChunk();
    }
    
    return copyWith(
      currentSentenceIndex: currentSentenceIndex + 1,
    );
  }

  /// 이전 문장으로 이동한 새 세션 반환
  LearningSession moveToPreviousSentence() {
    if (currentSentenceIndex <= 0) {
      return moveToPreviousChunk();
    }
    
    return copyWith(
      currentSentenceIndex: currentSentenceIndex - 1,
    );
  }

  /// 다음 청크로 이동한 새 세션 반환
  LearningSession moveToNextChunk() {
    if (currentChunkIndex >= chunks.length - 1) {
      // 마지막 청크인 경우 현재 상태 유지
      return this;
    }
    
    return copyWith(
      currentChunkIndex: currentChunkIndex + 1,
      currentSentenceIndex: 0,
      // 새 청크에 대한 문장 분리는 호출자가 처리해야 함
    );
  }

  /// 이전 청크로 이동한 새 세션 반환
  LearningSession moveToPreviousChunk() {
    if (currentChunkIndex <= 0) {
      // 첫 번째 청크인 경우 현재 상태 유지
      return this;
    }
    
    return copyWith(
      currentChunkIndex: currentChunkIndex - 1,
      currentSentenceIndex: 0,
      // 새 청크에 대한 문장 분리는 호출자가 처리해야 함
    );
  }

  /// 모드 토글한 새 세션 반환
  LearningSession toggleMode() {
    return copyWith(
      isSentenceMode: !isSentenceMode,
    );
  }

  /// 새 문장 목록으로 업데이트한 세션 반환
  LearningSession updateSentences({
    required List<String> sentences,
    required List<String> translations,
  }) {
    return copyWith(
      currentSentences: sentences,
      translatedSentences: translations,
    );
  }

  /// 학습 이력 추가한 새 세션 반환
  LearningSession addHistoryEntry(Map<String, dynamic> entry) {
    final newHistory = List<Map<String, dynamic>>.from(learningHistory)..add(entry);
    return copyWith(
      learningHistory: newHistory,
    );
  }

  /// 현재 청크 반환 (없으면 null)
  Chunk? get currentChunk => 
    currentChunkIndex < chunks.length ? chunks[currentChunkIndex] : null;

  /// 현재 문장 반환 (없으면 null)
  String? get currentSentence => 
    currentSentenceIndex < currentSentences.length ? currentSentences[currentSentenceIndex] : null;

  /// 현재 번역 문장 반환 (없으면 null)
  String? get currentTranslation => 
    currentSentenceIndex < translatedSentences.length ? translatedSentences[currentSentenceIndex] : null;

  /// 학습 중인 단어 목록 (모든 청크에서 고유한 단어 추출)
  List<String> get allLearningWords {
    final Set<String> uniqueWords = {};
    for (var chunk in chunks) {
      for (var word in chunk.includedWords) {
        uniqueWords.add(word.english);
      }
    }
    return uniqueWords.toList();
  }

  /// 학습 진행률 계산 (0.0 ~ 1.0)
  double calculateProgress() {
    if (chunks.isEmpty) return 0.0;

    // 모든 청크의 총 문장 수 계산
    int totalSentences = 0;
    for (var i = 0; i < chunks.length; i++) {
      // 문장 수를 추정하기 위한 메서드가 필요 - 실제 구현에서는 이 부분 수정 필요
      final sentenceCount = i == currentChunkIndex 
          ? currentSentences.length 
          : _estimateSentenceCount(chunks[i].englishContent);
      totalSentences += sentenceCount;
    }

    // 이전 청크들의 모든 문장 수
    int completedSentences = 0;
    for (var i = 0; i < currentChunkIndex; i++) {
      final sentenceCount = _estimateSentenceCount(chunks[i].englishContent);
      completedSentences += sentenceCount;
    }

    // 현재 청크의 완료된 문장 수 추가
    completedSentences += currentSentenceIndex;

    // 진행률 계산
    return totalSentences > 0 ? completedSentences / totalSentences : 0.0;
  }

  /// 문장 수 추정 메서드 (문장 분리 로직을 대체하는 간단한 추정)
  int _estimateSentenceCount(String text) {
    final matches = RegExp(r'[.!?]+\s+').allMatches(text);
    return matches.length + 1; // 마지막 문장을 위해 +1
  }
}
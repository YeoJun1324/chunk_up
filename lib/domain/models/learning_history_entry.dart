// lib/domain/models/learning_history_entry.dart
import 'dart:convert';

/// 학습 이력 항목을 관리하는 불변 클래스
/// 학습 이력 데이터를 불변성 패턴으로 관리합니다.
class LearningHistoryEntry {
  /// 학습 일시
  final DateTime date;
  
  /// 학습한 청크 제목 목록 (불변)
  final List<String> chunkTitles;
  
  /// 학습한 단어 수
  final int wordCount;
  
  /// 학습 시간 (분)
  final int durationMinutes;
  
  /// 학습한 문장 수
  final int sentenceCount;

  /// 생성자
  LearningHistoryEntry({
    required this.date,
    required this.chunkTitles,
    required this.wordCount,
    required this.durationMinutes,
    required this.sentenceCount,
  });

  /// 불변성 패턴을 위한 복사 생성 메서드
  LearningHistoryEntry copyWith({
    DateTime? date,
    List<String>? chunkTitles,
    int? wordCount,
    int? durationMinutes,
    int? sentenceCount,
  }) {
    return LearningHistoryEntry(
      date: date ?? this.date,
      chunkTitles: chunkTitles ?? List<String>.from(this.chunkTitles),
      wordCount: wordCount ?? this.wordCount,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sentenceCount: sentenceCount ?? this.sentenceCount,
    );
  }

  /// JSON에서 객체 생성
  factory LearningHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LearningHistoryEntry(
      date: DateTime.parse(json['date'] as String),
      chunkTitles: List<String>.from(json['chunks'] as List),
      wordCount: json['wordCount'] as int,
      durationMinutes: json['durationMinutes'] as int,
      sentenceCount: json['sentences'] as int,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'chunks': chunkTitles,
      'wordCount': wordCount,
      'durationMinutes': durationMinutes,
      'sentences': sentenceCount,
    };
  }

  /// SharedPreferences용 String으로 변환
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// SharedPreferences용 String에서 객체 생성
  factory LearningHistoryEntry.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
    return LearningHistoryEntry.fromJson(json);
  }

  /// 오늘 학습인지 확인
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// 이번 주 학습인지 확인
  bool get isThisWeek {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    return difference <= 7;
  }

  /// 학습 효율 계산 (단어당 분) - 값이 낮을수록 효율적
  double get efficiency {
    if (wordCount == 0 || durationMinutes == 0) return 0;
    return durationMinutes / wordCount;
  }
}
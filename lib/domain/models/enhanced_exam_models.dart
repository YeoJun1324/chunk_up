// lib/domain/models/enhanced_exam_models.dart
import 'dart:math';
import 'word.dart';
import 'chunk.dart';
import 'exam_models.dart'; // Import to use QuestionType from exam_models.dart

/// 난이도 레벨
enum DifficultyLevel {
  basic,
  easy,
  medium,
  hard,
  advanced,
  expert,
}

/// 답안 채점 기준
class GradingCriteria {
  final int fullPoints;           // 만점
  final int partialPoints;        // 부분 점수
  final List<String> keywords;    // 필수 키워드
  final bool allowSynonyms;       // 동의어 허용
  final String rubric;            // 채점 기준 설명

  const GradingCriteria({
    required this.fullPoints,
    this.partialPoints = 0,
    this.keywords = const [],
    this.allowSynonyms = false,
    required this.rubric,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullPoints': fullPoints,
      'partialPoints': partialPoints,
      'keywords': keywords,
      'allowSynonyms': allowSynonyms,
      'rubric': rubric,
    };
  }

  factory GradingCriteria.fromJson(Map<String, dynamic> json) {
    return GradingCriteria(
      fullPoints: json['fullPoints'],
      partialPoints: json['partialPoints'] ?? 0,
      keywords: List<String>.from(json['keywords'] ?? []),
      allowSynonyms: json['allowSynonyms'] ?? false,
      rubric: json['rubric'],
    );
  }
}

/// 상세 해설
class DetailedExplanation {
  final String stepByStepSolution;  // 단계별 풀이
  final String grammarPoint;        // 문법 포인트
  final String vocabularyNote;      // 어휘 설명
  final String learningTip;         // 학습 팁
  final List<String> commonMistakes; // 흔한 실수들
  final List<String> relatedWords;   // 관련 단어들

  const DetailedExplanation({
    required this.stepByStepSolution,
    this.grammarPoint = '',
    this.vocabularyNote = '',
    this.learningTip = '',
    this.commonMistakes = const [],
    this.relatedWords = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'stepByStepSolution': stepByStepSolution,
      'grammarPoint': grammarPoint,
      'vocabularyNote': vocabularyNote,
      'learningTip': learningTip,
      'commonMistakes': commonMistakes,
      'relatedWords': relatedWords,
    };
  }

  factory DetailedExplanation.fromJson(Map<String, dynamic> json) {
    return DetailedExplanation(
      stepByStepSolution: json['stepByStepSolution'],
      grammarPoint: json['grammarPoint'] ?? '',
      vocabularyNote: json['vocabularyNote'] ?? '',
      learningTip: json['learningTip'] ?? '',
      commonMistakes: List<String>.from(json['commonMistakes'] ?? []),
      relatedWords: List<String>.from(json['relatedWords'] ?? []),
    );
  }
}

/// 강화된 시험 문제
class EnhancedExamQuestion {
  final String id;
  final QuestionType type;
  final String question;
  final dynamic answer;              // 정답
  final List<String>? options;       // 객관식 보기
  final String? hint;                // 힌트
  final GradingCriteria gradingCriteria; // 채점 기준
  final DetailedExplanation explanation; // 상세 해설
  final String? sourceChunkId;       // 출처 청크 ID
  final List<String> tags;           // 태그 (문법, 어휘 등)
  final String difficulty;           // 난이도
  final Duration estimatedTime;      // 예상 소요 시간

  const EnhancedExamQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.answer,
    this.options,
    this.hint,
    required this.gradingCriteria,
    required this.explanation,
    this.sourceChunkId,
    this.tags = const [],
    this.difficulty = 'medium',
    this.estimatedTime = const Duration(minutes: 2),
  });

  EnhancedExamQuestion copyWith({
    String? id,
    QuestionType? type,
    String? question,
    dynamic answer,
    List<String>? options,
    String? hint,
    GradingCriteria? gradingCriteria,
    DetailedExplanation? explanation,
    String? sourceChunkId,
    List<String>? tags,
    String? difficulty,
    Duration? estimatedTime,
  }) {
    return EnhancedExamQuestion(
      id: id ?? this.id,
      type: type ?? this.type,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      options: options ?? this.options,
      hint: hint ?? this.hint,
      gradingCriteria: gradingCriteria ?? this.gradingCriteria,
      explanation: explanation ?? this.explanation,
      sourceChunkId: sourceChunkId ?? this.sourceChunkId,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      estimatedTime: estimatedTime ?? this.estimatedTime,
    );
  }

  /// 문제 점수
  int get points => gradingCriteria.fullPoints;
  
  /// 호환성을 위한 targetWord getter
  String? get targetWord => tags.isNotEmpty ? tags.first : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'question': question,
      'answer': answer,
      'options': options,
      'hint': hint,
      'gradingCriteria': gradingCriteria.toJson(),
      'explanation': explanation.toJson(),
      'sourceChunkId': sourceChunkId,
      'tags': tags,
      'difficulty': difficulty,
      'estimatedTime': estimatedTime.inMinutes,
    };
  }

  factory EnhancedExamQuestion.fromJson(Map<String, dynamic> json) {
    return EnhancedExamQuestion(
      id: json['id'],
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      question: json['question'],
      answer: json['answer'],
      options: json['options']?.cast<String>(),
      hint: json['hint'],
      gradingCriteria: GradingCriteria.fromJson(json['gradingCriteria']),
      explanation: DetailedExplanation.fromJson(json['explanation']),
      sourceChunkId: json['sourceChunkId'],
      tags: List<String>.from(json['tags'] ?? []),
      difficulty: json['difficulty'] ?? 'medium',
      estimatedTime: Duration(minutes: json['estimatedTime'] ?? 2),
    );
  }
}

/// 시험지 통계
class ExamStatistics {
  final Map<QuestionType, int> typeDistribution;    // 문제 유형별 분포
  final Map<String, int> difficultyDistribution;   // 난이도별 분포
  final Duration totalEstimatedTime;               // 총 예상 소요 시간
  final Map<String, int> tagDistribution;         // 태그별 분포
  final int averagePoints;                         // 평균 배점

  const ExamStatistics({
    required this.typeDistribution,
    required this.difficultyDistribution,
    required this.totalEstimatedTime,
    required this.tagDistribution,
    required this.averagePoints,
  });

  static ExamStatistics calculate(List<EnhancedExamQuestion> questions) {
    final typeDistribution = <QuestionType, int>{};
    final difficultyDistribution = <String, int>{};
    final tagDistribution = <String, int>{};
    var totalMinutes = 0;
    var totalPoints = 0;

    for (var question in questions) {
      // 유형별 분포
      typeDistribution[question.type] = 
          (typeDistribution[question.type] ?? 0) + 1;

      // 난이도별 분포
      difficultyDistribution[question.difficulty] = 
          (difficultyDistribution[question.difficulty] ?? 0) + 1;

      // 태그별 분포
      for (var tag in question.tags) {
        tagDistribution[tag] = (tagDistribution[tag] ?? 0) + 1;
      }

      totalMinutes += question.estimatedTime.inMinutes;
      totalPoints += question.points;
    }

    return ExamStatistics(
      typeDistribution: typeDistribution,
      difficultyDistribution: difficultyDistribution,
      totalEstimatedTime: Duration(minutes: totalMinutes),
      tagDistribution: tagDistribution,
      averagePoints: questions.isNotEmpty ? totalPoints ~/ questions.length : 0,
    );
  }
}

/// 강화된 시험지
class EnhancedExamPaper {
  final String id;
  final String title;
  final List<EnhancedExamQuestion> questions;
  final ExamStatistics statistics;
  final DateTime createdAt;
  final ExamConfig config;
  final String instructions;              // 시험 안내사항
  final Map<String, dynamic> metadata;   // 추가 메타데이터

  const EnhancedExamPaper({
    required this.id,
    required this.title,
    required this.questions,
    required this.statistics,
    required this.createdAt,
    required this.config,
    this.instructions = '',
    this.metadata = const {},
  });

  /// 총 점수
  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);

  /// 총 문제 수
  int get totalQuestions => questions.length;

  /// 예상 소요 시간
  Duration get estimatedTime => statistics.totalEstimatedTime;
  
  /// 호환성을 위한 difficultyLevel getter
  String get difficultyLevel => 'medium';

  EnhancedExamPaper copyWith({
    String? id,
    String? title,
    List<EnhancedExamQuestion>? questions,
    ExamStatistics? statistics,
    DateTime? createdAt,
    ExamConfig? config,
    String? instructions,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedExamPaper(
      id: id ?? this.id,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      statistics: statistics ?? this.statistics,
      createdAt: createdAt ?? this.createdAt,
      config: config ?? this.config,
      instructions: instructions ?? this.instructions,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'questions': questions.map((q) => q.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'config': config.toJson(),
      'instructions': instructions,
      'metadata': metadata,
    };
  }
}

/// 문제 유형별 상세 정보
class EnhancedQuestionTypeInfo {
  final QuestionType type;
  final String name;
  final String description;
  final String instructions;         // 문제 해결 방법
  final int minPoints;              // 최소 배점
  final int maxPoints;              // 최대 배점
  final int defaultPoints;          // 기본 배점
  final Duration estimatedTime;     // 예상 소요 시간
  final List<String> requiredSkills; // 필요한 스킬
  final bool isPhase1;              // Phase 1 여부
  final String icon;                // 아이콘 이름

  const EnhancedQuestionTypeInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.instructions,
    required this.minPoints,
    required this.maxPoints,
    required this.defaultPoints,
    required this.estimatedTime,
    required this.requiredSkills,
    required this.isPhase1,
    required this.icon,
  });

  static const Map<QuestionType, EnhancedQuestionTypeInfo> typeInfoMap = {
    QuestionType.fillInBlanks: EnhancedQuestionTypeInfo(
      type: QuestionType.fillInBlanks,
      name: '단어 철자 쓰기',
      description: '문장 속 빈칸에 들어갈 단어를 쓰는 문제',
      instructions: '문맥을 파악하여 알맞은 단어를 빈칸에 채우세요.',
      minPoints: 1,
      maxPoints: 4,
      defaultPoints: 2,
      estimatedTime: Duration(minutes: 1),
      requiredSkills: ['어휘력', '문맥 이해', '철자'],
      isPhase1: true,
      icon: 'edit_note',
    ),
    QuestionType.contextMeaning: EnhancedQuestionTypeInfo(
      type: QuestionType.contextMeaning,
      name: '단어 용법 설명',
      description: '굵게 표시된 단어의 문맥상 의미를 설명하는 문제',
      instructions: '문맥을 고려하여 단어가 어떤 의미로 사용되었는지 설명하세요.',
      minPoints: 2,
      maxPoints: 5,
      defaultPoints: 3,
      estimatedTime: Duration(minutes: 2),
      requiredSkills: ['어휘력', '문맥 이해', '설명 능력'],
      isPhase1: true,
      icon: 'lightbulb_outline',
    ),
    QuestionType.korToEngTranslation: EnhancedQuestionTypeInfo(
      type: QuestionType.korToEngTranslation,
      name: '문장 번역 (한→영)',
      description: '한국어 문장을 영어로 번역하는 문제',
      instructions: '주어진 한국어 문장을 정확한 영어로 번역하세요.',
      minPoints: 3,
      maxPoints: 8,
      defaultPoints: 5,
      estimatedTime: Duration(minutes: 3),
      requiredSkills: ['영작문', '문법', '어휘력'],
      isPhase1: true,
      icon: 'translate',
    ),
  };

  static EnhancedQuestionTypeInfo? getInfo(QuestionType type) {
    return typeInfoMap[type];
  }

  static List<QuestionType> getAllTypes() {
    return typeInfoMap.keys.toList();
  }
}
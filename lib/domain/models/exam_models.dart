// lib/domain/models/exam_models.dart
import 'word.dart';
import 'chunk.dart';
import 'enhanced_exam_models.dart';

/// 시험지 문제 유형
enum QuestionType {
  fillInBlanks,           // 빈칸 채우기 (단어 철자 쓰기)
  contextMeaning,         // 문맥상 단어 의미 서술  
  korToEngTranslation,    // 한영 번역 (한국어 → 영어)
}

/// 개별 시험 문제
class ExamQuestion {
  final String id;
  final QuestionType type;
  final String question;
  final String answer;
  final String? targetWord; // 대상 단어 (빈칸 채우기, 문맥 의미용)
  final String? sourceChunkId; // 출처 청크 ID
  final List<String>? options; // 객관식 보기

  const ExamQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.answer,
    this.targetWord,
    this.sourceChunkId,
    this.options,
  });

  ExamQuestion copyWith({
    String? id,
    QuestionType? type,
    String? question,
    String? answer,
    String? targetWord,
    String? sourceChunkId,
    List<String>? options,
  }) {
    return ExamQuestion(
      id: id ?? this.id,
      type: type ?? this.type,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      targetWord: targetWord ?? this.targetWord,
      sourceChunkId: sourceChunkId ?? this.sourceChunkId,
      options: options ?? this.options,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'question': question,
      'answer': answer,
      'targetWord': targetWord,
      'sourceChunkId': sourceChunkId,
      'options': options,
    };
  }

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id'],
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      question: json['question'],
      answer: json['answer'],
      targetWord: json['targetWord'],
      sourceChunkId: json['sourceChunkId'],
      options: json['options'] != null ? List<String>.from(json['options']) : null,
    );
  }
}

/// 시험지 설정
class ExamConfig {
  final Map<QuestionType, int> questionCounts;
  final bool includeAnswerKey;
  final bool shuffleQuestions;
  final String title;
  final List<String> selectedWordListNames;
  final bool includeDetailedExplanations;
  final bool includeGradingRubric;

  const ExamConfig({
    required this.questionCounts,
    this.includeAnswerKey = true,
    this.shuffleQuestions = false,
    this.title = 'ChunkUp 시험지',
    this.selectedWordListNames = const [],
    this.includeDetailedExplanations = false,
    this.includeGradingRubric = false,
  });

  ExamConfig copyWith({
    Map<QuestionType, int>? questionCounts,
    bool? includeAnswerKey,
    bool? shuffleQuestions,
    String? title,
    List<String>? selectedWordListNames,
    bool? includeDetailedExplanations,
    bool? includeGradingRubric,
  }) {
    return ExamConfig(
      questionCounts: questionCounts ?? this.questionCounts,
      includeAnswerKey: includeAnswerKey ?? this.includeAnswerKey,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      title: title ?? this.title,
      selectedWordListNames: selectedWordListNames ?? this.selectedWordListNames,
      includeDetailedExplanations: includeDetailedExplanations ?? this.includeDetailedExplanations,
      includeGradingRubric: includeGradingRubric ?? this.includeGradingRubric,
    );
  }

  int get totalQuestions => questionCounts.values.fold(0, (sum, count) => sum + count);
  
  // 호환성을 위한 getter들
  int get questionCount => totalQuestions;
  bool get includeHints => includeDetailedExplanations;
  List<QuestionType> get enabledQuestionTypes => questionCounts.keys.toList();
  bool get isPremiumFeature => includeDetailedExplanations || includeGradingRubric;
  bool get requiresPremium => isPremiumFeature;

  Map<String, dynamic> toJson() {
    return {
      'questionCounts': questionCounts.map((k, v) => MapEntry(k.toString(), v)),
      'includeAnswerKey': includeAnswerKey,
      'shuffleQuestions': shuffleQuestions,
      'title': title,
      'selectedWordListNames': selectedWordListNames,
      'includeDetailedExplanations': includeDetailedExplanations,
      'includeGradingRubric': includeGradingRubric,
    };
  }
}

/// 완성된 시험지
class ExamPaper {
  final String id;
  final String title;
  final List<ExamQuestion> questions;
  final Map<QuestionType, int> questionCounts;
  final DateTime createdAt;
  final ExamConfig config;
  final String? difficultyLevel;
  final int? totalQuestions;

  const ExamPaper({
    required this.id,
    required this.title,
    required this.questions,
    required this.questionCounts,
    required this.createdAt,
    required this.config,
    this.difficultyLevel,
    this.totalQuestions,
  });

  // fromEnhanced 팩토리 메서드 추가
  factory ExamPaper.fromEnhanced(dynamic enhancedPaper) {
    if (enhancedPaper is EnhancedExamPaper) {
      return ExamPaper(
        id: enhancedPaper.id,
        title: enhancedPaper.title,
        questions: enhancedPaper.questions.map((q) => ExamQuestion(
          id: q.id,
          type: q.type,
          question: q.question,
          answer: q.answer,
          targetWord: q.targetWord,
          sourceChunkId: q.sourceChunkId,
          options: q.options,
        )).toList(),
        questionCounts: {},
        createdAt: enhancedPaper.createdAt,
        config: ExamConfig(questionCounts: {}),
        difficultyLevel: enhancedPaper.difficultyLevel,
        totalQuestions: enhancedPaper.totalQuestions,
      );
    }
    return enhancedPaper as ExamPaper;
  }

  ExamPaper copyWith({
    String? id,
    String? title,
    List<ExamQuestion>? questions,
    Map<QuestionType, int>? questionCounts,
    DateTime? createdAt,
    ExamConfig? config,
    String? difficultyLevel,
    int? totalQuestions,
  }) {
    return ExamPaper(
      id: id ?? this.id,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      questionCounts: questionCounts ?? this.questionCounts,
      createdAt: createdAt ?? this.createdAt,
      config: config ?? this.config,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      totalQuestions: totalQuestions ?? this.totalQuestions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'questions': questions.map((q) => q.toJson()).toList(),
      'questionCounts': questionCounts.map((k, v) => MapEntry(k.toString(), v)),
      'createdAt': createdAt.toIso8601String(),
      'config': config.toJson(),
    };
  }

  factory ExamPaper.fromJson(Map<String, dynamic> json) {
    return ExamPaper(
      id: json['id'],
      title: json['title'],
      questions: (json['questions'] as List)
          .map((q) => ExamQuestion.fromJson(q))
          .toList(),
      questionCounts: (json['questionCounts'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          QuestionType.values.firstWhere((e) => e.toString() == k),
          v as int,
        ),
      ),
      createdAt: DateTime.parse(json['createdAt']),
      config: ExamConfig(
        questionCounts: {},
        title: json['title'],
      ), // 간단히 처리
    );
  }
}

/// 문제 유형별 정보
class QuestionTypeInfo {
  final QuestionType type;
  final String name;
  final String description;
  final bool isPhase1;

  const QuestionTypeInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.isPhase1,
  });

  static const Map<QuestionType, QuestionTypeInfo> typeInfoMap = {
    QuestionType.fillInBlanks: QuestionTypeInfo(
      type: QuestionType.fillInBlanks,
      name: '단어 철자 쓰기',
      description: '문장 속 빈칸에 들어갈 단어를 쓰는 문제',
      isPhase1: true,
    ),
    QuestionType.contextMeaning: QuestionTypeInfo(
      type: QuestionType.contextMeaning,
      name: '단어 용법 설명',
      description: '굵게 표시된 단어의 문맥상 의미를 설명하는 문제',
      isPhase1: true,
    ),
    QuestionType.korToEngTranslation: QuestionTypeInfo(
      type: QuestionType.korToEngTranslation,
      name: '문장 번역 (한→영)',
      description: '한국어 문장을 영어로 번역하는 문제',
      isPhase1: true,
    ),
  };

  static QuestionTypeInfo? getInfo(QuestionType type) {
    return typeInfoMap[type];
  }

  static List<QuestionType> getAllTypes() {
    return typeInfoMap.keys.toList();
  }
}
// exam_pdf_implementation_example.dart
// 시험지 PDF 생성을 위한 구현 예시

import 'dart:typed_data';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/word.dart';

// 문제 유형 enum
enum QuestionType {
  fillInBlanks,           // 빈칸 채우기
  engToKorTranslation,    // 영한 번역
  multipleChoice,         // 객관식 (단어 의미)
  korToEngTranslation,    // 한영 번역
  synonymAntonym,         // 동의어/반의어
  sentenceArrangement,    // 문장 재배열
  errorCorrection,        // 오류 수정
  wordFormation,          // 단어 형태 변환
  contextInference,       // 문맥 추론
}

// 문제 모델
class ExamQuestion {
  final String id;
  final QuestionType type;
  final String question;
  final dynamic answer; // String or List<String>
  final List<String>? options; // 객관식 보기
  final String? hint;
  final int points;
  final String? explanation; // 해설

  const ExamQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.answer,
    this.options,
    this.hint,
    required this.points,
    this.explanation,
  });
}

// 시험지 설정
class ExamConfig {
  final Map<QuestionType, int> questionCounts;
  final String difficulty; // 'easy', 'medium', 'hard'
  final bool includeAnswerKey;
  final bool shuffleQuestions;
  final Duration? timeLimit;
  final String title;

  const ExamConfig({
    required this.questionCounts,
    this.difficulty = 'medium',
    this.includeAnswerKey = true,
    this.shuffleQuestions = false,
    this.timeLimit,
    this.title = 'ChunkUp 시험지',
  });
}

// 시험지 모델
class ExamPaper {
  final String title;
  final List<ExamQuestion> questions;
  final Map<QuestionType, int> questionCounts;
  final int totalPoints;
  final Duration? timeLimit;
  final DateTime createdAt;

  const ExamPaper({
    required this.title,
    required this.questions,
    required this.questionCounts,
    required this.totalPoints,
    this.timeLimit,
    required this.createdAt,
  });
}

// 문제 생성기
class ExamQuestionGenerator {
  final Random _random = Random();

  // 빈칸 채우기 문제 생성
  List<ExamQuestion> generateFillInBlanks(
    List<Chunk> chunks,
    List<Word> targetWords,
    int count,
    String difficulty,
  ) {
    final questions = <ExamQuestion>[];
    final usedChunks = <String>{};

    for (int i = 0; i < count && chunks.isNotEmpty; i++) {
      final chunk = chunks[_random.nextInt(chunks.length)];
      if (usedChunks.contains(chunk.id)) continue;
      usedChunks.add(chunk.id);

      // 청크에서 사용 가능한 단어 찾기
      final availableWords = targetWords
          .where((word) => chunk.englishContent.toLowerCase()
              .contains(word.english.toLowerCase()))
          .toList();

      if (availableWords.isEmpty) continue;

      final selectedWord = availableWords[_random.nextInt(availableWords.length)];
      final questionText = _createFillInBlankQuestion(
        chunk.englishContent,
        selectedWord.english,
        difficulty,
      );

      questions.add(ExamQuestion(
        id: 'fill_${i + 1}',
        type: QuestionType.fillInBlanks,
        question: questionText,
        answer: selectedWord.english,
        points: 2,
        hint: difficulty == 'easy' ? selectedWord.english[0] : null,
        explanation: '${selectedWord.english} = ${selectedWord.korean}',
      ));
    }

    return questions;
  }

  // 객관식 문제 생성
  List<ExamQuestion> generateMultipleChoice(
    List<Chunk> chunks,
    List<Word> targetWords,
    int count,
  ) {
    final questions = <ExamQuestion>[];
    final usedWords = <String>{};

    for (int i = 0; i < count && targetWords.isNotEmpty; i++) {
      final word = targetWords[_random.nextInt(targetWords.length)];
      if (usedWords.contains(word.english)) continue;
      usedWords.add(word.english);

      // 관련 청크 찾기
      final relatedChunk = chunks.firstWhere(
        (chunk) => chunk.englishContent.toLowerCase()
            .contains(word.english.toLowerCase()),
        orElse: () => chunks[_random.nextInt(chunks.length)],
      );

      final options = _generateMultipleChoiceOptions(word, targetWords);
      final questionText = '다음 문장에서 "${word.english}"의 의미는?\n\n'
          '"${_extractSentenceWithWord(relatedChunk.englishContent, word.english)}"';

      questions.add(ExamQuestion(
        id: 'mc_${i + 1}',
        type: QuestionType.multipleChoice,
        question: questionText,
        answer: word.korean,
        options: options,
        points: 3,
        explanation: '${word.english}는 "${word.korean}"라는 뜻입니다.',
      ));
    }

    return questions;
  }

  // 영한 번역 문제 생성
  List<ExamQuestion> generateEngToKorTranslation(
    List<Chunk> chunks,
    int count,
  ) {
    final questions = <ExamQuestion>[];
    final usedChunks = <String>{};

    for (int i = 0; i < count && chunks.isNotEmpty; i++) {
      final chunk = chunks[_random.nextInt(chunks.length)];
      if (usedChunks.contains(chunk.id)) continue;
      usedChunks.add(chunk.id);

      final sentence = _extractRandomSentence(chunk.englishContent);
      final questionText = '다음 문장을 한국어로 번역하시오.\n\n"$sentence"';

      questions.add(ExamQuestion(
        id: 'e2k_${i + 1}',
        type: QuestionType.engToKorTranslation,
        question: questionText,
        answer: _getKoreanTranslation(sentence, chunk),
        points: 5,
        explanation: '번역 참고: ${chunk.koreanTranslation}',
      ));
    }

    return questions;
  }

  // 한영 번역 문제 생성
  List<ExamQuestion> generateKorToEngTranslation(
    List<Chunk> chunks,
    int count,
  ) {
    final questions = <ExamQuestion>[];
    final usedChunks = <String>{};

    for (int i = 0; i < count && chunks.isNotEmpty; i++) {
      final chunk = chunks[_random.nextInt(chunks.length)];
      if (usedChunks.contains(chunk.id)) continue;
      usedChunks.add(chunk.id);

      final koreanSentence = _extractRandomKoreanSentence(chunk.koreanTranslation);
      final questionText = '다음을 영어로 번역하시오.\n\n"$koreanSentence"';

      questions.add(ExamQuestion(
        id: 'k2e_${i + 1}',
        type: QuestionType.korToEngTranslation,
        question: questionText,
        answer: _getEnglishTranslation(koreanSentence, chunk),
        points: 5,
        explanation: '영어 원문 참고: ${chunk.englishContent}',
      ));
    }

    return questions;
  }

  // 문장 재배열 문제 생성
  List<ExamQuestion> generateSentenceArrangement(
    List<Chunk> chunks,
    int count,
  ) {
    final questions = <ExamQuestion>[];

    for (int i = 0; i < count && chunks.isNotEmpty; i++) {
      final chunk = chunks[_random.nextInt(chunks.length)];
      final sentence = _extractRandomSentence(chunk.englishContent);
      final words = sentence.replaceAll(RegExp(r'[^\w\s]'), '').split(' ');
      
      if (words.length < 4 || words.length > 10) continue;

      final shuffledWords = List<String>.from(words)..shuffle(_random);
      final questionText = '다음 단어들을 올바른 순서로 배열하여 문장을 만드시오.\n\n'
          '[${shuffledWords.join(' / ')}]';

      questions.add(ExamQuestion(
        id: 'arrange_${i + 1}',
        type: QuestionType.sentenceArrangement,
        question: questionText,
        answer: sentence,
        points: 4,
        explanation: '정답: $sentence',
      ));
    }

    return questions;
  }

  // 보조 메서드들
  String _createFillInBlankQuestion(String text, String word, String difficulty) {
    final wordPattern = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
    final match = wordPattern.firstMatch(text);
    
    if (match == null) return text;

    String blank;
    switch (difficulty) {
      case 'easy':
        blank = word[0] + '_' * (word.length - 1);
        break;
      case 'medium':
        blank = '_' * word.length;
        break;
      case 'hard':
        blank = '______';
        break;
      default:
        blank = '_' * word.length;
    }

    return text.replaceFirst(wordPattern, blank);
  }

  List<String> _generateMultipleChoiceOptions(Word correctWord, List<Word> allWords) {
    final options = <String>[correctWord.korean];
    final otherWords = allWords.where((w) => w.korean != correctWord.korean).toList();
    
    while (options.length < 4 && otherWords.isNotEmpty) {
      final randomWord = otherWords.removeAt(_random.nextInt(otherWords.length));
      options.add(randomWord.korean);
    }

    options.shuffle(_random);
    return options;
  }

  String _extractSentenceWithWord(String text, String word) {
    final sentences = text.split(RegExp(r'[.!?]+'));
    for (var sentence in sentences) {
      if (sentence.toLowerCase().contains(word.toLowerCase())) {
        return sentence.trim();
      }
    }
    return sentences.first.trim();
  }

  String _extractRandomSentence(String text) {
    final sentences = text.split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return sentences[_random.nextInt(sentences.length)].trim();
  }

  String _extractRandomKoreanSentence(String text) {
    final sentences = text.split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return sentences[_random.nextInt(sentences.length)].trim();
  }

  String _getKoreanTranslation(String englishSentence, Chunk chunk) {
    // 실제 구현에서는 더 정교한 매칭 로직 필요
    return chunk.koreanTranslation;
  }

  String _getEnglishTranslation(String koreanSentence, Chunk chunk) {
    // 실제 구현에서는 더 정교한 매칭 로직 필요
    return chunk.englishContent;
  }
}

// 시험지 PDF 생성기
class ExamPdfGenerator {
  final ExamQuestionGenerator _questionGenerator = ExamQuestionGenerator();

  Future<Uint8List> generateExamPdf(
    List<Chunk> chunks,
    List<Word> words,
    ExamConfig config,
  ) async {
    // 1. 문제 생성
    final examPaper = await _generateExamPaper(chunks, words, config);

    // 2. PDF 생성
    return await _createExamPdf(examPaper, config);
  }

  Future<ExamPaper> _generateExamPaper(
    List<Chunk> chunks,
    List<Word> words,
    ExamConfig config,
  ) async {
    final allQuestions = <ExamQuestion>[];

    // 각 문제 유형별로 문제 생성
    for (var entry in config.questionCounts.entries) {
      final type = entry.key;
      final count = entry.value;

      List<ExamQuestion> questions;
      switch (type) {
        case QuestionType.fillInBlanks:
          questions = _questionGenerator.generateFillInBlanks(
            chunks, words, count, config.difficulty);
          break;
        case QuestionType.multipleChoice:
          questions = _questionGenerator.generateMultipleChoice(
            chunks, words, count);
          break;
        case QuestionType.engToKorTranslation:
          questions = _questionGenerator.generateEngToKorTranslation(chunks, count);
          break;
        case QuestionType.korToEngTranslation:
          questions = _questionGenerator.generateKorToEngTranslation(chunks, count);
          break;
        case QuestionType.sentenceArrangement:
          questions = _questionGenerator.generateSentenceArrangement(chunks, count);
          break;
        default:
          questions = [];
      }

      allQuestions.addAll(questions);
    }

    // 문제 섞기
    if (config.shuffleQuestions) {
      allQuestions.shuffle();
    }

    final totalPoints = allQuestions.fold<int>(0, (sum, q) => sum + q.points);

    return ExamPaper(
      title: config.title,
      questions: allQuestions,
      questionCounts: config.questionCounts,
      totalPoints: totalPoints,
      timeLimit: config.timeLimit,
      createdAt: DateTime.now(),
    );
  }

  Future<Uint8List> _createExamPdf(ExamPaper examPaper, ExamConfig config) async {
    final pdf = pw.Document();
    
    // 폰트 로드
    final regularFont = await PdfGoogleFonts.nanumGothicRegular();
    final boldFont = await PdfGoogleFonts.nanumGothicBold();

    // 1. 표지 페이지
    pdf.addPage(_buildCoverPage(examPaper, regularFont, boldFont));

    // 2. 문제 페이지들
    final questionPages = _buildQuestionPages(examPaper, regularFont, boldFont);
    for (var page in questionPages) {
      pdf.addPage(page);
    }

    // 3. 답안지 (옵션)
    if (config.includeAnswerKey) {
      final answerPages = _buildAnswerKeyPages(examPaper, regularFont, boldFont);
      for (var page in answerPages) {
        pdf.addPage(page);
      }
    }

    return pdf.save();
  }

  pw.Page _buildCoverPage(ExamPaper examPaper, pw.Font regularFont, pw.Font boldFont) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // 제목
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  examPaper.title,
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 24,
                    color: PdfColors.blue900,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 40),
              
              // 시험 정보
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  children: [
                    pw.Text('총 문항: ${examPaper.questions.length}문제',
                        style: pw.TextStyle(font: regularFont, fontSize: 14)),
                    pw.SizedBox(height: 5),
                    pw.Text('총 배점: ${examPaper.totalPoints}점',
                        style: pw.TextStyle(font: regularFont, fontSize: 14)),
                    if (examPaper.timeLimit != null) ...[
                      pw.SizedBox(height: 5),
                      pw.Text('제한시간: ${examPaper.timeLimit!.inMinutes}분',
                          style: pw.TextStyle(font: regularFont, fontSize: 14)),
                    ],
                  ],
                ),
              ),
              
              pw.SizedBox(height: 40),
              
              // 응시자 정보
              pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('이름: ', style: pw.TextStyle(font: regularFont, fontSize: 16)),
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('날짜: ', style: pw.TextStyle(font: regularFont, fontSize: 16)),
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<pw.Page> _buildQuestionPages(ExamPaper examPaper, pw.Font regularFont, pw.Font boldFont) {
    final pages = <pw.Page>[];
    final questionsPerPage = 5; // 페이지당 문제 수
    
    for (int i = 0; i < examPaper.questions.length; i += questionsPerPage) {
      final endIndex = (i + questionsPerPage).clamp(0, examPaper.questions.length);
      final pageQuestions = examPaper.questions.sublist(i, endIndex);
      
      pages.add(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 페이지 헤더
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    examPaper.title,
                    style: pw.TextStyle(font: boldFont, fontSize: 16),
                  ),
                  pw.Text(
                    '페이지 ${(i ~/ questionsPerPage) + 1}',
                    style: pw.TextStyle(font: regularFont, fontSize: 12),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // 문제들
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: pageQuestions.asMap().entries.map((entry) {
                    final questionIndex = i + entry.key + 1;
                    final question = entry.value;
                    return _buildQuestionWidget(
                      questionIndex, question, regularFont, boldFont);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ));
    }
    
    return pages;
  }

  pw.Widget _buildQuestionWidget(
    int questionNumber,
    ExamQuestion question,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 문제 번호와 배점
          pw.Row(
            children: [
              pw.Text(
                '$questionNumber. ',
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              pw.Text(
                _getQuestionTypeLabel(question.type),
                style: pw.TextStyle(font: regularFont, fontSize: 12),
              ),
              pw.Spacer(),
              pw.Text(
                '(${question.points}점)',
                style: pw.TextStyle(font: regularFont, fontSize: 12),
              ),
            ],
          ),
          
          pw.SizedBox(height: 8),
          
          // 문제 내용
          pw.Text(
            question.question,
            style: pw.TextStyle(font: regularFont, fontSize: 12),
          ),
          
          pw.SizedBox(height: 8),
          
          // 객관식 보기
          if (question.options != null) ...[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: question.options!.asMap().entries.map((entry) {
                final optionLetter = String.fromCharCode(97 + entry.key); // a, b, c, d
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 20, bottom: 4),
                  child: pw.Text(
                    '$optionLetter) ${entry.value}',
                    style: pw.TextStyle(font: regularFont, fontSize: 11),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            // 주관식 답안 공간
            pw.Container(
              width: double.infinity,
              height: 40,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
            ),
          ],
          
          pw.SizedBox(height: 10),
        ],
      ),
    );
  }

  List<pw.Page> _buildAnswerKeyPages(ExamPaper examPaper, pw.Font regularFont, pw.Font boldFont) {
    return [
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 답안지 제목
              pw.Center(
                child: pw.Text(
                  '정답 및 해설',
                  style: pw.TextStyle(font: boldFont, fontSize: 18),
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // 정답들
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: examPaper.questions.asMap().entries.map((entry) {
                    final questionNumber = entry.key + 1;
                    final question = entry.value;
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 15),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '$questionNumber. ${question.answer}',
                            style: pw.TextStyle(font: boldFont, fontSize: 12),
                          ),
                          if (question.explanation != null) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '   ${question.explanation}',
                              style: pw.TextStyle(font: regularFont, fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.fillInBlanks:
        return '빈칸 채우기';
      case QuestionType.multipleChoice:
        return '객관식';
      case QuestionType.engToKorTranslation:
        return '영한 번역';
      case QuestionType.korToEngTranslation:
        return '한영 번역';
      case QuestionType.sentenceArrangement:
        return '문장 재배열';
      case QuestionType.synonymAntonym:
        return '동의어/반의어';
      case QuestionType.errorCorrection:
        return '오류 수정';
      case QuestionType.wordFormation:
        return '단어 형태 변환';
      case QuestionType.contextInference:
        return '문맥 추론';
    }
  }
}

// 사용 예시
class ExamPdfService {
  final ExamPdfGenerator _generator = ExamPdfGenerator();

  Future<Uint8List> createCustomExam({
    required List<Chunk> chunks,
    required List<Word> words,
    required Map<QuestionType, int> questionCounts,
    String difficulty = 'medium',
    bool includeAnswerKey = true,
    bool shuffleQuestions = false,
    Duration? timeLimit,
    String title = 'ChunkUp 시험지',
  }) async {
    final config = ExamConfig(
      questionCounts: questionCounts,
      difficulty: difficulty,
      includeAnswerKey: includeAnswerKey,
      shuffleQuestions: shuffleQuestions,
      timeLimit: timeLimit,
      title: title,
    );

    return await _generator.generateExamPdf(chunks, words, config);
  }
}
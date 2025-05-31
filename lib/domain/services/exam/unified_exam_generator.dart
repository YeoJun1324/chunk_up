// lib/core/services/unified_exam_generator.dart
import 'dart:math';
import 'package:pluralize/pluralize.dart';
import '../../models/exam_models.dart';
import '../../models/enhanced_exam_models.dart';
import '../../models/word.dart';
import '../../models/chunk.dart';
import '../../models/sentence_pair.dart';
import 'package:chunk_up/domain/services/sentence/unified_sentence_mapping_service.dart';
import 'package:get_it/get_it.dart';

/// Configuration for exam generation (Premium only)
class ExamGenerationConfig {
  final bool includeDetailedExplanations;
  final bool includeGradingCriteria;
  final int maxQuestionsPerType;

  const ExamGenerationConfig({
    this.includeDetailedExplanations = true,
    this.includeGradingCriteria = true,
    this.maxQuestionsPerType = 20,
  });
  
  // Premium 티어 설정 (시험지 생성은 Premium 전용)
  static const ExamGenerationConfig premium = ExamGenerationConfig(
    includeDetailedExplanations: true,
    includeGradingCriteria: true,
    maxQuestionsPerType: 20,
  );
}

/// Exam question generator for premium users
class UnifiedExamGenerator {
  final Random _random = Random();
  final ExamGenerationConfig config;
  late final UnifiedSentenceMappingService _sentenceMappingService;

  UnifiedExamGenerator({this.config = const ExamGenerationConfig()}) {
    _sentenceMappingService = GetIt.I<UnifiedSentenceMappingService>();
  }

  /// Generate exam paper
  ExamPaper generateExam({
    required List<Chunk> chunks,
    required int questionCount,
    required QuestionType questionType,
  }) {
    final questionCounts = <QuestionType, int>{questionType: questionCount};
    
    final questions = _generateQuestions(chunks, [], questionCounts);
    
    return ExamPaper(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'ChunkUp 시험지',
      questions: questions,
      questionCounts: questionCounts,
      createdAt: DateTime.now(),
      config: ExamConfig(questionCounts: questionCounts),
      difficultyLevel: 'medium',
      totalQuestions: questions.length,
    );
  }

  /// Generate enhanced exam paper
  EnhancedExamPaper generateEnhancedExam({
    required List<Chunk> chunks,
    required int questionCount,
    required QuestionType questionType,
  }) {
    final questionCounts = <QuestionType, int>{questionType: questionCount};
    
    final questions = _generateEnhancedQuestions(chunks, [], questionCounts);
    
    return EnhancedExamPaper(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'ChunkUp 시험지',
      questions: questions.cast<EnhancedExamQuestion>(),
      statistics: ExamStatistics(
        typeDistribution: questionCounts,
        difficultyDistribution: {'medium': questions.length},
        totalEstimatedTime: Duration(minutes: questions.length * 2),
        tagDistribution: {},
        averagePoints: 2,
      ),
      createdAt: DateTime.now(),
      config: ExamConfig(questionCounts: questionCounts),
    );
  }

  /// Generate exam questions
  List<dynamic> generateQuestions({
    required List<Chunk> chunks,
    required List<Word> targetWords,
    required Map<QuestionType, int> questionCounts,
  }) {
    return _generateQuestions(chunks, targetWords, questionCounts);
  }

  /// Generate exam questions based on specification
  List<ExamQuestion> _generateQuestions(
    List<Chunk> chunks,
    List<Word> targetWords,
    Map<QuestionType, int> questionCounts,
  ) {
    final questions = <ExamQuestion>[];
    final type = questionCounts.keys.first;
    final requestedCount = questionCounts.values.first;

    // 한영 번역 문제는 문장 수 기준으로 처리
    if (type == QuestionType.korToEngTranslation) {
      print('📊 Translation Exam Generation:');
      print('  Total chunks: ${chunks.length}');
      print('  Questions to generate: $requestedCount');
      
      // 모든 청크에서 문장 쌍 수집
      final List<SentencePair> allSentencePairs = [];
      for (var chunk in chunks) {
        final sentencePairs = _sentenceMappingService.extractAllSentencePairs(chunk);
        allSentencePairs.addAll(sentencePairs);
      }
      
      print('  Total sentence pairs available: ${allSentencePairs.length}');
      
      // 중복 제거하고 요청된 수만큼 생성
      final generatedQuestions = _generateTranslationQuestionsFromSentences(
        chunks, 
        allSentencePairs, 
        requestedCount
      );
      
      questions.addAll(generatedQuestions);
    } else {
      // 다른 문제 유형은 기존 방식 유지 (단어 수 기준)
      final Set<String> seenWords = {};
      final List<Word> allWordsFromChunks = [];
      
      for (var chunk in chunks) {
        for (var word in chunk.includedWords) {
          final wordKey = word.english.toLowerCase();
          if (!seenWords.contains(wordKey)) {
            seenWords.add(wordKey);
            allWordsFromChunks.add(word);
          }
        }
      }

      print('📊 Exam Generation:');
      print('  Total unique words in chunks: ${allWordsFromChunks.length}');
      print('  Question type: ${type.name}');
      print('  Questions to generate: $requestedCount');

      final assignedWords = allWordsFromChunks.take(requestedCount).toList();
      
      print('  📝 Generating ${type.name}: ${assignedWords.length} questions');

      List<ExamQuestion> generatedQuestions = [];
      switch (type) {
        case QuestionType.fillInBlanks:
          generatedQuestions = _generateFillInBlankQuestions(chunks, assignedWords, requestedCount);
          break;
        case QuestionType.contextMeaning:
          generatedQuestions = _generateContextMeaningQuestions(chunks, assignedWords, requestedCount);
          break;
        case QuestionType.korToEngTranslation:
          // 이미 위에서 처리됨
          break;
      }
      
      questions.addAll(generatedQuestions);
    }

    print('📋 Final result: ${questions.length} total questions generated');
    return questions;
  }


  // ===== 기획에 맞는 새로운 문제 생성 메서드들 =====

  /// Type 1: 빈칸 채우기 - 청크 단락 통합 문제 생성
  List<ExamQuestion> _generateFillInBlankQuestions(
    List<Chunk> chunks,
    List<Word> assignedWords,
    int maxQuestions,
  ) {
    final questions = <ExamQuestion>[];
    
    print('  📝 Generating integrated fill-in-blank questions for ${assignedWords.length} words');
    
    // 각 청크마다 통합 문제 생성
    for (int chunkIndex = 0; chunkIndex < chunks.length && questions.length < maxQuestions; chunkIndex++) {
      final chunk = chunks[chunkIndex];
      
      // 해당 청크에 포함된 단어들 찾기
      final chunkWords = assignedWords.where((word) => 
        chunk.includedWords.any((w) => w.english.toLowerCase() == word.english.toLowerCase())
      ).toList();
      
      if (chunkWords.isEmpty) continue;
      
      print('    Chunk ${chunkIndex + 1}: ${chunkWords.length} words to process');
      
      try {
        // 청크의 영어 내용을 사용하여 통합 빈칸 문제 생성
        final integratedQuestion = _createIntegratedFillInBlankQuestion(chunk, chunkWords);
        
        if (integratedQuestion != null) {
          questions.add(integratedQuestion);
          print('    ✅ Created integrated question for chunk ${chunkIndex + 1}');
        } else {
          print('    ⚠️ Failed to create integrated question for chunk ${chunkIndex + 1}');
        }
      } catch (e) {
        print('    ❌ Error creating integrated question for chunk ${chunkIndex + 1}: $e');
      }
    }
    
    // 요청된 수보다 적게 생성된 경우, 추가 문제 생성
    while (questions.length < maxQuestions && questions.length < chunks.length) {
      final remainingChunkIndex = questions.length;
      if (remainingChunkIndex < chunks.length) {
        final chunk = chunks[remainingChunkIndex];
        final fallbackQuestion = _createFallbackFillInBlankQuestion(chunk, remainingChunkIndex + 1);
        if (fallbackQuestion != null) {
          questions.add(fallbackQuestion);
        }
      } else {
        break;
      }
    }
    
    print('  📋 Final fill-in-blank questions generated: ${questions.length}');
    return questions;
  }
  
  /// 청크 단락 통합 빈칸 문제 생성
  ExamQuestion? _createIntegratedFillInBlankQuestion(Chunk chunk, List<Word> targetWords) {
    // Remove ||| delimiters from content and clean it up
    String content = chunk.englishContent
        .replaceAll('|||', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final List<String> answers = [];
    final List<String> targetWordsKorean = [];
    
    // 모든 타겟 단어의 매칭 정보를 먼저 수집하고 위치순으로 정렬
    final List<Map<String, dynamic>> allMatches = [];
    
    for (final word in targetWords) {
      final matches = _findWordMatches(content, word.english);
      
      if (matches.isNotEmpty) {
        // 첫 번째 매칭 정보를 저장
        final match = matches.first;
        allMatches.add({
          'word': word,
          'match': match,
        });
      }
    }
    
    // 매칭들을 위치순으로 정렬 (앞에서 뒤로)
    allMatches.sort((a, b) => (a['match']['start'] as int).compareTo(b['match']['start'] as int));
    
    // 뒤에서부터 빈칸을 생성 (인덱스 변경 방지)
    for (int i = allMatches.length - 1; i >= 0; i--) {
      final matchInfo = allMatches[i];
      final word = matchInfo['word'] as Word;
      final match = matchInfo['match'] as Map<String, dynamic>;
      
      final beforeBlank = content.substring(0, match['start']);
      final afterBlank = content.substring(match['end']);
      
      // 빈칸 번호는 정렬된 순서대로 (1부터 시작)
      final blankNumber = allMatches.indexOf(matchInfo) + 1;
      content = beforeBlank + '(_${blankNumber}_)' + afterBlank;
    }
    
    // 답안도 정렬된 순서대로 저장
    for (final matchInfo in allMatches) {
      final word = matchInfo['word'] as Word;
      final match = matchInfo['match'] as Map<String, dynamic>;
      answers.add(match['exactMatch']);
      targetWordsKorean.add(word.korean);
    }
    
    // 빈칸이 생성되지 않은 경우
    if (answers.isEmpty) {
      return null;
    }
    
    // 답안 문자열 생성
    final answerText = answers.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final answer = entry.value;
      final korean = targetWordsKorean[entry.key];
      return '${index}. $answer (${korean})';
    }).join('\n');
    
    return ExamQuestion(
      id: 'integrated_fill_${chunk.id}',
      type: QuestionType.fillInBlanks,
      question: '다음 단락의 빈칸에 알맞은 단어를 쓰시오.\n\n$content',
      answer: answerText,
      targetWord: targetWords.map((w) => w.english).join(', '),
      sourceChunkId: chunk.id,
    );
  }
  
  /// 대체 빈칸 문제 생성 (청크 단어가 없는 경우)
  ExamQuestion? _createFallbackFillInBlankQuestion(Chunk chunk, int questionNumber) {
    // Remove ||| delimiters from content and clean it up
    final content = chunk.englishContent
        .replaceAll('|||', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // 단락에서 가장 의미 있는 단어들 찾기
    final words = content.split(RegExp(r'\s+'));
    final meaningfulWords = words.where((word) {
      final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      return cleanWord.length >= 4 && 
             !['this', 'that', 'with', 'from', 'they', 'them', 'have', 'been', 'will', 
               'were', 'when', 'what', 'where', 'which', 'would', 'could', 'should'].contains(cleanWord.toLowerCase());
    }).toList();
    
    if (meaningfulWords.length < 2) {
      return null;
    }
    
    // 무작위로 2-3개 단어 선택하여 빈칸 생성
    meaningfulWords.shuffle(_random);
    final selectedWords = meaningfulWords.take(2).toList();
    
    String modifiedContent = content;
    final List<String> answers = [];
    
    for (int i = 0; i < selectedWords.length; i++) {
      final word = selectedWords[i];
      final cleanWord = word.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      
      // 첫 번째 발견만 빈칸으로 대체
      modifiedContent = modifiedContent.replaceFirst(word, '(_${i + 1}_)');
      answers.add(cleanWord);
    }
    
    final answerText = answers.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final answer = entry.value;
      return '${index}. $answer';
    }).join('\n');
    
    return ExamQuestion(
      id: 'fallback_fill_${questionNumber}',
      type: QuestionType.fillInBlanks,
      question: '다음 단락의 빈칸에 알맞은 단어를 쓰시오.\n\n$modifiedContent',
      answer: answerText,
      targetWord: 'fallback',
      sourceChunkId: chunk.id,
    );
  }

  /// Type 2: 단어 용법 설명 - 타겟 단어가 포함된 문장에서 단어를 굵게 표시하고 문맥상 의미 설명
  List<ExamQuestion> _generateContextMeaningQuestions(
    List<Chunk> chunks,
    List<Word> assignedWords,
    int maxQuestions,
  ) {
    final questions = <ExamQuestion>[];
    int questionNumber = 1;

    // 요청된 개수만큼만 생성
    final int questionsToGenerate = assignedWords.length < maxQuestions ? assignedWords.length : maxQuestions;
    
    for (int i = 0; i < questionsToGenerate; i++) {
      final word = assignedWords[i];
      try {
        final suitableChunk = _findChunkWithWord(chunks, word.english);
        
        // 해당 단어가 포함된 가장 적절한 문장 찾기
        final sentencePair = _sentenceMappingService.findSentencePairWithWord(suitableChunk, word.english);
        
        String sentence = '';
        String koreanTranslation = '';
        
        if (sentencePair != null) {
          sentence = sentencePair.english;
          koreanTranslation = sentencePair.korean;
        } else {
          sentence = _extractBestSentenceWithWord(suitableChunk.englishContent, word.english);
          // 번역이 없는 경우 기본 설명 사용
          koreanTranslation = '(해당 문장의 번역 정보 없음)';
        }
        
        // 문장에서 실제 사용된 단어 찾기 (새로운 로직 사용)
        final wordMatches = _findWordMatches(sentence, word.english);
        String wordToHighlight = word.english;
        
        if (wordMatches.isNotEmpty) {
          wordToHighlight = wordMatches.first['exactMatch'];
        }
        
        // 타겟 단어를 굵게 표시
        String highlightedSentence = sentence;
        
        if (wordMatches.isNotEmpty) {
          // 정확한 매칭 위치를 사용하여 하이라이트
          final match = wordMatches.first;
          highlightedSentence = sentence.substring(0, match['start']) + 
                                '**${match['exactMatch']}**' + 
                                sentence.substring(match['end']);
        } else {
          // 매칭 실패시 대체 방법
          highlightedSentence = sentence.replaceFirst(
            word.english, 
            '**${word.english}**',
          );
        }
        
        final questionText = '다음 문장에서 굵게 표시된 단어의 문맥상 의미를 설명하시오.\n\n$highlightedSentence';
        
        // 정답 구성: 단어 의미 + 문맥 설명 + 문장 번역
        String answer = '';
        
        // 1. 기본 의미
        answer += '"${wordToHighlight}"의 의미: ${word.korean}';
        
        // 2. 문맥상 설명 (청크에서 가져오거나 기본 설명)
        final explanation = suitableChunk.getExplanationFor(word.english);
        if (explanation != null && explanation.isNotEmpty) {
          answer += '\n\n문맥상 설명: $explanation';
        } else {
          answer += '\n\n문맥상 설명: 이 문장에서 "${wordToHighlight}"은(는) "${word.korean}"의 의미로 사용되었습니다.';
        }
        
        // 3. 문장 번역
        if (koreanTranslation.isNotEmpty && koreanTranslation != '(해당 문장의 번역 정보 없음)') {
          answer += '\n\n전체 문장 번역: $koreanTranslation';
        }
        
        questions.add(ExamQuestion(
          id: 'context_${questionNumber++}',
          type: QuestionType.contextMeaning,
          question: questionText,
          answer: answer,
          targetWord: word.english,
          sourceChunkId: suitableChunk.id,
        ));
      } catch (e) {
        print('⚠️ Error generating context meaning question for ${word.english}: $e');
        // 에러 발생시 기본 문제 생성
        questions.add(ExamQuestion(
          id: 'context_${questionNumber++}',
          type: QuestionType.contextMeaning,
          question: '다음 단어의 의미를 설명하시오: ${word.english}',
          answer: '"${word.english}"의 의미: ${word.korean}',
          targetWord: word.english,
          sourceChunkId: chunks.first.id,
        ));
      }
    }

    return questions;
  }

  /// 새로운 문장 기반 번역 문제 생성 메서드
  List<ExamQuestion> _generateTranslationQuestionsFromSentences(
    List<Chunk> chunks,
    List<SentencePair> allSentencePairs,
    int maxQuestions,
  ) {
    final questions = <ExamQuestion>[];
    final Set<String> usedSentences = {};
    int questionNumber = 1;
    
    // 적절한 문장들만 필터링
    final appropriateSentences = allSentencePairs
        .where((pair) => _isAppropriateForTranslation(pair))
        .toList();
    
    // 랜덤하게 섞어서 다양성 확보
    appropriateSentences.shuffle(_random);
    
    print('  Appropriate sentences for translation: ${appropriateSentences.length}');
    
    // 요청된 수만큼 문제 생성
    for (int i = 0; i < appropriateSentences.length && questions.length < maxQuestions; i++) {
      final sentencePair = appropriateSentences[i];
      
      // 중복 체크
      if (usedSentences.contains(sentencePair.korean)) {
        continue;
      }
      
      usedSentences.add(sentencePair.korean);
      
      // 문제 생성
      final questionText = '다음 한국어 문장을 영어로 번역하시오.\n\n${sentencePair.korean}';
      
      // 문장에 포함된 단어들 찾기 (힌트용)
      final wordsInSentence = <Word>[];
      for (var chunk in chunks) {
        for (var word in chunk.includedWords) {
          if (sentencePair.english.toLowerCase().contains(word.english.toLowerCase())) {
            wordsInSentence.add(word);
          }
        }
      }
      
      // 힌트 추가 (단어가 포함되어 있으면)
      String finalQuestionText = questionText;
      if (wordsInSentence.isNotEmpty) {
        final hints = wordsInSentence
            .map((w) => '${w.korean}: ${w.english}')
            .join(', ');
        finalQuestionText += '\n\n💡 단어 힌트: $hints';
      }
      
      // 문제 추가
      questions.add(ExamQuestion(
        id: 'translation_${questionNumber++}',
        type: QuestionType.korToEngTranslation,
        question: finalQuestionText,
        answer: sentencePair.english,
        targetWord: wordsInSentence.isNotEmpty ? wordsInSentence.first.english : '',
        sourceChunkId: chunks.first.id,
      ));
    }
    
    print('  Generated ${questions.length} translation questions from sentences');
    
    return questions;
  }

  /// Type 3: 문장 번역 - 한국어 문장을 제시하고 대응하는 영어 문장을 쓰도록 함 (구버전 - 단어 기반)
  List<ExamQuestion> _generateTranslationQuestions(
    List<Chunk> chunks,
    List<Word> assignedWords,
    Set<String> usedSentencesForTranslation,
    int maxQuestions,
  ) {
    final questions = <ExamQuestion>[];
    int questionNumber = 1;

    // 요청된 개수만큼만 생성
    final int questionsToGenerate = assignedWords.length < maxQuestions ? assignedWords.length : maxQuestions;
    
    for (int i = 0; i < questionsToGenerate; i++) {
      final word = assignedWords[i];
      try {
        final suitableChunk = _findChunkWithWord(chunks, word.english);
        
        // 문장 매칭 정보를 활용하여 정확한 한-영 문장 쌍 찾기
        final sentencePair = _sentenceMappingService.findSentencePairWithWord(suitableChunk, word.english);
        
        if (sentencePair != null && 
            !usedSentencesForTranslation.contains(sentencePair.korean) &&
            _isAppropriateForTranslation(sentencePair)) {
          
          // 중복 방지를 위해 사용된 문장으로 표시
          usedSentencesForTranslation.add(sentencePair.korean);
          
          // 타겟 단어가 영어 문장에 포함되어 있는지 확인
          final englishSentence = sentencePair.english;
          final containsTargetWord = englishSentence.toLowerCase().contains(word.english.toLowerCase());
          
          // 다른 단어들도 포함되어 있는지 확인
          final otherWordsInSentence = assignedWords
              .where((w) => w.english != word.english && 
                           englishSentence.toLowerCase().contains(w.english.toLowerCase()))
              .toList();
          
          String questionText;
          String answer;
          
          if (containsTargetWord) {
            // 정확한 번역 문제
            questionText = '다음 한국어 문장을 영어로 번역하시오.\n\n${sentencePair.korean}';
            
            // 여러 단어가 포함된 경우 힌트 제공
            if (otherWordsInSentence.isNotEmpty) {
              final allWordsInSentence = [word, ...otherWordsInSentence];
              final hints = allWordsInSentence
                  .map((w) => '${w.korean}: ${w.english}')
                  .join(', ');
              questionText += '\n\n💡 힌트: $hints';
            } else {
              // 단일 단어만 포함된 경우에만 힌트 제공
              questionText += '\n\n💡 힌트: ${word.korean}: ${word.english}';
            }
            
            answer = englishSentence;
          } else {
            // 타겟 단어가 포함되지 않은 경우에만 fallback
            questionText = '"${word.korean}" (${word.english})을 사용하여 다음 문장과 비슷한 의미의 영어 문장을 작성하시오.\n\n${sentencePair.korean}';
            answer = '${englishSentence}\n\n(또는 "${word.english}"을 포함한 유사한 의미의 문장)';
          }
          
          questions.add(ExamQuestion(
            id: 'translation_${questionNumber++}',
            type: QuestionType.korToEngTranslation,
            question: questionText,
            answer: answer,
            targetWord: word.english,
            sourceChunkId: suitableChunk.id,
          ));
        } else {
          // 적절한 문장 쌍을 찾지 못한 경우, 단어 기반 번역 문제 생성
          final questionText = '"${word.korean}"에 해당하는 영어 단어 "${word.english}"을 사용하여 간단한 영어 문장을 작성하시오.';
          
          // 예시 답안 생성
          final exampleAnswers = [
            'I need to ${word.english}.',
            'The ${word.english} is important.',
            'She can ${word.english} well.',
            'This is a good ${word.english}.',
          ];
          
          final answer = '예시 답안: ${exampleAnswers[_random.nextInt(exampleAnswers.length)]}\n\n("${word.english}"을 포함한 문법적으로 올바른 영어 문장이면 정답입니다.)';
          
          questions.add(ExamQuestion(
            id: 'translation_${questionNumber++}',
            type: QuestionType.korToEngTranslation,
            question: questionText,
            answer: answer,
            targetWord: word.english,
            sourceChunkId: suitableChunk.id,
          ));
        }
      } catch (e) {
        print('⚠️ Error generating translation question for ${word.english}: $e');
        // 에러 발생시 기본 문제 생성
        questions.add(ExamQuestion(
          id: 'translation_${questionNumber++}',
          type: QuestionType.korToEngTranslation,
          question: '"${word.korean}"에 해당하는 영어 단어를 쓰시오.',
          answer: word.english,
          targetWord: word.english,
          sourceChunkId: chunks.first.id,
        ));
      }
    }

    return questions;
  }

  // ===== 헬퍼 메서드들 =====

  /// 해당 단어가 포함된 가장 적절한 청크 찾기
  Chunk _findChunkWithWord(List<Chunk> chunks, String word) {
    // 1순위: 해당 단어를 includedWords에 포함하는 청크
    for (final chunk in chunks) {
      if (chunk.includedWords.any((w) => w.english.toLowerCase() == word.toLowerCase())) {
        return chunk;
      }
    }
    
    // 2순위: 해당 단어가 내용에 포함된 청크
    for (final chunk in chunks) {
      final cleanContent = chunk.englishContent
          .replaceAll('|||', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (cleanContent.toLowerCase().contains(word.toLowerCase())) {
        return chunk;
      }
    }
    
    // 폴백: 첫 번째 청크
    return chunks.first;
  }

  /// 해당 단어가 포함된 가장 적절한 문장 추출 (향상된 버전)
  String _extractBestSentenceWithWord(String content, String word) {
    // Remove ||| delimiters from content and clean it up
    final cleanContent = content
        .replaceAll('|||', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final sentences = cleanContent.split(RegExp(r'[.!?]+\s+'));
    
    // 해당 단어가 포함된 문장들 찾기
    final matchingSentences = sentences.where((sentence) => 
      sentence.toLowerCase().contains(word.toLowerCase())
    ).toList();
    
    if (matchingSentences.isEmpty) {
      return cleanContent.split('.').first + '.'; // 첫 번째 문장 반환
    }
    
    // 가장 적절한 문장 선택 (길이, 복잡도 고려)
    matchingSentences.sort((a, b) {
      // 너무 짧거나 긴 문장은 낮은 점수
      int scoreA = _calculateSentenceScore(a, word);
      int scoreB = _calculateSentenceScore(b, word);
      return scoreB.compareTo(scoreA); // 높은 점수 순
    });
    
    return matchingSentences.first.trim();
  }

  /// 문장의 적절성 점수 계산
  int _calculateSentenceScore(String sentence, String word) {
    int score = 0;
    
    // 길이 점수 (20-100자가 적절)
    if (sentence.length >= 20 && sentence.length <= 100) score += 10;
    else if (sentence.length >= 10 && sentence.length <= 150) score += 5;
    
    // 단어 위치 점수 (문장 중간에 있으면 더 좋음)
    final wordIndex = sentence.toLowerCase().indexOf(word.toLowerCase());
    if (wordIndex > sentence.length * 0.2 && wordIndex < sentence.length * 0.8) {
      score += 5;
    }
    
    // 대화문이 아닌 서술문 선호
    if (!sentence.contains('"') && !sentence.contains("'")) {
      score += 3;
    }
    
    return score;
  }

  /// 번역에 적절한 문장인지 확인
  bool _isAppropriateForTranslation(SentencePair sentencePair) {
    // 너무 긴 문장은 제외 (150자 이하)
    if (sentencePair.korean.length > 150) return false;
    
    // 너무 짧은 문장도 제외 (10자 이상)
    if (sentencePair.korean.length < 10) return false;
    
    // 특수 문자가 너무 많은 문장 제외
    final specialCharCount = RegExp(r'[^\w\s가-힣]').allMatches(sentencePair.korean).length;
    if (specialCharCount > sentencePair.korean.length * 0.3) return false;
    
    return true;
  }

  /// 빈칸 채우기 문제 생성 (WordHighlighter 로직 참고)
  String _createFillInBlankQuestion(String sentence, String word) {
    // Remove ||| delimiters and clean up the sentence
    final cleanSentence = sentence
        .replaceAll('|||', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // WordHighlighter와 같은 로직으로 단어 찾기
    final matches = _findWordMatches(cleanSentence, word);
    
    if (matches.isEmpty) {
      // 매칭 실패시 기본 문제 생성
      return 'Fill in the blank: The word _____ means something in this context.';
    }
    
    // 가장 전형적인 매칭 선택 (첫 번째 매칭 사용)
    final match = matches.first;
    
    // 문장에서 매칭된 부분을 빈칸으로 대체
    final String questionText = cleanSentence.substring(0, match['start']) + 
                                '_____' + 
                                cleanSentence.substring(match['end']);
    
    return questionText;
  }
  
  /// WordHighlighter의 로직을 참고하여 문장에서 단어 매칭 찾기
  List<Map<String, dynamic>> _findWordMatches(String text, String targetWord) {
    final matches = <Map<String, dynamic>>[];
    final lowerText = text.toLowerCase();
    final lowerTargetWord = targetWord.toLowerCase();
    
    // 1. 기본 단어 찾기
    _findExactWordForm(text, lowerText, lowerTargetWord, matches);
    
    // 2. 복수형/단수형 변환하여 찾기
    // 간단한 복수형 처리 (s 추가/제거)
    if (lowerTargetWord.endsWith('s') && lowerTargetWord.length > 2) {
      // 복수형 -> 단수형
      final singular = lowerTargetWord.substring(0, lowerTargetWord.length - 1);
      _findExactWordForm(text, lowerText, singular, matches);
    } else {
      // 단수형 -> 복수형
      _findExactWordForm(text, lowerText, lowerTargetWord + 's', matches);
    }
    
    // 3. 동사 활용형 찾기 (ing, ed 등)
    if (!lowerTargetWord.endsWith('ing') && !lowerTargetWord.endsWith('ed')) {
      // ing 형태
      if (lowerTargetWord.endsWith('e')) {
        // dance -> dancing (e 삭제)
        _findExactWordForm(text, lowerText, 
            lowerTargetWord.substring(0, lowerTargetWord.length - 1) + 'ing', matches);
      } else {
        // walk -> walking
        _findExactWordForm(text, lowerText, lowerTargetWord + 'ing', matches);
      }
      
      // ed 형태
      if (lowerTargetWord.endsWith('e')) {
        // dance -> danced
        _findExactWordForm(text, lowerText, lowerTargetWord + 'd', matches);
      } else if (lowerTargetWord.endsWith('y')) {
        // study -> studied (y->i 변경)
        _findExactWordForm(text, lowerText, 
            lowerTargetWord.substring(0, lowerTargetWord.length - 1) + 'ied', matches);
      } else {
        // walk -> walked
        _findExactWordForm(text, lowerText, lowerTargetWord + 'ed', matches);
      }
    }
    
    // 4. 형용사 비교급/최상급 찾기
    if (!lowerTargetWord.endsWith('er') && !lowerTargetWord.endsWith('est')) {
      // er 형태 (비교급)
      if (lowerTargetWord.endsWith('e')) {
        _findExactWordForm(text, lowerText, lowerTargetWord + 'r', matches);
      } else if (lowerTargetWord.endsWith('y')) {
        _findExactWordForm(text, lowerText, 
            lowerTargetWord.substring(0, lowerTargetWord.length - 1) + 'ier', matches);
      } else {
        _findExactWordForm(text, lowerText, lowerTargetWord + 'er', matches);
      }
      
      // est 형태 (최상급)
      if (lowerTargetWord.endsWith('e')) {
        _findExactWordForm(text, lowerText, lowerTargetWord + 'st', matches);
      } else if (lowerTargetWord.endsWith('y')) {
        _findExactWordForm(text, lowerText, 
            lowerTargetWord.substring(0, lowerTargetWord.length - 1) + 'iest', matches);
      } else {
        _findExactWordForm(text, lowerText, lowerTargetWord + 'est', matches);
      }
    }
    
    // 5. 활용형에서 기본형 찾기
    if (lowerTargetWord.endsWith('ing')) {
      // running -> run
      String baseForm = lowerTargetWord.substring(0, lowerTargetWord.length - 3);
      _findExactWordForm(text, lowerText, baseForm, matches);
      
      // dancing -> dance (e 추가)
      _findExactWordForm(text, lowerText, baseForm + 'e', matches);
    } else if (lowerTargetWord.endsWith('ed')) {
      // walked -> walk
      String baseForm = lowerTargetWord.substring(0, lowerTargetWord.length - 2);
      _findExactWordForm(text, lowerText, baseForm, matches);
    }
    
    // 중복 제거 및 정렬 (위치 순)
    final uniqueMatches = <Map<String, dynamic>>[];
    final seenPositions = <int>{};
    
    for (final match in matches) {
      final start = match['start'] as int;
      if (!seenPositions.contains(start)) {
        seenPositions.add(start);
        uniqueMatches.add(match);
      }
    }
    
    uniqueMatches.sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));
    return uniqueMatches;
  }
  
  /// 정확한 단어 형태를 찾아 matches에 추가하는 헬퍼 메서드
  void _findExactWordForm(
      String originalText,
      String lowerText,
      String exactTargetWord,
      List<Map<String, dynamic>> matches
      ) {
    // 단어 경계를 고려한 정규식 패턴
    final pattern = r'\b' + RegExp.escape(exactTargetWord) + r'\b';
    final regex = RegExp(pattern, caseSensitive: false);
    
    for (final match in regex.allMatches(lowerText)) {
      // 원래 텍스트에서 매칭된 정확한 문자열 추출
      final String exactMatch = originalText.substring(match.start, match.end);
      
      matches.add({
        'start': match.start,
        'end': match.end,
        'exactMatch': exactMatch,
      });
    }
  }
  
  

  /// Enhanced 문제로 변환
  EnhancedExamQuestion _convertToEnhanced(ExamQuestion basic) {
    return EnhancedExamQuestion(
      id: basic.id,
      type: basic.type,
      question: basic.question,
      answer: basic.answer,
      gradingCriteria: GradingCriteria(
        fullPoints: 5,
        rubric: '기본 채점 기준',
      ),
      explanation: DetailedExplanation(
        stepByStepSolution: '단계별 해설',
        grammarPoint: '문법 포인트',
        vocabularyNote: '어휘 설명',
        learningTip: '학습 팁',
        commonMistakes: ['일반적인 실수'],
      ),
      sourceChunkId: basic.sourceChunkId,
    );
  }

  /// Generate enhanced exam questions for premium users
  List<EnhancedExamQuestion> _generateEnhancedQuestions(
    List<Chunk> chunks,
    List<Word> targetWords,
    Map<QuestionType, int> questionCounts,
  ) {
    // 기본 구현으로 폴백
    final basicQuestions = _generateQuestions(chunks, targetWords, questionCounts);
    return basicQuestions.map((q) => _convertToEnhanced(q)).toList();
  }
}
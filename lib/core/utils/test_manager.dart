// lib/core/utils/test_manager.dart
import 'dart:math';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'test_result.dart';

enum TestType {
  chunk, // Gap-fill in paragraph
  word,  // Word-meaning matching
  mixed  // Both types
}

enum TestStatus {
  notStarted,
  inProgress,
  completed
}

/// 테스트 로직을 관리하는 클래스
/// 테스트 초기화, 채점, 진행 상태 추적 등 담당
class TestManager {
  // 데이터 모델
  final List<Chunk> chunks;
  final TestType testType;

  // 상태 변수
  int currentChunkIndex;
  bool isWordTestPhase;
  TestStatus testStatus = TestStatus.notStarted;
  DateTime? startTime;
  DateTime? endTime;

  // 테스트 데이터
  Map<String, String> correctGapMap = {};
  Map<String, String> userAnswers = {};
  List<Word> testWords = [];
  Map<String, String> selectedMeanings = {};
  Map<String, double> wordScores = {};

  // 테스트 결과 저장
  List<TestResult> results = [];
  Map<String, List<Map<String, dynamic>>> incorrectWords = {};

  TestManager({
    required this.chunks,
    required this.testType,
    this.currentChunkIndex = 0,
    this.isWordTestPhase = false,
  }) {
    startTime = DateTime.now();
  }

  /// 현재 테스트 초기화
  void initializeTest() {
    if (chunks.isEmpty) return;

    if (isWordTestPhase && (testType == TestType.word || testType == TestType.mixed)) {
      // 단어 테스트 준비
      _prepareWordTest();
    } else {
      // 단락 테스트 준비
      _prepareChunkTest();
    }

    testStatus = TestStatus.inProgress;
  }

  /// 단락 테스트 준비
  void _prepareChunkTest() {
    final currentChunk = chunks[currentChunkIndex];

    // 테스트할 단어 선택 (현재 단락에 있는 단어만 사용)
    testWords = List.from(currentChunk.includedWords);
    testWords.shuffle();

    // ||| 제거하고 단어 위치 찾기 및 빈칸 매핑 생성
    final cleanContent = currentChunk.englishContent
        .replaceAll('|||', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    correctGapMap = _findWordPositionsInText(cleanContent, testWords);

    // 사용자 응답 및 점수 초기화
    userAnswers = {};
    wordScores = {for (var word in testWords) word.english: 0.0};
  }

  /// 단어 테스트 준비
  void _prepareWordTest() {
    final currentChunk = chunks[currentChunkIndex];

    // 테스트할 단어 선택 (현재 단락 내 단어만 사용)
    testWords = List.from(currentChunk.includedWords);
    testWords.shuffle();

    // 사용자 응답 및 점수 초기화
    selectedMeanings = {};
    wordScores = {for (var word in testWords) word.english: 0.0};
  }

  /// 텍스트에서 단어 위치 찾기
  Map<String, String> _findWordPositionsInText(String text, List<Word> words) {
    Map<String, String> gaps = {};
    final lowerText = text.toLowerCase();

    for (var word in words) {
      final String targetWord = word.english.toLowerCase();

      if (word.english.contains(' ')) {
        // 복합 단어 처리
        final parts = word.english.split(' ');
        final pattern = parts.map((part) => RegExp.escape(part)).join(r'\s+');
        final regex = RegExp(pattern, caseSensitive: false);
        final match = regex.firstMatch(lowerText);

        if (match != null) {
          final gapId = 'gap_${word.english.replaceAll(' ', '_')}';
          gaps[gapId] = word.english;
        }
      } else {
        // 단일 단어 처리
        final wordForms = _generateWordForms(targetWord);

        bool found = false;
        for (var form in wordForms) {
          final pattern = r'\b' + RegExp.escape(form) + r'\b';
          final regex = RegExp(pattern, caseSensitive: false);
          final match = regex.firstMatch(lowerText);

          if (match != null) {
            final exactMatch = text.substring(match.start, match.end);
            final gapId = 'gap_${word.english.replaceAll(' ', '_')}';
            gaps[gapId] = exactMatch; // 찾은 정확한 형태를 사용
            found = true;
            break;
          }
        }
      }
    }

    return gaps;
  }

  /// 단어의 다양한 형태를 생성합니다 (복수형, 과거형 등)
  List<String> _generateWordForms(String word) {
    List<String> forms = [word]; // 기본 형태

    // 1. 단수/복수형
    // 실제로는 Pluralize 클래스를 사용하는 것이 좋지만,
    // 간단히 규칙적인 복수형만 처리
    if (word.endsWith('s')) {
      // 복수형일 가능성: cars -> car
      forms.add(word.substring(0, word.length - 1));
      // 복수형으로 es가 붙는 경우: boxes -> box
      if (word.endsWith('es')) {
        forms.add(word.substring(0, word.length - 2));
      }
    } else {
      // 단수형일 가능성: car -> cars
      forms.add('${word}s');
      // es 로 끝나는 복수형 처리: box -> boxes
      if (word.endsWith('x') || word.endsWith('ch') ||
          word.endsWith('sh') || word.endsWith('ss')) {
        forms.add('${word}es');
      }
      // 불규칙 y -> ies 복수형: story -> stories
      if (word.endsWith('y')) {
        forms.add('${word.substring(0, word.length - 1)}ies');
      }
    }

    // 2. 동사 변형 (ing, ed 형태)
    if (!word.endsWith('ing') && !word.endsWith('ed')) {
      // ing 형태 추가
      if (word.endsWith('e')) {
        // dance -> dancing (e 삭제)
        forms.add('${word.substring(0, word.length - 1)}ing');
      } else if (word.length > 2 &&
                !_isVowel(word[word.length - 1]) &&
                _isVowel(word[word.length - 2]) &&
                !_isVowel(word[word.length - 3])) {
        // 단음절 CVC 패턴에서 자음 중복: run -> running
        forms.add('${word}${word[word.length - 1]}ing');
      } else {
        // walk -> walking
        forms.add('${word}ing');
      }

      // ed 형태 추가
      if (word.endsWith('e')) {
        // dance -> danced
        forms.add('${word}d');
      } else if (word.length > 2 &&
                !_isVowel(word[word.length - 1]) &&
                _isVowel(word[word.length - 2]) &&
                !_isVowel(word[word.length - 3])) {
        // 단음절 CVC 패턴에서 자음 중복: stop -> stopped
        forms.add('${word}${word[word.length - 1]}ed');
      } else if (word.endsWith('y') && word.length > 1 && !_isVowel(word[word.length - 2])) {
        // 자음 + y로 끝나는 경우: try -> tried
        forms.add('${word.substring(0, word.length - 1)}ied');
      } else {
        // walk -> walked
        forms.add('${word}ed');
      }
    }

    // 3. ing/ed에서 기본형 복원
    if (word.endsWith('ing') && word.length > 3) {
      // running -> run
      String baseForm = word.substring(0, word.length - 3);
      forms.add(baseForm);
      // dancing -> dance (e 추가)
      forms.add('${baseForm}e');
      // running -> run (중복 자음 처리)
      if (baseForm.length > 1 && baseForm[baseForm.length - 1] == baseForm[baseForm.length - 2]) {
        forms.add(baseForm.substring(0, baseForm.length - 1));
      }
    } else if (word.endsWith('ed') && word.length > 2) {
      // walked -> walk
      String baseForm = word.substring(0, word.length - 2);
      forms.add(baseForm);
      // saved -> save (e 추가)
      forms.add('${baseForm}e');
      // stopped -> stop (중복 자음 처리)
      if (baseForm.length > 1 && baseForm[baseForm.length - 1] == baseForm[baseForm.length - 2]) {
        forms.add(baseForm.substring(0, baseForm.length - 1));
      }
      // tried -> try (ied -> y 처리)
      if (word.endsWith('ied')) {
        forms.add('${baseForm.substring(0, baseForm.length - 1)}y');
      }
    }

    return forms;
  }

  /// 주어진 문자가 모음인지 확인합니다
  bool _isVowel(String char) {
    return char.toLowerCase() == 'a' ||
           char.toLowerCase() == 'e' ||
           char.toLowerCase() == 'i' ||
           char.toLowerCase() == 'o' ||
           char.toLowerCase() == 'u';
  }

  /// 사용자가 입력한 형태가 정답 단어의 유효한 형태인지 확인합니다
  bool _isValidWordForm(String userAnswer, String correctWord) {
    // 두 단어 모두에 대해 가능한 형태 생성
    final userForms = _generateWordForms(userAnswer);
    final correctForms = _generateWordForms(correctWord);

    // 교집합 확인: 공통된 형태가 있으면 유효한 것으로 간주
    for (var uForm in userForms) {
      for (var cForm in correctForms) {
        if (uForm == cForm) {
          return true;
        }
      }
    }

    // 유사도 확인 (거의 비슷한 단어도 허용)
    final similarity = _calculateSimilarity(userAnswer, correctWord);
    return similarity > 0.8; // 80% 이상 비슷하면 허용
  }

  /// 현재 테스트 채점
  TestResult gradeTest() {
    int correctCount = 0;
    int totalCount = 0;
    List<String> incorrect = [];
    Map<String, Map<String, dynamic>> detailedIncorrect = {};

    if (isWordTestPhase || testType == TestType.word) {
      // 단어 테스트 채점
      totalCount = testWords.length;

      for (var word in testWords) {
        final selected = selectedMeanings[word.english];

        if (selected == word.korean) {
          correctCount++;
          wordScores[word.english] = 1.0;
        } else if (selected != null) {
          incorrect.add(word.english);

          // 오답 정보 저장
          detailedIncorrect[word.english] = {
            'word': word,
            'userAnswer': selected,
            'correctAnswer': word.korean,
            'explanation': chunks[currentChunkIndex].wordExplanations[word.english.toLowerCase()] ?? '',
          };

          // 부분 점수 계산
          final similarity = _calculateSimilarity(selected, word.korean);
          wordScores[word.english] = similarity > 0.5 ? similarity : 0.0;

          // 부분 점수가 충분히 높으면 정답으로 간주
          if (similarity > 0.8) correctCount++;
        } else {
          incorrect.add(word.english);

          // 오답 정보 저장 (무응답)
          detailedIncorrect[word.english] = {
            'word': word,
            'userAnswer': '(무응답)',
            'correctAnswer': word.korean,
            'explanation': chunks[currentChunkIndex].wordExplanations[word.english.toLowerCase()] ?? '',
          };

          wordScores[word.english] = 0.0;
        }
      }
    } else {
      // 단락 테스트 채점
      totalCount = correctGapMap.length;

      for (final entry in correctGapMap.entries) {
        final gapId = entry.key;
        final correctWord = entry.value;
        final userAnswer = userAnswers[gapId];

        if (userAnswer != null) {
          // 사용자 답변이 올바른 단어의 다른 형태인지 확인
          final userAnswerLower = userAnswer.toLowerCase();
          final correctWordLower = correctWord.toLowerCase();

          if (userAnswerLower == correctWordLower || _isValidWordForm(userAnswerLower, correctWordLower)) {
            correctCount++;
            wordScores[correctWord] = 1.0;
          } else {
            incorrect.add(correctWord);

            // 단어 객체 찾기
            final wordObj = testWords.firstWhere(
                    (w) => w.english.toLowerCase() == correctWord.toLowerCase(),
                orElse: () => Word(english: correctWord, korean: '')
            );

            // 오답 정보 저장
            detailedIncorrect[correctWord] = {
              'word': wordObj,
              'userAnswer': userAnswer,
              'correctAnswer': correctWord,
              'explanation': chunks[currentChunkIndex].wordExplanations[correctWord.toLowerCase()] ?? '',
            };

            // 부분 점수 계산
            final similarity = _calculateSimilarity(userAnswer, correctWord);
            wordScores[correctWord] = similarity > 0.5 ? similarity : 0.0;

            // 부분 점수가 충분히 높으면 정답으로 간주
            if (similarity > 0.8) correctCount++;
          }
        } else {
          incorrect.add(correctWord);

          // 단어 객체 찾기
          final wordObj = testWords.firstWhere(
                  (w) => w.english.toLowerCase() == correctWord.toLowerCase(),
              orElse: () => Word(english: correctWord, korean: '')
          );

          // 오답 정보 저장 (무응답)
          detailedIncorrect[correctWord] = {
            'word': wordObj,
            'userAnswer': '(무응답)',
            'correctAnswer': correctWord,
            'explanation': chunks[currentChunkIndex].wordExplanations[correctWord.toLowerCase()] ?? '',
          };

          wordScores[correctWord] = 0.0;
        }
      }
    }

    final accuracy = totalCount > 0 ? correctCount / totalCount : 0.0;

    // 테스트 결과 생성
    final result = TestResult(
      chunkTitle: chunks[currentChunkIndex].title,
      totalQuestions: totalCount,
      correctAnswers: correctCount,
      accuracy: accuracy,
      incorrectWords: incorrect,
      wordScores: Map.from(wordScores),
      testType: isWordTestPhase ? 'word' : 'chunk',
      detailedIncorrect: detailedIncorrect,
    );

    // 결과 저장
    results.add(result);

    // 틀린 단어를 단락별로 정리
    if (detailedIncorrect.isNotEmpty) {
      final chunkTitle = chunks[currentChunkIndex].title;
      
      // 복합 테스트의 경우 기존 오답에 추가, 아니면 새로 설정
      if (testType == TestType.mixed && incorrectWords.containsKey(chunkTitle)) {
        // 기존 오답 목록에 새로운 오답 추가
        incorrectWords[chunkTitle]!.addAll(detailedIncorrect.values.toList());
      } else {
        // 새로운 오답 목록 생성
        incorrectWords[chunkTitle] = detailedIncorrect.values.toList();
      }
    }

    return result;
  }

  /// 테스트 유사도 계산 (Levenshtein distance 기반)
  double _calculateSimilarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 1.0;

    // 소문자로 변환하여 비교
    final String s1 = a.toLowerCase();
    final String s2 = b.toLowerCase();

    // Levenshtein 거리 계산
    final int len1 = s1.length;
    final int len2 = s2.length;
    List<List<int>> d = List.generate(len1 + 1, (_) => List.filled(len2 + 1, 0));

    for (int i = 0; i <= len1; i++) {
      d[i][0] = i;
    }

    for (int j = 0; j <= len2; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        d[i][j] = min(
            min(d[i - 1][j] + 1, d[i][j - 1] + 1),
            d[i - 1][j - 1] + cost
        );
      }
    }

    // 최대 편집 거리
    final int maxDistance = max(len1, len2);
    if (maxDistance == 0) return 1.0;

    // 유사도 계산 (0.0 ~ 1.0)
    return 1.0 - (d[len1][len2] / maxDistance);
  }

  /// 다음 테스트로 이동
  bool moveToNextTest() {
    // 현재 스텝 결과 저장
    if (testStatus == TestStatus.inProgress) {
      gradeTest();
    }

    if (testType == TestType.mixed && !isWordTestPhase) {
      // 복합 테스트에서 단어 테스트로 전환
      isWordTestPhase = true;
      return true;
    } else if (currentChunkIndex < chunks.length - 1) {
      // 다음 청크로 이동
      currentChunkIndex++;
      isWordTestPhase = false;
      return true;
    }

    // 모든 테스트 완료
    testStatus = TestStatus.completed;
    endTime = DateTime.now();
    return false;
  }

  /// 모든 테스트 결과 반환
  List<Map<String, dynamic>> getAllResults() {
    return results.map((result) => result.toMap()).toList();
  }

  /// 모든 틀린 단어 반환
  Map<String, List<Map<String, dynamic>>> getAllIncorrectWords() {
    return incorrectWords;
  }

  /// 전체 테스트 소요 시간 계산 (초)
  int getTotalDuration() {
    if (startTime == null) return 0;
    final endDateTime = endTime ?? DateTime.now();
    return endDateTime.difference(startTime!).inSeconds;
  }

  /// 전체 정확도 계산
  double getOverallAccuracy() {
    if (results.isEmpty) return 0.0;

    int totalCorrect = 0;
    int totalQuestions = 0;

    for (var result in results) {
      totalCorrect += result.correctAnswers;
      totalQuestions += result.totalQuestions;
    }

    return totalQuestions > 0 ? totalCorrect / totalQuestions : 0.0;
  }

  /// 테스트 진행률 계산 (0.0 ~ 1.0)
  double getProgressPercentage() {
    if (chunks.isEmpty) return 0.0;

    // 전체 단계 수 계산
    int totalSteps = chunks.length;
    if (testType == TestType.mixed) {
      totalSteps *= 2; // 각 단락마다 두 번의 테스트 (단락, 단어)
    }

    // 현재 진행 단계 계산
    int currentStep = currentChunkIndex;
    if (testType == TestType.mixed) {
      currentStep = currentChunkIndex * 2 + (isWordTestPhase ? 1 : 0);
    }

    return currentStep / totalSteps;
  }
}
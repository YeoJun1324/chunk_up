// lib/screens/learning_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/learning_history_entry.dart'; // 불변 모델 추가
import 'package:chunk_up/domain/models/learning_session.dart'; // 불변 모델 추가
import 'package:chunk_up/domain/models/review_reminder.dart'; // 복습 알림 모델 추가
import 'package:chunk_up/core/utils/word_highlighter.dart';
import 'package:chunk_up/domain/services/review/review_service.dart'; // 복습 서비스 추가
import 'package:chunk_up/di/service_locator.dart'; // 의존성 주입
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:pluralize/pluralize.dart';
import 'package:chunk_up/domain/services/sentence/unified_sentence_mapping_service.dart';
import 'package:chunk_up/domain/models/sentence_pair.dart';
import 'package:get_it/get_it.dart';

enum TtsState { playing, stopped, paused }

class LearningScreen extends StatefulWidget {
  final List<Chunk> selectedChunks;
  final bool isReview; // 복습 모드 여부
  final String? reviewReminderId; // 복습 완료 처리를 위한 ID

  const LearningScreen({
    super.key,
    required this.selectedChunks,
    this.isReview = false,
    this.reviewReminderId,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  FlutterTts flutterTts = FlutterTts();
  int _currentChunkIndex = 0;
  int _currentSentenceIndex = 0;
  List<String> _currentSentences = [];
  List<String> _translatedSentences = [];
  List<SentencePair> _currentSentencePairs = [];
  TtsState _ttsState = TtsState.stopped;
  bool _isSentenceMode = true;
  final List<Map<String, dynamic>> _learningHistory = [];
  DateTime _startTime = DateTime.now();
  late final UnifiedSentenceMappingService _sentenceMappingService;

  @override
  void initState() {
    super.initState();
    _sentenceMappingService = GetIt.I<UnifiedSentenceMappingService>();
    _initTts();
    _prepareChunkForLearning();
    _startTime = DateTime.now();
  }

  void _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    // TTS 상태 변경 리스너 설정
    flutterTts.setStartHandler(() {
      setState(() {
        _ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        _ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((message) {
      setState(() {
        _ttsState = TtsState.stopped;
      });
      print('TTS 오류: $message');
    });
  }

  void _prepareChunkForLearning() {
    if (_currentChunkIndex >= widget.selectedChunks.length) {
      _finishLearning();
      return;
    }

    final currentChunk = widget.selectedChunks[_currentChunkIndex];

    // Use sentence mapping service to get sentence pairs
    _currentSentencePairs = _sentenceMappingService.extractSentencePairs(currentChunk);
    
    if (_currentSentencePairs.isNotEmpty) {
      // Extract sentences from pairs
      _currentSentences = _currentSentencePairs.map((pair) => pair.english).toList();
      _translatedSentences = _currentSentencePairs.map((pair) => pair.korean).toList();
    } else {
      // Fallback to old method if no pairs found
      _currentSentences = _splitIntoSentences(currentChunk.englishContent);
      
      try {
        _translatedSentences = _splitIntoSentences(currentChunk.koreanTranslation, isKorean: true);

        // 분할된 문장 수가 영어 문장 수와 다를 경우 대체 전략 적용
        if (_translatedSentences.length != _currentSentences.length) {
          // 비율에 따라 문장을 매핑
          if (_translatedSentences.length < _currentSentences.length) {
            // 한국어 문장이 적으면 마지막 문장을 반복
            while (_translatedSentences.length < _currentSentences.length) {
              _translatedSentences.add(_translatedSentences.isNotEmpty ? _translatedSentences.last : "번역 없음");
            }
          } else if (_translatedSentences.length > _currentSentences.length) {
            // 한국어 문장이 많으면 앞부분만 사용
            _translatedSentences = _translatedSentences.sublist(0, _currentSentences.length);
          }
        }
      } catch (e) {
        // 오류 발생 시 기본 메시지 표시
        _translatedSentences = List.generate(
            _currentSentences.length, (_) => "번역 문장 분리 오류");
      }
    }

    _currentSentenceIndex = 0;
  }

  // 문장 분리 헬퍼 메서드
  List<String> _splitIntoSentences(String text, {bool isKorean = false}) {
    // 일반적인 약어 목록
    final commonAbbreviations = [
      'Dr.', 'Mr.', 'Mrs.', 'Ms.', 'Prof.', 'Sr.', 'Jr.',
      'Ph.D.', 'M.D.', 'B.A.', 'M.A.', 'B.S.', 'M.S.',
      'i.e.', 'e.g.', 'vs.', 'etc.', 'Inc.', 'Ltd.', 'Co.',
      'Corp.', 'U.S.', 'U.K.', 'E.U.', 'U.N.',
    ];

    String processedText = text;

    // 약어를 임시 플레이스홀더로 대체
    Map<String, String> placeholders = {};
    int placeholderCount = 0;

    for (String abbr in commonAbbreviations) {
      if (processedText.contains(abbr)) {
        String placeholder = '<<<PLACEHOLDER_$placeholderCount>>>';
        placeholders[placeholder] = abbr;
        processedText = processedText.replaceAll(abbr, placeholder);
        placeholderCount++;
      }
    }

    // 소수점 처리 (숫자.숫자 패턴)
    processedText = processedText.replaceAllMapped(
        RegExp(r'(\d+)\.(\d+)'),
            (match) => '${match.group(1)}<<<DOT>>>${match.group(2)}'
    );

    // 문장 분리
    List<String> sentences = [];

    if (isKorean) {
      // 한국어의 경우
      sentences = processedText
          .split(RegExp(r'(?<=[.!?])\s*'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      // 영어의 경우
      sentences = processedText
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // 플레이스홀더를 원래 텍스트로 복원
    for (int i = 0; i < sentences.length; i++) {
      String sentence = sentences[i];

      // 약어 복원
      placeholders.forEach((placeholder, original) {
        sentence = sentence.replaceAll(placeholder, original);
      });

      // 소수점 복원
      sentence = sentence.replaceAll('<<<DOT>>>', '.');

      sentences[i] = sentence;
    }

    return sentences;
  }

  void _playCurrentSentence() async {
    if (_currentSentenceIndex >= _currentSentences.length) {
      return;
    }

    final currentSentence = _currentSentences[_currentSentenceIndex];

    // 현재 문장만 읽기
    await flutterTts.speak(currentSentence);
  }

  void _togglePlayPause() async {
    if (_ttsState == TtsState.playing) {
      await flutterTts.stop();
      setState(() {
        _ttsState = TtsState.stopped;
      });
    } else {
      _playCurrentSentence();
    }
  }

  void _moveToNextChunk() {
    setState(() {
      _currentChunkIndex++;
      _currentSentenceIndex = 0;
    });

    if (_currentChunkIndex < widget.selectedChunks.length) {
      _prepareChunkForLearning();
    } else {
      _finishLearning();
    }
  }

  /// 학습 완료 처리 - 불변성 패턴 적용
  void _finishLearning() async {
    await flutterTts.stop();
    setState(() {
      _ttsState = TtsState.stopped;
    });

    // 학습 시간 계산
    final learningDuration = DateTime.now().difference(_startTime);

    // 복습 서비스 인스턴스
    final reviewService = getIt<ReviewService>();

    // 복습 모드인 경우
    if (widget.isReview) {
      await _handleReviewCompletion(learningDuration);
      return;
    }

    // 일반 학습 모드: 학습 이력 저장 및 복습 일정 생성
    try {
      // 기존 이력 불러오기
      final prefs = await SharedPreferences.getInstance();
      final existingHistory = prefs.getStringList('learning_history') ?? [];

      // 불변 객체 생성
      final historyEntry = LearningHistoryEntry(
        date: DateTime.now(),
        chunkTitles: widget.selectedChunks.map((c) => c.title).toList(),
        wordCount: _getLearningWordCount(),
        durationMinutes: learningDuration.inMinutes,
        sentenceCount: _learningHistory.length,
      );

      // 불변성을 유지하며 목록에 추가
      final newHistoryList = List<String>.from(existingHistory)..add(historyEntry.toJsonString());

      // 저장
      await prefs.setStringList('learning_history', newHistoryList);

      // 망각 곡선에 따른 복습 알림 설정
      await _scheduleReviewReminders();

      // 학습 완료 다이얼로그 - 세련된 디자인
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // 바깥 영역 터치로 닫기 방지
          builder: (context) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final backgroundColor = isDarkMode ? const Color(0xFF333333) : Colors.white;
            final textColor = isDarkMode ? Colors.white : Colors.black87;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              backgroundColor: backgroundColor,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상단 성공 아이콘
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.orange,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 축하 타이틀
                    Text(
                      '축하합니다!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 학습 완료 메시지
                    Text(
                      '학습을 성공적으로 완료했습니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 학습 통계 박스
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black12 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildStatRow(
                            icon: Icons.menu_book,
                            label: '학습한 단락',
                            value: '${widget.selectedChunks.length}개',
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow(
                            icon: Icons.spellcheck,
                            label: '학습한 단어',
                            value: '${_getLearningWordCount()}개',
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow(
                            icon: Icons.timer,
                            label: '학습 시간',
                            value: '${learningDuration.inMinutes}분',
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 안내 메시지
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '학습 내용이 저장되었으며, 효과적인 학습을 위해 복습 알림이 자동으로 설정되었습니다.',
                              style: TextStyle(
                                color: isDarkMode ? Colors.blue.shade100 : Colors.blue.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 확인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ).then((_) => Navigator.pop(context));
      }
    } catch (e) {
      print('학습 이력 저장 오류: $e');
      // 오류 발생 시에도 화면은 닫음
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  /// 복습 완료 처리
  Future<void> _handleReviewCompletion(Duration learningDuration) async {
    try {
      final reviewService = getIt<ReviewService>();

      // 복습 알림 ID가 있는 경우 완료 처리
      if (widget.reviewReminderId != null) {
        await reviewService.markReminderAsCompleted(widget.reviewReminderId!);
      }

      // 복습 완료 이력 저장
      final prefs = await SharedPreferences.getInstance();
      final existingHistory = prefs.getStringList('review_history') ?? [];

      // 복습 기록 생성
      final reviewEntry = {
        'id': const Uuid().v4(),
        'date': DateTime.now().toIso8601String(),
        'chunkTitles': widget.selectedChunks.map((c) => c.title).toList(),
        'wordCount': _getLearningWordCount(),
        'durationMinutes': learningDuration.inMinutes,
        'reviewReminderId': widget.reviewReminderId,
      };

      // 목록에 추가
      final newHistoryList = List<String>.from(existingHistory)..add(jsonEncode(reviewEntry));
      await prefs.setStringList('review_history', newHistoryList);

      // 복습 완료 다이얼로그 - 세련된 디자인
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, // 바깥 영역 터치로 닫기 방지
          builder: (context) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            final backgroundColor = isDarkMode ? const Color(0xFF333333) : Colors.white;
            final textColor = isDarkMode ? Colors.white : Colors.black87;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              backgroundColor: backgroundColor,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상단 성공 아이콘
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        color: Colors.green,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 축하 타이틀
                    Text(
                      '잘하셨습니다!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 복습 완료 메시지
                    Text(
                      '복습을 성공적으로 완료했습니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 복습 통계 박스
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black12 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildStatRow(
                            icon: Icons.menu_book,
                            label: '복습한 단락',
                            value: '${widget.selectedChunks.length}개',
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow(
                            icon: Icons.spellcheck,
                            label: '복습한 단어',
                            value: '${_getLearningWordCount()}개',
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          _buildStatRow(
                            icon: Icons.timer,
                            label: '복습 시간',
                            value: '${learningDuration.inMinutes}분',
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 안내 메시지
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '복습을 완료하면 기억 유지 효과가 크게 증가합니다. 정기적인 복습은 장기 기억력을 향상시킵니다!',
                              style: TextStyle(
                                color: isDarkMode ? Colors.green.shade100 : Colors.green.shade800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 확인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ).then((_) => Navigator.pop(context));
      }
    } catch (e) {
      print('복습 완료 처리 오류: $e');
      // 오류 발생 시에도 화면은 닫음
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  int _getLearningWordCount() {
    // 학습한 고유 단어 수 계산
    final Set<String> uniqueWords = {};
    for (var chunk in widget.selectedChunks) {
      for (var word in chunk.includedWords) {
        uniqueWords.add(word.english);
      }
    }
    return uniqueWords.length;
  }

  // 통계 행을 표시하는 헬퍼 메서드
  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.orange,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  /// 망각 곡선에 따른 복습 일정 설정 - ReviewService 사용
  Future<void> _scheduleReviewReminders() async {
    try {
      // ReviewService를 사용하여 한 번에 모든 복습 단계 알림 생성
      final reviewService = getIt<ReviewService>();
      final reminders = await reviewService.scheduleAllReviewsForLearningSession(
        widget.selectedChunks,
        DateTime.now(),
      );

      debugPrint('${reminders.length}개의 복습 알림이 생성되었습니다.');

      // 오늘의 복습 알림 확인 (앱 시작 시 실행하는 것이 좋음)
      final hasTodayReminders = await reviewService.checkForTodaysReviews();
      if (hasTodayReminders) {
        debugPrint('오늘 예정된 복습이 있습니다!');

        // 복습 알림 전송
        await reviewService.sendDailyReviewNotifications();
      }
    } catch (e) {
      debugPrint('복습 일정 설정 중 오류 발생: $e');
      // 복습 일정 설정 실패는 앱 사용에 치명적이지 않으므로 조용히 실패
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  /// 문장에서 단어를 추출하는 헬퍼 메서드
  List<String> _extractWordsFromSentence(String sentence) {
    // 문장부호와 특수문자를 제거하고 단어만 추출
    final wordMatches = RegExp(r'\b[a-z]+\b').allMatches(sentence.toLowerCase());
    return wordMatches.map((m) => m.group(0)!).toList();
  }

  /// 두 단어가 같은 단어의 변형인지 확인하는 헬퍼 메서드
  bool _areWordVariations(String baseWord, String wordToCheck, Pluralize pluralize) {
    // 1. 완전히 동일한 경우
    if (baseWord == wordToCheck) return true;

    // 2. 복수형/단수형 확인
    final baseSingular = pluralize.singular(baseWord);
    final checkSingular = pluralize.singular(wordToCheck);

    if (baseSingular == checkSingular) return true;

    // 3. 동사 변형 확인 (ing, ed 등)
    // ing 형태 확인
    if (wordToCheck.endsWith('ing') && wordToCheck.length > 4) {
      String baseForm = wordToCheck.substring(0, wordToCheck.length - 3);

      // running -> run (중복된 자음 제거)
      if (baseForm.length >= 2 &&
          baseForm[baseForm.length - 1] == baseForm[baseForm.length - 2]) {
        baseForm = baseForm.substring(0, baseForm.length - 1);
      }

      if (baseForm == baseWord) return true;

      // dancing -> dance (e 추가)
      if (baseForm + 'e' == baseWord) return true;
    }

    // ed 형태 확인
    if (wordToCheck.endsWith('ed') && wordToCheck.length > 3) {
      String baseForm = wordToCheck.substring(0, wordToCheck.length - 2);

      if (baseForm == baseWord) return true;

      // added -> add (중복된 자음 제거)
      if (baseForm.length >= 2 &&
          baseForm[baseForm.length - 1] == baseForm[baseForm.length - 2]) {
        baseForm = baseForm.substring(0, baseForm.length - 1);
        if (baseForm == baseWord) return true;
      }

      // loved -> love (e 추가)
      if (baseForm + 'e' == baseWord) return true;
    }

    // er, est 형태 (비교급, 최상급) 확인
    if ((wordToCheck.endsWith('er') || wordToCheck.endsWith('est')) &&
        wordToCheck.length > 3) {
      String baseForm = wordToCheck.endsWith('er')
          ? wordToCheck.substring(0, wordToCheck.length - 2)
          : wordToCheck.substring(0, wordToCheck.length - 3);

      if (baseForm == baseWord) return true;

      // happier -> happy, nicest -> nice
      if (baseForm.endsWith('i')) {
        baseForm = baseForm.substring(0, baseForm.length - 1) + 'y';
        if (baseForm == baseWord) return true;
      }
    }

    // 5. 기본형에서 파생된 형태 확인
    // 기본형 -> ing 형태
    String ingForm;
    if (baseWord.endsWith('e')) {
      // dance -> dancing (e 삭제)
      ingForm = baseWord.substring(0, baseWord.length - 1) + 'ing';
    } else if (baseWord.length > 2 &&
              !_isVowel(baseWord[baseWord.length - 1]) &&
              _isVowel(baseWord[baseWord.length - 2]) &&
              !_isVowel(baseWord[baseWord.length - 3])) {
      // 단음절 CVC 패턴에서 자음 중복: run -> running
      ingForm = baseWord + baseWord[baseWord.length - 1] + 'ing';
    } else {
      // walk -> walking
      ingForm = baseWord + 'ing';
    }

    if (ingForm == wordToCheck) return true;

    // 기본형 -> ed 형태
    String edForm;
    if (baseWord.endsWith('e')) {
      // dance -> danced
      edForm = baseWord + 'd';
    } else if (baseWord.length > 2 &&
              !_isVowel(baseWord[baseWord.length - 1]) &&
              _isVowel(baseWord[baseWord.length - 2]) &&
              !_isVowel(baseWord[baseWord.length - 3])) {
      // 단음절 CVC 패턴에서 자음 중복: stop -> stopped
      edForm = baseWord + baseWord[baseWord.length - 1] + 'ed';
    } else if (baseWord.endsWith('y') && baseWord.length > 1 && !_isVowel(baseWord[baseWord.length - 2])) {
      // 자음 + y로 끝나는 경우: try -> tried
      edForm = baseWord.substring(0, baseWord.length - 1) + 'ied';
    } else {
      // walk -> walked
      edForm = baseWord + 'ed';
    }

    if (edForm == wordToCheck) return true;

    // 해당없음
    return false;
  }

  /// 주어진 문자가 모음인지 확인합니다
  bool _isVowel(String char) {
    return char.toLowerCase() == 'a' ||
           char.toLowerCase() == 'e' ||
           char.toLowerCase() == 'i' ||
           char.toLowerCase() == 'o' ||
           char.toLowerCase() == 'u';
  }
  
  Widget _buildWordExplanations(String sentence, Chunk chunk) {
    // 현재 문장에 포함된 단어 찾기
    final List<Word> wordsInSentence = [];
    final List<String> foundVariations = []; // 실제 발견된 변형 단어 저장

    final lowerSentence = sentence.toLowerCase();
    final sentenceWords = _extractWordsFromSentence(lowerSentence);

    for (var word in chunk.includedWords) {
      // 향상된 매칭 로직 사용
      final String targetWord = word.english.toLowerCase();

      // 복합 단어(공백 포함) 확인
      if (targetWord.contains(' ')) {
        final parts = targetWord.split(' ');
        final pattern = parts.map((part) => RegExp.escape(part)).join(r'\s+');
        final regex = RegExp(pattern, caseSensitive: false);

        if (regex.hasMatch(lowerSentence)) {
          wordsInSentence.add(word);
          // 복합 단어는 그대로 저장
          foundVariations.add(targetWord);
        }
      } else {
        // 단일 단어 매칭: 기본 단어 또는 변형된 형태 모두 검색
        bool isWordPresent = false;
        String foundVariation = targetWord; // 기본적으로 원래 단어로 설정

        // 1. 정확한 단어 매칭
        final exactPattern = r'\b' + RegExp.escape(targetWord) + r'\b';
        final exactRegex = RegExp(exactPattern, caseSensitive: false);
        if (exactRegex.hasMatch(lowerSentence)) {
          isWordPresent = true;
        } else {
          // 2. 문장에서 추출한 단어들과 비교
          // 각 단어와 가능한 변형 형태를 비교
          final pluralize = Pluralize();
          for (final sentenceWord in sentenceWords) {
            // 복수형/단수형 확인
            if (_areWordVariations(targetWord, sentenceWord, pluralize)) {
              isWordPresent = true;
              foundVariation = sentenceWord; // 실제 발견된 변형 저장
              break;
            }
          }
        }

        if (isWordPresent) {
          wordsInSentence.add(word);
          foundVariations.add(foundVariation);
        }
      }
    }

    if (wordsInSentence.isEmpty) {
      return const Text(
        '이 문장에는 학습 단어가 없습니다.',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(wordsInSentence.length, (index) {
        final word = wordsInSentence[index];
        final foundVariation = foundVariations[index];

        // 개선된 로직: 찾은 변형 단어로 설명 가져오기
        String? explanation = chunk.wordExplanations[foundVariation.toLowerCase()];

        // 설명이 없으면 getExplanationFor 메서드를 통해 기본 단어의 설명 가져오기
        if (explanation == null) {
          explanation = chunk.getExplanationFor(word.english);
        }

        return Builder(
          builder: (context) {
            // 다크 모드 감지
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isDarkMode ? const Color(0xFF3A3A3A) : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 첫 번째 줄: 단어와 뜻
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // 상단 정렬
                          children: [
                            // 영어 단어
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                // 기본 단어 대신 발견된 실제 변형을 표시
                                foundVariation != word.english.toLowerCase()
                                    ? foundVariation
                                    : word.english,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 한국어 의미
                            Expanded(
                              child: Text(
                                word.korean,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2, // 최대 2줄까지 표시
                              ),
                            ),
                          ],
                        ),

                        // 두 번째 줄: 단어 변형 정보 (필요한 경우에만 표시)
                        if (foundVariation != word.english.toLowerCase()) ...[
                          const SizedBox(height: 4),
                          Text(
                            "(${word.english}의 변형)",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (explanation != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDarkMode
                            ? Colors.grey.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          explanation,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentChunkIndex >= widget.selectedChunks.length) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentChunk = widget.selectedChunks[_currentChunkIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('학습: ${currentChunk.title}'),
        actions: [
          IconButton(
            icon: Icon(_isSentenceMode ? Icons.subject : Icons.short_text),
            tooltip: _isSentenceMode ? '전체 모드' : '문장 모드',
            onPressed: () {
              setState(() {
                _isSentenceMode = !_isSentenceMode;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 진행 상태 표시 - 더 정확한 계산
          LinearProgressIndicator(
            value: _calculateProgress(),
          ),

          // 현재 학습 정보
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '단락 ${_currentChunkIndex + 1}/${widget.selectedChunks.length}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '문장 ${_currentSentenceIndex + 1}/${_currentSentences.length}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 현재 문장 또는 전체 텍스트
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _isSentenceMode
                  ? _buildCurrentSentence()
                  : _buildFullText(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                tooltip: '이전',
                onPressed: _currentSentenceIndex > 0 || _currentChunkIndex > 0
                    ? () {
                  setState(() {
                    if (_currentSentenceIndex > 0) {
                      _currentSentenceIndex--;
                    } else if (_currentChunkIndex > 0) {
                      _currentChunkIndex--;
                      _prepareChunkForLearning();
                      _currentSentenceIndex = _currentSentences.length - 1;
                    }
                  });
                }
                    : null,
              ),
              IconButton(
                icon: Icon(_ttsState == TtsState.playing ? Icons.pause : Icons.play_arrow),
                tooltip: _ttsState == TtsState.playing ? '일시정지' : '재생',
                iconSize: 36,
                onPressed: _togglePlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                tooltip: '다음',
                onPressed: () {
                  setState(() {
                    if (_currentSentenceIndex < _currentSentences.length - 1) {
                      _currentSentenceIndex++;
                    } else {
                      _moveToNextChunk();
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 학습 진행도 계산 함수 개선
  double _calculateProgress() {
    if (widget.selectedChunks.isEmpty) return 0.0;

    // 이전 청크들의 모든 문장 수
    int totalPreviousSentences = 0;
    for (int i = 0; i < _currentChunkIndex; i++) {
      final chunk = widget.selectedChunks[i];
      final sentences = _splitIntoSentences(chunk.englishContent).length;
      totalPreviousSentences += sentences;
    }

    // 현재 청크의 완료된 문장 수
    int currentCompletedSentences = _currentSentenceIndex;

    // 모든 청크의 총 문장 수
    int totalSentences = totalPreviousSentences;
    for (int i = _currentChunkIndex; i < widget.selectedChunks.length; i++) {
      final chunk = widget.selectedChunks[i];
      final sentences = _splitIntoSentences(chunk.englishContent).length;
      totalSentences += sentences;
    }

    // 진행률 계산
    return (totalPreviousSentences + currentCompletedSentences) / totalSentences;
  }

  Widget _buildCurrentSentence() {
    if (_currentSentenceIndex >= _currentSentences.length) {
      return const SizedBox();
    }

    final currentSentence = _currentSentences[_currentSentenceIndex];
    String translatedSentence = '';

    if (_currentSentenceIndex < _translatedSentences.length) {
      translatedSentence = _translatedSentences[_currentSentenceIndex];
    }

    final currentChunk = widget.selectedChunks[_currentChunkIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '영어 문장:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            // 다크 모드 감지
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF383838) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
              ),
              child: WordHighlighter.buildHighlightedText(
                text: currentSentence,
                highlightWords: currentChunk.includedWords,
                highlightColor: Colors.orange,
                textColor: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          '한국어 해석:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            // 다크 모드 감지
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF383838) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
              ),
              child: Text(
                translatedSentence,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.left,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          '단어 해설:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildWordExplanations(currentSentence, currentChunk),
      ],
    );
  }

  Widget _buildFullText() {
    final currentChunk = widget.selectedChunks[_currentChunkIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '영어 단락:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            // 다크 모드 감지
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF383838) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
              ),
              child: WordHighlighter.buildHighlightedText(
                text: currentChunk.englishContent,
                highlightWords: currentChunk.includedWords,
                highlightColor: Colors.orange,
                textColor: isDarkMode ? Colors.white : Colors.black87,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          '한국어 해석:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            // 다크 모드 감지
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF383838) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                ),
              ),
              child: Text(
                currentChunk.koreanTranslation,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.left,
              ),
            );
          },
        ),
      ],
    );
  }
}
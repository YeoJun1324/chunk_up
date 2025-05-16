// lib/screens/chunk_test_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/core/utils/test_manager.dart';
import 'package:chunk_up/core/utils/test_result.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:ui' as ui;

class ChunkTestScreen extends StatefulWidget {
  final List<Chunk> chunks;
  final TestType testType;
  final Function(List<Map<String, dynamic>>)? onTestComplete;

  const ChunkTestScreen({
    super.key,
    required this.chunks,
    this.testType = TestType.mixed,
    this.onTestComplete,
  });

  @override
  State<ChunkTestScreen> createState() => _ChunkTestScreenState();
}

class _ChunkTestScreenState extends State<ChunkTestScreen> {
  late TestManager _testManager;
  bool _isTestInProgress = true;
  DateTime _startTime = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  // 새로운 상태 변수
  List<TestResult>? _allResults;
  Map<String, List<Map<String, dynamic>>>? _incorrectWords;
  int _totalDuration = 0;
  double _overallAccuracy = 0.0;

  // 오답 노트 관련 상태
  bool _isAddingToMistakeList = false;
  bool _addedToMistakeList = false;

  // Bottom Sheet 상태
  final bool _isBottomSheetExpanded = true;
  final double _bottomSheetMinHeight = 55.0;
  final double _bottomSheetMaxHeight = 55.0;
  
  // 스크롤바 관련 상태
  double _scrollPosition = 0.0;
  double _containerWidth = 0.0;
  double _contentWidth = 0.0;
  double _thumbWidth = 40.0;
  double _scrollbarHeight = 4.0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initializeTest();
    
    // 스크롤 위치 변경 감지
    _scrollController.addListener(_updateScrollInfo);
    
    // 레이아웃이 완성된 후 스크롤바 크기 계산을 위한 콜백
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateScrollbarDimensions();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollInfo);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _calculateScrollbarDimensions() {
    if (_scrollController.hasClients) {
      final double viewportWidth = _scrollController.position.viewportDimension;
      final double maxScrollExtent = _scrollController.position.maxScrollExtent;
      final double contentWidth = viewportWidth + maxScrollExtent;
      
      setState(() {
        _containerWidth = viewportWidth;
        _contentWidth = contentWidth;
        
        // 컨텐츠 대비 뷰포트 비율에 따라 스크롤바 크기 계산
        if (contentWidth > 0 && viewportWidth > 0) {
          final double ratio = viewportWidth / contentWidth;
          _thumbWidth = max(20.0, viewportWidth * ratio); // 최소 너비 20
        }
        
        _updateScrollInfo();
      });
    }
  }
  
  void _updateScrollInfo() {
    if (_scrollController.hasClients) {
      final double viewportWidth = _scrollController.position.viewportDimension;
      final double maxScrollExtent = _scrollController.position.maxScrollExtent;
      final double currentOffset = _scrollController.offset;
      
      // 스크롤 가능 여부 확인
      setState(() {
        _canScrollLeft = currentOffset > 0;
        _canScrollRight = currentOffset < maxScrollExtent;
        
        // 스크롤바 위치 계산
        if (maxScrollExtent > 0) {
          _scrollPosition = (currentOffset / maxScrollExtent) * (viewportWidth - _thumbWidth);
        } else {
          _scrollPosition = 0;
        }
      });
    }
  }
  
  // 스크롤바 드래그 처리
  void _handleScrollThumbDrag(DragUpdateDetails details) {
    if (_scrollController.hasClients) {
      final double viewportWidth = _scrollController.position.viewportDimension;
      final double maxScrollExtent = _scrollController.position.maxScrollExtent;
      
      // 스크롤바의 드래그에 따라 스크롤 위치 계산 및 적용
      if (viewportWidth > _thumbWidth && maxScrollExtent > 0) {
        final double dragPixels = details.delta.dx;
        final double dragRatio = dragPixels / (viewportWidth - _thumbWidth);
        final double scrollPixels = dragRatio * maxScrollExtent;
        
        _scrollController.jumpTo(
          (_scrollController.offset + scrollPixels).clamp(0.0, maxScrollExtent)
        );
      }
    }
  }

  void _initializeTest() {
    _testManager = TestManager(
      chunks: widget.chunks,
      testType: widget.testType,
    );

    _testManager.initializeTest();
  }

  void _finishTest() {
    setState(() {
      _isTestInProgress = false;
      _allResults = _testManager.results;
      _incorrectWords = _testManager.getAllIncorrectWords();
      _totalDuration = _testManager.getTotalDuration();
      _overallAccuracy = _testManager.getOverallAccuracy();
    });

    _saveTestResults();

    if (widget.onTestComplete != null) {
      widget.onTestComplete!(_testManager.getAllResults());
    }
  }

  Future<void> _saveTestResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('test_history') ?? [];

      final newResult = {
        'date': DateTime.now().toIso8601String(),
        'testType': widget.testType.toString().split('.').last,
        'chunks': widget.chunks.map((c) => c.title).toList(),
        'accuracy': _overallAccuracy,
        'totalQuestions': _calculateTotalQuestions(),
        'correctAnswers': _calculateTotalCorrectAnswers(),
        'durationSeconds': _totalDuration,
        'timestamp': DateTime.now().toIso8601String(),
      };

      historyJson.add(jsonEncode(newResult));
      await prefs.setStringList('test_history', historyJson);
    } catch (e) {
      print('테스트 결과 저장 오류: $e');
    }
  }

  int _calculateTotalQuestions() {
    int total = 0;
    for (var result in _testManager.results) {
      total += result.totalQuestions;
    }
    return total;
  }

  int _calculateTotalCorrectAnswers() {
    int total = 0;
    for (var result in _testManager.results) {
      total += result.correctAnswers;
    }
    return total;
  }

  void _moveToNextTest() {
    if (_testManager.moveToNextTest()) {
      _testManager.initializeTest();
      setState(() {});
    } else {
      _finishTest();
    }
  }

  Widget _buildProgressBar() {
    final progress = _testManager.getProgressPercentage();

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          minHeight: 6,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '진행률: ${(progress * 100).toInt()}%',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                '단락 ${_testManager.currentChunkIndex + 1}/${widget.chunks.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChunkTestView() {
    final currentChunk = widget.chunks[_testManager.currentChunkIndex];
    String processedParagraph = currentChunk.englishContent;

    // 각 빈칸 위치에 gapId로 대체
    for (final entry in _testManager.correctGapMap.entries) {
      final gapId = entry.key;
      final word = entry.value;

      final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
      final match = pattern.firstMatch(processedParagraph);

      if (match != null) {
        processedParagraph = processedParagraph.replaceRange(
            match.start,
            match.end,
            gapId
        );
      }
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '빈칸에 알맞은 단어를 드래그해서 넣으세요:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF333333)
                      : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300),
                  ),
                  child: _buildDraggableParagraph(processedParagraph),
                ),
              ],
            ),
          ),
        ),

        // Bottom Sheet 스타일의 드래그 가능한 단어 영역 및 스크롤 표시기
        SizedBox(
          height: _bottomSheetMinHeight + 10, // 스크롤바 높이 추가
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: _bottomSheetMinHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                    ? Color(0xFF333333)
                    : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    // 스크롤 이벤트 발생시 스크롤바 크기 재계산
                    if (notification is ScrollEndNotification) {
                      _calculateScrollbarDimensions();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    key: const PageStorageKey('word-list'),
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _testManager.testWords.length,
                    itemBuilder: (context, index) {
                      final word = _testManager.testWords[index];
                      final isSelected = _testManager.userAnswers.containsValue(word.english);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                        child: Draggable<Word>(
                          data: word,
                          dragAnchorStrategy: pointerDragAnchorStrategy,
                          feedback: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.orange
                                  : Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                word.english,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400
                              ),
                            ),
                            child: Text(
                              word.english,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
                              ),
                            ),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade200)
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.orange.shade100),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? (Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400)
                                    : (Theme.of(context).brightness == Brightness.dark
                                        ? Colors.orange.withOpacity(0.5)
                                        : Colors.orange.withOpacity(0.3)),
                              ),
                            ),
                            child: Text(
                              word.english,
                              style: TextStyle(
                                color: isSelected
                                  ? Colors.grey.shade600
                                  : Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: isSelected ? FontWeight.normal : FontWeight.bold,
                                decoration: isSelected ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // 커스텀 스크롤바
              if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0)
                Container(
                  height: 10,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      // 스크롤바 트랙
                      Container(
                        height: _scrollbarHeight,
                        width: _containerWidth,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(_scrollbarHeight / 2),
                        ),
                      ),
                      // 스크롤바 썸(thumb)
                      Positioned(
                        left: _scrollPosition,
                        child: GestureDetector(
                          onHorizontalDragUpdate: _handleScrollThumbDrag,
                          child: Container(
                            height: _scrollbarHeight,
                            width: _thumbWidth,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(_scrollbarHeight / 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableParagraph(String processedParagraph) {
    final List<String> parts = [];
    final pattern = RegExp(r'gap_[a-zA-Z0-9_]+');

    int lastEnd = 0;
    for (final match in pattern.allMatches(processedParagraph)) {
      if (match.start > lastEnd) {
        parts.add(processedParagraph.substring(lastEnd, match.start));
      }
      parts.add(match.group(0)!);
      lastEnd = match.end;
    }

    if (lastEnd < processedParagraph.length) {
      parts.add(processedParagraph.substring(lastEnd));
    }

    final List<InlineSpan> spans = [];

    for (final part in parts) {
      if (_testManager.correctGapMap.containsKey(part)) {
        final correctWord = _testManager.correctGapMap[part]!;
        final selectedWord = _testManager.userAnswers[part];

        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: DragTarget<Word>(
              onWillAcceptWithDetails: (data) => true,
              onAcceptWithDetails: (data) {
                setState(() {
                  _testManager.userAnswers.removeWhere((key, value) => value == data.data.english);
                  _testManager.userAnswers[part] = data.data.english;
                });
              },
              builder: (context, candidateData, rejectedData) {
                final bool isHovering = candidateData.isNotEmpty;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHovering
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.orange.shade50)
                        : selectedWord != null
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.withOpacity(0.3)
                            : Colors.blue.shade50)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isHovering
                          ? Colors.orange
                          : selectedWord != null
                          ? Colors.blue
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400),
                      width: isHovering ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selectedWord != null) ...[
                        Text(
                          selectedWord,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _testManager.userAnswers.remove(part);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ] else
                        Text(
                          '_'.padRight(correctWord.length, '_'),
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey,
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      } else {
        spans.add(TextSpan(
          text: part,
          style: const TextStyle(fontSize: 16, height: 1.8),
        ));
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
          fontSize: 16,
          height: 1.8,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildWordTestView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _testManager.testWords.length,
      itemBuilder: (context, index) {
        final word = _testManager.testWords[index];
        final selectedMeaning = _testManager.selectedMeanings[word.english];

        final currentChunk = widget.chunks[_testManager.currentChunkIndex];
        List<String> options = [word.korean];

        final List<String> otherMeanings = currentChunk.includedWords
            .where((w) => w.english != word.english)
            .map((w) => w.korean)
            .toList();

        final dummyOptions = [
          '${word.korean}와 유사한 의미',
          '관련 없는 의미',
          '다른 용도의 단어',
          '일반적인 ${word.korean}',
          '${word.korean}의 반대 의미',
        ];

        while (options.length < 4) {
          if (otherMeanings.isNotEmpty) {
            final meaning = otherMeanings.removeAt(0);
            if (!options.contains(meaning)) {
              options.add(meaning);
            }
          } else if (options.length < 4) {
            final dummyOption = dummyOptions[options.length - 1];
            options.add(dummyOption);
          }
        }

        final random = Random(word.english.hashCode);
        final List<String> shuffledOptions = List.from(options);
        shuffledOptions.shuffle(random);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF333333) : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${word.english}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...shuffledOptions.map((option) {
                  final isSelected = selectedMeaning == option;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.orange.shade100)
                        : (Theme.of(context).brightness == Brightness.dark
                            ? Color(0xFF3D3D3D)
                            : Colors.white),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                          ? Colors.orange
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      title: Text(
                        option,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : null,
                        ),
                      ),
                      value: option,
                      groupValue: selectedMeaning,
                      onChanged: (value) {
                        setState(() {
                          _testManager.selectedMeanings[word.english] = value ?? '';
                        });
                      },
                      activeColor: Colors.orange,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestResultView() {
    if (_allResults == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 점수 섹션
          Card(
            elevation: 2,
            color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF333333) : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '테스트 결과',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(_overallAccuracy * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '등급: ${_getGradeFromAccuracy(_overallAccuracy)}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            '${_calculateTotalCorrectAnswers()}/${_calculateTotalQuestions()} 문제',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getFeedbackMessage(_overallAccuracy),
                    style: TextStyle(
                      fontSize: 18,
                      color: _getColorFromAccuracy(_overallAccuracy),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '소요 시간: ${_formatDuration(_totalDuration)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 테스트 유형 표시
          Card(
            color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF333333) : null,
            child: ListTile(
              leading: Icon(
                widget.testType == TestType.chunk ? Icons.notes :
                widget.testType == TestType.word ? Icons.text_fields :
                Icons.merge_type,
                color: Colors.orange,
              ),
              title: Text(
                '테스트 유형: ${_getTestTypeDisplayName(widget.testType)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('총 ${widget.chunks.length}개 단락'),
            ),
          ),

          const SizedBox(height: 24),

          // 오답 목록과 해설
          if (_incorrectWords != null && _incorrectWords!.isNotEmpty) ...[
            const Text(
              '오답 및 해설',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ..._incorrectWords!.entries.map((entry) {
              final chunkTitle = entry.key;
              final incorrectList = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.orange.shade900.withOpacity(0.3)
                        : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.orange.shade700
                        : Colors.orange.shade200),
                    ),
                    child: Text(
                      '단락: $chunkTitle',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...incorrectList.map((item) {
                    final word = item['word'] as Word;
                    final userAnswer = item['userAnswer'];
                    final correctAnswer = item['correctAnswer'];
                    final explanation = item['explanation'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF333333) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  word.english,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('당신의 답:'),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.red.shade900.withOpacity(0.3)
                                            : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.red.shade700
                                            : Colors.red.shade200),
                                        ),
                                        child: Text(
                                          userAnswer,
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('정답:'),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.green.shade900.withOpacity(0.3)
                                            : Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.green.shade700
                                            : Colors.green.shade200),
                                        ),
                                        child: Text(
                                          correctAnswer,
                                          style: TextStyle(
                                            color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (explanation.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                '단어 해설:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade900.withOpacity(0.3)
                                    : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.blue.shade700
                                    : Colors.blue.shade200),
                                ),
                                child: Text(
                                  explanation,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : null,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],

          const SizedBox(height: 24),

          // 오답 노트 생성 버튼
          if (_incorrectWords != null && _incorrectWords!.isNotEmpty && !_addedToMistakeList)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.note_add),
                label: _isAddingToMistakeList
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('오답 노트에 추가 중...'),
                        ],
                      )
                    : const Text('틀린 단어를 오답 노트에 추가하기'),
                onPressed: _isAddingToMistakeList
                    ? null
                    : () => _addMistakesToWordList(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

          // 오답 노트 생성 완료 메시지
          if (_addedToMistakeList)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '틀린 단어가 오답 노트 단어장에 추가되었습니다!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('홈으로 돌아가기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTestTypeDisplayName(TestType type) {
    switch (type) {
      case TestType.chunk:
        return '단락 테스트';
      case TestType.word:
        return '단어 테스트';
      case TestType.mixed:
        return '복합 테스트';
    }
  }

  String _getGradeFromAccuracy(double accuracy) {
    if (accuracy >= 0.9) return 'A';
    if (accuracy >= 0.8) return 'B';
    if (accuracy >= 0.7) return 'C';
    if (accuracy >= 0.6) return 'D';
    return 'F';
  }

  Color _getColorFromAccuracy(double accuracy) {
    if (accuracy >= 0.9) return Colors.green;
    if (accuracy >= 0.7) return Colors.blue;
    if (accuracy >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _getFeedbackMessage(double accuracy) {
    if (accuracy >= 0.9) {
      return '훌륭해요! 완벽에 가까운 점수입니다.';
    } else if (accuracy >= 0.7) {
      return '잘했어요! 대부분의 단어를 잘 알고 있네요.';
    } else if (accuracy >= 0.5) {
      return '좋아요. 조금 더 학습이 필요합니다.';
    } else {
      return '더 많은 연습이 필요합니다. 다시 도전해보세요!';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes > 0) {
      return '$minutes분 $remainingSeconds초';
    } else {
      return '$seconds초';
    }
  }

  /// 오답 노트에 틀린 단어들 추가
  Future<void> _addMistakesToWordList(BuildContext context) async {
    setState(() {
      _isAddingToMistakeList = true;
    });

    try {
      // WordListNotifier 가져오기
      final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);

      // 틀린 단어들 수집
      final List<Word> mistakeWords = [];

      if (_incorrectWords != null) {
        // 모든 단락의 틀린 단어들을 순회
        for (final chunkTitle in _incorrectWords!.keys) {
          final incorrectListForChunk = _incorrectWords![chunkTitle] ?? [];

          for (final item in incorrectListForChunk) {
            if (item.containsKey('word')) {
              final Word word = item['word'];
              mistakeWords.add(word);
            }
          }
        }
      }

      // 오답 노트에 단어 추가
      await wordListNotifier.addMistakesToWordList(mistakeWords);

      setState(() {
        _isAddingToMistakeList = false;
        _addedToMistakeList = true;
      });
    } catch (e) {
      // 오류 처리
      setState(() {
        _isAddingToMistakeList = false;
      });

      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오답 노트 생성 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isAllAnswered() {
    if (_testManager.isWordTestPhase || widget.testType == TestType.word) {
      return _testManager.testWords.every(
              (word) => _testManager.selectedMeanings.containsKey(word.english));
    } else {
      return _testManager.correctGapMap.keys.every(
              (gapId) => _testManager.userAnswers.containsKey(gapId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isTestInProgress) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
              widget.chunks.length > 1
                  ? '테스트 (${_testManager.currentChunkIndex + 1}/${widget.chunks.length})'
                  : widget.chunks[_testManager.currentChunkIndex].title
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildProgressBar(),
              Expanded(
                child: _testManager.isWordTestPhase || widget.testType == TestType.word
                    ? _buildWordTestView()
                    : _buildChunkTestView(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF333333) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isAllAnswered() ? _moveToNextTest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
                  disabledForegroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('다음'),
              ),
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('테스트 결과'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: _buildTestResultView(),
        ),
      );
    }
  }
}
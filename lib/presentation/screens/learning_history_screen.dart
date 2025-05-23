// lib/presentation/screens/learning_history_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:chunk_up/domain/models/learning_history_entry.dart';
import 'package:chunk_up/domain/models/review_reminder.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/core/services/review_service.dart';
import 'package:chunk_up/core/services/notification_service.dart'; // 알림 서비스 추가
import 'package:chunk_up/di/service_locator.dart'; // 의존성 주입 추가
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/presentation/screens/learning_screen.dart';

class LearningHistoryScreen extends StatefulWidget {
  final int initialTab; // 초기 탭 인덱스
  final String? reviewId; // 특정 복습 ID (알림에서 열 때 사용)

  const LearningHistoryScreen({
    Key? key,
    this.initialTab = 0,
    this.reviewId,
  }) : super(key: key);

  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LearningHistoryEntry> _learningHistory = [];
  List<Map<String, dynamic>> _testHistory = [];
  List<ReviewReminder> _reviewReminders = [];
  bool _isLoading = true;
  late ReviewService _reviewService;

  @override
  void initState() {
    super.initState();
    _reviewService = getIt<ReviewService>();
    _tabController = TabController(length: 3, vsync: this); // 탭이 3개로 변경 (학습, 테스트, 복습)

    // 초기 탭 인덱스 설정 (알림에서 열 때 사용)
    if (widget.initialTab > 0 && widget.initialTab < 3) {
      _tabController.index = widget.initialTab;
    }

    _loadHistory().then((_) {
      // 특정 복습 ID가 있으면 해당 항목을 찾아 하이라이트
      if (widget.reviewId != null) {
        _showReminderByIdAfterLoad(widget.reviewId!);
      }
    });
  }

  // 알림에서 열리거나 특정 ID로 접근했을 때 해당 항목 찾기
  void _showReminderByIdAfterLoad(String reminderId) {
    // 복습 탭으로 이동
    _tabController.animateTo(2); // 복습 탭 인덱스

    // 해당 ID의 리마인더 찾기
    final reminder = _reviewReminders.firstWhere(
      (r) => r.id == reminderId,
      orElse: () => _reviewReminders.firstOrNull ?? ReviewReminder(
        id: 'not_found',
        originalLearningDate: DateTime.now(),
        scheduledReviewDate: DateTime.now(),
        chunkIds: [],
        chunkTitles: [],
        reviewStage: 1,
      ),
    );

    // 없으면 그냥 리턴
    if (reminder.id == 'not_found') {
      return;
    }

    // 해당 항목 하이라이트하는 팝업 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('복습 알림'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('복습 대상: ${reminder.chunkTitles.join(', ')}'),
              const SizedBox(height: 8),
              Text('복습 단계: ${reminder.reviewStage}단계'),
              const SizedBox(height: 16),
              const Text('지금 복습을 시작하시겠습니까?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('나중에'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _startReviewFromReminder(reminder);
              },
              child: const Text('복습 시작'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // 학습 기록 로드 (개선된 방식으로 JSON 파싱)
      final learningHistoryJson = prefs.getStringList('learning_history') ?? [];
      final List<LearningHistoryEntry> learningHistory = [];

      for (var entry in learningHistoryJson) {
        try {
          // 정상적인 JSON 파싱 시도
          final historyEntry = LearningHistoryEntry.fromJsonString(entry);
          learningHistory.add(historyEntry);
        } catch (e) {
          // 이전 형식 호환을 위한 수동 파싱
          try {
            final Map<String, dynamic> historyMap = {};
            final cleanEntry = entry
                .replaceAll('{', '')
                .replaceAll('}', '')
                .split(',');

            for (var item in cleanEntry) {
              final parts = item.split(':');
              if (parts.length >= 2) {
                final key = parts[0].trim();
                final value = parts.sublist(1).join(':').trim();
                historyMap[key] = value;
              }
            }

            // 필수 필드 확인
            if (historyMap.containsKey('date')) {
              final date = DateTime.parse(historyMap['date']);

              // 필드 변환
              final wordCount = int.tryParse(historyMap['wordCount'] ?? '0') ?? 0;
              final durationMinutes = int.tryParse(historyMap['durationMinutes'] ?? '0') ?? 0;
              final sentenceCount = int.tryParse(historyMap['sentenceCount'] ?? '0') ?? 0;

              // 청크 제목 목록 - 문자열을 리스트로 변환
              List<String> chunkTitles = [];
              if (historyMap.containsKey('chunkTitles')) {
                final titlesStr = historyMap['chunkTitles'];
                if (titlesStr.startsWith('[') && titlesStr.endsWith(']')) {
                  final cleanTitles = titlesStr
                      .substring(1, titlesStr.length - 1)
                      .split(',')
                      .map((s) => s.trim().replaceAll('"', ''))
                      .toList();
                  chunkTitles = cleanTitles;
                }
              }

              // 청크 ID 목록 - 나중에 필요할 수 있으므로 추가
              List<String> chunkIds = [];
              if (historyMap.containsKey('chunkIds')) {
                final idsStr = historyMap['chunkIds'];
                if (idsStr.startsWith('[') && idsStr.endsWith(']')) {
                  final cleanIds = idsStr
                      .substring(1, idsStr.length - 1)
                      .split(',')
                      .map((s) => s.trim().replaceAll('"', ''))
                      .toList();
                  chunkIds = cleanIds;
                }
              }

              // 학습 기록 객체 생성
              final historyEntry = LearningHistoryEntry(
                date: date,
                chunkTitles: chunkTitles,
                wordCount: wordCount,
                durationMinutes: durationMinutes,
                sentenceCount: sentenceCount,
              );

              learningHistory.add(historyEntry);
            }
          } catch (innerError) {
            print('학습 기록 파싱 심각한 오류: $innerError');
          }
        }
      }

      // 날짜별로 정렬 (최신순)
      learningHistory.sort((a, b) => b.date.compareTo(a.date));

      // 테스트 기록 로드
      final testHistoryJson = prefs.getStringList('test_history') ?? [];
      final List<Map<String, dynamic>> testHistory = [];

      for (var entry in testHistoryJson) {
        try {
          // 먼저 JSON 파싱 시도
          final historyMap = jsonDecode(entry) as Map<String, dynamic>;
          if (historyMap.containsKey('date') || historyMap.containsKey('timestamp')) {
            // date 필드가 있으면 그것을 사용, 없으면 timestamp 필드 사용
            final dateStr = historyMap['date'] as String? ?? historyMap['timestamp'] as String?;
            if (dateStr != null) {
              historyMap['dateObj'] = DateTime.parse(dateStr);
              testHistory.add(historyMap);
            }
          }
        } catch (e) {
          // 이전 형식 호환을 위한 수동 파싱
          try {
            final Map<String, dynamic> historyMap = {};
            final cleanEntry = entry
                .replaceAll('{', '')
                .replaceAll('}', '')
                .split(',');

            for (var item in cleanEntry) {
              final parts = item.split(':');
              if (parts.length >= 2) {
                final key = parts[0].trim();
                final value = parts[1].trim();
                historyMap[key] = value;
              }
            }

            if (historyMap.containsKey('date')) {
              historyMap['dateObj'] = DateTime.parse(historyMap['date']);
              testHistory.add(historyMap);
            }
          } catch (innerError) {
            print('테스트 기록 파싱 오류: $innerError');
          }
        }
      }

      // 날짜별로 정렬 (최신순)
      testHistory.sort((a, b) => (b['dateObj'] as DateTime).compareTo(a['dateObj'] as DateTime));

      // 복습 알림 로드
      final reviewReminders = await _reviewService.getAllReminders();
      // 날짜별로 정렬 (예정일 기준 최신순)
      reviewReminders.sort((a, b) => b.scheduledReviewDate.compareTo(a.scheduledReviewDate));

      setState(() {
        _learningHistory = learningHistory;
        _testHistory = testHistory;
        _reviewReminders = reviewReminders;
        _isLoading = false;
      });

      // 리마인더 알림 상태 로드
      await _preloadReminderNotificationStates();
    } catch (e) {
      print('기록 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 학습 기록 항목 탭 시 해당 청크들로 복습 화면 시작
  Future<void> _startReviewFromHistory(LearningHistoryEntry entry) async {
    // 해당 항목에 포함된 청크들 찾기
    final chunks = await _findChunksForHistory(entry);

    if (chunks.isEmpty) {
      // 청크를 찾지 못한 경우
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('해당 학습 세션의 청크를 찾을 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 학습 화면으로 이동
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LearningScreen(
            selectedChunks: chunks,
            isReview: true, // 복습 모드로 설정
          ),
        ),
      );
    }
  }

  // 복습 알림 항목을 탭하여 복습 시작
  Future<void> _startReviewFromReminder(ReviewReminder reminder) async {
    // 해당 알림에 포함된 청크들 찾기
    final chunks = await _findChunksById(reminder.chunkIds);

    if (chunks.isEmpty) {
      // 청크를 찾지 못한 경우
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('해당 복습의 청크를 찾을 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 학습 화면으로 이동
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LearningScreen(
            selectedChunks: chunks,
            isReview: true, // 복습 모드로 설정
            reviewReminderId: reminder.id, // 복습 완료 처리를 위한 ID 전달
          ),
        ),
      ).then((_) {
        // 복습 완료 후 리스트 새로고침
        _loadHistory();
      });
    }
  }

  // 학습 기록에 해당하는 청크들 찾기
  Future<List<Chunk>> _findChunksForHistory(LearningHistoryEntry entry) async {
    // WordListNotifier에서 모든 단어장의 청크들을 검색
    final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);
    final allWordLists = wordListNotifier.wordLists;

    final List<Chunk> matchingChunks = [];

    // 각 단어장에서 제목이 일치하는 청크 찾기
    for (final wordList in allWordLists) {
      if (wordList.chunks != null) {
        for (final chunk in wordList.chunks!) {
          if (entry.chunkTitles.contains(chunk.title)) {
            matchingChunks.add(chunk);
          }
        }
      }
    }

    return matchingChunks;
  }

  // ID로 청크들 찾기
  Future<List<Chunk>> _findChunksById(List<String> chunkIds) async {
    // WordListNotifier에서 모든 단어장의 청크들을 검색
    final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);
    final allWordLists = wordListNotifier.wordLists;

    final List<Chunk> matchingChunks = [];

    // 각 단어장에서 ID가 일치하는 청크 찾기
    for (final wordList in allWordLists) {
      if (wordList.chunks != null) {
        for (final chunk in wordList.chunks!) {
          if (chunkIds.contains(chunk.id)) {
            matchingChunks.add(chunk);
          }
        }
      }
    }

    return matchingChunks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학습 기록'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? null // Use default dark theme color
            : Colors.orange, // Use orange background in light mode
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '학습 기록'),
            Tab(text: '테스트 기록'),
            Tab(text: '복습 일정'),
          ],
          labelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.orange.shade300
              : Colors.white,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.grey.shade300,
          indicatorColor: Colors.orange,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLearningHistoryTab(),
                _buildTestHistoryTab(),
                _buildReviewRemindersTab(),
              ],
            ),
    );
  }

  Widget _buildLearningHistoryTab() {
    if (_learningHistory.isEmpty) {
      return _buildEmptyState('아직 학습 기록이 없습니다.', Icons.school);
    }

    return ListView.builder(
      itemCount: _learningHistory.length,
      itemBuilder: (context, index) {
        final entry = _learningHistory[index];
        final formattedDate = DateFormat('yyyy년 MM월 dd일 HH:mm').format(entry.date);

        // 청크 제목 목록을 콤마로 구분하여 문자열로 변환
        final chunkTitlesText = entry.chunkTitles.isEmpty
            ? "기록 없음"
            : entry.chunkTitles.join(', ');

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _startReviewFromHistory(entry),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.replay, color: Colors.orange),
                        tooltip: '다시 학습하기',
                        onPressed: () => _startReviewFromHistory(entry),
                      ),
                    ],
                  ),
                  const Divider(),
                  // 학습한 청크 제목 표시
                  if (entry.chunkTitles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        '학습 내용: $chunkTitlesText',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatItem(Icons.text_fields, '${entry.wordCount}', '학습 단어'),
                      _buildStatItem(Icons.menu_book, '${entry.chunkTitles.length}', '학습 단락'),
                      _buildStatItem(Icons.timer, '${entry.durationMinutes}', '학습 시간(분)'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestHistoryTab() {
    if (_testHistory.isEmpty) {
      return _buildEmptyState('아직 테스트 기록이 없습니다.', Icons.quiz);
    }

    return ListView.builder(
      itemCount: _testHistory.length,
      itemBuilder: (context, index) {
        final historyItem = _testHistory[index];
        final date = historyItem['dateObj'] as DateTime;
        final formattedDate = DateFormat('yyyy년 MM월 dd일 HH:mm').format(date);

        // 테스트 유형과 단락 정보 확인
        final testType = historyItem['testType'] as String? ?? '테스트';
        final chunks = historyItem['chunks'] as List<dynamic>? ?? [];

        // 테스트 유형 한글화
        String typeText;
        switch(testType.toLowerCase()) {
          case 'mixed':
            typeText = '복합 테스트';
            break;
          case 'chunk':
            typeText = '단락 테스트';
            break;
          case 'word':
            typeText = '단어 테스트';
            break;
          default:
            typeText = '테스트';
        }

        // 정확도 계산
        double accuracy;
        int correct;
        int total;

        // 저장된 정확도가 있으면 그대로 사용, 없으면 계산
        if (historyItem.containsKey('accuracy')) {
          // accuracy가 이미 퍼센트(0-100)인지 소수(0-1)인지 확인
          var rawAccuracy = historyItem['accuracy'];
          if (rawAccuracy is double || rawAccuracy is num) {
            double numAccuracy = (rawAccuracy as num).toDouble();
            // 1보다 작으면 0-1 범위로 저장된 것이므로 100을 곱해줌
            accuracy = numAccuracy <= 1.0 ? numAccuracy * 100 : numAccuracy;
          } else if (rawAccuracy is String) {
            accuracy = double.tryParse(rawAccuracy) ?? 0.0;
            // 1보다 작으면 0-1 범위로 저장된 것이므로 100을 곱해줌
            if (accuracy <= 1.0 && accuracy > 0) {
              accuracy *= 100;
            }
          } else {
            // 다른 타입인 경우 0으로 설정
            accuracy = 0.0;
          }
        } else {
          // 데이터 구조에 따라 필드명 선택
          correct = historyItem.containsKey('correctAnswers')
              ? (historyItem['correctAnswers'] is int
                  ? historyItem['correctAnswers'] as int
                  : int.tryParse(historyItem['correctAnswers'].toString()) ?? 0)
              : int.tryParse(historyItem['correctCount'] ?? '0') ?? 0;

          total = historyItem.containsKey('totalQuestions')
              ? (historyItem['totalQuestions'] is int
                  ? historyItem['totalQuestions'] as int
                  : int.tryParse(historyItem['totalQuestions'].toString()) ?? 0)
              : int.tryParse(historyItem['totalCount'] ?? '0') ?? 0;

          accuracy = total > 0 ? (correct / total * 100) : 0.0;
        }

        final accuracyText = accuracy.toStringAsFixed(1);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 날짜와 테스트 유형
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // 테스트 유형 표시
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 1),
                      ),
                      child: Text(
                        typeText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // 테스트한 단락 표시 (있는 경우에만)
                if (chunks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '테스트 내용: ${chunks.join(', ')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const Divider(),
                const SizedBox(height: 8),
                // 통계 정보
                Row(
                  children: [
                    _buildStatItem(
                      Icons.check_circle,
                      '${historyItem['correctAnswers'] ?? historyItem['correctCount'] ?? '0'}/${historyItem['totalQuestions'] ?? historyItem['totalCount'] ?? '0'}',
                      '정답'
                    ),
                    _buildStatItem(
                      Icons.percent,
                      '$accuracyText%',
                      '정확도'
                    ),
                    _buildStatItem(
                      Icons.timer,
                      '${historyItem.containsKey('durationSeconds') ? (int.parse(historyItem['durationSeconds'].toString()) / 60).round() : historyItem['durationMinutes'] ?? '0'}',
                      '소요 시간(분)'
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewRemindersTab() {
    if (_reviewReminders.isEmpty) {
      return _buildEmptyState('아직 예정된 복습이 없습니다.', Icons.update);
    }

    // 오늘 날짜
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 오늘 복습, 예정된 복습, 지난 복습으로 분류
    final todayReminders = _reviewReminders.where((r) =>
      !r.isCompleted &&
      r.scheduledReviewDate.year == today.year &&
      r.scheduledReviewDate.month == today.month &&
      r.scheduledReviewDate.day == today.day
    ).toList();

    final overdueReminders = _reviewReminders.where((r) =>
      !r.isCompleted &&
      r.scheduledReviewDate.isBefore(today)
    ).toList();

    final upcomingReminders = _reviewReminders.where((r) =>
      !r.isCompleted &&
      r.scheduledReviewDate.isAfter(today)
    ).toList();

    final completedReminders = _reviewReminders.where((r) => r.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 오늘 복습
        if (todayReminders.isNotEmpty) ...[
          _buildReminderSectionHeader('오늘의 복습', Icons.today, Colors.green),
          const SizedBox(height: 8.0),
          ...todayReminders.map((reminder) => _buildReminderCard(reminder, isToday: true)),
          const SizedBox(height: 16.0),
        ],

        // 지난 복습
        if (overdueReminders.isNotEmpty) ...[
          _buildReminderSectionHeader('지난 복습', Icons.update, Colors.red),
          const SizedBox(height: 8.0),
          ...overdueReminders.map((reminder) => _buildReminderCard(reminder, isOverdue: true)),
          const SizedBox(height: 16.0),
        ],

        // 예정된 복습
        if (upcomingReminders.isNotEmpty) ...[
          _buildReminderSectionHeader('예정된 복습', Icons.event, Colors.blue),
          const SizedBox(height: 8.0),
          ...upcomingReminders.map((reminder) => _buildReminderCard(reminder)),
          const SizedBox(height: 16.0),
        ],

        // 완료된 복습
        if (completedReminders.isNotEmpty) ...[
          _buildReminderSectionHeader('완료된 복습', Icons.check_circle, Colors.grey),
          const SizedBox(height: 8.0),
          ...completedReminders.map((reminder) => _buildReminderCard(reminder, isCompleted: true)),
        ],
      ],
    );
  }

  // 복습 섹션 헤더 위젯
  Widget _buildReminderSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // 복습 알림 카드 위젯
  Widget _buildReminderCard(ReviewReminder reminder, {
    bool isToday = false,
    bool isOverdue = false,
    bool isCompleted = false,
  }) {
    // 날짜 포맷
    final originalDate = DateFormat('yyyy년 MM월 dd일').format(reminder.originalLearningDate);
    final scheduledDate = DateFormat('yyyy년 MM월 dd일').format(reminder.scheduledReviewDate);

    // 복습 단계별 아이콘 및 텍스트
    String stageText;
    Color stageColor;

    switch (reminder.reviewStage) {
      case 1:
        stageText = '1일 후 복습 (1단계)';
        stageColor = Colors.blue;
        break;
      case 2:
        stageText = '7일 후 복습 (2단계)';
        stageColor = Colors.green;
        break;
      case 3:
        stageText = '16일 후 복습 (3단계)';
        stageColor = Colors.orange;
        break;
      case 4:
        stageText = '35일 후 복습 (4단계)';
        stageColor = Colors.purple;
        break;
      default:
        stageText = '복습 (${reminder.reviewStage}단계)';
        stageColor = Colors.grey;
    }

    // 학습 내용 (청크 제목) 문자열로 변환
    final chunkTitlesText = reminder.chunkTitles.join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      color: isCompleted
          ? Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF333333)
              : Colors.grey.shade100
          : isToday
              ? Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2D3A30) // 다크 모드에서 녹색 계열
                  : Colors.green.shade50
              : isOverdue
                  ? Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF3D2D2F) // 다크 모드에서 빨간색 계열
                      : Colors.red.shade50
                  : null,
      child: InkWell(
        onTap: isCompleted ? null : () => _startReviewFromReminder(reminder),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 복습 단계 표시
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.grey : stageColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted ? Colors.grey : stageColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      stageText,
                      style: TextStyle(
                        color: isCompleted ? Colors.grey : stageColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // 오른쪽 액션 버튼
                  if (!isCompleted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 알림 버튼 (알림 상태 토글)
                        IconButton(
                          icon: Icon(
                            // 현재 알림 상태에 따라 아이콘 변경
                            _reminderNotificationStates[reminder.id] ?? true
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            color: _reminderNotificationStates[reminder.id] ?? true
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          tooltip: (_reminderNotificationStates[reminder.id] ?? true)
                              ? '알림 비활성화하기'
                              : '알림 활성화하기',
                          onPressed: () => _sendReminderNotification(reminder),
                        ),
                        // 복습 시작 버튼
                        IconButton(
                          icon: const Icon(Icons.play_circle_outline, color: Colors.orange),
                          tooltip: '복습 시작하기',
                          onPressed: () => _startReviewFromReminder(reminder),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // 학습 내용
              const Text(
                '학습 내용:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                chunkTitlesText,
                style: TextStyle(
                  fontSize: 14,
                  color: isCompleted
                      ? Colors.grey
                      : Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // 날짜 정보
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '원 학습일: $originalDate',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle
                                : isOverdue
                                    ? Icons.warning
                                    : Icons.schedule,
                            size: 12,
                            color: isCompleted
                                ? Colors.green
                                : isOverdue
                                    ? Colors.red
                                    : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCompleted
                                ? '완료됨'
                                : '예정일: $scheduledDate',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCompleted
                                  ? Colors.green
                                  : isOverdue
                                      ? Colors.red
                                      : Colors.blue,
                              fontWeight: isOverdue && !isCompleted
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 상태 표시
                  if (isCompleted)
                    const Chip(
                      label: Text('완료', style: TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    )
                  else if (isToday)
                    const Chip(
                      label: Text('오늘', style: TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    )
                  else if (isOverdue)
                    const Chip(
                      label: Text('지연', style: TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // 특정 리마인더에 대한 알림 보내기
  // 복습 알림 활성화 상태 저장
  Map<String, bool> _reminderNotificationStates = {};

  // 복습 알림 상태를 미리 로드
  Future<void> _preloadReminderNotificationStates() async {
    for (final reminder in _reviewReminders) {
      final isEnabled = await _reviewService.isReminderNotificationEnabled(reminder.id);
      setState(() {
        _reminderNotificationStates[reminder.id] = isEnabled;
      });
    }
  }

  // 복습 알림 상태 토글 및 즉시 전송
  Future<void> _sendReminderNotification(ReviewReminder reminder) async {
    try {
      // 상태 토글 (비활성화 <-> 활성화)
      final isEnabled = await _reviewService.toggleReminderNotification(reminder.id);

      // 상태 업데이트
      setState(() {
        _reminderNotificationStates[reminder.id] = isEnabled;
      });

      if (isEnabled) {
        // 알림 활성화된 경우에만 메시지 전송
        await _reviewService.sendReviewNotificationForReminder(reminder);
      }

      // 사용자에게 상태 변경 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnabled
              ? '복습 알림이 활성화되고 전송되었습니다.'
              : '복습 알림이 비활성화되었습니다.'),
            backgroundColor: isEnabled ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('알림 처리 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('알림 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
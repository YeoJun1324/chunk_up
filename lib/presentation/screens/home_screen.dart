// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/presentation/providers/theme_notifier.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/core/theme/app_theme.dart';
import 'package:chunk_up/core/services/route_service.dart';
import 'package:chunk_up/core/config/app_config.dart';
import 'package:chunk_up/core/config/feature_flags.dart';
import 'package:chunk_up/presentation/widgets/debug_panel.dart'; // 디버그 패널 추가
import 'chunk_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WordListNotifier>(
      builder: (context, notifier, child) {
        // Calculate learning stats
        int totalWordLists = notifier.wordLists.length;
        int totalWords = 0;
        int wordsInChunks = 0;
        int totalChunks = 0;
        List<Chunk> recentChunks = [];

        // Collect data for stats and recent chunks
        for (var wordList in notifier.wordLists) {
          totalWords += wordList.words.length;
          wordsInChunks += wordList.words.where((w) => w.isInChunk).length;
          totalChunks += wordList.chunkCount;

          if (wordList.chunks != null && wordList.chunks!.isNotEmpty) {
            recentChunks.addAll(wordList.chunks!);
          }
        }

        // Sort chunks by creation date (most recent first)
        recentChunks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Get only the 5 most recent chunks
        final mostRecentChunks = recentChunks.take(5).toList();

        // Calculate progress percentage
        double progressPercentage = totalWords > 0
            ? wordsInChunks / totalWords
            : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chunk Up'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkBackground
                : null,
            actions: [
              // 다크 모드 토글 버튼
              Consumer<ThemeNotifier>(
                builder: (context, themeNotifier, child) {
                  // 현재 테마 모드 확인 (다크 모드 여부)
                  final isDarkMode = themeNotifier.isDarkMode(context);

                  return IconButton(
                    icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                    tooltip: isDarkMode ? '라이트 모드로 전환' : '다크 모드로 전환',
                    onPressed: () async {
                      await themeNotifier.toggleThemeMode();

                      // 사용자에게 변경 알림 (짧게)
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isDarkMode ? '라이트 모드로 전환되었습니다.' : '다크 모드로 전환되었습니다.'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '통계 새로고침',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('통계가 새로고침 되었습니다')),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 디버그 패널 추가 (개발 환경에서만 표시됨)
                const DebugPanel(),
                // Welcome section with app logo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade300, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.orange,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chunk Up',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '단어를 문맥으로 배우는 새로운 방법',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 학습 버튼 추가
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 오늘의 학습 이력
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '오늘의 학습',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<Map<String, dynamic>>(
                            future: _getTodayLearningStats(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final stats = snapshot.data ?? {
                                'wordCount': 0,
                                'chunkCount': 0,
                                'totalMinutes': 0,
                              };

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 균등 분배
                                children: [
                                  Expanded(  // Flexible 대신 Expanded 사용
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4), // 좌우 패딩 추가
                                      child: _buildLearningStatCard(
                                        context,
                                        Icons.extension,
                                        '${stats['wordCount']}',
                                        '학습 단어',
                                        Colors.blue.shade100,
                                        Colors.blue,
                                      ),
                                    ),
                                  ),
                                  Expanded(  // Flexible 대신 Expanded 사용
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4), // 좌우 패딩 추가
                                      child: _buildLearningStatCard(
                                        context,
                                        Icons.menu_book,
                                        '${stats['chunkCount']}',
                                        '학습 단락',
                                        Colors.green.shade100,
                                        Colors.green,
                                      ),
                                    ),
                                  ),
                                  Expanded(  // Flexible 대신 Expanded 사용
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4), // 좌우 패딩 추가
                                      child: _buildLearningStatCard(
                                        context,
                                        Icons.timer,
                                        '${stats['totalMinutes']}',
                                        '학습 시간 (분)',
                                        Colors.purple.shade100,
                                        Colors.purple,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                      const Text(
                        '학습 통계',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatCard(
                            context,
                            Icons.menu_book,
                            '$totalWordLists',
                            '단어장',
                            Colors.blue.shade100,
                            Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            context,
                            Icons.text_fields,
                            '$totalWords',
                            '총 단어',
                            Colors.purple.shade100,
                            Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatCard(
                            context,
                            Icons.notes,
                            '$totalChunks',
                            '생성된 단락',
                            Colors.orange.shade100,
                            Colors.orange,
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            context,
                            Icons.check_circle,
                            '$wordsInChunks',
                            '맥락화된 단어',
                            Colors.teal.shade100,
                            Colors.teal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Progress bar
                      const Text(
                        '단어 맥락화 진행도:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: progressPercentage,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progressPercentage * 100).toStringAsFixed(1)}% 완료',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 학습하기 버튼
                      ElevatedButton.icon(
                        icon: const Icon(Icons.school),
                        label: const Text('학습하기'),
                        onPressed: () => _navigateToLearningSelection(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 학습 기록 버튼
                      OutlinedButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('학습 기록'),
                        onPressed: () => _navigateToLearningHistory(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          minimumSize: const Size(double.infinity, 50),
                          side: BorderSide(color: Colors.blueGrey.shade200),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Recent chunks section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '최근 생성된 단락',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (mostRecentChunks.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 32,
                            horizontal: 16,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.note_add,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '아직 생성된 단락이 없습니다',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('첫 단락 생성하기'),
                                onPressed: () {
                                  // Navigate to bottom tab for chunk creation
                                  Navigator.pushReplacementNamed(context, '/');
                                  // 약간의 딜레이 후 탭 변경
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    MainScreen.navigateToTab(2);
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: mostRecentChunks.length,
                          itemBuilder: (context, index) {
                            final chunk = mostRecentChunks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChunkDetailScreen(
                                        chunk: chunk,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                                          return Text(
                                            chunk.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Builder(
                                        builder: (context) {
                                          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                                          return Text(
                                            chunk.englishContent,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: chunk.includedWords
                                            .take(5)
                                            .map((Word word) {
                                              final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: isDarkMode
                                                      ? Colors.orange.withOpacity(0.2)
                                                      : Colors.orange.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: isDarkMode
                                                        ? Colors.orange.withOpacity(0.5)
                                                        : Colors.orange.withOpacity(0.3)
                                                  ),
                                                ),
                                                child: Text(
                                                  word.english,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDarkMode ? Colors.white : Colors.black87,
                                                  ),
                                                ),
                                              );
                                            })
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      if (mostRecentChunks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Align(
                            alignment: Alignment.center,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('새 단락 생성하기'),
                              onPressed: () {
                                // Navigate to bottom tab for chunk creation
                                Navigator.pushReplacementNamed(context, '/');
                                // 약간의 딜레이 후 탭 변경
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  MainScreen.navigateToTab(2);
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
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
        );
      },
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      IconData icon,
      String value,
      String label,
      Color backgroundColor,
      Color iconColor,
      ) {
    // 다크 모드 여부 확인
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 다크 모드에서는 배경색과 아이콘 색상 조정
    final adjustedBgColor = isDarkMode ? backgroundColor.withOpacity(0.2) : backgroundColor;
    final adjustedIconColor = isDarkMode ? iconColor.withOpacity(0.9) : iconColor;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: adjustedBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: iconColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningStatCard(
      BuildContext context,
      IconData icon,
      String value,
      String label,
      Color backgroundColor,
      Color iconColor,
      ) {
    // 다크 모드 여부 확인
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 다크 모드에서는 배경색과 아이콘 색상 조정
    final adjustedBgColor = isDarkMode ? backgroundColor.withOpacity(0.2) : backgroundColor;
    final adjustedIconColor = isDarkMode ? iconColor.withOpacity(0.9) : iconColor;

    return Container(
      padding: const EdgeInsets.all(12), // 패딩 줄이기
      decoration: BoxDecoration(
        color: adjustedBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // 최소 크기로 조정
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 20, // 아이콘 크기 줄이기
          ),
          const SizedBox(height: 4),
          FittedBox( // 텍스트가 넘치지 않도록 FittedBox 추가
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18, // 폰트 크기 줄이기
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ),
          Flexible( // 라벨 텍스트를 유연하게 처리
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11, // 폰트 크기 줄이기
                color: iconColor.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis, // 텍스트 오버플로우 처리
              maxLines: 2, // 최대 2줄
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getTodayLearningStats() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('learning_history') ?? [];

    // 오늘 날짜
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int wordCount = 0;
    int chunkCount = 0;
    int totalMinutes = 0;

    for (var entry in historyJson) {
      try {
        // 문자열을 Map으로 변환 - 여기 부분 수정
        final Map<String, dynamic> historyEntry = {};
        final cleanEntry = entry
            .replaceAll('{', '')
            .replaceAll('}', '')
            .split(',');

        for (var item in cleanEntry) {
          final parts = item.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts[1].trim();
            historyEntry[key] = value;
          }
        }

        if (historyEntry.containsKey('date')) {
          final date = DateTime.parse(historyEntry['date']);

          // 오늘 기록만 필터링
          if (date.year == today.year && date.month == today.month && date.day == today.day) {
            wordCount += int.tryParse(historyEntry['wordCount'].toString()) ?? 0;
            chunkCount += (historyEntry['chunks'].toString().split(',').length);
            totalMinutes += int.tryParse(historyEntry['durationMinutes'].toString()) ?? 0;
          }
        }
      } catch (e) {
        print('History parsing error: $e');
      }
    }

    return {
      'wordCount': wordCount,
      'chunkCount': chunkCount,
      'totalMinutes': totalMinutes,
    };
  }

  void _navigateToLearningSelection(BuildContext context) {
    Navigator.pushNamed(context, '/learning_selection');
  }

  void _navigateToLearningHistory(BuildContext context) {
    Navigator.pushNamed(context, '/learning_history');
  }

}
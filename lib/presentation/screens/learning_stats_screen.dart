// lib/screens/learning_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class LearningStatsScreen extends StatefulWidget {
  const LearningStatsScreen({super.key});

  @override
  State<LearningStatsScreen> createState() => _LearningStatsScreenState();
}

class _LearningStatsScreenState extends State<LearningStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학습 통계'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '단어'),
            Tab(text: '단락'),
            Tab(text: '테스트'),
          ],
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const WordStatisticsTab(),
          const ChunkStatisticsTab(),
          TestStatisticsTab(),  // TestStatisticsTab만 const 제거
        ],
      ),
    );
  }
}

class WordStatisticsTab extends StatelessWidget {
  const WordStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WordListNotifier>(
      builder: (context, notifier, child) {
        // Calculate word statistics
        int totalWords = 0;
        int wordsInChunks = 0;
        int wordsWithHighAccuracy = 0;
        int wordsWithMediumAccuracy = 0;
        int wordsWithLowAccuracy = 0;

        // Group words by added date to show learning progress over time
        Map<DateTime, int> wordsByDate = {};

        for (var wordList in notifier.wordLists) {
          for (var word in wordList.words) {
            totalWords++;

            if (word.isInChunk) {
              wordsInChunks++;
            }

            if (word.testAccuracy != null) {
              if (word.testAccuracy! >= 0.8) {
                wordsWithHighAccuracy++;
              } else if (word.testAccuracy! >= 0.5) {
                wordsWithMediumAccuracy++;
              } else {
                wordsWithLowAccuracy++;
              }
            }

            // Group by day for chart
            final day = DateTime(
              word.addedDate.year,
              word.addedDate.month,
              word.addedDate.day,
            );

            wordsByDate[day] = (wordsByDate[day] ?? 0) + 1;
          }
        }

        // Sort dates for chart
        final sortedDates = wordsByDate.keys.toList()..sort();

        // Prepare data for chart
        final spots = <FlSpot>[];

        if (sortedDates.isNotEmpty) {
          int cumulativeWords = 0;
          for (int i = 0; i < sortedDates.length; i++) {
            final date = sortedDates[i];
            cumulativeWords += wordsByDate[date]!;

            final daysFromStart = date.difference(sortedDates.first).inDays.toDouble();
            spots.add(FlSpot(daysFromStart, cumulativeWords.toDouble()));
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Word count card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '단어 현황',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '$totalWords',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Text('총 단어'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '$wordsInChunks',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const Text('맥락화된 단어'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${totalWords > 0 ? (wordsInChunks * 100 ~/ totalWords) : 0}%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text('맥락화 비율'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Test accuracy breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '테스트 정확도',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (wordsWithHighAccuracy + wordsWithMediumAccuracy + wordsWithLowAccuracy == 0)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '아직 테스트 데이터가 없습니다.\n단락을 생성하고 테스트를 진행해보세요!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: wordsWithHighAccuracy.toDouble(),
                                      title: '상',
                                      color: Colors.green,
                                      radius: 60,
                                    ),
                                    PieChartSectionData(
                                      value: wordsWithMediumAccuracy.toDouble(),
                                      title: '중',
                                      color: Colors.orange,
                                      radius: 60,
                                    ),
                                    PieChartSectionData(
                                      value: wordsWithLowAccuracy.toDouble(),
                                      title: '하',
                                      color: Colors.red,
                                      radius: 60,
                                    ),
                                  ],
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendItem('상 (80%+)', Colors.green),
                                const SizedBox(width: 16),
                                _buildLegendItem('중 (50-80%)', Colors.orange),
                                const SizedBox(width: 16),
                                _buildLegendItem('하 (50% 미만)', Colors.red),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Learning progress over time
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '학습 추이',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (spots.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '아직 충분한 데이터가 없습니다.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval: 10,
                                verticalInterval: 1,
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 7 != 0) {
                                        return const SizedBox.shrink();
                                      }

                                      final date = sortedDates.first.add(
                                          Duration(days: value.toInt())
                                      );

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          DateFormat('MM/dd').format(date),
                                          style: const TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 42,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: false,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.blue.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class ChunkStatisticsTab extends StatelessWidget {
  const ChunkStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WordListNotifier>(
      builder: (context, notifier, child) {
        // Calculate chunk statistics
        int totalChunks = 0;
        int totalWordsInChunks = 0;
        double averageWordsPerChunk = 0;

        // Group chunks by creation date
        Map<DateTime, int> chunksByDate = {};

        // Word list breakdown
        Map<String, int> chunksByWordList = {};

        for (var wordList in notifier.wordLists) {
          if (wordList.chunks != null) {
            final listChunks = wordList.chunks!.length;
            totalChunks += listChunks;
            chunksByWordList[wordList.name] = listChunks;

            for (var chunk in wordList.chunks!) {
              totalWordsInChunks += chunk.includedWords.length;

              // Group by day for chart
              final day = DateTime(
                chunk.createdAt.year,
                chunk.createdAt.month,
                chunk.createdAt.day,
              );

              chunksByDate[day] = (chunksByDate[day] ?? 0) + 1;
            }
          }
        }

        if (totalChunks > 0) {
          averageWordsPerChunk = totalWordsInChunks / totalChunks;
        }

        // Sort dates for chart
        final sortedDates = chunksByDate.keys.toList()..sort();

        // Prepare data for chart
        final spots = <FlSpot>[];

        if (sortedDates.isNotEmpty) {
          int cumulativeChunks = 0;
          for (int i = 0; i < sortedDates.length; i++) {
            final date = sortedDates[i];
            cumulativeChunks += chunksByDate[date]!;

            final daysFromStart = date.difference(sortedDates.first).inDays.toDouble();
            spots.add(FlSpot(daysFromStart, cumulativeChunks.toDouble()));
          }
        }

        // Prepare word list breakdown data
        final wordListNames = chunksByWordList.keys.toList();
        final wordListChunkCounts = chunksByWordList.values.toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chunk count card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '단락 현황',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '$totalChunks',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const Text('총 단락'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '$totalWordsInChunks',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Text('단락 속 단어'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                averageWordsPerChunk.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              const Text('평균 단어 수'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Word list breakdown
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '단어장별 단락 수',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (wordListNames.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '아직 단락 데이터가 없습니다.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: wordListChunkCounts.reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value >= wordListNames.length) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          wordListNames[value.toInt()],
                                          style: const TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                    reservedSize: 40,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 1 != 0) {
                                        return const SizedBox.shrink();
                                      }

                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                checkToShowHorizontalLine: (value) => value % 1 == 0,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey.withOpacity(0.3),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              borderData: FlBorderData(
                                show: false,
                              ),
                              barGroups: List.generate(
                                wordListNames.length,
                                    (index) => BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: wordListChunkCounts[index].toDouble(),
                                      color: Colors.orange,
                                      width: 20,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Chunk creation over time
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '단락 생성 추이',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (spots.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '아직 충분한 데이터가 없습니다.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                horizontalInterval: 1,
                                verticalInterval: 1,
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 7 != 0) {
                                        return const SizedBox.shrink();
                                      }

                                      final date = sortedDates.first.add(
                                          Duration(days: value.toInt())
                                      );

                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          DateFormat('MM/dd').format(date),
                                          style: const TextStyle(
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 42,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 1 != 0) {
                                        return const SizedBox.shrink();
                                      }

                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: false,
                                  color: Colors.orange,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.orange.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TestStatisticsTab extends StatelessWidget {
  const TestStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // For this implementation, we'll create a placeholder
    // In a real app, you'd track test results over time

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              '테스트 통계 기능 준비 중',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '이 기능은 곧 업데이트될 예정입니다.\n테스트 결과를 추적하고 학습 진행 상황을 분석할 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('테스트 시작하기'),
              onPressed: () {
                Navigator.pushNamed(context, '/test');
              },
            ),
          ],
        ),
      ),
    );
  }
}
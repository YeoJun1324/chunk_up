// lib/presentation/screens/word_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/presentation/screens/chunk_detail_screen.dart';
import 'package:intl/intl.dart';

class WordDetailScreen extends StatelessWidget {
  final Word word;
  final String wordListName;

  const WordDetailScreen({
    Key? key,
    required this.word,
    required this.wordListName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('단어 상세 정보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '단어 편집',
            onPressed: () {
              // TODO: 단어 편집 기능 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('단어 편집 기능은 준비 중입니다.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<WordListNotifier>(
        builder: (context, notifier, child) {
          // 현재 단어장 정보 가져오기
          WordListInfo? currentWordList;
          try {
            currentWordList = notifier.wordLists.firstWhere(
              (list) => list.name == wordListName,
            );
          } catch (e) {
            return const Center(
              child: Text('단어장 정보를 찾을 수 없습니다.'),
            );
          }

          // 이 단어가 포함된 단락들 찾기
          List<Chunk> chunksWithThisWord = [];
          if (currentWordList.chunks != null) {
            chunksWithThisWord = currentWordList.chunks!.where((chunk) {
              return chunk.includedWords.any((w) => w.english == word.english);
            }).toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 단어 헤더 섹션
                _buildWordHeader(context),
                
                const SizedBox(height: 24),
                
                // 단어 정보 섹션
                _buildWordInfoSection(),
                
                const SizedBox(height: 24),
                
                // 단어가 포함된 단락들
                _buildChunksSection(context, chunksWithThisWord),
              ],
            ),
          );
        },
      ),
    );
  }

  // 단어 헤더 섹션
  Widget _buildWordHeader(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              word.english,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              word.korean,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (word.isInChunk)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Chip(
                  label: const Text('단락에 포함됨'),
                  avatar: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  backgroundColor: Colors.green,
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 단어 정보 섹션
  Widget _buildWordInfoSection() {
    final dateFormat = DateFormat('yyyy년 MM월 dd일');
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '단어 정보',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow('단어장', wordListName),
            _buildInfoRow('추가 날짜', dateFormat.format(word.addedDate)),
            if (word.testAccuracy != null)
              _buildInfoRow(
                '테스트 정확도', 
                '${(word.testAccuracy! * 100).toStringAsFixed(1)}%',
                valueColor: _getAccuracyColor(word.testAccuracy!),
              ),
          ],
        ),
      ),
    );
  }

  // 정확도에 따른 색상 반환
  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.5) return Colors.orange;
    return Colors.red;
  }

  // 정보 행 위젯
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 단어가 포함된 단락들 섹션
  Widget _buildChunksSection(BuildContext context, List<Chunk> chunks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '포함된 단락',
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        if (chunks.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '이 단어가 포함된 단락이 없습니다.\n'
                  'Chunk Up 버튼을 눌러 단락을 생성해보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chunks.length,
            itemBuilder: (context, index) {
              final chunk = chunks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(
                    chunk.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    chunk.englishContent,
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
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
                ),
              );
            },
          ),
      ],
    );
  }
}
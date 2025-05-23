// lib/screens/learning_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/presentation/widgets/labeled_border_container.dart';
import 'learning_screen.dart';

class LearningSelectionScreen extends StatefulWidget {
  const LearningSelectionScreen({super.key});

  @override
  State<LearningSelectionScreen> createState() => _LearningSelectionScreenState();
}

class _LearningSelectionScreenState extends State<LearningSelectionScreen> {
  WordListInfo? _selectedWordList;
  List<Chunk> _selectedChunks = [];

  @override
  Widget build(BuildContext context) {
    return Consumer<WordListNotifier>(
      builder: (context, notifier, child) {
        final wordLists = notifier.wordLists;

        // 단락이 있는 단어장만 필터링
        final wordListsWithChunks = wordLists
            .where((list) => (list.chunks?.isNotEmpty ?? false))
            .toList();

        if (wordListsWithChunks.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('학습할 단락 선택'),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 24),
                    Text(
                      '학습할 단락이 없습니다',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chunk Up 버튼을 눌러 단어 학습을 위한 단락을 먼저 생성해보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 선택한 단어장이 변경되면 선택된 단락 초기화
        if (_selectedWordList != null &&
            !wordListsWithChunks.contains(_selectedWordList)) {
          _selectedWordList = null;
          _selectedChunks = [];
        }

        // 선택한 단어장의 단락들
        final List<Chunk> availableChunks = _selectedWordList != null
            ? (_selectedWordList!.chunks ?? [])
            : [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('학습할 단락 선택'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledDropdown<WordListInfo>(
                  label: '1. 단어장 선택',
                  hint: '학습할 단어장을 선택하세요',
                  value: _selectedWordList,
                  hasValueOverride: _selectedWordList != null,
                  items: wordListsWithChunks.map((WordListInfo list) {
                    return DropdownMenuItem<WordListInfo>(
                      value: list,
                      child: Text('${list.name} (단락 ${list.chunkCount}개)'),
                    );
                  }).toList(),
                  onChanged: (WordListInfo? newValue) {
                    setState(() {
                      _selectedWordList = newValue;
                      _selectedChunks = [];
                    });
                  },
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                ),
                const SizedBox(height: 24),

                LabeledBorderContainer(
                  label: '2. 학습할 단락 선택',
                  hasValue: _selectedChunks.isNotEmpty,
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _selectedWordList == null
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('단어장을 먼저 선택해주세요.'),
                        )
                      : availableChunks.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('선택한 단어장에 학습할 단락이 없습니다.'),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('모든 단락 선택/해제'),
                                trailing: Checkbox(
                                  value: availableChunks.isNotEmpty &&
                                      _selectedChunks.length == availableChunks.length,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedChunks = List.from(availableChunks);
                                      } else {
                                        _selectedChunks = [];
                                      }
                                    });
                                  },
                                  activeColor: Colors.orange,
                                  checkColor: Colors.white,
                                ),
                              ),
                              const Divider(height: 1),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: availableChunks.length,
                                itemBuilder: (context, index) {
                                  final chunk = availableChunks[index];
                                  return CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(chunk.title),
                                    subtitle: Text(
                                      '단어 ${chunk.includedWords.length}개',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                    value: _selectedChunks.contains(chunk),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedChunks.add(chunk);
                                        } else {
                                          _selectedChunks.remove(chunk);
                                        }
                                      });
                                    },
                                    activeColor: Colors.orange,
                                    checkColor: Colors.white,
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                // 하단 학습 시작 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('학습 시작'),
                    onPressed: (_selectedWordList != null && _selectedChunks.isNotEmpty)
                        ? () => _startLearning(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startLearning(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningScreen(
          selectedChunks: _selectedChunks,
        ),
      ),
    );
  }
}
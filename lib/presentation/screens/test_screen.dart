// lib/screens/test_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/core/utils/test_manager.dart';
import 'package:chunk_up/presentation/widgets/labeled_border_container.dart';
import 'package:chunk_up/data/services/subscription/subscription_service.dart';
import 'package:get_it/get_it.dart';
import 'chunk_test_screen.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String? _selectedWordListName;
  List<Chunk> _selectedChunks = [];
  TestType? _selectedTestType; // 기본값 없이 null로 설정

  // 구독 서비스 인스턴스 가져오기
  final SubscriptionService _subscriptionService = GetIt.instance<SubscriptionService>();

  @override
  Widget build(BuildContext context) {
    return Consumer<WordListNotifier>(
      builder: (context, notifier, child) {
        // 단락이 있는 단어장만 필터링
        final wordListsWithChunks = notifier.wordLists
            .where((list) => (list.chunks?.isNotEmpty ?? false))
            .toList();

        if (wordListsWithChunks.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('테스트'),
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
                      '테스트할 단락이 없습니다',
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

        // 사용 가능한 청크 목록
        List<Chunk> availableChunks = [];
        if (_selectedWordListName != null) {
          final selectedList = wordListsWithChunks.firstWhere(
                (list) => list.name == _selectedWordListName,
            orElse: () => wordListsWithChunks.first,
          );
          availableChunks = selectedList.chunks ?? [];
        }

        return Scaffold(
          appBar: AppBar(
            title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('테스트 준비'),
        ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16.0,
                16.0,
                16.0,
                16.0 + MediaQuery.of(context).padding.bottom
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                LabeledDropdown<String?>(
                  label: '1. 단어장 선택',
                  hint: '테스트할 단어장을 선택하세요',
                  value: _selectedWordListName,
                  hasValueOverride: _selectedWordListName != null,
                  items: [
                    // null 값 항목 추가
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('단어장을 선택하세요'),
                    ),
                    ...wordListsWithChunks.map((list) {
                      return DropdownMenuItem<String?>(
                        value: list.name,
                        child: Text('${list.name} (단락 ${list.chunkCount}개)'),
                      );
                    }).toList(),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedWordListName = newValue;
                      _selectedChunks = [];
                    });
                  },
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                ),
                const SizedBox(height: 24),

                LabeledBorderContainer(
                  label: '2. 테스트할 단락 선택',
                  hasValue: _selectedChunks.isNotEmpty,
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _selectedWordListName == null
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('단어장을 먼저 선택해주세요.'),
                        )
                      : availableChunks.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('선택한 단어장에 테스트할 단락이 없습니다.'),
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
                const SizedBox(height: 24),

                LabeledBorderContainer(
                  label: '3. 테스트 유형 선택',
                  hasValue: _selectedTestType != null, // 테스트 유형이 선택되었을 때만 true
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        RadioListTile<TestType>(
                          title: const Text('복합 테스트'),
                          subtitle: const Text('단락과 단어 테스트를 순차적으로 진행'),
                          value: TestType.mixed,
                          groupValue: _selectedTestType,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (TestType? value) {
                            if (value != null) {
                              setState(() {
                                _selectedTestType = value;
                              });
                            }
                          },
                          activeColor: Colors.orange,
                        ),
                        RadioListTile<TestType>(
                          title: const Text('단락 테스트'),
                          subtitle: const Text('문맥 속에서 빈칸 채우기'),
                          value: TestType.chunk,
                          groupValue: _selectedTestType,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (TestType? value) {
                            if (value != null) {
                              setState(() {
                                _selectedTestType = value;
                              });
                            }
                          },
                          activeColor: Colors.orange,
                        ),
                        RadioListTile<TestType>(
                          title: const Text('단어 테스트'),
                          subtitle: const Text('단어와 뜻 매칭하기'),
                          value: TestType.word,
                          groupValue: _selectedTestType,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (TestType? value) {
                            if (value != null) {
                              setState(() {
                                _selectedTestType = value;
                              });
                            }
                          },
                          activeColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 무료 사용자를 위한 프리미엄 알림 메시지
                if (!_subscriptionService.canUseTestFeature)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.amber.shade900.withOpacity(0.3)
                            : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.amber.shade700
                              : Colors.amber.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.amber.shade400
                                : Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '테스트 기능은 프리미엄 사용자 전용 기능입니다.\n구독을 통해 모든 기능을 이용해보세요!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.amber.shade100
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('테스트 시작'),
                      onPressed: (_selectedWordListName != null &&
                               _selectedChunks.isNotEmpty &&
                               _selectedTestType != null &&
                               _subscriptionService.canUseTestFeature) // 구독 서비스를 통해 테스트 기능 사용 가능 여부 확인
                          ? () => _startTest(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  void _startTest(BuildContext context) {
    // 구독 상태 확인 - 추가 안전장치
    if (!_subscriptionService.canUseTestFeature) {
      // 무료 사용자가 테스트를 시작하려고 할 경우 (보안상 이중 확인)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('테스트 기능은 프리미엄 사용자 전용 기능입니다.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    // 테스트 유형이 선택되지 않았으면 복합 테스트로 기본 설정
    final testType = _selectedTestType ?? TestType.mixed;

    // 선택된 청크 순서를 랜덤으로 섞지 않고 그대로 유지
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChunkTestScreen(
          chunks: _selectedChunks,
          testType: testType,
          onTestComplete: (results) {
            // 테스트 결과 처리
            print('테스트 완료: ${results.length} 결과');
            // 결과는 ChunkTestScreen 내에서 직접 처리됨
          },
        ),
      ),
    );
  }
}
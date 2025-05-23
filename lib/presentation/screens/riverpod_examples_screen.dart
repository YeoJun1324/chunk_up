import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chunk_up/presentation/providers/riverpod/word_list_provider.dart';
import 'package:chunk_up/presentation/providers/riverpod/word_list_state.dart';
import 'package:chunk_up/domain/models/freezed/word.dart';
import 'package:chunk_up/domain/models/freezed/chunk.dart';
import 'freezed_help_screen.dart';

/// Riverpod 및 Freezed 예제 화면
///
/// 이 화면은 Riverpod 상태 관리와 Freezed 불변 객체 패턴을 사용하는 예제를 제공합니다.
///
/// 참고: 이 예제를 완전히 활용하려면 코드 생성이 필요합니다. 다음 명령어를 실행하세요:
/// ```
/// flutter pub run build_runner build --delete-conflicting-outputs
/// ```
///
/// 코드 생성 전에도 기본적인 기능은 작동합니다.

/// Riverpod 예제 화면
///
/// Riverpod을 사용한 상태 관리 예제를 보여주는 화면입니다.
class RiverpodExamplesScreen extends ConsumerWidget {
  const RiverpodExamplesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 단어장 상태 구독
    final wordListState = ref.watch(wordListProvider);

    // Freezed 코드 생성 체크 (실제로는 동작하지 않지만 UI 플로우를 위한 것)
    final bool codeGenerated = false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod 상태 관리 예제'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FreezedHelpScreen(),
                ),
              );
            },
            tooltip: 'Freezed 도움말',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 코드 생성 안내 배너
                if (!codeGenerated)
                  _buildCodeGenerationBanner(context),

                // 소개 카드
                _buildIntroCard(),
                const SizedBox(height: 24),

                // 상태 정보 카드
                _buildStateInfoCard(wordListState),
                const SizedBox(height: 24),

                // 단어장 목록 카드
                _buildWordListsCard(context, ref, wordListState),
                const SizedBox(height: 24),

                // 액션 카드
                _buildActionCard(context, ref, wordListState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeGenerationBanner(BuildContext context) {
    return Card(
      color: Colors.orange.shade100,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text(
                  'Freezed 코드 생성 필요',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Freezed 패키지를 사용하기 위해 코드 생성이 필요합니다. '
              '일부 기능은 코드 생성 없이 사용할 수 없습니다.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.info_outline),
              label: const Text('코드 생성 방법 보기'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FreezedHelpScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Riverpod 상태 관리',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Riverpod은 Flutter 애플리케이션을 위한 반응형 캐싱 및 데이터 바인딩 프레임워크입니다. '
              'Provider 패키지의 한계를 극복하고 더 강력한 기능을 제공합니다.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              '주요 특징:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text('• 컴파일 타임 안전성\n• 의존성 오버라이드 지원\n• 테스트 용이성\n• 코드 생성 없이 상태 관리\n• Provider 소비 위치 제한 없음'),
          ],
        ),
      ),
    );
  }

  Widget _buildStateInfoCard(WordListState state) {
    return Card(
      elevation: 2,
      color: state.map(
        loading: (_) => Colors.blue.shade50,
        error: (_) => Colors.red.shade50,
        loaded: (_) => Colors.green.shade50,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 상태: ${state.runtimeType}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.stateMessage,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('단어장 수: ${state.wordLists.length}'),
            if (state.selectedWordListName != null)
              Text('선택된 단어장: ${state.selectedWordListName}'),
          ],
        ),
      ),
    );
  }

  Widget _buildWordListsCard(BuildContext context, WidgetRef ref, WordListState state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '단어장 목록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (state.map(
              loading: (_) => true,
              error: (_) => false,
              loaded: (_) => false,
            ))
              const Center(child: CircularProgressIndicator())
            else if (state.wordLists.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('단어장이 없습니다. 아래 버튼으로 샘플 단어장을 추가해보세요.'),
                ),
              )
            else
              ...state.wordLists.map((wordList) => _buildWordListItem(context, ref, wordList)),
          ],
        ),
      ),
    );
  }

  Widget _buildWordListItem(BuildContext context, WidgetRef ref, WordListInfo wordList) {
    final wordListState = ref.read(wordListProvider.notifier);
    final currentState = ref.read(wordListProvider);
    final isSelected = currentState.selectedWordListName == wordList.name;

    // 임시적으로 샘플 데이터를 표시 (freezed 생성 코드가 없을 경우를 대비)
    final wordCount = wordList.words?.length ?? 0;
    final chunkCount = wordList.chunkCount ?? 0;
    final progressPercent = 0;

    return ListTile(
      title: Text(wordList.name),
      subtitle: Text('단어 ${wordCount}개, 단락 ${chunkCount}개'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '진행: ${progressPercent}%',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => wordListState.deleteWordList(wordList.name),
          ),
        ],
      ),
      selected: isSelected,
      selectedTileColor: Colors.orange.shade50,
      onTap: () => wordListState.selectWordList(wordList.name),
    );
  }

  Widget _buildActionCard(BuildContext context, WidgetRef ref, WordListState state) {
    final wordListState = ref.read(wordListProvider.notifier);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '테스트 액션',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('샘플 단어장 추가'),
                  onPressed: () => _addSampleWordList(ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.book),
                  label: const Text('샘플 단어 추가'),
                  onPressed: state.selectedWordListName != null
                      ? () => _addSampleWord(ref)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text('샘플 단락 추가'),
                  onPressed: state.selectedWordListName != null
                      ? () => _addSampleChunk(ref)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('모두 초기화'),
                  onPressed: () => wordListState.resetAllData(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addSampleWordList(WidgetRef ref) {
    final notifier = ref.read(wordListProvider.notifier);

    try {
      final sampleList = WordListInfo(
        name: '샘플 단어장 ${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      );

      notifier.addWordList(sampleList);
    } catch (e) {
      print('단어장 추가 실패: $e');
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(content: Text('샘플 단어장 추가 중 오류: $e')),
      );
    }
  }

  void _addSampleWord(WidgetRef ref) {
    final state = ref.read(wordListProvider);
    final notifier = ref.read(wordListProvider.notifier);
    final selectedName = state.selectedWordListName;

    if (selectedName == null) return;

    try {
      final sampleWord = Word(
        english: 'sample${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        korean: '샘플',
        examples: ['This is a sample word.'],
      );

      notifier.addWordToList(selectedName, sampleWord);
    } catch (e) {
      print('단어 추가 실패: $e');
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(content: Text('샘플 단어 추가 중 오류: $e')),
      );
    }
  }

  void _addSampleChunk(WidgetRef ref) {
    final state = ref.read(wordListProvider);
    final notifier = ref.read(wordListProvider.notifier);
    final selectedList = state.selectedWordList;

    if (selectedList == null) return;

    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(7);

    try {
      final sampleWords = [
        Word(english: 'hello', korean: '안녕하세요'),
        Word(english: 'world', korean: '세계'),
        Word(english: 'sample', korean: '샘플'),
      ];

      final sampleChunk = Chunk(
        id: 'chunk-$timestamp',
        title: '샘플 단락 $timestamp',
        englishContent: 'Hello world! This is a sample chunk created at ${now.toString()}.',
        koreanTranslation: '안녕 세계! 이것은 ${now.toString()}에 생성된 샘플 단락입니다.',
        includedWords: sampleWords,
        createdAt: now,
        wordExplanations: {
          'hello': '인사말로 사용되는 표현',
          'world': '지구 또는 세계를 의미함',
          'sample': '예시나 견본을 의미함',
        },
      );

      notifier.addChunkToList(selectedList.name, sampleChunk);
    } catch (e) {
      print('단락 추가 실패: $e');
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(content: Text('샘플 단락 추가 중 오류: $e')),
      );
    }
  }
}
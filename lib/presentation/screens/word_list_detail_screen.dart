// lib/screens/word_list_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider import
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart'; // WordListNotifier import
import 'package:chunk_up/domain/services/character/enhanced_character_service.dart'; // EnhancedCharacterService import
import 'new_word_add_screen.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'chunk_detail_screen.dart';
import 'word_detail_screen.dart';
import 'edit_word_screen.dart';
import 'create_chunk_screen.dart';

class WordListDetailScreen extends StatefulWidget {
  final WordListInfo wordListInfo; // 표시할 단어장 정보

  const WordListDetailScreen({
    super.key,
    required this.wordListInfo,
    // final void Function(Word newWord) onWordAdded; // <<< 이 콜백 파라미터 제거
  });

  @override
  State<WordListDetailScreen> createState() => _WordListDetailScreenState();
}

class _WordListDetailScreenState extends State<WordListDetailScreen> {
  bool _isSelectionMode = false;
  Set<String> _selectedWordEnglish = {};

  void _navigateToAddWord() {
    print('"${widget.wordListInfo.name}" 단어장에 새 단어 추가 화면으로 이동');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewWordAddScreen(
          wordListName: widget.wordListInfo.name,
          // onWordAdded 콜백은 더 이상 전달할 필요 없음
        ),
      ),
    );
    // .then((_) { ... }) 부분도 제거 가능, NewWordAddScreen에서 pop하면
    // WordListDetailScreen의 build가 WordListNotifier의 변경을 감지하고 다시 그려짐.
    // 다만, 즉각적인 UI 변경이 필요한 경우 then을 사용하거나,
    // Consumer/Selector를 더 세밀하게 사용할 수 있음.
    // 여기서는 WordListNotifier가 변경을 알릴 것이므로 then은 일단 제거.
  }

  // 단어 목록 UI를 만드는 별도 함수
  Widget _buildWordList(BuildContext context, List<Word> words) {
    if (words.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '단어장에 단어가 없습니다.\n오른쪽 위 (+) 버튼을 눌러 단어를 추가하세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ));
    }
    return ListView.builder(
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          // 맥락화된 단어는 일반 카드와 동일한 모양으로 표시 (테두리 없음)
          child: ListTile(
            // 순서대로 번호 매기기
            leading: _isSelectionMode
                ? Checkbox(
                    value: _selectedWordEnglish.contains(word.english),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedWordEnglish.add(word.english);
                        } else {
                          _selectedWordEnglish.remove(word.english);
                        }
                      });
                    },
                  )
                : CircleAvatar(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    radius: 16,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
            title: Text(
              word.english,
              style: const TextStyle(fontWeight: FontWeight.w500)
            ),
            subtitle: Text(word.korean),
            // 청크에 포함된 경우 체크 아이콘 표시
            trailing: _isSelectionMode 
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (word.isInChunk)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Tooltip(
                            message: '맥락화 완료 (단락에 포함됨)',
                            child: Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 22,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        tooltip: '${word.english} 옵션',
                        onPressed: () {
                          _showWordOptions(context, word);
                        },
                      ),
                    ],
                  ),
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  if (_selectedWordEnglish.contains(word.english)) {
                    _selectedWordEnglish.remove(word.english);
                  } else {
                    _selectedWordEnglish.add(word.english);
                  }
                });
              } else {
                _navigateToWordDetail(context, word);
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                setState(() {
                  _isSelectionMode = true;
                  _selectedWordEnglish.add(word.english);
                });
              }
            },
          ),
        );
      },
    );
  } // 여기가 _buildWordList 메서드의 올바른 끝

  // 단어 상세 정보 화면으로 이동
  void _navigateToWordDetail(BuildContext context, Word word) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordDetailScreen(
          word: word,
          wordListName: widget.wordListInfo.name,
        ),
      ),
    );
  }

  // 단어 옵션 메뉴 표시
  void _showWordOptions(BuildContext context, Word word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('상세 정보'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToWordDetail(context, word);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('편집'),
                onTap: () {
                  Navigator.pop(context);
                  // 단어 편집 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditWordScreen(
                        word: word,
                        wordListName: widget.wordListInfo.name,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteWord(context, word);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 단어 삭제 확인 다이얼로그
  void _confirmDeleteWord(BuildContext context, Word word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단어 삭제'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            children: [
              const TextSpan(text: '단어 '),
              TextSpan(
                text: word.english,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '을(를) 삭제하시겠습니까?'),
              if (word.isInChunk)
                const TextSpan(
                  text: '\n\n⚠️ 이 단어는 하나 이상의 단락에서 사용되고 있습니다.',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Provider.of<WordListNotifier>(context, listen: false)
                  .deleteWord(widget.wordListInfo.name, word);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('단어가 삭제되었습니다.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _buildChunkList(BuildContext context, List<Chunk> chunks) {
    if (chunks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Chunk Up 버튼을 눌러 단어를 활용한 단락을 생성해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // 시리즈별로 단락 그룹화를 위한 Future
    return FutureBuilder<Map<String, List<Chunk>>>(
      future: _groupChunksBySeries(chunks),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('단락을 불러오는 중 오류가 발생했습니다.'),
          );
        }

        final chunksGroupedBySeries = snapshot.data!;
        
        // 시리즈 이름 정렬 (기타는 항상 마지막에)
        List<String> seriesNames = chunksGroupedBySeries.keys.toList();
        seriesNames.sort((a, b) {
          if (a == '기타') return 1;
          if (b == '기타') return -1;
          return a.compareTo(b);
        });

        return ListView.builder(
          itemCount: seriesNames.length,
          itemBuilder: (context, index) {
            final seriesName = seriesNames[index];
            final seriesChunks = chunksGroupedBySeries[seriesName] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 시리즈 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        seriesName == '기타' ? Icons.more_horiz : Icons.movie,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          seriesName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${seriesChunks.length})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // 해당 시리즈의 단락 목록
                ...seriesChunks.map((chunk) => _buildChunkCard(context, chunk)),

                // 구분선
                if (index < seriesNames.length - 1)
                  Divider(color: Colors.grey.shade300, thickness: 1),
              ],
            );
          },
        );
      },
    );
  }

  // 단락을 시리즈별로 그룹화하는 메소드
  Future<Map<String, List<Chunk>>> _groupChunksBySeries(List<Chunk> chunks) async {
    final enhancedCharacterService = EnhancedCharacterService();
    Map<String, List<Chunk>> chunksGroupedBySeries = {};
    
    // 기타 카테고리 초기화
    chunksGroupedBySeries['기타'] = [];

    for (var chunk in chunks) {
      String seriesName = '기타';
      
      if (chunk.character.isNotEmpty) {
        // 첫 번째 캐릭터의 시리즈 정보를 가져옴
        final firstCharacterName = chunk.character.first;
        final character = await enhancedCharacterService.getCharacterByName(firstCharacterName);
        
        if (character != null && character.seriesName.isNotEmpty) {
          seriesName = character.seriesName;
        }
      }
      
      if (!chunksGroupedBySeries.containsKey(seriesName)) {
        chunksGroupedBySeries[seriesName] = [];
      }
      chunksGroupedBySeries[seriesName]!.add(chunk);
    }

    // 기타 카테고리에 단락이 없으면 삭제
    if (chunksGroupedBySeries['기타']?.isEmpty ?? true) {
      chunksGroupedBySeries.remove('기타');
    }

    return chunksGroupedBySeries;
  }

  // 단락 카드 위젯을 생성하는 보조 메서드
  Widget _buildChunkCard(BuildContext context, Chunk chunk) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(
          chunk.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // 포함된 단어 수 표시
            IntrinsicHeight(
              child: Row(
                children: [
                  Text(
                    '단어 ${chunk.includedWords.length}개',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (chunk.scenario != null && chunk.scenario!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.event_note, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        chunk.scenario!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            // 단어 태그 형태로 표시
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: chunk.includedWords
                  .take(7) // 7개 단어까지 표시
                  .map((word) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  word.english,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
                  .toList(),
            ),
            if (chunk.includedWords.length > 7)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '+ ${chunk.includedWords.length - 7}개 더...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        onTap: () => _viewChunkDetails(context, chunk),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showChunkOptions(context, chunk),
        ),
      ),
    );
  }

  // Method to view chunk details
  void _viewChunkDetails(BuildContext context, Chunk chunk) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChunkDetailScreen(
          chunk: chunk,
        ),
      ),
    );
  }

// Method to show chunk options
  void _showChunkOptions(BuildContext context, Chunk chunk) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('상세 보기'),
                onTap: () {
                  Navigator.pop(context);
                  _viewChunkDetails(context, chunk);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteChunk(context, chunk);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

// Method to confirm chunk deletion
  void _confirmDeleteChunk(BuildContext context, Chunk chunk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단락 삭제'),
        content: Text('"${chunk.title}" 단락을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              // Delete the chunk using Provider
              Provider.of<WordListNotifier>(context, listen: false)
                  .deleteChunk(widget.wordListInfo.name, chunk);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('단락이 삭제되었습니다.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 선택한 단어들을 일괄 삭제
  void _confirmDeleteSelectedWords(BuildContext context, WordListInfo currentListInfo) {
    final selectedWords = currentListInfo.words
        .where((word) => _selectedWordEnglish.contains(word.english))
        .toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단어 삭제'),
        content: Text('선택한 ${selectedWords.length}개의 단어를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              for (final word in selectedWords) {
                Provider.of<WordListNotifier>(context, listen: false)
                    .deleteWord(widget.wordListInfo.name, word);
              }
              setState(() {
                _isSelectionMode = false;
                _selectedWordEnglish.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${selectedWords.length}개의 단어가 삭제되었습니다.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 선택한 단어들로 Chunk 생성 화면으로 이동
  void _moveToChunkCreation(BuildContext context, WordListInfo currentListInfo) {
    final selectedWords = currentListInfo.words
        .where((word) => _selectedWordEnglish.contains(word.english))
        .toList();
    
    // 단어 순서 유지
    selectedWords.sort((a, b) {
      final aIndex = currentListInfo.words.indexOf(a);
      final bIndex = currentListInfo.words.indexOf(b);
      return aIndex.compareTo(bIndex);
    });
    
    // CreateChunkScreen으로 이동하면서 선택한 단어들 전달
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateChunkScreen(
          preSelectedWords: selectedWords,
          wordListName: widget.wordListInfo.name,
        ),
      ),
    ).then((_) {
      // 돌아왔을 때 선택 모드 해제
      setState(() {
        _isSelectionMode = false;
        _selectedWordEnglish.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('=== WordListDetailScreen build ===');
    debugPrint('Word list name: ${widget.wordListInfo.name}');
    
    return Consumer<WordListNotifier>(
      builder: (context, notifier, child) {
        WordListInfo currentListInfo;
        try {
          currentListInfo = notifier.wordLists.firstWhere(
                (list) => list.name == widget.wordListInfo.name,
          );
          debugPrint('Found word list with ${currentListInfo.words.length} words and ${currentListInfo.chunks?.length ?? 0} chunks');
        } catch (e) {
          print('오류: 현재 단어장(${widget.wordListInfo.name})을 찾을 수 없습니다. $e');
          return Scaffold(
            appBar: AppBar(title: Text(widget.wordListInfo.name)),
            body: const Center(child: Text('단어장을 찾을 수 없습니다.\n이전 화면으로 돌아가세요.')),
          );
        }

        // Use DefaultTabController for tab management
        return WillPopScope(
          onWillPop: () async {
            if (_isSelectionMode) {
              setState(() {
                _isSelectionMode = false;
                _selectedWordEnglish.clear();
              });
              return false;
            }
            return true;
          },
          child: DefaultTabController(
            length: 2, // Two tabs: Words and Chunks
            child: Scaffold(
            appBar: AppBar(
              title: Text(_isSelectionMode 
                  ? '${_selectedWordEnglish.length}개 선택' 
                  : currentListInfo.name),
              leading: _isSelectionMode
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedWordEnglish.clear();
                        });
                      },
                    )
                  : null,
              actions: [
                if (_isSelectionMode) ...[
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: '선택한 단어 삭제',
                    onPressed: _selectedWordEnglish.isNotEmpty
                        ? () => _confirmDeleteSelectedWords(context, currentListInfo)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Chunk 생성으로 이동',
                    onPressed: _selectedWordEnglish.isNotEmpty
                        ? () => _moveToChunkCreation(context, currentListInfo)
                        : null,
                  ),
                ] else
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: '새 단어 추가',
                    onPressed: _navigateToAddWord,
                  ),
              ],
              bottom: TabBar(
                tabs: const [
                  Tab(
                    height: 56,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.text_fields, size: 20),
                        SizedBox(height: 4),
                        Text('단어', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Tab(
                    height: 56,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notes, size: 20),
                        SizedBox(height: 4),
                        Text('단락', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                indicatorColor: Colors.orange,
                labelColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.white,
                unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey.shade100,
                labelPadding: EdgeInsets.zero,
              ),
            ),
            body: TabBarView(
              children: [
                // Tab 1: Words list
                _buildWordList(context, currentListInfo.words),

                // Tab 2: Chunks list
                Builder(
                  builder: (context) {
                    debugPrint('Building chunks tab with ${currentListInfo.chunks?.length ?? 0} chunks');
                    return _buildChunkList(context, currentListInfo.chunks ?? []);
                  },
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}
// lib/screens/word_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/presentation/providers/folder_notifier.dart';
import 'package:chunk_up/domain/models/folder.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/core/constants/route_names.dart';
import 'word_list_detail_screen.dart';
import 'word_list_search_screen.dart';
import 'package:chunk_up/core/utils/korean_search_helper.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _expandedFolders = {};
  String _draggedWordListName = '';
  bool _isDragging = false;

  // 진행률에 따른 색상 반환 - 모두 초록색 통일
  Color _getProgressColor(double progress) {
    // 모든 진행도에 대해 동일한 초록색 반환
    return Colors.green;
  }

  // 진행률 바를 세그먼트로 나누어 그리기
  Widget _buildProgressBar(double progress, BuildContext context) {
    // 다크 모드 감지
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 3,
          width: constraints.maxWidth,
          child: Stack(
            children: List.generate(10, (index) {
              final segmentProgress = (index + 1) / 10; // 0.1, 0.2, ..., 1.0
              final segmentWidth = constraints.maxWidth / 10;
              double width = 0;

              if (progress >= segmentProgress) {
                // 완전히 채워진 세그먼트
                width = segmentWidth;
              } else if (progress > (segmentProgress - 0.1)) {
                // 부분적으로 채워진 세그먼트 (현재 진행 중인 세그먼트)
                final segmentFillPercentage = (progress - (segmentProgress - 0.1)) / 0.1;
                width = segmentWidth * segmentFillPercentage;
              }

              // 다크 모드에 맞는 색상 선택
              final color = isDarkMode ? Colors.lightGreen : Colors.green;

              return Positioned(
                left: index * segmentWidth,
                child: Container(
                  height: 3,
                  width: width,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: index == 9 && progress >= 0.99
                        ? const BorderRadius.only(topRight: Radius.circular(8))
                        : null,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 단어장'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '단어장 검색',
            onPressed: () => _navigateToSearchScreen(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '더보기',
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
      body: Consumer2<WordListNotifier, FolderNotifier>(
        builder: (context, wordListNotifier, folderNotifier, child) {
          if (wordListNotifier.isLoading || folderNotifier.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final folders = folderNotifier.folders;
          final allWordLists = wordListNotifier.wordLists;

          // 폴더에 속하지 않은 단어장들
          final unorganizedWordLists = _getUnorganizedWordLists(allWordLists, folders);

          return ListView(
            children: [
              // 폴더 목록
              ...folders.map((folder) => _buildFolderItem(folder, allWordLists)),

              if (unorganizedWordLists.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Builder(
                    builder: (context) {
                      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                      return Text(
                        '미분류 단어장',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ],

              // 폴더에 속하지 않은 단어장들
              ...unorganizedWordLists.map((wordList) => _buildWordListItem(wordList, null)),
            ],
          );
        },
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    // 디바이스 네비게이터 바 높이 계산
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 더 많은 공간을 사용할 수 있도록 허용
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // 다크 모드 감지
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return SafeArea(
          child: Padding(
            // 네비게이터 바 높이만큼 하단 패딩 추가
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 핸들바 추가 (옵션)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // 제목 추가
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      '단어장 관리',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),

                  // 구분선
                  Divider(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),

                  // 메뉴 항목
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_box, color: Colors.orange),
                    ),
                    title: const Text('새 단어장 만들기'),
                    subtitle: const Text('단어 학습을 위한 새 단어장을 생성합니다'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddWordListDialog(context);
                    },
                  ),

                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.create_new_folder, color: Colors.blue),
                    ),
                    title: const Text('새 폴더 만들기'),
                    subtitle: const Text('단어장을 정리할 새 폴더를 생성합니다'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddFolderDialog(context);
                    },
                  ),

                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.green),
                    ),
                    title: const Text('단어장 내보내기'),
                    subtitle: const Text('단어장을 PDF 파일로 내보냅니다'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToExportScreen(context);
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

  void _navigateToExportScreen(BuildContext context) {
    Navigator.pushNamed(context, RouteNames.wordListExport);
  }

  Widget _buildFolderItem(Folder folder, List<WordListInfo> allWordLists) {
    final isExpanded = _expandedFolders[folder.name] ?? false;
    final wordListsInFolder = allWordLists
        .where((list) => folder.wordListNames.contains(list.name))
        .toList();

    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => !folder.wordListNames.contains(data.data),
      onAcceptWithDetails: (details) {
        Provider.of<FolderNotifier>(context, listen: false)
            .addWordListToFolder(folder.name, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        // 폴더 내 단어장들의 맥락화 진행도 계산
        int totalWords = 0;
        int wordsInChunks = 0;
        for (var wordList in wordListsInFolder) {
          totalWords += wordList.wordCount;
          wordsInChunks += wordList.contextualizedWordCount;
        }
        final double folderProgress = totalWords > 0 ? wordsInChunks / totalWords : 0.0;

        // 다크 모드 감지
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isHovering
                ? (isDarkMode ? Colors.orange.shade900.withOpacity(0.2) : Colors.orange.shade50)
                : (isDarkMode ? Colors.grey.shade800 : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHovering
                  ? Colors.orange
                  : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
              width: isHovering ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // 폴더 맥락화 진행도 표시 바
              Container(
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: _buildProgressBar(folderProgress, context),
              ),

              ListTile(
                leading: Icon(
                  isExpanded ? Icons.folder_open : Icons.folder,
                  color: isDarkMode ? Colors.orange.shade300 : Colors.orange,
                ),
                title: Text(
                  folder.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '단어장: ${wordListsInFolder.length}개',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                    if (totalWords > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '맥락화: ${(folderProgress * 100).toInt()}% (${wordsInChunks}/${totalWords})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.lightGreen : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: () {
                        setState(() {
                          _expandedFolders[folder.name] = !isExpanded;
                        });
                      },
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('이름 변경'),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 10),
                                () => _showRenameFolderDialog(context, folder.name),
                          ),
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('삭제', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 10),
                                () => _showDeleteFolderConfirmation(context, folder.name),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  setState(() {
                    _expandedFolders[folder.name] = !isExpanded;
                  });
                },
              ),

              if (isExpanded)
                ...wordListsInFolder.map((wordList) =>
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: _buildWordListItem(wordList, folder.name),
                    ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordListItem(WordListInfo wordList, String? folderName) {
    return Draggable<String>(
      data: wordList.name,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            wordList.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      onDragStarted: () {
        setState(() {
          _isDragging = true;
          _draggedWordListName = wordList.name;
        });
      },
      onDragEnd: (_) {
        setState(() {
          _isDragging = false;
          _draggedWordListName = '';
        });
      },
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildWordListTile(wordList, folderName),
      ),
      child: _buildWordListTile(wordList, folderName),
    );
  }

  Widget _buildWordListTile(WordListInfo wordList, String? folderName) {
    // 단어 맥락화 진행도 계산 - WordListInfo 클래스의 getter 활용
    final double contextProgress = wordList.contextProgress; // 간소화된 코드

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 단어 맥락화 진행도 표시 바
          Container(
            height: 3,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: _buildProgressBar(contextProgress, context),
          ),

          // 기존 ListTile
          ListTile(
            leading: const Icon(Icons.menu_book_outlined, color: Colors.orange),
            title: Text(
              wordList.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('단어: ${wordList.words.length}개 / 단락: ${wordList.chunkCount}개'),
                const SizedBox(height: 2),
                Text(
                  '맥락화: ${wordList.contextProgressPercent}% (${wordList.contextualizedWordCount}/${wordList.wordCount})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('이름 수정'),
                ],
              ),
              onTap: () => Future.delayed(
                const Duration(milliseconds: 10),
                    () => _showWordListRenameDialog(context, wordList),
              ),
            ),
            if (folderName != null)
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.drive_file_move_outline, size: 20),
                    SizedBox(width: 8),
                    Text('폴더에서 제거'),
                  ],
                ),
                onTap: () => Future.delayed(
                  const Duration(milliseconds: 10),
                      () => Provider.of<FolderNotifier>(context, listen: false)
                      .removeWordListFromFolder(folderName, wordList.name),
                ),
              ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('삭제', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () => Future.delayed(
                const Duration(milliseconds: 10),
                    () => _showWordListDeleteDialog(context, wordList),
              ),
            ),
          ],
        ),
        onTap: () => _viewWordListDetails(context, wordList),
      ),
    ]));
  }

  Widget _buildAddFolderButton() {
    return ListTile(
      leading: const Icon(Icons.create_new_folder, color: Colors.grey),
      title: const Text(
        '새 폴더 추가',
        style: TextStyle(color: Colors.grey),
      ),
      onTap: () => _showAddFolderDialog(context),
    );
  }

  List<WordListInfo> _getUnorganizedWordLists(
      List<WordListInfo> allWordLists,
      List<Folder> folders,
      ) {
    final organizedWordListNames = folders
        .expand((folder) => folder.wordListNames)
        .toSet();

    return allWordLists
        .where((list) => !organizedWordListNames.contains(list.name))
        .toList();
  }

  void _navigateToSearchScreen(BuildContext context) {
    // 전체 화면 검색 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WordListSearchScreen(),
      ),
    );
  }

  Future<void> _showAddWordListDialog(BuildContext context) async {
    final TextEditingController textController = TextEditingController();
    final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('새 단어장 이름'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "단어장 이름을 입력하세요"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('추가'),
              onPressed: () {
                final String newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  wordListNotifier.addNewWordList(newName);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddFolderDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final folderNotifier = Provider.of<FolderNotifier>(context, listen: false);

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 폴더 이름'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '폴더 이름을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                folderNotifier.addFolder(name);
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameFolderDialog(BuildContext context, String folderName) async {
    final TextEditingController controller = TextEditingController(text: folderName);
    final folderNotifier = Provider.of<FolderNotifier>(context, listen: false);

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '새 폴더 이름을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty && name != folderName) {
                folderNotifier.renameFolder(folderName, name);
                setState(() {
                  _expandedFolders[name] = _expandedFolders[folderName] ?? false;
                  _expandedFolders.remove(folderName);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteFolderConfirmation(BuildContext context, String folderName) {
    final folderNotifier = Provider.of<FolderNotifier>(context, listen: false);

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"$folderName" 폴더 삭제'),
        content: const Text('정말로 이 폴더를 삭제하시겠습니까?\n폴더 내 단어장은 삭제되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              folderNotifier.deleteFolder(folderName);
              setState(() {
                _expandedFolders.remove(folderName);
              });
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWordListRenameDialog(BuildContext context, WordListInfo listInfo) {
    final TextEditingController controller = TextEditingController(text: listInfo.name);
    final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단어장 이름 수정'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '새 이름을 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != listInfo.name) {
                wordListNotifier.editWordListName(listInfo, newName);
                Navigator.pop(context);
              }
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWordListDeleteDialog(BuildContext context, WordListInfo listInfo) {
    final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('"${listInfo.name}" 삭제'),
        content: const Text('정말로 이 단어장을 삭제하시겠습니까? 포함된 단어들도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              wordListNotifier.deleteWordList(listInfo);
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _viewWordListDetails(BuildContext context, WordListInfo listInfo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WordListDetailScreen(wordListInfo: listInfo),
      ),
    );
  }
}


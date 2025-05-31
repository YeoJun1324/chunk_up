// lib/presentation/screens/word_list_selection_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/presentation/providers/folder_notifier.dart';

class WordListSelectionModal extends StatefulWidget {
  final Function(WordListInfo) onWordListSelected;
  final String? selectedWordListName;

  const WordListSelectionModal({
    Key? key,
    required this.onWordListSelected,
    this.selectedWordListName,
  }) : super(key: key);

  @override
  State<WordListSelectionModal> createState() => _WordListSelectionModalState();
}

class _WordListSelectionModalState extends State<WordListSelectionModal> {
  String _searchQuery = '';
  String? _expandedFolder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  '단어장 선택',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: '단어장 검색...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ],
            ),
          ),
          // Word lists
          Expanded(
            child: Consumer2<WordListNotifier, FolderNotifier>(
              builder: (context, wordListNotifier, folderNotifier, child) {
                final folders = folderNotifier.folders;
                final wordLists = wordListNotifier.wordLists;
                
                // Filter word lists based on search
                final filteredWordLists = wordLists.where((list) {
                  return list.name.toLowerCase().contains(_searchQuery);
                }).toList();

                // Group word lists by folder
                final Map<String?, List<WordListInfo>> groupedLists = {
                  null: [],
                };
                
                for (final folder in folders) {
                  groupedLists[folder.name] = [];
                }
                
                // WordListInfo에 folderName이 없으므로 folder에 포함된 단어장을 찾음
                for (final wordList in filteredWordLists) {
                  bool foundInFolder = false;
                  for (final folder in folders) {
                    if (folder.wordListNames.contains(wordList.name)) {
                      groupedLists[folder.name]?.add(wordList);
                      foundInFolder = true;
                      break;
                    }
                  }
                  if (!foundInFolder) {
                    groupedLists[null]?.add(wordList);
                  }
                }
                
                // Remove empty folders
                groupedLists.removeWhere((key, value) => value.isEmpty);
                
                return ListView(
                  children: [
                    // Ungrouped word lists
                    if (groupedLists[null]?.isNotEmpty ?? false) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          '분류되지 않음',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      ...groupedLists[null]!.map((wordList) => _buildWordListTile(wordList)),
                    ],
                    // Grouped word lists
                    ...folders.map((folder) {
                      final listsInFolder = groupedLists[folder.name] ?? [];
                      if (listsInFolder.isEmpty) return const SizedBox.shrink();
                      
                      final isExpanded = _expandedFolder == folder.name;
                      
                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _expandedFolder = isExpanded ? null : folder.name;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    isExpanded ? Icons.folder_open : Icons.folder,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      folder.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${listsInFolder.length}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isExpanded ? Icons.expand_less : Icons.expand_more,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isExpanded)
                            ...listsInFolder.map((wordList) => Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: _buildWordListTile(wordList),
                            )),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordListTile(WordListInfo wordList) {
    final isSelected = wordList.name == widget.selectedWordListName;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSelected ? Colors.orange : Colors.grey[300],
        child: Text(
          wordList.name[0].toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        wordList.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.orange : null,
        ),
      ),
      subtitle: Text('${wordList.words.length}개 단어'),
      selected: isSelected,
      selectedTileColor: Colors.orange.withOpacity(0.1),
      onTap: () {
        widget.onWordListSelected(wordList);
        Navigator.pop(context);
      },
    );
  }
}
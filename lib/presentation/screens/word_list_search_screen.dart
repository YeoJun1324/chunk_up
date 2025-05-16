// lib/presentation/screens/word_list_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/presentation/screens/word_list_detail_screen.dart';
import 'package:chunk_up/core/utils/korean_search_helper.dart';

class WordListSearchScreen extends StatefulWidget {
  const WordListSearchScreen({super.key});

  @override
  State<WordListSearchScreen> createState() => _WordListSearchScreenState();
}

class _WordListSearchScreenState extends State<WordListSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어장 검색'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '단어장 또는 단어 검색 (초성 검색 가능)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: Consumer<WordListNotifier>(
        builder: (context, notifier, child) {
          if (_searchQuery.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade800.withOpacity(0.6) : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search,
                      size: 80,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '단어장 또는 단어를 검색하세요',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '단어장 이름, 영어 단어, 한글 뜻으로 검색 가능합니다',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final wordLists = notifier.wordLists;
          final results = _searchWordLists(wordLists, _searchQuery);

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '검색 결과가 없습니다',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"$_searchQuery"에 대한 결과를 찾지 못했습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('검색어 지우기'),
                  ),
                ],
              ),
            );
          }

          // 검색 결과가 있는 경우
          return ListView.builder(
            itemCount: results.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final result = results[index];
              final isWordList = result['type'] == 'wordList';
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isWordList ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isWordList ? Icons.menu_book : Icons.text_fields,
                      color: isWordList ? Colors.blue : Colors.orange,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    result['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    result['subtitle'],
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _viewWordListDetails(context, result['wordList']),
                ),
              );
            },
          );
        },
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

  List<Map<String, dynamic>> _searchWordLists(
    List<WordListInfo> wordLists,
    String query,
  ) {
    final results = <Map<String, dynamic>>[];

    // 단어장 이름으로 검색
    for (var wordList in wordLists) {
      if (KoreanSearchHelper.matches(wordList.name, query)) {
        results.add({
          'type': 'wordList',
          'title': wordList.name,
          'subtitle': '단어: ${wordList.words.length}개, 단락: ${wordList.chunkCount}개',
          'wordList': wordList,
        });
      }
    }

    // 단어로 검색
    for (var wordList in wordLists) {
      final matchingWords = wordList.words.where((word) =>
          KoreanSearchHelper.matches(word.english, query) ||
          KoreanSearchHelper.matches(word.korean, query)
      ).toList();

      for (var word in matchingWords) {
        results.add({
          'type': 'word',
          'title': '${word.english} - ${word.korean}',
          'subtitle': '단어장: ${wordList.name}',
          'wordList': wordList,
        });
      }
    }

    return results;
  }
}
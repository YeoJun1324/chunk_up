// lib/screens/select_words_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';

class SelectWordsScreen extends StatefulWidget {
  final WordListInfo wordList;
  final List<Word> initiallySelectedWords;

  const SelectWordsScreen({
    super.key,
    required this.wordList,
    required this.initiallySelectedWords,
  });

  @override
  State<SelectWordsScreen> createState() => _SelectWordsScreenState();
}

class _SelectWordsScreenState extends State<SelectWordsScreen> {
  late List<Word> _selectedWords;

  @override
  void initState() {
    super.initState();
    // 초기 선택된 단어들로 상태 설정 (깊은 복사)
    _selectedWords = List<Word>.from(widget.initiallySelectedWords);
  }

  void _toggleWordSelection(Word word) {
    setState(() {
      if (_selectedWords.any((selected) => selected.english == word.english)) { // 간단히 영어 단어로 비교
        _selectedWords.removeWhere((selected) => selected.english == word.english);
      } else {
        _selectedWords.add(word);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.wordList.name}: 단어 선택'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: '선택 완료',
            onPressed: () {
              // 선택된 단어 목록을 이전 화면으로 반환
              Navigator.pop(context, _selectedWords);
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: widget.wordList.words.length,
        itemBuilder: (context, index) {
          final word = widget.wordList.words[index];
          final bool isSelected = _selectedWords.any((selected) => selected.english == word.english);
          return CheckboxListTile(
            title: Text(word.english),
            subtitle: Text(word.korean),
            value: isSelected,
            onChanged: (bool? value) {
              _toggleWordSelection(word);
            },
            activeColor: Colors.orange, // 체크박스 활성화 색상 변경
            checkColor: Colors.white, // 체크 표시 색상
          );
        },
      ),
    );
  }
}
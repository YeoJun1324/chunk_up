// lib/screens/new_word_add_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider import
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';

class NewWordAddScreen extends StatefulWidget {
  final String wordListName; // 어느 단어장에 추가할지 식별하기 위해 여전히 필요

  const NewWordAddScreen({
    super.key,
    required this.wordListName,
    // final void Function(Word newWord) onWordAdded; // <<< 이 콜백 파라미터 제거
  });

  @override
  State<NewWordAddScreen> createState() => _NewWordAddScreenState();
}

class _NewWordAddScreenState extends State<NewWordAddScreen> {
  final TextEditingController _englishController = TextEditingController();
  final TextEditingController _koreanController = TextEditingController();

  @override
  void dispose() {
    _englishController.dispose();
    _koreanController.dispose();
    super.dispose();
  }

  void _addWordToList() {
    final String englishWord = _englishController.text.trim();
    final String koreanMeaning = _koreanController.text.trim();

    if (englishWord.isNotEmpty && koreanMeaning.isNotEmpty) {
      final newWord = Word(english: englishWord, korean: koreanMeaning);

      // Provider를 사용하여 단어 추가
      // listen: false는 UI를 다시 빌드할 필요 없이 메서드만 호출할 때 사용
      Provider.of<WordListNotifier>(context, listen: false)
          .addWordToSpecificList(widget.wordListName, newWord);

      // 현재 화면 닫고 이전 화면으로 돌아가기
      if (mounted) { // 위젯이 여전히 트리에 있는지 확인 (비동기 작업 후 중요)
        Navigator.pop(context);
      }
    } else {
      // 사용자에게 입력값이 비어있다고 알려주기 (예: SnackBar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('영어 단어와 한글 뜻을 모두 입력해주세요.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      print('영어 단어와 한글 뜻을 모두 입력해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('"${widget.wordListName}"에 새 단어 추가'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 버튼 너비 채우기
          children: [
            TextField(
              controller: _englishController,
              decoration: const InputDecoration(
                labelText: '영어 단어',
                hintText: '예: apple',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _koreanController,
              decoration: const InputDecoration(
                labelText: '한글 뜻',
                hintText: '예: 사과',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('단어 추가'),
              onPressed: _addWordToList,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
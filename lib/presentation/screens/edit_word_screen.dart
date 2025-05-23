// lib/presentation/screens/edit_word_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';

class EditWordScreen extends StatefulWidget {
  final Word word;
  final String wordListName;

  const EditWordScreen({
    super.key,
    required this.word,
    required this.wordListName,
  });

  @override
  State<EditWordScreen> createState() => _EditWordScreenState();
}

class _EditWordScreenState extends State<EditWordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _englishController;
  late TextEditingController _koreanController;

  @override
  void initState() {
    super.initState();
    _englishController = TextEditingController(text: widget.word.english);
    _koreanController = TextEditingController(text: widget.word.korean);
  }

  @override
  void dispose() {
    _englishController.dispose();
    _koreanController.dispose();
    super.dispose();
  }

  // 단어 수정 처리
  void _updateWord() {
    if (_formKey.currentState!.validate()) {
      final updatedWord = widget.word.copyWith(
        english: _englishController.text.trim(),
        korean: _koreanController.text.trim(),
      );

      // Provider를 통해 단어 업데이트
      Provider.of<WordListNotifier>(context, listen: false)
          .updateWord(widget.wordListName, widget.word, updatedWord);

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('단어가 성공적으로 수정되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      // 이전 화면으로 이동
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 수정'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 영어 단어 입력 필드
              TextFormField(
                controller: _englishController,
                decoration: const InputDecoration(
                  labelText: '영어 단어',
                  hintText: '영어 단어를 입력하세요',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '영어 단어를 입력해주세요';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // 한국어 의미 입력 필드
              TextFormField(
                controller: _koreanController,
                decoration: const InputDecoration(
                  labelText: '한국어 의미',
                  hintText: '한국어 의미를 입력하세요',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '한국어 의미를 입력해주세요';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _updateWord(),
              ),
              const SizedBox(height: 24),
              
              // 수정 버튼
              ElevatedButton(
                onPressed: _updateWord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '단어 수정',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              // 주의사항 (단어가 청크에 포함된 경우 경고)
              if (widget.word.isInChunk)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade800),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '이 단어는 이미 단락에서 사용 중입니다. 수정 시 기존 단락의 내용과 일치하지 않을 수 있습니다.',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
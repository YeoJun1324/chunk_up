// lib/screens/select_words_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/core/services/subscription_service.dart';
import 'package:chunk_up/di/service_locator.dart';

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
  late SubscriptionService _subscriptionService;
  int _maxWordLimit = 10; // 기본값은 무료 사용자 제한

  @override
  void initState() {
    super.initState();
    // 초기 선택된 단어들로 상태 설정 (깊은 복사)
    _selectedWords = List<Word>.from(widget.initiallySelectedWords);

    // 구독 서비스 초기화 및 단어 제한 가져오기
    _initSubscriptionService();
  }

  void _initSubscriptionService() {
    try {
      if (!getIt.isRegistered<SubscriptionService>()) {
        getIt.registerLazySingleton<SubscriptionService>(() => SubscriptionService());
      }

      _subscriptionService = getIt<SubscriptionService>();
      _maxWordLimit = _subscriptionService.maxWordLimit;

      debugPrint('📏 단어 선택 화면: 최대 단어 제한 = $_maxWordLimit');
    } catch (e) {
      debugPrint('❌ 구독 서비스 초기화 실패: $e');
    }
  }

  void _toggleWordSelection(Word word) {
    setState(() {
      if (_selectedWords.any((selected) => selected.english == word.english)) {
        // 이미 선택된 단어라면 제거
        _selectedWords.removeWhere((selected) => selected.english == word.english);
      } else {
        // 최대 단어 수 제한 검사
        if (_selectedWords.length >= _maxWordLimit) {
          // 선택 단어 수가 최대치에 도달했을 때 알림
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('최대 $_maxWordLimit개까지 선택할 수 있습니다.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }

        // 제한에 도달하지 않았다면 단어 추가
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
          // 선택된 단어 수 표시
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '${_selectedWords.length}/$_maxWordLimit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _selectedWords.length >= _maxWordLimit ? Colors.orange : Colors.white,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: '선택 완료',
            onPressed: () {
              // 최소 5개 단어 선택 체크
              if (_selectedWords.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('최소 5개 이상의 단어를 선택해주세요.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

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
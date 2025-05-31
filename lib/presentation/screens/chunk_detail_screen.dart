// lib/screens/chunk_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/services/api_service_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:chunk_up/infrastructure/error/error_service.dart';
import 'package:chunk_up/core/utils/word_highlighter.dart';

class ChunkDetailScreen extends StatefulWidget {
  final Chunk chunk;

  const ChunkDetailScreen({
    super.key,
    required this.chunk,
  });

  @override
  State<ChunkDetailScreen> createState() => _ChunkDetailScreenState();
}

class _ChunkDetailScreenState extends State<ChunkDetailScreen> {
  final ErrorService _errorService = ErrorService();
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _showWordExplanation(BuildContext context, String word) {
    // Get explanation if it exists
    String? explanation = widget.chunk.wordExplanations[word];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bContext) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                    Text(
                      "'$word' 단어 해설",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: SingleChildScrollView(
                        child: explanation != null
                            ? Text(
                          explanation,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        )
                            : _buildWordExplanationRequest(setModalState, word),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        child: const Text('닫기', style: TextStyle(color: Colors.orange)),
                        onPressed: () => Navigator.pop(bContext),
                      ),
                    ),
                  ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildWordExplanationRequest(StateSetter setModalState, String word) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "이 단어에 대한 설명이 아직 준비되지 않았습니다.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.auto_awesome),
          label: const Text('AI 해설 생성하기'),
          onPressed: () => _generateExplanation(setModalState, word),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 단어 설명 생성 - 불변성 패턴 적용
  Future<void> _generateExplanation(StateSetter setModalState, String word) async {
    setModalState(() {
      _isLoading = true;
    });

    try {
      await _errorService.handleErrorWithContext(
        context: context,
        operation: 'generateExplanation',
        action: () async {
          final apiService = GetIt.instance<ApiServiceInterface>();
          final String explanation = await apiService.generateWordExplanation(
            word,
            widget.chunk.englishContent,
          );

          if (!mounted) return;

          // 불변성 패턴 적용 - 새로운 Chunk 객체 생성하고 설명 추가
          setState(() {
            // widget.chunk는 불변이므로 새 객체를 생성해 업데이트해야 함
            // 하지만 현재 StatefulWidget에서 불변성을 완전히 구현하려면 부모 위젯으로부터
            // 업데이트 콜백을 전달받아야 함 (이 구현에서는 생략)
            // 향후 개선: Provider나 다른 상태 관리 솔루션으로 이동해야 함
            widget.chunk.wordExplanations[word] = explanation;
          });

          setModalState(() {
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setModalState(() {
        _isLoading = false;
      });
    }
  }


  // AI 모델 표시 위젯 제거 - 오직 Gemini만 사용
  Widget _buildModelInfo() {
    // 모델 정보를 표시하지 않음
    return const SizedBox.shrink();
  }

  Widget _buildWordList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '포함된 단어',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.orange
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300
            ),
          ),
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF333333)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: widget.chunk.includedWords.map((word) {
                // 단어 설명이 있는지 확인
                final bool hasExplanation = widget.chunk.wordExplanations.containsKey(word.english.toLowerCase());

                return InkWell(
                  onTap: () => _showWordExplanation(context, word.english.toLowerCase()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange.withOpacity(0.5)
                            : Colors.orange.withOpacity(0.3)
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          word.english,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chunk.title),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? null // Use default dark theme color
            : Colors.orange, // Use orange background in light mode
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // 영어 단락
                _buildContentSection(
                  '영어 단락 (English Chunk)',
                  widget.chunk.englishContent,
                  isEnglish: true,
                ),
                // 한국어 해석
                _buildContentSection(
                  '한국어 해석 (Korean Translation)',
                  widget.chunk.koreanTranslation,
                  isEnglish: false,
                ),
                // 단어 목록
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildWordList(),
                ),
                // AI 모델 정보 표시 제거 - 오직 Gemini만 사용
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '단어 해설 생성 중...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildContentSection(String title, String content, {bool isEnglish = false}) {
    // ||| 구분자 제거하고 공백 추가
    final displayContent = content.replaceAll('|||', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEnglish ? Icons.article : Icons.translate,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: isEnglish
                  ? WordHighlighter.buildHighlightedText(
                      text: displayContent,
                      highlightWords: widget.chunk.includedWords,
                      highlightColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.orange.shade300
                          : Colors.orange,
                      onTap: (word) => _showWordExplanation(context, word.toLowerCase()),
                      underlineHighlights: true,
                      textColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 17.5,
                    )
                  : Text(
                      displayContent,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.6,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
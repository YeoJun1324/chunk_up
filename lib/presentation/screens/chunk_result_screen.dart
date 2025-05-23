// lib/screens/chunk_result_screen.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/data/datasources/remote/api_service.dart' as remote_api;
import 'package:chunk_up/core/services/api_service.dart';
import 'package:chunk_up/core/utils/word_highlighter.dart';
import 'package:chunk_up/di/service_locator.dart' as di;
import 'package:uuid/uuid.dart';

class ChunkResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final WordListInfo wordListInfo;
  final List<Word> selectedWords;

  const ChunkResultScreen({
    super.key,
    required this.result,
    required this.wordListInfo,
    required this.selectedWords,
  });

  @override
  State<ChunkResultScreen> createState() => _ChunkResultScreenState();
}

/// 결과 객체를 위한 불변 클래스 - 상태 관리 개선
class ChunkResultData {
  final String title;
  final String englishChunk;
  final String koreanTranslation;
  final Map<String, dynamic> wordExplanations;
  final String? chunkId;
  final String? usedModel;
  final bool isSaved;
  final Map<String, dynamic>? originalGenerationParams;

  ChunkResultData({
    required this.title,
    required this.englishChunk,
    required this.koreanTranslation,
    required this.wordExplanations,
    this.chunkId,
    this.usedModel,
    this.isSaved = false,
    this.originalGenerationParams,
  });

  // 맵에서 객체 생성 - 초기화에 사용
  factory ChunkResultData.fromMap(Map<String, dynamic> map) {
    return ChunkResultData(
      title: map['title'] ?? 'New Chunk',
      englishChunk: map['englishChunk'] ?? '',
      koreanTranslation: map['koreanTranslation'] ?? '',
      wordExplanations: Map<String, dynamic>.from(map['wordExplanations'] ?? {}),
      chunkId: map['chunkId'],
      usedModel: map['usedModel'],
      isSaved: map['isSaved'] ?? false,
      originalGenerationParams: map['originalGenerationParams'],
    );
  }

  // 변경된 데이터로 새 객체 생성 - 불변성 유지
  ChunkResultData copyWith({
    String? title,
    String? englishChunk,
    String? koreanTranslation,
    Map<String, dynamic>? wordExplanations,
    String? chunkId,
    String? usedModel,
    bool? isSaved,
    Map<String, dynamic>? originalGenerationParams,
  }) {
    return ChunkResultData(
      title: title ?? this.title,
      englishChunk: englishChunk ?? this.englishChunk,
      koreanTranslation: koreanTranslation ?? this.koreanTranslation,
      wordExplanations: wordExplanations ?? Map<String, dynamic>.from(this.wordExplanations),
      chunkId: chunkId ?? this.chunkId,
      usedModel: usedModel ?? this.usedModel,
      isSaved: isSaved ?? this.isSaved,
      originalGenerationParams: originalGenerationParams ?? this.originalGenerationParams,
    );
  }

  // 단어 설명 추가 - 불변성 유지
  ChunkResultData addWordExplanation(String word, String explanation) {
    final newExplanations = Map<String, dynamic>.from(wordExplanations);
    newExplanations[word.toLowerCase()] = explanation;
    return copyWith(wordExplanations: newExplanations);
  }

  // Chunk 객체로 변환 - 저장에 사용
  Chunk toChunk(List<Word> includedWords) {
    // Map<String, dynamic>을 Map<String, String>으로 변환
    final Map<String, String> normalizedExplanations = {};
    wordExplanations.forEach((key, value) {
      if (key is String) {
        normalizedExplanations[key.toLowerCase()] = value.toString();
      }
    });

    return Chunk(
      id: chunkId ?? const Uuid().v4(),
      title: title,
      englishContent: englishChunk,
      koreanTranslation: koreanTranslation,
      includedWords: includedWords,
      wordExplanations: normalizedExplanations,
      character: originalGenerationParams?['character'],
      scenario: originalGenerationParams?['scenario'],
      additionalDetails: originalGenerationParams?['details'],
      usedModel: usedModel,
    );
  }
}

class _ChunkResultScreenState extends State<ChunkResultScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isModified = false; // 수정 여부 추적
  late TextEditingController _englishTextController;
  late TextEditingController _koreanTextController;
  late TextEditingController _titleController;

  // 불변 결과 객체를 사용
  late ChunkResultData _resultData;

  @override
  void initState() {
    super.initState();

    // 맵 데이터를 결과 객체로 변환
    _resultData = ChunkResultData.fromMap({
      'title': widget.result['title'],
      'englishChunk': widget.result['englishChunk'],
      'koreanTranslation': widget.result['koreanTranslation'],
      'wordExplanations': widget.result['wordExplanations'] ?? {},
      'chunkId': widget.result['chunkId'],
      'isSaved': widget.result['isSaved'] ?? false,
      'originalGenerationParams': widget.result['originalGenerationParams'],
    });

    // 텍스트 컨트롤러 초기화
    _englishTextController = TextEditingController(text: _resultData.englishChunk);
    _koreanTextController = TextEditingController(text: _resultData.koreanTranslation);
    _titleController = TextEditingController(text: _resultData.title);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _englishTextController.dispose();
    _koreanTextController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  /// 단어 설명 생성 - 불변성 원칙 적용
  Future<void> _generateExplanation(StateSetter setModalState, String word) async {
    // 상태 설정: 로딩 중
    setModalState(() {
      _isLoading = true;
    });

    try {
      // API 서비스를 통해 설명 생성
      final String explanation = await remote_api.ApiService.generateWordExplanation(
        word,
        _resultData.englishChunk,
      );

      if (!mounted) return;

      // 불변 객체를 사용하여 결과 업데이트
      setState(() {
        // 새 단어 설명을 추가한 새 결과 객체 생성
        _resultData = _resultData.addWordExplanation(word.toLowerCase(), explanation);
        _isModified = true; // 수정됨으로 표시
      });

      // 모달 상태 업데이트
      setModalState(() {
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('단어 해설 생성 오류: $e');
      if (!mounted) return;

      setModalState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('단어 해설 생성 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWordExplanation(BuildContext context, String word) {
    // 단어를 소문자로 변환하여 일관성 유지
    word = word.toLowerCase();

    // 선택된 단어인지 확인
    final bool isSelectedWord = widget.selectedWords
        .any((w) => w.english.toLowerCase() == word);

    // 선택된 단어가 아니면 알림만 표시하고 리턴
    if (!isSelectedWord) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'$word'는 학습 단어 목록에 없습니다."),
          action: SnackBarAction(
            label: '사전 검색',
            onPressed: () {
              // TODO: 사전 검색 기능 구현
              debugPrint('Look up "$word" in dictionary');
            },
          ),
        ),
      );
      return;
    }

    // 불변 객체에서 단어 설명 가져오기
    String? explanation = _resultData.wordExplanations[word.toLowerCase()]?.toString();

    // 디버깅 로그
    debugPrint('단어 설명 찾기: $word -> ${explanation != null ? "설명 있음" : "설명 없음"}');
    if (explanation == null) {
      debugPrint('현재 단어 설명 목록: ${_resultData.wordExplanations.keys.join(', ')}');
    }

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
                            : Column(
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
                        ),
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

  /// 페이지 뷰 콘텐츠 빌드 - 문서화 주석 추가
  Widget _buildPageViewContent(String title, String content, {bool isEnglish = false, required TextEditingController controller}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final isDarkMode = Theme.of(context).brightness == Brightness.dark;
              return Text(
                title.split(' (')[0], // 괄호 속 영어 제거
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8.0),
              color: _isEditing ? Colors.white : Colors.grey.shade50,
              boxShadow: _isEditing
                ? []
                : [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ]
            ),
            child: _isEditing
              ? TextField(
                  controller: controller,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : (isEnglish
                ? WordHighlighter.buildHighlightedText(
                    text: content,
                    highlightWords: widget.selectedWords,
                    highlightColor: Colors.orange,
                    onTap: (word) => _showWordExplanation(context, word),
                  )
                : Text(
                    content,
                    style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87),
                  )
              ),
          ),
        ],
      ),
    );
  }

  // 제목 편집 다이얼로그 표시
  void _showTitleEditDialog(BuildContext context) {
    final TextEditingController editTitleController = TextEditingController(text: _titleController.text);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('제목 편집', style: TextStyle(color: Colors.orange)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '이 단락의 제목을 편집합니다.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: editTitleController,
                decoration: const InputDecoration(
                  hintText: '제목을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('저장'),
              onPressed: () {
                final String newTitle = editTitleController.text.trim();
                if (newTitle.isNotEmpty) {
                  setState(() {
                    _titleController.text = newTitle;
                    _resultData = _resultData.copyWith(title: newTitle);
                    _isModified = true; // 제목 수정으로 수정됨으로 표시
                  });

                  Navigator.pop(dialogContext);

                  // 제목 변경 알림
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('제목이 변경되었습니다'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('제목을 입력해주세요.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleReprint() {
    // 재출력 시 수정됨으로 표시
    setState(() {
      _isModified = true;
    });

    final TextEditingController modificationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('수정 사항 입력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '기존 단락에서 어떤 점을 변경하고 싶으신가요? 구체적으로 설명해주세요.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modificationController,
                decoration: const InputDecoration(
                  hintText: '예: 분위기를 더 밝게 해주세요, 좀 더 대화를 많이 넣어주세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('재생성'),
              onPressed: () {
                final String modifications = modificationController.text.trim();
                if (modifications.isNotEmpty) {
                  Navigator.pop(dialogContext);
                  _generateModifiedChunk(modifications);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('수정 사항을 입력해주세요.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateModifiedChunk(String modifications) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 필요한 import 추가
      final apiService = di.getIt<ApiService>();

      // 단어들의 목록 확보
      final wordList = <String>[];
      for (final word in widget.selectedWords) {
        wordList.add("${word.english}: ${word.korean}");
      }

      // Build modified prompt for the API
      final String modifiedPrompt = """
I need you to improve or modify the paragraph you generated earlier based on specific feedback.

Original paragraph:
${widget.result['englishChunk']}

Original Korean translation:
${widget.result['koreanTranslation']}

Original word list:
${wordList.join('\n')}

Please make these specific changes:
$modifications

REQUIREMENTS:
1. Keep using ALL the same vocabulary words as before
2. Use EACH vocabulary word EXACTLY ONCE - do not repeat any word from the word list
3. Maintain the story flow while applying the requested changes
4. Make the Korean translation natural and fluent
5. FOR EACH WORD in the original word list, provide a detailed explanation IN KOREAN about how the word is used in the context
6. Return ONLY valid JSON with this exact format:
{
  "title": "Updated title that reflects changes",
  "englishContent": "The modified English paragraph...",
  "koreanTranslation": "한국어 번역...",
  "wordExplanations": {
    "word1": "단어1에 대한 한국어 설명: 이 단어는 문단에서 어떻게 사용되었는지, 어떤 의미로 사용되었는지 등",
    "word2": "단어2에 대한 한국어 설명: 이 단어는 문단에서 어떻게 사용되었는지, 어떤 의미로 사용되었는지 등"
  }
}
""";

      // 실제 API 호출 - 원본과 동일한 모델 사용
      final String? originalModel = widget.result['usedModel'];
      if (originalModel != null) {
        debugPrint('🔄 재출력: 원본과 동일한 모델 사용 - $originalModel');
      }
      final Map<String, dynamic> apiResponse = await apiService.generateChunk(
        modifiedPrompt,
        modelOverride: originalModel, // 원본 모델 사용
      );

      // API 응답 처리
      Map<String, dynamic> jsonData = {};

      // 응답 구조 확인 및 파싱
      try {
        // Claude 응답 형식으로 변환
        if (apiResponse.containsKey('content') &&
            apiResponse['content'] is List &&
            apiResponse['content'].isNotEmpty) {

          final String responseText = apiResponse['content'][0]['text'] ?? '';
          print('API 응답 텍스트: ${responseText.substring(0, min(100, responseText.length))}...');

          // JSON 부분 추출
          final jsonStart = responseText.indexOf('{');
          final jsonEnd = responseText.lastIndexOf('}');

          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonString = responseText.substring(jsonStart, jsonEnd + 1);
            final parsedJson = json.decode(jsonString) as Map<dynamic, dynamic>;

            // 필드 매핑
            jsonData = {
              'title': parsedJson['title'] ?? widget.result['title'],
              'english_chunk': parsedJson['englishContent'] ?? parsedJson['english_chunk'] ?? '',
              'korean_translation': parsedJson['koreanTranslation'] ?? parsedJson['korean_translation'] ?? '',
              'wordExplanations': parsedJson['wordExplanations'] ?? {},
            };
          } else {
            throw Exception('API 응답에서 JSON을 찾을 수 없습니다');
          }
        } else {
          throw Exception('API 응답 형식이 예상과 다릅니다');
        }
      } catch (parsingError) {
        print('JSON 파싱 오류: $parsingError');
        throw Exception('응답 파싱 중 오류 발생: $parsingError');
      }

      // 결과 업데이트
      setState(() {
        _isLoading = false;
        if (jsonData['title'] != null) {
          widget.result['title'] = jsonData['title'];
          _titleController.text = jsonData['title'];
        }
        widget.result['englishChunk'] = jsonData['english_chunk'];
        widget.result['koreanTranslation'] = jsonData['korean_translation'];
        _englishTextController.text = jsonData['english_chunk'];
        _koreanTextController.text = jsonData['korean_translation'];

        // 새로운 단어 설명으로 업데이트 - 항상 새로운 단어 설명 적용
        final newExplanations = jsonData['wordExplanations'] ?? {};
        if (newExplanations is Map) {
          // 항상 새 설명으로 전부 교체 (키를 소문자로 변환하여 일관성 유지)
          final Map<String, dynamic> normalizedExplanations = {};
          newExplanations.forEach((key, value) {
            // 문자열 키를 소문자로 변환하여 저장
            if (key is String) {
              normalizedExplanations[key.toLowerCase()] = value;
            } else {
              normalizedExplanations[key.toString()] = value;
            }
          });

          widget.result['wordExplanations'] = normalizedExplanations;
          print('단어 설명 ${normalizedExplanations.length}개 업데이트됨');
        }
        _isModified = true; // 재생성 후 수정됨으로 표시
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('수정된 단락이 생성되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('단락 재생성 중 오류 발생: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('단락 재생성 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 단락 저장 및 홈 화면 이동 - 불변성 원칙 적용
  Future<void> _confirmAndNavigateHome() async {
    // 이미 저장된 청크인지 확인
    if (_resultData.isSaved && !_isModified) {
      // 이미 저장되었고 수정되지 않았으면 바로 홈으로
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('단락이 단어장에 저장되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );

      // Pop until we reach the home route
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    // 수정된 내용이 있을 경우에만 저장
    if (_isModified) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 텍스트 컨트롤러의 값을 사용하여 최신 상태로 결과 데이터 업데이트
        final updatedResultData = _resultData.copyWith(
          title: _titleController.text.trim().isEmpty
              ? _resultData.title
              : _titleController.text.trim(),
          englishChunk: _englishTextController.text,
          koreanTranslation: _koreanTextController.text,
        );

        // 결과 데이터로부터 Chunk 객체 생성
        final updatedChunk = updatedResultData.toChunk(widget.selectedWords);

        // WordListNotifier를 통해 청크 저장
        await Provider.of<WordListNotifier>(context, listen: false)
            .addChunkToWordList(widget.wordListInfo.name, updatedChunk);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('수정된 단락이 저장되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        debugPrint('단락 저장 중 오류 발생: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('단락 저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Navigate back to home screen
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // 사용된 단어 목록을 보여주는 위젯
  Widget _buildUsedWordsSection() {
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
            Builder(
              builder: (context) {
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                return Row(
                  children: [
                    const Icon(Icons.text_fields, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      '사용된 단어 목록',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                );
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 10.0,
              children: widget.selectedWords.map((word) {
                // 단어 설명이 있는지 확인
                final bool hasExplanation = widget.result['wordExplanations'] != null &&
                    widget.result['wordExplanations'][word.english] != null;

                return GestureDetector(
                  onTap: () => _showWordExplanation(context, word.english),
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
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                return Text(
                  '단어를 탭하면 단어 설명을 볼 수 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 불변 객체를 사용하여 현재 상태 가져오기
    final String currentEnglishChunk = _resultData.englishChunk;
    final String currentKoreanTranslation = _resultData.koreanTranslation;

    final List<Widget> pages = [
      // 영어 단락 페이지에는 단어 목록도 함께 표시
      SingleChildScrollView(
        child: Column(
          children: [
            _buildPageViewContent(
              '영어 단락 (English Chunk)',
              currentEnglishChunk,
              isEnglish: true,
              controller: _englishTextController,
            ),
            _buildUsedWordsSection(),
          ],
        ),
      ),
      _buildPageViewContent(
        '한국어 해석 (Korean Translation)',
        currentKoreanTranslation,
        controller: _koreanTextController,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              // 제목 클릭 시 제목 편집 다이얼로그 표시
              _showTitleEditDialog(context);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _isEditing
                    ? TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          hintText: '제목을 입력하세요',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                          return Text(
                            _titleController.text,
                            style: TextStyle(
                              fontSize: 18,
                              color: isDarkMode ? Colors.white : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                ),
                if (!_isEditing)
                  const Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Tooltip(
                      message: '제목 편집',
                      child: Icon(Icons.edit, size: 16, color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40.0),
            child: Builder(
              builder: (context) {
                // 다크 모드 감지
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(pages.length, (index) {
                    return GestureDetector(
                      onTap: () => _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Text(
                          index == 0 ? '영어' : '한국어',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: _currentPageIndex == index ? FontWeight.bold : FontWeight.normal,
                            color: _currentPageIndex == index
                                ? (isDarkMode ? Colors.white : Colors.white)
                                : (isDarkMode ? Colors.white70 : Colors.grey.shade300),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }
            ),
          )
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            children: pages,
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
                      '단락을 처리하고 있습니다...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isEditing
          ? Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('취소'),
              onPressed: () {
                // 편집 취소 - 원래 값으로 되돌림
                setState(() {
                  _isEditing = false;
                  _englishTextController.text = _resultData.englishChunk;
                  _koreanTextController.text = _resultData.koreanTranslation;
                });
              },
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.grey),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined),
              label: const Text('저장'),
              onPressed: () {
                // 불변 객체 패턴 적용 - 새 객체 생성
                setState(() {
                  _resultData = _resultData.copyWith(
                    englishChunk: _englishTextController.text,
                    koreanTranslation: _koreanTextController.text,
                    title: _titleController.text,
                  );
                  _isEditing = false;
                  _isModified = true; // 수정됨으로 표시
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('내용이 저장되었습니다.'), backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.green),
            ),
          ],
        ),
      )
          : Padding(
        padding: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
          top: 12.0,
          bottom: 12.0 + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.orange),
              label: const Text('재출력', style: TextStyle(color: Colors.orange)),
              onPressed: _handleReprint,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange,
                elevation: 1,
                side: const BorderSide(color: Colors.orange),
                minimumSize: Size(MediaQuery.of(context).size.width * 0.44, 48),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, color: Colors.orange),
              label: const Text('확인', style: TextStyle(color: Colors.orange)),
              onPressed: _confirmAndNavigateHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange,
                elevation: 1,
                side: const BorderSide(color: Colors.orange),
                minimumSize: Size(MediaQuery.of(context).size.width * 0.44, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
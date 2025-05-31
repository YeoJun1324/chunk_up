// exam_export_screen_example.dart
// 시험지 내보내기 화면 UI 구현 예시

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'exam_pdf_implementation_example.dart';

class ExamExportScreen extends StatefulWidget {
  const ExamExportScreen({super.key});

  @override
  State<ExamExportScreen> createState() => _ExamExportScreenState();
}

class _ExamExportScreenState extends State<ExamExportScreen> {
  // 선택된 문제 유형과 개수
  final Map<QuestionType, int> _selectedQuestionTypes = {};
  
  // 시험지 설정
  String _difficulty = 'medium';
  bool _includeAnswerKey = true;
  bool _shuffleQuestions = false;
  Duration? _timeLimit;
  String _examTitle = 'ChunkUp 시험지';
  
  // UI 상태
  bool _isGenerating = false;
  
  @override
  void initState() {
    super.initState();
    _initializeDefaultSettings();
  }

  void _initializeDefaultSettings() {
    _selectedQuestionTypes[QuestionType.fillInBlanks] = 5;
    _selectedQuestionTypes[QuestionType.multipleChoice] = 5;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('시험지 내보내기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 메시지
            _buildInfoCard(),
            
            const SizedBox(height: 20),
            
            // 시험지 기본 설정
            _buildBasicSettings(),
            
            const SizedBox(height: 20),
            
            // 문제 유형 선택
            _buildQuestionTypeSelection(),
            
            const SizedBox(height: 20),
            
            // 고급 설정
            _buildAdvancedSettings(),
            
            const SizedBox(height: 20),
            
            // 미리보기 정보
            _buildPreviewInfo(),
            
            const SizedBox(height: 80), // 버튼 공간 확보
          ],
        ),
      ),
      bottomNavigationBar: _buildGenerateButton(),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '시험지 생성',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '학습한 단어와 청크를 바탕으로 다양한 유형의 문제가 포함된 시험지를 생성합니다. '
              '문제 유형과 개수를 선택하고 설정을 조정해보세요.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기본 설정',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            // 시험지 제목
            TextFormField(
              initialValue: _examTitle,
              decoration: const InputDecoration(
                labelText: '시험지 제목',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              onChanged: (value) => _examTitle = value,
            ),
            
            const SizedBox(height: 16),
            
            // 난이도 선택
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('난이도', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDifficultyChip('쉬움', 'easy', Colors.green),
                    const SizedBox(width: 8),
                    _buildDifficultyChip('보통', 'medium', Colors.orange),
                    const SizedBox(width: 8),
                    _buildDifficultyChip('어려움', 'hard', Colors.red),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String label, String value, Color color) {
    final isSelected = _difficulty == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      onSelected: (selected) {
        if (selected) {
          setState(() => _difficulty = value);
        }
      },
    );
  }

  Widget _buildQuestionTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '문제 유형 선택',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            // 문제 유형 목록
            ..._buildQuestionTypeItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQuestionTypeItems() {
    final questionTypeInfo = {
      QuestionType.fillInBlanks: {
        'title': '빈칸 채우기',
        'description': '영어 문장에서 단어를 빈칸으로 만들어 채우는 문제',
        'icon': Icons.edit,
        'points': 2,
      },
      QuestionType.multipleChoice: {
        'title': '객관식 (단어 의미)',
        'description': '문맥상 단어의 의미를 4지선다로 선택하는 문제',
        'icon': Icons.radio_button_checked,
        'points': 3,
      },
      QuestionType.engToKorTranslation: {
        'title': '영한 번역',
        'description': '영어 문장을 한국어로 번역하는 주관식 문제',
        'icon': Icons.translate,
        'points': 5,
      },
      QuestionType.korToEngTranslation: {
        'title': '한영 번역',
        'description': '한국어 문장을 영어로 번역하는 주관식 문제',
        'icon': Icons.translate,
        'points': 5,
      },
      QuestionType.sentenceArrangement: {
        'title': '문장 재배열',
        'description': '뒤섞인 단어들을 올바른 순서로 배열하는 문제',
        'icon': Icons.reorder,
        'points': 4,
      },
    };

    return questionTypeInfo.entries.map((entry) {
      final type = entry.key;
      final info = entry.value;
      final isSelected = _selectedQuestionTypes.containsKey(type);
      final count = _selectedQuestionTypes[type] ?? 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.withOpacity(0.05) : null,
        ),
        child: CheckboxListTile(
          value: isSelected,
          onChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedQuestionTypes[type] = 5; // 기본 5문제
              } else {
                _selectedQuestionTypes.remove(type);
              }
            });
          },
          title: Row(
            children: [
              Icon(info['icon'] as IconData, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${info['points']}점',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info['description'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('문제 수: '),
                    Container(
                      width: 80,
                      child: TextFormField(
                        initialValue: count.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final newCount = int.tryParse(value) ?? 0;
                          if (newCount > 0) {
                            setState(() {
                              _selectedQuestionTypes[type] = newCount;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('문제'),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAdvancedSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '고급 설정',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            
            // 답안지 포함
            SwitchListTile(
              title: const Text('답안지 포함'),
              subtitle: const Text('시험지 뒤에 정답과 해설을 포함합니다'),
              value: _includeAnswerKey,
              onChanged: (value) => setState(() => _includeAnswerKey = value),
            ),
            
            // 문제 섞기
            SwitchListTile(
              title: const Text('문제 섞기'),
              subtitle: const Text('문제 순서를 무작위로 섞습니다'),
              value: _shuffleQuestions,
              onChanged: (value) => setState(() => _shuffleQuestions = value),
            ),
            
            // 제한시간 설정
            ListTile(
              title: const Text('제한시간 설정'),
              subtitle: Text(_timeLimit != null 
                  ? '${_timeLimit!.inMinutes}분' 
                  : '제한시간 없음'),
              trailing: const Icon(Icons.timer),
              onTap: _showTimeLimitDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewInfo() {
    final totalQuestions = _selectedQuestionTypes.values
        .fold<int>(0, (sum, count) => sum + count);
    final totalPoints = _selectedQuestionTypes.entries
        .fold<int>(0, (sum, entry) {
          final points = _getQuestionTypePoints(entry.key);
          return sum + (entry.value * points);
        });

    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '시험지 미리보기',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (totalQuestions > 0) ...[
              Text('• 총 문제 수: $totalQuestions문제'),
              Text('• 총 배점: $totalPoints점'),
              if (_timeLimit != null)
                Text('• 제한시간: ${_timeLimit!.inMinutes}분'),
              const SizedBox(height: 8),
              Text('• 포함된 문제 유형:'),
              ..._selectedQuestionTypes.entries.map((entry) {
                final typeName = _getQuestionTypeName(entry.key);
                return Text('  - $typeName: ${entry.value}문제');
              }),
            ] else ...[
              Text(
                '문제 유형을 선택해주세요.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    final canGenerate = _selectedQuestionTypes.isNotEmpty && !_isGenerating;
    
    return BottomAppBar(
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ElevatedButton.icon(
          onPressed: canGenerate ? _generateExamPdf : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
          ),
          icon: _isGenerating
              ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(Icons.picture_as_pdf),
          label: Text(
            _isGenerating ? '생성 중...' : '시험지 생성하기',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('시험지 생성 도움말'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• 문제 유형을 선택하고 각 유형별 문제 수를 설정하세요.'),
              SizedBox(height: 8),
              Text('• 난이도에 따라 문제의 복잡도가 조절됩니다.'),
              SizedBox(height: 8),
              Text('• 답안지를 포함하면 정답과 해설이 함께 생성됩니다.'),
              SizedBox(height: 8),
              Text('• 생성된 PDF는 다운로드하거나 공유할 수 있습니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showTimeLimitDialog() {
    int selectedMinutes = _timeLimit?.inMinutes ?? 60;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('제한시간 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('제한시간: $selectedMinutes분'),
            Slider(
              value: selectedMinutes.toDouble(),
              min: 0,
              max: 180,
              divisions: 36,
              onChanged: (value) {
                setState(() {
                  selectedMinutes = value.toInt();
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _timeLimit = null);
              Navigator.pop(context);
            },
            child: const Text('제한시간 없음'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _timeLimit = Duration(minutes: selectedMinutes);
              });
              Navigator.pop(context);
            },
            child: const Text('설정'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateExamPdf() async {
    setState(() => _isGenerating = true);
    
    try {
      // TODO: 실제 구현에서는 WordListNotifier에서 데이터 가져오기
      // final chunks = await _getSelectedChunks();
      // final words = await _getSelectedWords();
      
      // final examService = ExamPdfService();
      // final pdfBytes = await examService.createCustomExam(
      //   chunks: chunks,
      //   words: words,
      //   questionCounts: _selectedQuestionTypes,
      //   difficulty: _difficulty,
      //   includeAnswerKey: _includeAnswerKey,
      //   shuffleQuestions: _shuffleQuestions,
      //   timeLimit: _timeLimit,
      //   title: _examTitle,
      // );
      
      // // PDF 미리보기 화면으로 이동
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => PdfPreviewScreen(
      //       pdfBytes: pdfBytes,
      //       title: _examTitle,
      //     ),
      //   ),
      // );
      
      // 임시: 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시험지가 생성되었습니다!')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시험지 생성 실패: $e')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  String _getQuestionTypeName(QuestionType type) {
    switch (type) {
      case QuestionType.fillInBlanks:
        return '빈칸 채우기';
      case QuestionType.multipleChoice:
        return '객관식';
      case QuestionType.engToKorTranslation:
        return '영한 번역';
      case QuestionType.korToEngTranslation:
        return '한영 번역';
      case QuestionType.sentenceArrangement:
        return '문장 재배열';
      case QuestionType.synonymAntonym:
        return '동의어/반의어';
      case QuestionType.errorCorrection:
        return '오류 수정';
      case QuestionType.wordFormation:
        return '단어 형태 변환';
      case QuestionType.contextInference:
        return '문맥 추론';
    }
  }

  int _getQuestionTypePoints(QuestionType type) {
    switch (type) {
      case QuestionType.fillInBlanks:
        return 2;
      case QuestionType.multipleChoice:
        return 3;
      case QuestionType.engToKorTranslation:
      case QuestionType.korToEngTranslation:
        return 5;
      case QuestionType.sentenceArrangement:
        return 4;
      default:
        return 3;
    }
  }
}
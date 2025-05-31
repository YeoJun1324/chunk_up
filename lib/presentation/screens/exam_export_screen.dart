// lib/presentation/screens/exam_export_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

import '../../domain/models/exam_models.dart';
import '../../domain/models/word_list_info.dart';
import '../../domain/models/chunk.dart';
import '../../data/services/subscription/subscription_service.dart';
import '../../data/services/pdf/pdf_coordinator.dart';
import '../providers/word_list_notifier.dart';
import '../../domain/repositories/chunk_repository_interface.dart';
import '../../di/service_locator.dart';
import 'word_list_export_screen.dart';
import '../../domain/services/exam/exam_distribution_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/services/sentence/unified_sentence_mapping_service.dart';
import 'package:get_it/get_it.dart';

/// 시험지 내보내기 화면
class ExamExportScreen extends StatefulWidget {
  const ExamExportScreen({super.key});

  @override
  State<ExamExportScreen> createState() => _ExamExportScreenState();
}

class _ExamExportScreenState extends State<ExamExportScreen> {
  
  // 탭 인덱스로 변경
  int _selectedTabIndex = 0;
  
  // 선택된 데이터
  final Map<String, bool> _selectedWordLists = {};
  Map<QuestionType, int> _selectedQuestionTypes = {};
  
  // TextEditingController 추가
  late final TextEditingController _totalQuestionsController;
  late final TextEditingController _examTitleController;
  
  // 문제 분배
  Map<QuestionType, int> _questionDistribution = {};
  int _totalQuestions = 0; // 선택된 단어장의 총 단어수로 자동 설정
  int _totalWordsInSelectedLists = 0; // 선택된 단어장의 총 단어수
  
  // 시험지 설정
  String _examTitle = 'ChunkUp 시험지';
  
  // 문제 유형 선택 상태 (하나만 선택 가능)
  int _selectedQuestionType = 1;  // 1: 단어 철자 쓰기, 2: 단어 용법 설명, 3: 문장 번역
  
  // UI 상태
  bool _isGenerating = false;
  bool _canUseFeature = false;
  
  // 서비스들
  late final PdfCoordinator _pdfCoordinator;
  late final SubscriptionService _subscriptionService;

  @override
  void initState() {
    super.initState();
    
    // 컨트롤러 초기화
    _totalQuestionsController = TextEditingController(text: _totalQuestions.toString());
    _examTitleController = TextEditingController(text: _examTitle);
    
    // 서비스 초기화
    _pdfCoordinator = getIt<PdfCoordinator>();
    _initializeDefaultSettings();
    _checkSubscription();
    _initWordListSelection();
  }

  @override
  void dispose() {
    // 컨트롤러 정리
    _totalQuestionsController.dispose();
    _examTitleController.dispose();
    
    super.dispose();
  }

  void _initializeDefaultSettings() {
    // 초기에는 단어장이 선택되지 않았으므로 분배 없음
    _questionDistribution = {};
    _selectedQuestionTypes.clear();
  }

  void _checkSubscription() {
    try {
      if (getIt.isRegistered<SubscriptionService>()) {
        _subscriptionService = getIt<SubscriptionService>();
        _canUseFeature = _subscriptionService.canUsePdfExport;
      } else {
        _canUseFeature = false;
      }
    } catch (e) {
      _canUseFeature = false;
    }
  }

  void _initWordListSelection() {
    final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);
    for (var wordList in wordListNotifier.wordLists) {
      _selectedWordLists[wordList.name] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF 내보내기'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 커스텀 탭바
          _buildCustomTabBar(),
          
          // 선택된 탭에 따른 컨텐츠
          Expanded(
            child: _selectedTabIndex == 0 
                ? _buildMaterialExportTab()
                : _buildExamExportTab(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCustomTabBar() {
    return Container(
      color: AppColors.primary(context).withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              index: 0,
              icon: Icons.menu_book,
              label: '교재',
              isSelected: _selectedTabIndex == 0,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              index: 1,
              icon: Icons.quiz,
              label: '시험지',
              isSelected: _selectedTabIndex == 1,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        if (mounted) {
          setState(() {
            _selectedTabIndex = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary(context) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary(context) : AppColors.textSecondary(context),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary(context) : AppColors.textSecondary(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 교재 내보내기 탭
  Widget _buildMaterialExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프리미엄 기능 배너
          if (!_canUseFeature) _buildPremiumBanner(),
          
          const SizedBox(height: 20),
          
          // 단어장 선택
          _buildWordListSelection(),
          
          const SizedBox(height: 20),
          
          // 교재 설정
          _buildMaterialSettings(),
          
          const SizedBox(height: 20),
          
          
          // 생성 버튼
          _buildMaterialGenerateButton(),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// 시험지 내보내기 탭
  Widget _buildExamExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프리미엄 기능 배너
          if (!_canUseFeature) _buildPremiumBanner(),
          
          const SizedBox(height: 20),
          
          // 단어장 선택
          _buildWordListSelection(),
          
          const SizedBox(height: 20),
          
          // 기본 설정
          _buildBasicSettings(),
          
          const SizedBox(height: 20),
          
          // 문제 유형 선택 (단순화된 버전)
          _buildSimpleQuestionTypeSelection(),
          
          const SizedBox(height: 20),
          
          
          // 생성 버튼
          _buildGenerateButton(),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.star, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          const Text(
            'PDF 내보내기',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '고급 시험지 생성은 프리미엄 구독자만 이용할 수 있습니다.\n더 많은 문제 유형과 상세한 해설을 경험해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/subscription'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.purple.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              '프리미엄 구독하기',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildWordListSelection() {
    return Card(
      child: ExpansionTile(
        leading: Icon(Icons.folder, color: AppColors.primary(context)),
        title: const Text(
          '단어장 선택',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${_getSelectedWordListCount()}개 선택됨'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('단어장을 선택하세요'),
                    TextButton.icon(
                      onPressed: _toggleSelectAllWordLists,
                      icon: const Icon(Icons.select_all, size: 16),
                      label: const Text('전체 선택'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Consumer<WordListNotifier>(
                  builder: (context, wordListNotifier, child) {
                    if (wordListNotifier.wordLists.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('단어장이 없습니다.'),
                        ),
                      );
                    }

                    return Column(
                      children: wordListNotifier.wordLists.map((wordList) {
                        final isSelected = _selectedWordLists[wordList.name] ?? false;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected ? Colors.blue.withOpacity(0.05) : null,
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              wordList.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '전체 단어: ${wordList.words.length}개 • 청크 사용 단어: ${wordList.contextualizedWordCount}개',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                _selectedWordLists[wordList.name] = value ?? false;
                                _updateTotalQuestionsFromSelectedLists();
                              });
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSettings() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDarkMode ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  '기본 설정',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 시험지 제목
            TextField(
              controller: _examTitleController,
              decoration: InputDecoration(
                labelText: '시험지 제목',
                prefixIcon: Icon(
                  Icons.title,
                  color: Theme.of(context).primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[850] : Colors.grey.shade50,
              ),
              onChanged: (value) => setState(() => _examTitle = value),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSimpleQuestionTypeSelection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDarkMode ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  '문제 설정',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 총 문제 수 표시 (자동 설정)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '총 문제 수',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Theme.of(context).primaryColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _totalQuestions == 0 ? '단어장을 선택하세요' : '$_totalQuestions문제',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_totalQuestions > 0) ...[
              const SizedBox(height: 8),
              Text(
                '선택한 단어장의 청크에 포함된 단어수에 맞춰 자동으로 설정됩니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            
            // 문제 유형 선택
            Row(
              children: [
                const Text(
                  '문제 유형 선택',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: '원하는 문제 유형을 1개 이상 선택하세요.\n선택한 유형에 문제가 균등하게 분배됩니다.',
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 문제 유형 라디오 버튼 (하나만 선택 가능)
            _buildQuestionTypeRadio(
              icon: Icons.edit_note,
              title: '단어 철자 쓰기',
              subtitle: '문장 속 빈칸에 들어갈 단어를 쓰는 문제',
              value: 1,
              groupValue: _selectedQuestionType,
              onChanged: (value) {
                setState(() {
                  _selectedQuestionType = value ?? 1;
                  _updateSimpleDistribution();
                });
              },
            ),
            const SizedBox(height: 12),
            _buildQuestionTypeRadio(
              icon: Icons.lightbulb_outline,
              title: '단어 용법 설명',
              subtitle: '굵게 표시된 단어의 문맥상 의미를 설명하는 문제',
              value: 2,
              groupValue: _selectedQuestionType,
              onChanged: (value) {
                setState(() {
                  _selectedQuestionType = value ?? 2;
                  _updateSimpleDistribution();
                });
              },
            ),
            const SizedBox(height: 12),
            _buildQuestionTypeRadio(
              icon: Icons.translate,
              title: '문장 번역 (한→영)',
              subtitle: '한국어 문장을 영어로 번역하는 문제',
              value: 3,
              groupValue: _selectedQuestionType,
              onChanged: (value) {
                setState(() {
                  _selectedQuestionType = value ?? 3;
                  _updateSimpleDistribution();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuestionTypeCheckbox({
    required IconData icon,
    required String title,
    required String subtitle,
    required String example,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: value 
            ? Theme.of(context).primaryColor 
            : isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: value ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: value 
          ? Theme.of(context).primaryColor.withOpacity(0.05)
          : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          unselectedWidgetColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        child: CheckboxListTile(
          value: value,
          onChanged: onChanged,
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          title: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: value 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: value 
                          ? Theme.of(context).primaryColor 
                          : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          activeColor: Theme.of(context).primaryColor,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTypeRadio({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required int groupValue,
    required Function(int?) onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = value == groupValue;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected 
            ? Theme.of(context).primaryColor 
            : isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected 
          ? Theme.of(context).primaryColor.withOpacity(0.05)
          : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          unselectedWidgetColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        child: RadioListTile<int>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          title: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          activeColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
  
  void _updateSimpleDistribution() {
    // 선택된 문제 유형 확인 (라디오 버튼이므로 하나만 선택됨)
    QuestionType selectedType;
    switch (_selectedQuestionType) {
      case 1:
        selectedType = QuestionType.fillInBlanks;
        break;
      case 2:
        selectedType = QuestionType.contextMeaning;
        break;
      case 3:
        selectedType = QuestionType.korToEngTranslation;
        break;
      default:
        selectedType = QuestionType.fillInBlanks;
    }
    
    // 한영 번역의 경우 문장 수 계산, 그 외는 단어 수 계산
    if (selectedType == QuestionType.korToEngTranslation) {
      _updateTotalQuestionsForTranslation();
    } else {
      // 단어 기반 문제는 단어 수로 재계산
      _totalQuestions = _totalWordsInSelectedLists;
      _totalQuestionsController.text = _totalQuestions.toString();
    }
    
    if (_totalQuestions == 0) {
      _questionDistribution = {};
      _selectedQuestionTypes.clear();
      return;
    }
    
    // 선택된 유형에 모든 문제 할당
    _questionDistribution = {selectedType: _totalQuestions};
    _selectedQuestionTypes = {selectedType: _totalQuestions};
  }
  
  void _updateTotalQuestionsFromSelectedLists() {
    final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);
    int totalWordsInChunks = 0;
    
    for (var entry in _selectedWordLists.entries) {
      if (entry.value) {
        final wordList = wordListNotifier.wordLists.firstWhere(
          (wl) => wl.name == entry.key,
        );
        
        // 청크에 포함된 단어 수 (isInChunk가 true인 단어들)
        totalWordsInChunks += wordList.contextualizedWordCount;
      }
    }
    
    setState(() {
      _totalWordsInSelectedLists = totalWordsInChunks;
      _totalQuestions = totalWordsInChunks;
      _totalQuestionsController.text = _totalQuestions.toString();
      _updateSimpleDistribution();
    });
  }
  
  void _updateTotalQuestionsForTranslation() {
    final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);
    final sentenceMappingService = GetIt.I<UnifiedSentenceMappingService>();
    int totalSentences = 0;
    
    // 선택된 단어장의 청크에서 문장 수 계산
    for (var entry in _selectedWordLists.entries) {
      if (entry.value) {
        final wordList = wordListNotifier.wordLists.firstWhere(
          (wl) => wl.name == entry.key,
        );
        
        // SentenceMapping 서비스를 사용하여 정확한 문장 수 계산
        if (wordList.chunks != null) {
          for (var chunk in wordList.chunks!) {
            final sentencePairs = sentenceMappingService.extractSentencePairs(chunk);
            totalSentences += sentencePairs.length;
          }
        }
      }
    }
    
    setState(() {
      _totalQuestions = totalSentences.clamp(1, 50).toInt(); // 최소 1문제, 최대 50문제
      _totalQuestionsController.text = _totalQuestions.toString();
    });
  }

  // 기존의 복잡한 메서드들은 제거됨



  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    final canGenerate = _selectedQuestionTypes.isNotEmpty && 
                       _selectedWordLists.values.any((selected) => selected) &&
                       !_isGenerating &&
                       _canUseFeature;
    
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: canGenerate ? [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : [],
      ),
      child: ElevatedButton.icon(
        onPressed: canGenerate ? _generateExamPdf : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
            : const Icon(Icons.picture_as_pdf, size: 24),
        label: Text(
          _isGenerating 
              ? '시험지 생성 중...' 
              : !_canUseFeature
                  ? '프리미엄 구독 필요'
                  : '시험지 생성하기',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===== 보조 메서드들 =====

  int _getSelectedWordListCount() {
    return _selectedWordLists.values.where((selected) => selected).length;
  }



  IconData _getQuestionTypeIcon(QuestionType type) {
    switch (type) {
      case QuestionType.fillInBlanks:
        return Icons.edit_note;
      case QuestionType.contextMeaning:
        return Icons.lightbulb_outline;
      case QuestionType.korToEngTranslation:
        return Icons.translate;
    }
  }

  void _toggleSelectAllWordLists() {
    final anySelected = _selectedWordLists.values.any((selected) => selected);
    setState(() {
      for (var key in _selectedWordLists.keys) {
        _selectedWordLists[key] = !anySelected;
      }
      _updateTotalQuestionsFromSelectedLists();
    });
  }


  Future<void> _generateExamPdf() async {
    if (!_canUseFeature) {
      _showSubscriptionDialog();
      return;
    }

    setState(() => _isGenerating = true);
    
    try {
      // 선택된 단어장들 가져오기
      final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);
      final selectedWordLists = wordListNotifier.wordLists
          .where((wordList) => _selectedWordLists[wordList.name] ?? false)
          .toList();

      if (selectedWordLists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('단어장을 선택해주세요')),
        );
        return;
      }

      // 청크 데이터 가져오기
      final chunkRepository = getIt<ChunkRepositoryInterface>();
      final allChunks = <Chunk>[];
      
      for (var wordList in selectedWordLists) {
        final chunks = await chunkRepository.getChunksForWordList(wordList.name);
        allChunks.addAll(chunks);
      }

      // 시험지 설정 생성 - ExamDistributionHelper로 분배된 문제 수 사용
      final config = ExamConfig(
        questionCounts: _questionDistribution,
        includeAnswerKey: true,  // 항상 답안지 포함
        shuffleQuestions: false,  // 문제 순서 유지
        title: _examTitle,
        selectedWordListNames: selectedWordLists.map((wl) => wl.name).toList(),
      );

      // PDF 생성
      final result = await _pdfCoordinator.generateExamPdf(
        wordLists: selectedWordLists,
        chunks: allChunks,
        config: config,
      );
      
      if (!result.isSuccess) {
        throw Exception(result.errorMessage ?? '시험지 생성 실패');
      }
      
      final pdfBytes = result.pdfBytes!;

      // PDF 미리보기 화면으로 이동
      if (!mounted) return;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfBytes: pdfBytes,
            title: _examTitle,
          ),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('시험지 생성 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }


  Widget _buildMaterialSettings() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDarkMode ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: AppColors.primary(context)),
                const SizedBox(width: 8),
                Text(
                  '교재 설정',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 교재 제목
            TextField(
              controller: _examTitleController,
              decoration: InputDecoration(
                labelText: '교재 제목',
                hintText: 'ChunkUp 학습교재',
                prefixIcon: Icon(
                  Icons.title,
                  color: AppColors.primary(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.inputFillColor(context),
              ),
              onChanged: (value) => setState(() => _examTitle = value.isEmpty ? 'ChunkUp 학습교재' : value),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMaterialGenerateButton() {
    final selectedCount = _selectedWordLists.values.where((selected) => selected).length;
    final canGenerate = selectedCount > 0 && _canUseFeature && !_isGenerating;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: InkWell(
        onTap: !canGenerate && !_canUseFeature ? _showSubscriptionDialog : null,
        borderRadius: BorderRadius.circular(12),
        child: ElevatedButton.icon(
          onPressed: canGenerate ? _generateMaterial : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary(context),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
              : const Icon(Icons.picture_as_pdf, size: 24),
          label: Text(
            _isGenerating
                ? '교재 생성 중...'
                : !_canUseFeature
                    ? '프리미엄 구독 필요'
                    : '교재 생성하기',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateMaterial() async {
    if (!_canUseFeature) {
      _showSubscriptionDialog();
      return;
    }

    setState(() => _isGenerating = true);
    
    try {
      // 선택된 단어장들 가져오기
      final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);
      final selectedWordLists = wordListNotifier.wordLists
          .where((wordList) => _selectedWordLists[wordList.name] ?? false)
          .toList();

      if (selectedWordLists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('단어장을 선택해주세요')),
        );
        return;
      }

      // 각 단어장의 단락 정보 가져오기
      final chunkRepository = getIt<ChunkRepositoryInterface>();
      final Map<WordListInfo, List<Chunk>> wordListChunks = {};
      
      for (var wordList in selectedWordLists) {
        final chunks = await chunkRepository.getChunksForWordList(wordList.name);
        wordListChunks[wordList] = chunks;
      }

      // 교재 PDF 생성 (PdfCoordinator 사용)
      final result = await _pdfCoordinator.generateWordListPdf(
        wordListChunks: wordListChunks,
        title: '단어장 교재',
      );
      
      if (!result.isSuccess || result.pdfBytes == null) {
        throw Exception(result.errorMessage ?? 'PDF 생성 실패');
      }
      
      final pdfBytes = result.pdfBytes!;

      // PDF 미리보기 화면으로 이동
      if (!mounted) return;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfBytes: pdfBytes,
            title: _examTitle,
          ),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('교재 생성 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('프리미엄 기능'),
          ],
        ),
        content: const Text(
          'PDF 내보내기는 프리미엄 구독자만 이용할 수 있습니다.\n\n'
          '프리미엄 구독 시 다음 기능을 이용하실 수 있습니다:\n'
          '• 다양한 문제 유형\n'
          '• 상세한 해설 및 학습 가이드\n'
          '• 채점 기준표\n'
          '• 무제한 PDF 생성',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('프리미엄 구독하기'),
          ),
        ],
      ),
    );
  }

}
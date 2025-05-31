// lib/presentation/screens/word_list_export_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/data/services/subscription/subscription_service.dart';
import 'package:chunk_up/data/services/pdf/pdf_coordinator.dart';
import 'package:get_it/get_it.dart';
import 'package:chunk_up/core/theme/app_colors.dart';

class WordListExportScreen extends StatefulWidget {
  const WordListExportScreen({super.key});

  @override
  State<WordListExportScreen> createState() => _WordListExportScreenState();
}

class _WordListExportScreenState extends State<WordListExportScreen> {
  final Map<String, bool> _selectedWordLists = {};
  bool _isGenerating = false;
  late final ChunkRepositoryInterface _chunkRepository;
  late final PdfCoordinator _pdfCoordinator;
  bool _canUseFeature = false;
  late SubscriptionService _subscriptionService;

  @override
  void initState() {
    super.initState();
    _chunkRepository = GetIt.I<ChunkRepositoryInterface>();
    _pdfCoordinator = GetIt.I<PdfCoordinator>();
    _initWordListSelection();
    _checkSubscription();
  }
  
  void _checkSubscription() {
    try {
      if (GetIt.instance.isRegistered<SubscriptionService>()) {
        _subscriptionService = GetIt.instance<SubscriptionService>();
        _canUseFeature = _subscriptionService.canUsePdfExport;
        debugPrint('✅ PDF 내보내기 화면: 기능 사용 가능 여부 = $_canUseFeature');
      } else {
        debugPrint('⚠️ SubscriptionService가 등록되어 있지 않음');
        _canUseFeature = false;
      }
    } catch (e) {
      debugPrint('❌ 구독 서비스 확인 실패: $e');
      _canUseFeature = false;
    }
  }

  void _initWordListSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);
      for (var wordList in wordListNotifier.wordLists) {
        _selectedWordLists[wordList.name] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF 교재 생성'),
        actions: [
          if (_hasSelections())
            TextButton(
              onPressed: _toggleSelectAll,
              child: Text(
                _selectedWordLists.values.any((isSelected) => isSelected) ? '모두 해제' : '모두 선택',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 정보 영역
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '단어장을 선택하여 PDF 교재를 생성하세요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '각 단어장의 단어와 단락이 포함된 학습 교재가 생성됩니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  if (!_canUseFeature) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'PDF 내보내기는 프리미엄 기능입니다',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 단어장 목록
            Expanded(
              child: Consumer<WordListNotifier>(
                builder: (context, notifier, child) {
                  final wordLists = notifier.wordLists;
                  
                  if (wordLists.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: AppColors.textHint(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '단어장이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '먼저 단어장을 생성해주세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return Column(
                    children: [
                      // 선택 정보
                      if (_hasSelections())
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: AppColors.primary(context).withOpacity(0.1),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 20,
                                color: AppColors.primary(context),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedWordLists.values.where((v) => v).length}개 선택됨',
                                style: TextStyle(
                                  color: AppColors.primary(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                    // 단어장 목록
                    Expanded(
                      child: ListView.builder(
                        itemCount: wordLists.length,
                        itemBuilder: (context, index) {
                          final wordList = wordLists[index];
                          final isSelected = _selectedWordLists[wordList.name] ?? false;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: CheckboxListTile(
                              title: Text(
                                wordList.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('단어: ${wordList.words.length}개'),
                                  Text('단락: ${wordList.chunkCount}개'),
                                ],
                              ),
                              secondary: Icon(
                                Icons.menu_book,
                                color: AppColors.primary(context),
                              ),
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  _selectedWordLists[wordList.name] = value ?? false;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // 하단 버튼
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canUseFeature && _hasSelections() && !_isGenerating
                    ? () => _generatePdf(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.textHint(context),
                  disabledForegroundColor: Colors.white,
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
                  _isGenerating
                    ? '생성 중...'
                    : !_canUseFeature
                      ? '유료 구독 필요'
                      : 'PDF 생성하기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  bool _hasSelections() {
    return _selectedWordLists.values.any((isSelected) => isSelected);
  }

  void _toggleSelectAll() {
    final anySelected = _selectedWordLists.values.any((isSelected) => isSelected);
    
    setState(() {
      for (var key in _selectedWordLists.keys) {
        _selectedWordLists[key] = !anySelected;
      }
    });
  }

  Future<void> _generatePdf(BuildContext context) async {
    if (_isGenerating) return;
    
    // 무료 사용자 차단
    if (!_canUseFeature) {
      // 구독 안내 다이얼로그 표시
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('유료 기능'),
          content: const Text('무료 기능에서는 지원하지 않습니다.\n유료 구독 사용자만 PDF 내보내기 기능을 이용할 수 있습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/subscription');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
              ),
              child: const Text('구독 플랜 보기'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // 1. 선택된 단어장 목록 가져오기
      final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);
      final selectedWordLists = wordListNotifier.wordLists
          .where((wordList) => _selectedWordLists[wordList.name] ?? false)
          .toList();

      if (selectedWordLists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내보낼 단어장을 선택해주세요')),
        );
        return;
      }

      // 2. 각 단어장의 단락 정보 가져오기
      final Map<WordListInfo, List<Chunk>> wordListChunks = {};
      for (var wordList in selectedWordLists) {
        final chunks = await _chunkRepository.getChunksForWordList(wordList.name);
        wordListChunks[wordList] = chunks;
      }

      // 3. PDF 문서 생성 - PdfCoordinator 사용
      final result = await _pdfCoordinator.generateWordListPdf(
        wordListChunks: wordListChunks,
        title: '단어장 내보내기',
      );

      if (!result.isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'PDF 생성 실패')),
        );
        return;
      }

      // 4. PDF 미리보기 표시
      if (!mounted) return;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfBytes: result.pdfBytes!,
            title: result.title ?? '단어장 내보내기',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF 생성 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}

class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PdfPreview(
        build: (format) => pdfBytes,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: 'ChunkUp_단어장_${DateTime.now().millisecondsSinceEpoch}.pdf',
      ),
    );
  }
}
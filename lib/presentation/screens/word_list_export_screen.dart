// lib/presentation/screens/word_list_export_screen.dart
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/domain/repositories/chunk_repository_interface.dart';
import 'package:chunk_up/di/service_locator.dart';
import 'package:chunk_up/core/services/subscription_service.dart';
import 'package:get_it/get_it.dart';

class WordListExportScreen extends StatefulWidget {
  const WordListExportScreen({super.key});

  @override
  State<WordListExportScreen> createState() => _WordListExportScreenState();
}

class _WordListExportScreenState extends State<WordListExportScreen> {
  final Map<String, bool> _selectedWordLists = {};
  bool _isGenerating = false;
  late final ChunkRepositoryInterface _chunkRepository;
  bool _canUseFeature = false;
  late SubscriptionService _subscriptionService;

  @override
  void initState() {
    super.initState();
    _chunkRepository = getIt<ChunkRepositoryInterface>();
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
        title: const Text('단어장 내보내기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: '전체 선택',
            onPressed: _toggleSelectAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // 프리미엄 기능 알림 배너
          if (!_canUseFeature)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: isDarkMode ? Colors.amber.shade900 : Colors.amber.shade100,
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PDF 내보내기는 유료 사용자 전용 기능입니다. 구독하고 이용해보세요.',
                      style: TextStyle(
                        color: isDarkMode ? Colors.amber.shade100 : Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/subscription'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text(
                      '구독하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<WordListNotifier>(
              builder: (context, wordListNotifier, child) {
                if (wordListNotifier.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final wordLists = wordListNotifier.wordLists;
                if (wordLists.isEmpty) {
                  return const Center(
                    child: Text('단어장이 없습니다.'),
                  );
                }

                // 선택 목록 초기화 (없는 단어장 제거)
                _selectedWordLists.removeWhere(
                    (key, value) => !wordLists.any((wl) => wl.name == key));

                // 새 단어장 추가
                for (var wordList in wordLists) {
                  if (!_selectedWordLists.containsKey(wordList.name)) {
                    _selectedWordLists[wordList.name] = false;
                  }
                }

                return Column(
                  children: [
                    // 안내 메시지
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '단어장 내보내기',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDarkMode
                                      ? Colors.blue.shade200
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '내보내기할 단어장을 선택하고 하단의 PDF 생성 버튼을 눌러주세요. 선택한 단어장의 모든 단락이 포함된 PDF 문서가 생성됩니다.',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.blue.shade100
                                  : Colors.blue.shade800,
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
                                color: Colors.orange,
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
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton.icon(
            onPressed: _isGenerating || !_hasSelections() || !_canUseFeature
                ? null
                : () => _generatePdf(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
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
                backgroundColor: Colors.orange,
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

      // 3. PDF 문서 생성
      final pdfBytes = await _createPdf(wordListChunks);

      // 4. PDF 미리보기 표시
      if (!mounted) return;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfBytes: pdfBytes,
            title: '단어장 내보내기',
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

  // PDF 문서 생성
  Future<Uint8List> _createPdf(Map<WordListInfo, List<Chunk>> wordListChunks) async {
    final pdf = pw.Document(
      title: 'ChunkUp 단어장 내보내기',
      author: 'ChunkUp App',
      creator: 'ChunkUp',
    );

    // 폰트 변수 선언
    late pw.Font regularFont;
    late pw.Font boldFont;
    late pw.Font italicFont;

    // 한글 표시를 위한 특수 폰트 사용
    try {
      // NanumGothic 폰트 로드 시도
      regularFont = await PdfGoogleFonts.nanumGothicRegular();
      boldFont = await PdfGoogleFonts.nanumGothicBold();
      italicFont = regularFont;
      print('한글 폰트 로드 성공');
    } catch (e) {
      print('한글 폰트 로드 실패: $e');

      // 다음으로 NotoSans 폰트 시도
      try {
        regularFont = await PdfGoogleFonts.notoSansRegular();
        boldFont = await PdfGoogleFonts.notoSansBold();
        italicFont = regularFont;
        print('Noto Sans 폰트 로드 성공');
      } catch (e) {
        print('모든 한글 폰트 로드 실패, 기본 폰트 사용: $e');

        // 모든 시도 실패 시 기본 폰트 사용
        regularFont = pw.Font.helvetica();
        boldFont = pw.Font.helveticaBold();
        italicFont = pw.Font.helveticaOblique();
      }
    }

    // 커버 페이지 추가
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'ChunkUp 단어장',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 28,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '내보내기 문서',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 18,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Container(
                  width: 100,
                  height: 100,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange200,
                    borderRadius: pw.BorderRadius.circular(50),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'C',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 60,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  '생성 일시: ${DateTime.now().toString().substring(0, 19)}',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '단어장 수: ${wordListChunks.length}',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 목차 페이지 추가
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '목차',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 18,
                  color: PdfColors.black,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.ListView.builder(
                itemCount: wordListChunks.length,
                itemBuilder: (pw.Context context, int index) {
                  final wordList = wordListChunks.keys.elementAt(index);
                  final chunks = wordListChunks[wordList] ?? [];
                  
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${index + 1}. ${wordList.name}',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 14,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 20),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: List.generate(chunks.length, (chunkIndex) {
                            return pw.Text(
                              '${index + 1}.${chunkIndex + 1} ${chunks[chunkIndex].title}',
                              style: pw.TextStyle(
                                font: regularFont,
                                fontSize: 12,
                                color: PdfColors.black,
                              ),
                            );
                          }),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );

    // 각 단어장 내용 추가
    int wordListIndex = 1;
    for (var wordList in wordListChunks.keys) {
      final chunks = wordListChunks[wordList] ?? [];
      
      // 단어장 제목 페이지
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.orange100,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      wordList.name,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 24,
                        color: PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    '단어 수: ${wordList.words.length}개',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '단락 수: ${chunks.length}개',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // 각 단락 내용 추가
      int chunkIndex = 1;
      for (var chunk in chunks) {
        // footerBuilder를 사용하는 테마 정의
        final myPageTheme = pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: regularFont,
            bold: boldFont,
            italic: italicFont,
          ),
          buildBackground: (context) => pw.Container(),
          buildForeground: (context) {
            if (context.pageNumber > 0) { // 첫 페이지가 아닐 때만 표시
              return pw.Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: pw.Text(
                  '페이지 ${context.pageNumber}/${context.pagesCount}',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              );
            } else {
              return pw.Container();
            }
          },
        );

        pdf.addPage(
          pw.MultiPage(
            // 페이지 테마만 사용하고 다른 속성은 제거
            pageTheme: myPageTheme,
            maxPages: 100,
            build: (pw.Context context) {
              return [
                // 단락 제목
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 30,
                        height: 30,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue900,
                          shape: pw.BoxShape.circle,
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          '$wordListIndex.$chunkIndex',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 14,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Text(
                          chunk.title,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 16,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 15),
                
                // 영어 내용
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue200),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '영어 원문',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 14,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.RichText(
                        text: _buildHighlightedPdfText(
                          text: chunk.englishContent,
                          highlightWords: chunk.includedWords,
                          regularFont: regularFont,
                          boldFont: boldFont,
                          highlightColor: PdfColors.orange,
                          textColor: PdfColors.black,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 10),
                
                // 한국어 번역
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.orange200),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '한국어 번역',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 14,
                          color: PdfColors.orange900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        chunk.koreanTranslation,
                        style: pw.TextStyle(
                          font: regularFont,
                          fontSize: 12,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 15),
                
                // 단어 설명
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '단어 설명',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 14,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      // 단일 큰 테이블 대신 각 단어별로 개별 테이블을 생성
                      // 헤더 테이블 (한 번만 표시)
                      pw.Table(
                        border: pw.TableBorder.all(
                          color: PdfColors.grey300,
                          width: 0.5,
                        ),
                        tableWidth: pw.TableWidth.max,
                        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                        columnWidths: {
                          0: const pw.FlexColumnWidth(2), // 영어 (20%)
                          1: const pw.FlexColumnWidth(2), // 한국어 (20%)
                          2: const pw.FlexColumnWidth(6), // 설명 (60%)
                        },
                        children: [
                          // 헤더 행
                          pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                            ),
                            children: [
                              _buildTableCell('영어', boldFont, 12, PdfColors.black),
                              _buildTableCell('한국어', boldFont, 12, PdfColors.black),
                              _buildTableCell('설명', boldFont, 12, PdfColors.black),
                            ],
                          ),
                        ],
                      ),
                      // 각 단어별로 개별 테이블을 생성하여 페이지 나눔 허용
                      ...List.generate(chunk.includedWords.length, (index) {
                        final word = chunk.includedWords[index];
                        final explanation = chunk.getExplanationFor(word.english) ?? '';

                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 0.5), // 테이블 사이 간격 최소화
                          child: pw.Table(
                            border: pw.TableBorder.all(
                              color: PdfColors.grey300,
                              width: 0.5,
                            ),
                            tableWidth: pw.TableWidth.max,
                            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                            columnWidths: {
                              0: const pw.FlexColumnWidth(2), // 영어 (20%)
                              1: const pw.FlexColumnWidth(2), // 한국어 (20%)
                              2: const pw.FlexColumnWidth(6), // 설명 (60%)
                            },
                            children: [
                              pw.TableRow(
                                children: [
                                  _buildTableCell(word.english, regularFont, 10, PdfColors.black),
                                  _buildTableCell(word.korean, regularFont, 10, PdfColors.black),
                                  _buildTableCell(explanation, italicFont, 9, PdfColors.grey800),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ];
            },
          ),
        );
        chunkIndex++;
      }
      wordListIndex++;
    }

    return pdf.save();
  }

  pw.Widget _buildTableCell(String text, pw.Font font, double fontSize, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: color,
        ),
        // 텍스트가 길 경우 텍스트가 자동으로 줄바꿈되도록 설정
        softWrap: true,
        // 텍스트를 행 내에서 최대한 채우기
        textAlign: pw.TextAlign.left,
        // 최대 줄 수를 제한하지 않아 텍스트가 모두 표시되도록 함
        maxLines: null,
      ),
    );
  }

  // PDF에서 단어를 하이라이트하는 메소드
  pw.TextSpan _buildHighlightedPdfText({
    required String text,
    required List<Word> highlightWords,
    required pw.Font regularFont,
    required pw.Font boldFont,
    required PdfColor highlightColor,
    required PdfColor textColor,
    required double fontSize,
  }) {
    // 단어와 해당 위치를 저장할 리스트
    final List<Map<String, dynamic>> wordOccurrences = [];

    // 각 단어의 모든 출현 위치 찾기
    for (var word in highlightWords) {
      // 단어가 복합 단어인 경우(공백 포함)
      final targetWord = word.english.toLowerCase();

      if (targetWord.contains(' ')) {
        // 복합 단어 처리
        final pattern = RegExp(targetWord, caseSensitive: false);
        for (var match in pattern.allMatches(text.toLowerCase())) {
          wordOccurrences.add({
            'word': text.substring(match.start, match.end),
            'start': match.start,
            'end': match.end,
          });
        }
      } else {
        // 단일 단어 처리 - 단어 경계를 고려하여 검색
        final pattern = RegExp(r'\b' + RegExp.escape(targetWord) + r'\b', caseSensitive: false);
        for (var match in pattern.allMatches(text.toLowerCase())) {
          wordOccurrences.add({
            'word': text.substring(match.start, match.end),
            'start': match.start,
            'end': match.end,
          });
        }
      }
    }

    // 출현 위치를 시작 위치 기준으로 정렬
    wordOccurrences.sort((a, b) => a['start'] - b['start']);

    // 최종 텍스트 스팬 리스트
    final spans = <pw.TextSpan>[];

    int currentIndex = 0;

    // 겹치는 단어 처리를 위한 로직
    final List<Map<String, dynamic>> nonOverlappingOccurrences = [];

    for (var occurrence in wordOccurrences) {
      bool overlapping = false;

      for (var nonOverlap in nonOverlappingOccurrences) {
        // 현재 단어가 기존 단어와 겹치는지 확인
        if ((occurrence['start'] < nonOverlap['end'] && occurrence['end'] > nonOverlap['start'])) {
          overlapping = true;
          break;
        }
      }

      if (!overlapping) {
        nonOverlappingOccurrences.add(occurrence);
      }
    }

    // 정렬된 비겹침 출현 위치로 스팬 생성
    nonOverlappingOccurrences.sort((a, b) => a['start'] - b['start']);

    for (var occurrence in nonOverlappingOccurrences) {
      final start = occurrence['start'];
      final end = occurrence['end'];

      // 현재 위치부터 단어 시작 위치까지 일반 텍스트 추가
      if (start > currentIndex) {
        spans.add(pw.TextSpan(
          text: text.substring(currentIndex, start),
          style: pw.TextStyle(
            font: regularFont,
            fontSize: fontSize,
            color: textColor,
          ),
        ));
      }

      // 하이라이트할 단어 추가 - PDF에서는 backgroundColor 지원되지 않아 색상으로 구분
      spans.add(pw.TextSpan(
        text: text.substring(start, end),
        style: pw.TextStyle(
          font: boldFont,
          fontSize: fontSize,
          color: PdfColors.orange900,
          decoration: pw.TextDecoration.underline,
        ),
      ));

      currentIndex = end;
    }

    // 마지막 단어 이후 남은 텍스트 추가
    if (currentIndex < text.length) {
      spans.add(pw.TextSpan(
        text: text.substring(currentIndex),
        style: pw.TextStyle(
          font: regularFont,
          fontSize: fontSize,
          color: textColor,
        ),
      ));
    }

    // 최종 RichText 위젯 반환
    return pw.TextSpan(
      children: spans,
    );
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
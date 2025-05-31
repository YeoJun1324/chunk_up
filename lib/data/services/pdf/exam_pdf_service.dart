// lib/core/services/pdf/exam_pdf_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/models/exam_models.dart';
import '../../../domain/models/enhanced_exam_models.dart';
import '../../../domain/models/word_list_info.dart';
import '../../../domain/models/chunk.dart';
import 'package:chunk_up/domain/services/exam/unified_exam_generator.dart';
import 'base_pdf_service.dart';

/// 시험지 전용 PDF 생성 서비스
class ExamPdfService extends BasePdfService {
  final UnifiedExamGenerator _examGenerator = UnifiedExamGenerator();
  
  
  /// 프리미엄 시험지 PDF 생성
  Future<Uint8List> createPremiumExamPdf({
    required List<WordListInfo> wordLists,
    required List<Chunk> chunks,
    required ExamConfig config,
  }) async {
    // 1. 향상된 시험 문제 생성
    final examPaper = await _generatePremiumExamPaper(wordLists, chunks, config);
    
    // 2. 프리미엄 PDF 생성
    return await _buildPremiumExamPdf(examPaper, config);
  }
  
  
  /// 프리미엄 시험 문제 생성
  Future<EnhancedExamPaper> _generatePremiumExamPaper(
    List<WordListInfo> wordLists,
    List<Chunk> chunks,
    ExamConfig config,
  ) async {
    // 단일 문제 유형만 지원
    final questionType = config.enabledQuestionTypes.first;
    return await _examGenerator.generateEnhancedExam(
      chunks: chunks,
      questionCount: config.questionCount,
      questionType: questionType,
    );
  }
  
  
  /// 프리미엄 시험지 PDF 구축
  Future<Uint8List> _buildPremiumExamPdf(EnhancedExamPaper examPaper, ExamConfig config) async {
    final pdf = pw.Document(
      title: examPaper.title,
      author: 'ChunkUp Premium',
      creator: 'ChunkUp Premium Exam Generator',
    );
    
    final fonts = await BasePdfService.loadFonts();
    
    // 1. 프리미엄 표지 페이지
    pdf.addPage(_buildPremiumCoverPage(examPaper, fonts));
    
    // 2. 향상된 문제 페이지들
    pdf.addPage(_buildEnhancedQuestionPages(examPaper, fonts));
    
    // 3. 상세 답안지
    if (config.includeAnswerKey) {
      pdf.addPage(_buildEnhancedAnswerKeyPages(examPaper, fonts));
    }
    
    return pdf.save();
  }
  
  /// 표지 페이지 생성
  pw.Page _buildCoverPage(ExamPaper examPaper, FontPair fonts) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 47, 32, 32), // 상단 여백 15pt 추가 (32+15=47)
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 제목
            pw.Center(
              child: pw.Text(
                examPaper.title,
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 24,
                  color: PdfColors.black,
                ),
              ),
            ),
            pw.SizedBox(height: 40),
            
            // 구분선
            pw.Container(
              width: double.infinity,
              height: 2,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 20),
            
            // 시험 정보
            _buildExamInfo(examPaper, fonts),
            
            pw.SizedBox(height: 40),
            
            // 학생 정보 입력란
            _buildStudentInfoSection(fonts),
            
            pw.SizedBox(height: 40),
            
            // 시험 안내사항
            _buildInstructions(fonts),
          ],
        );
      },
    );
  }
  
  /// 시험 정보 섹션
  pw.Widget _buildExamInfo(ExamPaper examPaper, FontPair fonts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoRow('시험 날짜', BasePdfService.formatDate(examPaper.createdAt), fonts),
        pw.SizedBox(height: 8),
        _buildInfoRow('총 문제 수', '${examPaper.questions.length}문제', fonts),
      ],
    );
  }
  
  /// 정보 행 생성
  pw.Widget _buildInfoRow(String label, String value, FontPair fonts) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: 14,
            color: PdfColors.black,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 14,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }
  
  /// 학생 정보 입력 섹션
  pw.Widget _buildStudentInfoSection(FontPair fonts) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '학생 정보',
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 16,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 15),
          _buildInputField('성명', fonts),
          pw.SizedBox(height: 10),
          _buildInputField('학번/수험번호', fonts),
          pw.SizedBox(height: 10),
          _buildInputField('날짜', fonts),
        ],
      ),
    );
  }
  
  /// 입력 필드 생성
  pw.Widget _buildInputField(String label, FontPair fonts) {
    return pw.Row(
      children: [
        pw.Container(
          width: 100,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 12,
              color: PdfColors.black,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            height: 1,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// 시험 안내사항
  pw.Widget _buildInstructions(FontPair fonts) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '시험 안내사항',
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 14,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '• 답안은 명확하고 정확하게 작성하시오.\n'
            '• 문제를 끝까지 읽고 신중하게 답변하시오.\n'
            '• 시간 배분에 유의하시오.',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 11,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 문제 페이지들 생성
  pw.MultiPage _buildQuestionPages(ExamPaper examPaper, FontPair fonts) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 47, 32, 32), // 상단 여백 15pt 추가 (32+15=47)
      header: (pw.Context context) {
        return pw.Column(
          children: [
            BasePdfService.buildHeader(examPaper.title, context.pageNumber, fonts),
            pw.SizedBox(height: 10), // 헤더와 본문 사이 여백
          ],
        );
      },
      footer: (pw.Context context) {
        return BasePdfService.buildFooter(context.pageNumber, fonts);
      },
      build: (pw.Context context) {
        return [
          ..._buildQuestionList(examPaper.questions, fonts),
        ];
      },
    );
  }
  
  /// 문제 목록 생성
  List<pw.Widget> _buildQuestionList(List<ExamQuestion> questions, FontPair fonts) {
    final widgets = <pw.Widget>[];
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      
      widgets.add(
        pw.Wrap(
          children: [
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 25),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 문제 번호와 유형
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 30,
                        child: pw.Text(
                          '${i + 1}.',
                          style: pw.TextStyle(
                            font: fonts.bold,
                            fontSize: 14,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                      pw.Text(
                        _getQuestionTypeLabel(question.type),
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  
                  // 문제 내용
                  pw.Container(
                    padding: const pw.EdgeInsets.only(left: 30),
                    child: _buildQuestionContent(question, fonts),
                  ),
                  pw.SizedBox(height: 12),
                  
                  // 답안 공간
                  pw.Container(
                    padding: const pw.EdgeInsets.only(left: 30),
                    child: _buildAnswerSpace(question, fonts),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return widgets;
  }
  
  /// 답안지 페이지들 생성
  pw.MultiPage _buildAnswerKeyPages(ExamPaper examPaper, FontPair fonts) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 47, 32, 32), // 상단 여백 15pt 추가 (32+15=47)
      header: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 10),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '정답 및 해설',
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 14,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    '- ${context.pageNumber} -',
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10), // 헤더와 본문 사이 여백
          ],
        );
      },
      footer: (pw.Context context) {
        return BasePdfService.buildFooter(context.pageNumber, fonts);
      },
      build: (pw.Context context) {
        return [
          ..._buildAnswerKeyList(examPaper.questions, fonts),
        ];
      },
    );
  }
  
  /// 답안 목록 생성
  List<pw.Widget> _buildAnswerKeyList(List<ExamQuestion> questions, FontPair fonts) {
    final widgets = <pw.Widget>[];
    
    // 문제 유형별 그룹화
    QuestionType? currentType;
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      
      // 문제 유형이 바뀔 때 구분선 추가
      if (currentType != question.type) {
        if (currentType != null) {
          widgets.add(pw.SizedBox(height: 10));
          widgets.add(pw.Divider(color: PdfColors.grey400, thickness: 0.5));
          widgets.add(pw.SizedBox(height: 10));
        }
        currentType = question.type;
      }
      
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(
                color: PdfColors.grey700,
                width: 3,
              ),
            ),
          ),
          child: pw.Container(
            padding: const pw.EdgeInsets.only(left: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 문제 번호와 유형
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey800,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        '${i + 1}',
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 11,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      _getQuestionTypeName(question.type),
                      style: pw.TextStyle(
                        font: fonts.regular,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                
                // 답안 내용
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: _buildAnswerContent(question, fonts),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }
  
  /// 답안 내용 위젯 생성
  pw.Widget _buildAnswerContent(ExamQuestion question, FontPair fonts) {
    if (question.type == QuestionType.contextMeaning) {
      // 문맥 의미 문제는 구조화된 답안 표시
      final parts = question.answer.split('\n\n');
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var part in parts) ...[
            if (part.startsWith('"')) 
              pw.Text(
                part,
                style: pw.TextStyle(
                  font: fonts.bold,
                  fontSize: 11,
                  color: PdfColors.black,
                ),
              )
            else if (part.startsWith('문맥상 설명:') || part.startsWith('전체 문장 번역:'))
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    part.split(':')[0] + ':',
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    part.substring(part.indexOf(':') + 1).trim(),
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 11,
                      color: PdfColors.black,
                      lineSpacing: 1.3,
                    ),
                  ),
                ]
              )
            else
              pw.Text(
                part,
                style: pw.TextStyle(
                  font: fonts.regular,
                  fontSize: 11,
                  color: PdfColors.black,
                  lineSpacing: 1.3,
                ),
              ),
            if (part != parts.last) pw.SizedBox(height: 6),
          ],
        ],
      );
    } else {
      // 다른 문제 유형은 기본 텍스트
      return pw.Text(
        question.answer,
        style: pw.TextStyle(
          font: fonts.regular,
          fontSize: 11,
          color: PdfColors.black,
          lineSpacing: 1.3,
        ),
      );
    }
  }
  
  /// 문제 유형 이름 반환
  String _getQuestionTypeName(QuestionType type) {
    switch (type) {
      case QuestionType.fillInBlanks:
        return '빈칸 채우기';
      case QuestionType.contextMeaning:
        return '문맥 의미';
      case QuestionType.korToEngTranslation:
        return '한→영 번역';
    }
  }
  
  /// 프리미엄 관련 메서드들 (간소화)
  pw.Page _buildPremiumCoverPage(EnhancedExamPaper examPaper, FontPair fonts) {
    // 프리미엄 표지 페이지 구현
    return _buildCoverPage(ExamPaper.fromEnhanced(examPaper), fonts);
  }
  
  pw.MultiPage _buildEnhancedQuestionPages(EnhancedExamPaper examPaper, FontPair fonts) {
    // 향상된 문제 페이지 구현
    return _buildQuestionPages(ExamPaper.fromEnhanced(examPaper), fonts);
  }
  
  pw.MultiPage _buildEnhancedAnswerKeyPages(EnhancedExamPaper examPaper, FontPair fonts) {
    // 향상된 답안지 구현
    return _buildAnswerKeyPages(ExamPaper.fromEnhanced(examPaper), fonts);
  }
  
  /// 문제 내용 위젯 생성 (문제 유형별 레이아웃 적용)
  pw.Widget _buildQuestionContent(ExamQuestion question, FontPair fonts) {
    if (question.type == QuestionType.fillInBlanks) {
      // 빈칸 채우기 문제: 문제 단락에 박스 적용
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.black,
            width: 1.0,
          ),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 문제 지시문
            pw.Text(
              '다음 지문을 읽고 빈칸에 알맞은 단어를 쓰시오.',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 12),
            
            // 지문 내용 (박스 안에)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                question.question,
                style: pw.TextStyle(
                  font: fonts.regular,
                  fontSize: 12,
                  color: PdfColors.black,
                  lineSpacing: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (question.type == QuestionType.contextMeaning) {
      // 문맥 의미 문제: 볼드 단어 처리
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.black,
            width: 1.0,
          ),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 문제 지시문
            pw.Text(
              '다음 지문에서 굵은 글씨로 표시된 단어의 문맥상 의미를 설명하시오.',
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 12),
            
            // 지문 내용 (볼드 처리 적용)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: _buildTextWithBold(question.question, fonts),
            ),
          ],
        ),
      );
    } else if (question.type == QuestionType.korToEngTranslation) {
      // 한영 번역 문제: 박스 레이아웃 적용
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.black,
            width: 1.0,
          ),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 문제 내용 파싱 (지시문과 한국어 문장 분리)
            pw.Builder(
              builder: (context) {
                final parts = question.question.split('\n\n');
                final widgets = <pw.Widget>[];
                
                // 지시문
                if (parts.isNotEmpty) {
                  widgets.add(
                    pw.Text(
                      parts[0],
                      style: pw.TextStyle(
                        font: fonts.regular,
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  );
                  widgets.add(pw.SizedBox(height: 12));
                }
                
                // 한국어 문장
                if (parts.length > 1) {
                  widgets.add(
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(
                          color: PdfColors.grey400,
                          width: 0.5,
                        ),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        parts[1],
                        style: pw.TextStyle(
                          font: fonts.regular,
                          fontSize: 12,
                          color: PdfColors.black,
                          lineSpacing: 1.4,
                        ),
                      ),
                    ),
                  );
                }
                
                // 힌트가 있는 경우
                if (parts.length > 2) {
                  widgets.add(pw.SizedBox(height: 8));
                  widgets.add(
                    pw.Text(
                      parts[2],
                      style: pw.TextStyle(
                        font: fonts.regular,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  );
                }
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: widgets,
                );
              },
            ),
          ],
        ),
      );
    } else {
      // 기타 문제 유형: 기본 레이아웃
      return pw.Text(
        question.question,
        style: pw.TextStyle(
          font: fonts.regular,
          fontSize: 12,
          color: PdfColors.black,
        ),
      );
    }
  }

  /// 볼드 처리된 텍스트 위젯 생성
  pw.Widget _buildTextWithBold(String text, FontPair fonts) {
    // **단어** 패턴을 찾아서 볼드로 변환
    final List<pw.InlineSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*([^*]+)\*\*');
    int lastIndex = 0;
    
    for (final Match match in boldPattern.allMatches(text)) {
      // 볼드 이전의 일반 텍스트 추가
      if (match.start > lastIndex) {
        final normalText = text.substring(lastIndex, match.start);
        if (normalText.isNotEmpty) {
          spans.add(
            pw.TextSpan(
              text: normalText,
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 12,
                color: PdfColors.black,
              ),
            ),
          );
        }
      }
      
      // 볼드 텍스트 추가
      final boldText = match.group(1) ?? '';
      spans.add(
        pw.TextSpan(
          text: boldText,
          style: pw.TextStyle(
            font: fonts.bold,
            fontSize: 12,
            color: PdfColors.black,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
      
      lastIndex = match.end;
    }
    
    // 마지막 일반 텍스트 추가
    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      if (remainingText.isNotEmpty) {
        spans.add(
          pw.TextSpan(
            text: remainingText,
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 12,
              color: PdfColors.black,
            ),
          ),
        );
      }
    }
    
    // 볼드 패턴이 없으면 일반 텍스트로 처리
    if (spans.isEmpty) {
      return pw.Text(
        text,
        style: pw.TextStyle(
          font: fonts.regular,
          fontSize: 12,
          color: PdfColors.black,
          lineSpacing: 1.4,
        ),
      );
    }
    
    return pw.RichText(
      text: pw.TextSpan(
        children: spans,
        style: pw.TextStyle(
          lineSpacing: 1.4,
        ),
      ),
    );
  }

  /// 답안 공간 위젯 생성 (문제 유형별 답안 공간 적용)
  pw.Widget _buildAnswerSpace(ExamQuestion question, FontPair fonts) {
    if (question.type == QuestionType.fillInBlanks) {
      // 빈칸 채우기 문제: 박스형 답안 공간
      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '답:',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 12,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              height: 40,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.black,
                  width: 1.0,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    '',
                    style: pw.TextStyle(
                      font: fonts.regular,
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (question.type == QuestionType.contextMeaning) {
      // 문맥 의미 문제: 설명 답안 공간
      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '의미 설명:',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 12,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              height: 60, // 설명용으로 더 높게
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.black,
                  width: 1.0,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  children: [
                    // 여러 줄 작성 가이드
                    pw.Container(
                      width: double.infinity,
                      height: 12,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      width: double.infinity,
                      height: 12,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      width: double.infinity,
                      height: 12,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // 다른 문제 유형: 기본 답안 선
      return pw.Container(
        width: double.infinity,
        height: 30,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
          ),
        ),
      );
    }
  }

  /// 문제 유형 라벨 생성
  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.fillInBlanks:
        return '[빈칸 추론]';
      case QuestionType.contextMeaning:
        return '[문맥 의미]';
      case QuestionType.korToEngTranslation:
        return '[번역]';
      default:
        return '[기타]';
    }
  }
}
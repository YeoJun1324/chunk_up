// lib/core/services/detailed_answer_key_builder.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/enhanced_exam_models.dart';
import '../../models/exam_models.dart';

/// 상세 답안지 빌더
class DetailedAnswerKeyBuilder {
  
  /// 완전한 답안 항목 생성
  static pw.Widget buildDetailedAnswerItem(
    int questionIndex,
    EnhancedExamQuestion question,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.Font italicFont,
    ExamConfig config,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 25),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 문제 번호와 정답
          _buildAnswerHeader(questionIndex, question, boldFont),
          
          pw.SizedBox(height: 12),
          
          // 단계별 해설 (상세 옵션이 켜져있을 때만)
          if (config.includeDetailedExplanations) ...[
            _buildStepByStepSolution(question, regularFont, boldFont),
            pw.SizedBox(height: 10),
          ],
          
          // 문법 포인트
          if (question.explanation.grammarPoint.isNotEmpty) ...[
            _buildGrammarPoint(question, regularFont, boldFont),
            pw.SizedBox(height: 8),
          ],
          
          // 어휘 설명
          if (question.explanation.vocabularyNote.isNotEmpty) ...[
            _buildVocabularyNote(question, regularFont, boldFont),
            pw.SizedBox(height: 8),
          ],
          
          // 학습 팁
          if (question.explanation.learningTip.isNotEmpty) ...[
            _buildLearningTip(question, regularFont, italicFont),
            pw.SizedBox(height: 8),
          ],
          
          // 흔한 실수들
          if (question.explanation.commonMistakes.isNotEmpty) ...[
            _buildCommonMistakes(question, regularFont, boldFont),
            pw.SizedBox(height: 8),
          ],
          
          // 관련 단어들
          if (question.explanation.relatedWords.isNotEmpty) ...[
            _buildRelatedWords(question, regularFont, boldFont),
          ],
        ],
      ),
    );
  }

  /// 답안 헤더 (문제 번호, 정답, 배점)
  static pw.Widget _buildAnswerHeader(
    int questionIndex,
    EnhancedExamQuestion question,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_getQuestionTypeColor(question.type), _getQuestionTypeColor(question.type).shade(0.8)],
        ),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          // 문제 번호 원형 배지
          pw.Container(
            width: 35,
            height: 35,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                '$questionIndex',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                  color: _getQuestionTypeColor(question.type),
                ),
              ),
            ),
          ),
          
          pw.SizedBox(width: 15),
          
          // 문제 정보
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _getQuestionTypeLabel(question.type),
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  '정답: ${_formatAnswer(question.answer)}',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 14,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // 배점 표시
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Text(
              '${question.points}점',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 12,
                color: _getQuestionTypeColor(question.type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 단계별 풀이 과정
  static pw.Widget _buildStepByStepSolution(
    EnhancedExamQuestion question,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue500,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '📝',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                '단계별 풀이',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            question.explanation.stepByStepSolution,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 10,
              lineSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 문법 포인트
  static pw.Widget _buildGrammarPoint(
    EnhancedExamQuestion question,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.orange200),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              '📖',
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '문법 포인트',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: PdfColors.orange800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  question.explanation.grammarPoint,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    lineSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 어휘 설명
  static pw.Widget _buildVocabularyNote(
    EnhancedExamQuestion question,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.green200),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              '💡',
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '어휘 설명',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  question.explanation.vocabularyNote,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    lineSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 학습 팁
  static pw.Widget _buildLearningTip(
    EnhancedExamQuestion question,
    pw.Font regularFont,
    pw.Font italicFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.purple200),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              '💭',
              style: pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              '💡 학습 팁: ${question.explanation.learningTip}',
              style: pw.TextStyle(
                font: italicFont,
                fontSize: 10,
                lineSpacing: 1.3,
                color: PdfColors.purple700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 흔한 실수들
  static pw.Widget _buildCommonMistakes(
    EnhancedExamQuestion question,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.red200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                '⚠️',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                '흔한 실수',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                  color: PdfColors.red800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          ...question.explanation.commonMistakes.map((mistake) => 
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10,
                      color: PdfColors.red700,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      mistake,
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.red700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  /// 관련 단어들
  static pw.Widget _buildRelatedWords(
    EnhancedExamQuestion question,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.teal200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                '🔗',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                '관련 단어',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 11,
                  color: PdfColors.teal800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 6,
            runSpacing: 4,
            children: question.explanation.relatedWords.map((word) =>
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal100,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  word,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 9,
                    color: PdfColors.teal800,
                  ),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  /// 채점 기준 항목 생성
  static pw.Widget buildGradingCriteriaItem(
    int questionIndex,
    EnhancedExamQuestion question,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.purple50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // 문제 정보 헤더
          pw.Row(
            children: [
              pw.Container(
                width: 30,
                height: 30,
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple600,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '$questionIndex',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 14,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _getQuestionTypeLabel(question.type),
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 12,
                        color: PdfColors.purple800,
                      ),
                    ),
                    pw.Text(
                      '배점: ${question.gradingCriteria.fullPoints}점',
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 10,
                        color: PdfColors.purple700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          pw.SizedBox(height: 12),
          
          // 채점 기준
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.purple200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '채점 기준',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 11,
                    color: PdfColors.purple800,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  question.gradingCriteria.rubric,
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    lineSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
          
          // 부분 점수 (있는 경우)
          if (question.gradingCriteria.partialPoints > 0) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.orange200),
              ),
              child: pw.Text(
                '부분 점수: ${question.gradingCriteria.partialPoints}점 (의미가 통하나 완전하지 않은 경우)',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 10,
                  color: PdfColors.orange800,
                ),
              ),
            ),
          ],
          
          // 필수 키워드 (있는 경우)
          if (question.gradingCriteria.keywords.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '필수 키워드:',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 10,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: question.gradingCriteria.keywords.map((keyword) =>
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue100,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Text(
                          keyword,
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 9,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===== 보조 메서드들 =====

  static String _getQuestionTypeLabel(QuestionType type) {
    final info = EnhancedQuestionTypeInfo.getInfo(type);
    return info?.name ?? type.toString().split('.').last;
  }

  static PdfColor _getQuestionTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.fillInBlanks:
        return PdfColors.blue500;
      case QuestionType.contextMeaning:
        return PdfColors.orange500;
      case QuestionType.korToEngTranslation:
        return PdfColors.purple500;
    }
  }

  static String _formatAnswer(dynamic answer) {
    if (answer is List) {
      return answer.join(', ');
    }
    return answer.toString();
  }
}
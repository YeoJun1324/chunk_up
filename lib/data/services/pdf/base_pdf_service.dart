// lib/core/services/pdf/base_pdf_service.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// PDF 기본 서비스 - 공통 기능들을 제공
abstract class BasePdfService {
  static const String _fontRegularAsset = 'assets/fonts/NotoSansKR-Regular.ttf';
  static const String _fontBoldAsset = 'assets/fonts/NotoSansKR-Bold.ttf';
  
  /// 폰트 로딩 (공통)
  static Future<FontPair> loadFonts() async {
    late pw.Font regularFont, boldFont;
    
    try {
      // 한글 폰트 로드 시도
      regularFont = await PdfGoogleFonts.notoSansKRRegular();
      boldFont = await PdfGoogleFonts.notoSansKRBold();
    } catch (e) {
      // 폴백 폰트 사용
      regularFont = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    }
    
    return FontPair(regularFont, boldFont);
  }
  
  /// 공통 헤더 생성
  static pw.Widget buildHeader(String title, int pageNumber, FontPair fonts) {
    return pw.Container(
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
            title,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 14,
              color: PdfColors.black,
            ),
          ),
          pw.Text(
            '- $pageNumber -',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 12,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 공통 푸터 생성
  static pw.Widget buildFooter(int pageNumber, FontPair fonts) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      child: pw.Center(
        child: pw.Text(
          '- $pageNumber -',
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: 10,
            color: PdfColors.black,
          ),
        ),
      ),
    );
  }
  
  /// 날짜 포맷팅
  static String formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}

/// 폰트 쌍 클래스
class FontPair {
  final pw.Font regular;
  final pw.Font bold;
  
  const FontPair(this.regular, this.bold);
}

/// PDF 테마 설정
class PdfTheme {
  final PdfColor primaryColor;
  final PdfColor secondaryColor;
  final PdfColor backgroundColor;
  final PdfColor textColor;
  final double headerFontSize;
  final double bodyFontSize;
  final double footerFontSize;
  
  const PdfTheme({
    this.primaryColor = PdfColors.blue,
    this.secondaryColor = PdfColors.grey,
    this.backgroundColor = PdfColors.white,
    this.textColor = PdfColors.black,
    this.headerFontSize = 14.0,
    this.bodyFontSize = 12.0,
    this.footerFontSize = 10.0,
  });
  
  static const PdfTheme academic = PdfTheme(
    primaryColor: PdfColors.black,
    secondaryColor: PdfColors.grey700,
    headerFontSize: 14.0,
    bodyFontSize: 12.0,
  );
  
  static const PdfTheme premium = PdfTheme(
    primaryColor: PdfColors.deepPurple,
    secondaryColor: PdfColors.purple100,
    headerFontSize: 16.0,
    bodyFontSize: 13.0,
  );
}
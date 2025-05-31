// lib/core/utils/word_highlighter.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:pluralize/pluralize.dart';

/// 단어 하이라이트를 위한 유틸리티 클래스
/// 단어 매칭과 하이라이트 관련 공통 로직을 제공합니다.
class WordHighlighter {
  /// 텍스트 내의 단어를 하이라이트하는 RichText 위젯을 생성합니다.
  static RichText buildHighlightedText({
    required String text,
    required List<Word> highlightWords,
    required Color highlightColor,
    double fontSize = 17,
    FontWeight normalFontWeight = FontWeight.normal,
    FontWeight highlightFontWeight = FontWeight.bold,
    Function(String)? onTap,
    bool underlineHighlights = false,
    Color textColor = Colors.black87, // 기본 텍스트 색상 추가
  }) {
    final Map<int, Map<String, dynamic>> markups = _findWordPositions(text, highlightWords);
    final spans = _buildTextSpans(
      text,
      markups,
      fontSize,
      normalFontWeight,
      highlightFontWeight,
      highlightColor,
      onTap,
      underlineHighlights,
      textColor,
    );

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.justify,
    );
  }

  /// 텍스트 내에서 강조할 단어의 위치를 찾습니다.
  static Map<int, Map<String, dynamic>> _findWordPositions(String text, List<Word> words) {
    final Map<int, Map<String, dynamic>> markups = {};
    final lowerText = text.toLowerCase();

    for (final word in words) {
      final String targetWord = word.english.toLowerCase();

      // 공백을 포함하는 복합 단어인지 확인
      if (targetWord.contains(' ')) {
        // 복합 단어 처리 (예: "go on strike")
        _findCompoundWord(text, lowerText, targetWord, word, markups);
      } else {
        // 단일 단어 처리
        _findSingleWord(text, lowerText, targetWord, word, markups);
      }
    }

    return markups;
  }

  /// 복합 단어(공백 포함)를 찾아 markups에 추가합니다.
  static void _findCompoundWord(
      String originalText,
      String lowerText,
      String targetWord,
      Word word,
      Map<int, Map<String, dynamic>> markups
      ) {
    // 복합 단어를 정규식으로 변환 (예: "go on strike" -> "go\s+on\s+strike")
    final parts = targetWord.split(' ');
    final pattern = parts.map((part) => RegExp.escape(part)).join(r'\s+');
    final regex = RegExp(pattern, caseSensitive: false);

    for (final match in regex.allMatches(lowerText)) {
      // 원래 텍스트에서 매칭된 정확한 문자열 추출
      final String exactMatch = originalText.substring(match.start, match.end);

      markups[match.start] = {
        'end': match.end,
        'word': word.english, // 원래 단어 사용
        'exactMatch': exactMatch,
      };
    }
  }

  /// 단일 단어를 찾아 markups에 추가합니다.
  /// 복수형, 시제 등 다양한 형태의 단어를 지원합니다.
  static void _findSingleWord(
      String originalText,
      String lowerText,
      String targetWord,
      Word word,
      Map<int, Map<String, dynamic>> markups
      ) {
    // 1. 기본 단어 찾기
    _findExactWordForm(originalText, lowerText, targetWord, word, markups);

    // 2. 복수형/단수형 변환하여 찾기
    final pluralize = Pluralize();
    final isSingular = pluralize.isSingular(targetWord);
    String alternateForm = isSingular
        ? pluralize.plural(targetWord)   // 단수 -> 복수
        : pluralize.singular(targetWord); // 복수 -> 단수

    // 변환된 형태가 원래와 다를 경우에만 검색
    if (alternateForm != targetWord) {
      _findExactWordForm(originalText, lowerText, alternateForm.toLowerCase(), word, markups);
    }

    // 3. 기본 동사형 + ing/ed/er/est 형태 추가 (기본적인 규칙 처리)
    if (!targetWord.endsWith('ing') && !targetWord.endsWith('ed') &&
        !targetWord.endsWith('er') && !targetWord.endsWith('est')) {

      // ing 형태 검색
      if (targetWord.endsWith('e')) {
        // dance -> dancing (e 삭제)
        _findExactWordForm(originalText, lowerText,
            (targetWord.substring(0, targetWord.length - 1) + 'ing').toLowerCase(),
            word, markups);
      } else if (targetWord.endsWith('y')) {
        // study -> studying (y->i 변경)
        _findExactWordForm(originalText, lowerText,
            (targetWord.substring(0, targetWord.length - 1) + 'ying').toLowerCase(),
            word, markups);
      } else {
        // walk -> walking
        _findExactWordForm(originalText, lowerText,
            (targetWord + 'ing').toLowerCase(),
            word, markups);
      }

      // ed 형태 검색
      if (targetWord.endsWith('e')) {
        // dance -> danced
        _findExactWordForm(originalText, lowerText,
            (targetWord + 'd').toLowerCase(),
            word, markups);
      } else if (targetWord.endsWith('y')) {
        // study -> studied (y->i 변경)
        _findExactWordForm(originalText, lowerText,
            (targetWord.substring(0, targetWord.length - 1) + 'ied').toLowerCase(),
            word, markups);
      } else {
        // walk -> walked
        _findExactWordForm(originalText, lowerText,
            (targetWord + 'ed').toLowerCase(),
            word, markups);
      }

      // er 형태 검색 (비교급)
      if (targetWord.endsWith('e')) {
        // nice -> nicer
        _findExactWordForm(originalText, lowerText,
            (targetWord + 'r').toLowerCase(),
            word, markups);
      } else if (targetWord.endsWith('y')) {
        // happy -> happier (y->i 변경)
        _findExactWordForm(originalText, lowerText,
            (targetWord.substring(0, targetWord.length - 1) + 'ier').toLowerCase(),
            word, markups);
      } else {
        // fast -> faster
        _findExactWordForm(originalText, lowerText,
            (targetWord + 'er').toLowerCase(),
            word, markups);
      }

      // est 형태 검색 (최상급)
      if (targetWord.endsWith('e')) {
        // nice -> nicest
        _findExactWordForm(originalText, lowerText,
            (targetWord + 'st').toLowerCase(),
            word, markups);
      } else if (targetWord.endsWith('y')) {
        // happy -> happiest (y->i 변경)
        _findExactWordForm(originalText, lowerText,
            (targetWord.substring(0, targetWord.length - 1) + 'iest').toLowerCase(),
            word, markups);
      } else {
        // fast -> fastest
        _findExactWordForm(originalText, lowerText,
            (targetWord + 'est').toLowerCase(),
            word, markups);
      }

      // ment 접미사 형태 검색 (명사화)
      // achieve -> achievement
      if (!targetWord.endsWith('ment')) {
        _findExactWordForm(originalText, lowerText,
            (targetWord + 'ment').toLowerCase(),
            word, markups);
      }
    }

    // 4. 해당 단어가 파생된 형태인 경우, 기본형 찾기
    if (targetWord.endsWith('ing')) {
      // running -> run, dancing -> danc
      String baseForm = targetWord.substring(0, targetWord.length - 3);
      if (baseForm.endsWith('n') && targetWord.length > 5) {
        // running -> run (반복된 n 제거)
        baseForm = baseForm.substring(0, baseForm.length - 1);
      }
      _findExactWordForm(originalText, lowerText, baseForm.toLowerCase(), word, markups);

      // dancing -> dance (e 추가)
      _findExactWordForm(originalText, lowerText, (baseForm + 'e').toLowerCase(), word, markups);
    } else if (targetWord.endsWith('ed')) {
      // walked -> walk
      String baseForm = targetWord.substring(0, targetWord.length - 2);
      _findExactWordForm(originalText, lowerText, baseForm.toLowerCase(), word, markups);

      // added -> add (반복된 자음 제거)
      if (baseForm.length >= 2 && baseForm[baseForm.length - 1] == baseForm[baseForm.length - 2]) {
        _findExactWordForm(originalText, lowerText,
            baseForm.substring(0, baseForm.length - 1).toLowerCase(), word, markups);
      }
    } else if (targetWord.endsWith('ment')) {
      // achievement -> achieve
      String baseForm = targetWord.substring(0, targetWord.length - 4);
      _findExactWordForm(originalText, lowerText, baseForm.toLowerCase(), word, markups);
    }
  }

  /// 정확한 단어 형태를 찾아 markups에 추가하는 헬퍼 메서드
  static void _findExactWordForm(
      String originalText,
      String lowerText,
      String exactTargetWord,
      Word word,
      Map<int, Map<String, dynamic>> markups
      ) {
    // 단어 경계를 고려한 정규식 패턴
    final pattern = r'\b' + RegExp.escape(exactTargetWord) + r'\b';
    final regex = RegExp(pattern, caseSensitive: false);

    for (final match in regex.allMatches(lowerText)) {
      // 원래 텍스트에서 매칭된 정확한 문자열 추출
      final String exactMatch = originalText.substring(match.start, match.end);

      markups[match.start] = {
        'end': match.end,
        'word': word.english, // 원래 단어 사용
        'exactMatch': exactMatch,
      };
    }
  }

  /// markups 정보를 기반으로 TextSpan 리스트를 생성합니다.
  static List<TextSpan> _buildTextSpans(
      String text,
      Map<int, Map<String, dynamic>> markups,
      double fontSize,
      FontWeight normalFontWeight,
      FontWeight highlightFontWeight,
      Color highlightColor,
      Function(String)? onTap,
      bool underlineHighlights,
      Color textColor,
      ) {
    final spans = <TextSpan>[];
    int lastIndex = 0;
    final indices = markups.keys.toList()..sort();

    for (final startIndex in indices) {
      final endIndex = markups[startIndex]!['end'];
      final word = markups[startIndex]!['word'];
      final exactMatch = markups[startIndex]!['exactMatch'];

      // 이전 텍스트 추가 (하이라이트 없음)
      if (startIndex > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, startIndex),
          style: TextStyle(
            fontSize: fontSize,
            height: 1.6,
            fontWeight: normalFontWeight,
            color: textColor,
          ),
        ));
      }

      // 하이라이트된 단어 추가
      spans.add(TextSpan(
        text: exactMatch, // 매치된 정확한 텍스트 사용
        style: TextStyle(
          fontSize: fontSize,
          height: 1.6,
          color: highlightColor,
          fontWeight: highlightFontWeight,
          decoration: underlineHighlights ? TextDecoration.underline : null,
          decorationColor: underlineHighlights ? highlightColor.withOpacity(0.5) : null,
          decorationStyle: underlineHighlights ? TextDecorationStyle.dotted : null,
        ),
        recognizer: onTap != null ? (TapGestureRecognizer()..onTap = () => onTap(word)) : null,
      ));

      lastIndex = endIndex;
    }

    // 남은 텍스트 추가
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          fontSize: fontSize,
          height: 1.6,
          fontWeight: normalFontWeight,
          color: textColor,
        ),
      ));
    }

    return spans;
  }
}
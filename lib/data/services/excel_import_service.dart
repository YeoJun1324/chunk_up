// lib/data/services/excel_import_service.dart
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
// import 'package:chunk_up/presentation/providers/word_list_notifier.dart';

class ExcelImportService {
  /// 엑셀 파일에서 단어장 가져오기
  static Future<List<WordListInfo>> importFromExcelBytes(
      Uint8List bytes, {
        String defaultName = '가져온 단어장',
      }) async {
    try {
      // 엑셀 파일 파싱
      final excel = Excel.decodeBytes(bytes);
      final List<WordListInfo> wordLists = [];

      // 각 시트를 개별 단어장으로 처리
      for (var sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];
        if (sheet == null || sheet.rows.isEmpty) continue;

        // 최소 2개 열이 있는지 확인
        bool hasEnoughColumns = false;
        for (var row in sheet.rows) {
          if (row.length >= 2) {
            hasEnoughColumns = true;
            break;
          }
        }

        if (!hasEnoughColumns) continue;

        final List<Word> words = [];
        final List<List<dynamic>> rows = sheet.rows;

        // 헤더 확인
        bool hasHeader = _detectHeader(rows);
        int startRow = hasHeader ? 1 : 0;

        // 행 수가 너무 많으면 UI 업데이트를 위해 백그라운드에서 처리
        for (var i = startRow; i < rows.length; i++) {
          final row = rows[i];
          if (row.length < 2) continue;

          final cellA = row[0]?.value?.toString() ?? '';
          final cellB = row[1]?.value?.toString() ?? '';

          final english = cellA.trim();
          final korean = cellB.trim();

          if (english.isNotEmpty && korean.isNotEmpty && 
              _isActualWord(english) && _isActualWord(korean)) {
            words.add(Word(
              english: english,
              korean: korean,
            ));
          }
        }

        if (words.isNotEmpty) {
          final name = sheetName != 'Sheet1' ? sheetName : defaultName;
          wordLists.add(WordListInfo(
            name: name,
            words: words,
          ));
        }
      }

      return wordLists;
    } catch (e) {
      debugPrint('엑셀 파일 파싱 오류: $e');
      return [];
    }
  }

  /// 헤더 존재 여부 확인
  static bool _detectHeader(List<List<dynamic>> rows) {
    if (rows.isEmpty) return false;

    final firstRow = rows[0];
    if (firstRow.length < 2) return false;

    final cell1 = firstRow[0]?.value?.toString()?.toLowerCase() ?? '';
    final cell2 = firstRow[1]?.value?.toString()?.toLowerCase() ?? '';

    return cell1.contains('english') || 
           cell1.contains('word') || 
           cell2.contains('korean') || 
           cell2.contains('meaning');
  }

  /// 실제 단어인지 확인 (헤더와 단어를 구분하기 위함)
  static bool _isActualWord(String text) {
    // 일반적인 헤더명이 아니면서 공백이 아닌 경우 실제 단어로 간주
    final headerKeywords = [
      'english', '영어', 'word', '단어', 'vocabulary',
      'korean', '한국어', '한글', 'meaning', '의미', 'translation'
    ];

    text = text.toLowerCase().trim();
    if (text.isEmpty) return false;
    if (headerKeywords.contains(text)) return false;

    return true;
  }

  /// WordListNotifier에 단어장 추가
  static Future<int> addWordListsToNotifier(
      dynamic notifier, // 동적 타입으로 변경
      List<WordListInfo> wordLists) async {
    int addedCount = 0;

    for (var wordList in wordLists) {
      var listName = wordList.name ?? 'Excel Import';
      var counter = 1;

      // 같은 이름의 단어장이 있는 경우 이름 뒤에 숫자 추가
      var existingLists = notifier.wordLists;
      while (existingLists.any((list) => list.name == listName)) {
        listName = '${wordList.name ?? 'Excel Import'} ($counter)';
        counter++;
      }

      // 단어장 추가
      await notifier.addNewWordList(listName);

      // 단어 추가
      for (var word in wordList.words) {
        await notifier.addWordToSpecificList(listName, word);
      }

      addedCount++;
    }

    return addedCount;
  }
}
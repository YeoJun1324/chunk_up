// lib/data/services/csv_import_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';

class CsvImportService {

  /// Excel 파일을 CSV로 변환 시도
  static String? tryConvertExcelToCsv(Uint8List bytes) {
    try {
      // Excel 파일 파싱 시도
      final excel = Excel.decodeBytes(bytes);

      // 첫 번째 시트만 CSV로 변환
      final sheet = excel.tables.values.first;
      if (sheet == null) return null;

      final rows = <String>[];
      for (var row in sheet.rows) {
        final cells = row.map((cell) => cell?.value?.toString() ?? '').toList();
        rows.add(cells.join(','));
      }

      return rows.join('\n');
    } catch (e) {
      debugPrint('Excel to CSV 변환 오류: $e');
      return null;
    }
  }

  /// CSV 데이터에서 단어장 가져오기
  static Future<WordListInfo?> importFromCsvString(
      String csvContent,
      String listName
      ) async {
    try {
      final List<Word> words = [];
      final lines = csvContent.split('\n');

      print('CSV 파일 처리 시작: ${lines.length} 행');
      bool hasHeader = _detectCsvHeader(lines);

      int startRow = hasHeader ? 1 : 0;
      for (var i = startRow; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // 쉼표로 분리 (엑셀에서 내보낸 CSV는 보통 쉼표로 구분됨)
        List<String> columns;

        // 큰따옴표가 있는 경우 (CSV 표준) 처리
        if (line.contains('"')) {
          columns = _parseQuotedCsvLine(line);
        } else {
          columns = line.split(',');
        }

        if (columns.length < 2) continue;

        final english = columns[0].trim();
        final korean = columns[1].trim();

        if (english.isNotEmpty && korean.isNotEmpty) {
          words.add(Word(
            english: english,
            korean: korean,
          ));
        }
      }

      if (words.isEmpty) {
        debugPrint('가져온 단어가 없습니다');
        return null;
      }

      debugPrint('가져온 단어 수: ${words.length}');
      return WordListInfo(
        name: listName,
        words: words,
      );
    } catch (e) {
      debugPrint('CSV 파싱 오류: $e');
      return null;
    }
  }

  /// CSV 헤더 여부 감지
  static bool _detectCsvHeader(List<String> lines) {
    if (lines.isEmpty || lines.length < 2) return false;

    final firstLine = lines[0].toLowerCase();
    return firstLine.contains('english') || 
           firstLine.contains('word') || 
           firstLine.contains('korean') || 
           firstLine.contains('meaning');
  }

  /// 따옴표가 있는 CSV 라인 파싱 (복잡한 CSV 구문 처리)
  static List<String> _parseQuotedCsvLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String currentValue = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        // 따옴표 내부일 때는 따옴표를 토글
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        // 따옴표 외부의 쉼표는 구분자로 처리
        result.add(currentValue.trim());
        currentValue = '';
      } else {
        // 다른 모든 문자는 현재 값에 추가
        currentValue += char;
      }
    }

    // 마지막 값 추가
    if (currentValue.isNotEmpty) {
      result.add(currentValue.trim());
    }

    // 따옴표 제거
    return result.map((value) => value.replaceAll('"', '')).toList();
  }

  /// 단어장을 워드리스트 노티파이어에 추가
  static Future<bool> addWordListToNotifier(
      dynamic notifier, // 타입을 dynamic으로 변경하여 유연하게 사용
      WordListInfo wordList,
      ) async {
    try {
      // 이름 중복 확인
      String listName = wordList.name ?? 'Imported List';
      int counter = 1;

      // 이미 같은 이름의 단어장이 있는지 확인
      var existingLists = notifier.wordLists;
      while (existingLists.any((list) => list.name == listName)) {
        listName = '${wordList.name ?? 'Imported List'} ($counter)';
        counter++;
      }

      // 단어장 추가
      await notifier.addNewWordList(listName);

      // 단어 추가
      for (var word in wordList.words) {
        await notifier.addWordToSpecificList(listName, word);
      }

      return true;
    } catch (e) {
      print('단어장 추가 오류: $e');
      return false;
    }
  }
}
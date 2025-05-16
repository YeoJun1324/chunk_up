// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:pluralize/pluralize.dart';
import 'word.dart';

/*
코드 생성이 완료되었습니다.
추가 수정이 필요한 경우 다음 명령어를 실행하세요:

flutter pub run build_runner build --delete-conflicting-outputs
*/
part 'chunk.freezed.dart';
part 'chunk.g.dart';

/// Freezed로 구현한 단락 모델 클래스
///
/// freezed 패키지를 사용하여 불변성(immutability)을 구현한 Chunk 클래스입니다.
/// 생성된 코드는 빌드 타임에 자동으로 생성됩니다.
@freezed
class Chunk with _$Chunk {
  const Chunk._(); // custom 메서드를 추가하기 위한 private 생성자

  /// 기본 생성자
  @Assert('title.isNotEmpty', 'title cannot be empty')
  @Assert('englishContent.isNotEmpty', 'englishContent cannot be empty')
  @Assert('koreanTranslation.isNotEmpty', 'koreanTranslation cannot be empty')
  factory Chunk({
    /// ID (UUID)
    String? id,

    /// 단락 제목
    required String title,

    /// 영어 내용
    required String englishContent,

    /// 한국어 번역
    required String koreanTranslation,

    /// 포함된 단어 목록
    required List<Word> includedWords,

    /// 생성 일시
    DateTime? createdAt,

    /// 단어 설명 맵
    @Default(<String, String>{}) Map<String, String> wordExplanations,

    /// 생성 파라미터: 캐릭터
    String? character,

    /// 생성 파라미터: 시나리오
    String? scenario,

    /// 생성 파라미터: 추가 세부사항
    String? additionalDetails,
  }) = _Chunk;

  /// JSON에서 객체 생성을 위한 팩토리 메서드
  factory Chunk.fromJson(Map<String, dynamic> json) => _$ChunkFromJson(json);

  /// 단어 포함 여부 확인
  bool containsWord(Word word) {
    return includedWords.any((w) => w.english.toLowerCase() == word.english.toLowerCase());
  }

  /// 특정 단어의 설명 가져오기
  String? getExplanationFor(String word) {
    // 설명은 소문자 키로 저장되므로 일관성을 위해 소문자 변환
    final lowerWord = word.toLowerCase();

    // 1. 정확히 일치하는 단어 찾기
    if (wordExplanations.containsKey(lowerWord)) {
      return wordExplanations[lowerWord];
    }

    // 2. 단어 변형을 처리하기 위한 로직
    // 복수형/단수형 확인
    final pluralizer = Pluralize();
    final isSingular = pluralizer.isSingular(lowerWord);

    // 단수 -> 복수 또는 복수 -> 단수 변환
    String alternateForm = isSingular
      ? pluralizer.plural(lowerWord)     // 단수 -> 복수
      : pluralizer.singular(lowerWord);  // 복수 -> 단수

    if (wordExplanations.containsKey(alternateForm)) {
      return wordExplanations[alternateForm];
    }

    // 3. 기본 형태의 변형 확인 (ing, ed, er, est 등)
    // ing 형태 확인
    if (lowerWord.endsWith('ing')) {
      // running -> run, dancing -> dance
      String baseForm = lowerWord.substring(0, lowerWord.length - 3);
      if (baseForm.endsWith('n') && lowerWord.length > 5) {
        // running -> run (반복된 n 제거)
        baseForm = baseForm.substring(0, baseForm.length - 1);
      }

      if (wordExplanations.containsKey(baseForm)) {
        return wordExplanations[baseForm];
      }

      // dancing -> dance (e 추가)
      baseForm += 'e';
      if (wordExplanations.containsKey(baseForm)) {
        return wordExplanations[baseForm];
      }
    }
    // ed 형태 확인
    else if (lowerWord.endsWith('ed')) {
      // walked -> walk
      String baseForm = lowerWord.substring(0, lowerWord.length - 2);
      if (wordExplanations.containsKey(baseForm)) {
        return wordExplanations[baseForm];
      }

      // added -> add (반복된 자음 제거)
      if (baseForm.length >= 2 && baseForm[baseForm.length - 1] == baseForm[baseForm.length - 2]) {
        baseForm = baseForm.substring(0, baseForm.length - 1);
        if (wordExplanations.containsKey(baseForm)) {
          return wordExplanations[baseForm];
        }
      }

      // loved -> love (e 추가)
      baseForm += 'e';
      if (wordExplanations.containsKey(baseForm)) {
        return wordExplanations[baseForm];
      }
    }

    // 찾지 못한 경우 null 반환
    return null;
  }

  /// 단어 설명 추가
  Chunk addExplanation(String word, String explanation) {
    final newExplanations = Map<String, String>.from(wordExplanations);
    newExplanations[word.toLowerCase()] = explanation;
    return copyWith(wordExplanations: newExplanations);
  }

  /// 단락의 총 단어 수
  int get totalWordCount => includedWords.length;

  /// 단락의 영어 문장 수
  int get sentenceCount {
    final sentenceEndRegex = RegExp(r'[.!?]+');
    return englishContent.split(sentenceEndRegex).where((s) => s.trim().isNotEmpty).length;
  }

  /// 단락의 난이도 레벨 (1: 쉬움, 2: 보통, 3: 어려움)
  int get difficultyLevel {
    final avgWordLength = englishContent.split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word.replaceAll(RegExp(r'[^\w]'), '')) // 구두점 제거
        .fold<int>(0, (sum, word) => sum + word.length) /
        englishContent.split(' ').where((word) => word.isNotEmpty).length;

    if (avgWordLength < 4) return 1; // 쉬움
    if (avgWordLength < 6) return 2; // 보통
    return 3; // 어려움
  }

  /// ID 자동 생성되도록 수정된 생성자
  factory Chunk.create({
    required String title,
    required String englishContent,
    required String koreanTranslation,
    required List<Word> includedWords,
    Map<String, String>? wordExplanations,
    String? character,
    String? scenario,
    String? additionalDetails,
  }) {
    return Chunk(
      id: const Uuid().v4(),
      title: title,
      englishContent: englishContent,
      koreanTranslation: koreanTranslation,
      includedWords: includedWords,
      createdAt: DateTime.now(),
      wordExplanations: wordExplanations ?? {},
      character: character,
      scenario: scenario,
      additionalDetails: additionalDetails,
    );
  }

  // 수동 copyWith 메서드는 제거됨 - Freezed가 자동 생성한 메서드 사용
}
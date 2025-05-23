import 'word.dart';
import 'package:uuid/uuid.dart';
import 'package:pluralize/pluralize.dart';

/// 단락 모델 클래스
///
/// 단어들을 문맥화한 단락 정보를 관리합니다.
class Chunk {
  final String id; // 고유 식별자 (UUID)
  final String title; // 단락 제목
  final String englishContent; // 영어 내용
  final String koreanTranslation; // 한국어 번역
  final DateTime createdAt; // 생성 일시
  final List<Word> includedWords; // 포함된 단어 목록
  final Map<String, String> wordExplanations; // 단어 설명

  // 생성 파라미터 (재출력에 사용)
  final List<String> character; // 캐릭터 목록
  final String? scenario; // 시나리오
  final String? additionalDetails; // 추가 세부사항
  final String? usedModel; // 사용된 AI 모델

  Chunk({
    String? id, // ID는 옵션
    required this.title,
    required this.englishContent,
    required this.koreanTranslation,
    required this.includedWords,
    DateTime? createdAt,
    Map<String, String>? wordExplanations,
    this.character = const [],
    this.scenario,
    this.additionalDetails,
    this.usedModel,
  }) :
        id = id ?? const Uuid().v4(), // ID가 없으면 자동 생성
        createdAt = createdAt ?? DateTime.now(),
        wordExplanations = wordExplanations ?? {};

  /// 불변성 패턴을 위한 복사 생성 메서드
  /// 
  /// 특정 속성만 변경한 새 Chunk 객체를 생성합니다.
  Chunk copyWith({
    String? id,
    String? title,
    String? englishContent,
    String? koreanTranslation,
    List<Word>? includedWords,
    DateTime? createdAt,
    Map<String, String>? wordExplanations,
    List<String>? character,
    String? scenario,
    String? additionalDetails,
    String? usedModel,
  }) {
    return Chunk(
      id: id ?? this.id,
      title: title ?? this.title,
      englishContent: englishContent ?? this.englishContent,
      koreanTranslation: koreanTranslation ?? this.koreanTranslation,
      includedWords: includedWords ?? List<Word>.from(this.includedWords),
      createdAt: createdAt ?? this.createdAt,
      wordExplanations: wordExplanations ?? Map<String, String>.from(this.wordExplanations),
      character: character ?? List<String>.from(this.character),
      scenario: scenario ?? this.scenario,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      usedModel: usedModel ?? this.usedModel,
    );
  }

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
    // er 형태 (비교급) 확인
    else if (lowerWord.endsWith('er') && lowerWord.length > 3) {
      // faster -> fast
      String baseForm = lowerWord.substring(0, lowerWord.length - 2);
      if (wordExplanations.containsKey(baseForm)) {
        return wordExplanations[baseForm];
      }

      // nicer -> nice (e 제거 후 확인)
      if (baseForm.endsWith('i') && baseForm.length > 1) {
        // happier -> happy (i -> y)
        baseForm = baseForm.substring(0, baseForm.length - 1) + 'y';
        if (wordExplanations.containsKey(baseForm)) {
          return wordExplanations[baseForm];
        }
      }
    }
    // est 형태 (최상급) 확인
    else if (lowerWord.endsWith('est') && lowerWord.length > 4) {
      // fastest -> fast
      String baseForm = lowerWord.substring(0, lowerWord.length - 3);
      if (wordExplanations.containsKey(baseForm)) {
        return wordExplanations[baseForm];
      }

      if (baseForm.endsWith('i') && baseForm.length > 1) {
        // happiest -> happy (i -> y)
        baseForm = baseForm.substring(0, baseForm.length - 1) + 'y';
        if (wordExplanations.containsKey(baseForm)) {
          return wordExplanations[baseForm];
        }
      }
    }

    // 4. 기본형에서 변형 확인 (반대 방향으로 확인)
    // 현재 단어가 기본형이라면 ing, ed 형태로 저장된 설명이 있는지 확인

    // 기본형 -> ing 형태
    String ingForm;
    if (lowerWord.endsWith('e')) {
      // dance -> dancing (e 삭제)
      ingForm = lowerWord.substring(0, lowerWord.length - 1) + 'ing';
    } else if (lowerWord.endsWith('y')) {
      // study -> studying (y 유지)
      ingForm = lowerWord + 'ing';
    } else {
      // walk -> walking
      ingForm = lowerWord + 'ing';
    }

    if (wordExplanations.containsKey(ingForm)) {
      return wordExplanations[ingForm];
    }

    // 기본형 -> ed 형태
    String edForm;
    if (lowerWord.endsWith('e')) {
      // dance -> danced
      edForm = lowerWord + 'd';
    } else if (lowerWord.endsWith('y')) {
      // study -> studied (y->i 변경)
      edForm = lowerWord.substring(0, lowerWord.length - 1) + 'ied';
    } else {
      // walk -> walked
      edForm = lowerWord + 'ed';
    }

    if (wordExplanations.containsKey(edForm)) {
      return wordExplanations[edForm];
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

  // 직렬화를 위한 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'englishContent': englishContent,
      'koreanTranslation': koreanTranslation,
      'createdAt': createdAt.toIso8601String(),
      'includedWords': includedWords.map((w) => {'english': w.english, 'korean': w.korean}).toList(),
      'wordExplanations': wordExplanations,
      'character': character,
      'scenario': scenario,
      'additionalDetails': additionalDetails,
      'usedModel': usedModel,
    };
  }

  // 역직렬화를 위한 팩토리 메서드
  factory Chunk.fromJson(Map<String, dynamic> json) {
    final List<dynamic> wordsJson = json['includedWords'];
    return Chunk(
      id: json['id'],
      title: json['title'],
      englishContent: json['englishContent'],
      koreanTranslation: json['koreanTranslation'],
      createdAt: DateTime.parse(json['createdAt']),
      includedWords: wordsJson.map((w) => Word(english: w['english'], korean: w['korean'])).toList(),
      wordExplanations: Map<String, String>.from(json['wordExplanations'] ?? {}),
      character: json['character'] != null 
          ? (json['character'] is List ? List<String>.from(json['character']) : [json['character']])
          : [],
      scenario: json['scenario'],
      additionalDetails: json['additionalDetails'],
      usedModel: json['usedModel'],
    );
  }
}
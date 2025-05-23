import 'package:flutter_test/flutter_test.dart';
import 'package:chunk_up/domain/models/chunk.dart';
import 'package:chunk_up/domain/models/word.dart';

void main() {
  group('Chunk 불변성 테스트', () {
    late Chunk originalChunk;
    
    setUp(() {
      // 테스트용 Chunk 객체 초기화
      originalChunk = Chunk(
        id: 'test-id',
        title: '테스트 단락',
        englishContent: 'This is a test paragraph with some words to learn.',
        koreanTranslation: '이것은 배울 단어가 있는 테스트 단락입니다.',
        includedWords: [
          Word(english: 'test', korean: '테스트'),
          Word(english: 'paragraph', korean: '단락'),
          Word(english: 'word', korean: '단어'),
        ],
        wordExplanations: {
          'test': '실험 또는 시험을 의미합니다.',
          'paragraph': '문단 또는 단락을 의미합니다.',
        },
        character: ['Teacher'],
        scenario: 'Classroom',
        additionalDetails: 'Basic vocabulary explanation',
      );
    });

    test('copyWith 메서드는 원본 객체를 변경하지 않고 새 객체를 생성해야 함', () {
      // 원본의 현재 상태 저장
      final originalTitle = originalChunk.title;
      final originalContent = originalChunk.englishContent;
      final originalWords = List<Word>.from(originalChunk.includedWords);
      final originalExplanations = Map<String, String>.from(originalChunk.wordExplanations);
      
      // copyWith으로 새 객체 생성
      final newChunk = originalChunk.copyWith(
        title: '수정된 제목',
        englishContent: 'This content has been modified.'
      );
      
      // 원본은 변경되지 않아야 함
      expect(originalChunk.title, equals(originalTitle));
      expect(originalChunk.englishContent, equals(originalContent));
      expect(originalChunk.includedWords, equals(originalWords));
      expect(originalChunk.wordExplanations, equals(originalExplanations));
      
      // 새 객체는 변경된 값을 가져야 함
      expect(newChunk.title, equals('수정된 제목'));
      expect(newChunk.englishContent, equals('This content has been modified.'));
      
      // 변경되지 않은 값은 원본과 동일해야 함
      expect(newChunk.id, equals(originalChunk.id));
      expect(newChunk.koreanTranslation, equals(originalChunk.koreanTranslation));
    });
    
    test('addExplanation 메서드는 원본 객체를 변경하지 않고 새 객체를 반환해야 함', () {
      // 원본의 wordExplanations 크기 저장
      final originalExplanationsSize = originalChunk.wordExplanations.length;
      
      // 새 설명 추가한 객체 생성
      final newChunk = originalChunk.addExplanation('learn', '배우다, 학습하다');
      
      // 원본은 변경되지 않아야 함
      expect(originalChunk.wordExplanations.length, equals(originalExplanationsSize));
      expect(originalChunk.wordExplanations.containsKey('learn'), isFalse);
      
      // 새 객체는 추가된 설명을 가져야 함
      expect(newChunk.wordExplanations.length, equals(originalExplanationsSize + 1));
      expect(newChunk.wordExplanations.containsKey('learn'), isTrue);
      expect(newChunk.wordExplanations['learn'], equals('배우다, 학습하다'));
    });
    
    test('컬렉션 속성은 불변이어야 함 (직접 수정 시도)', () {
      // 원본 객체의 includedWords와 wordExplanations에 직접 접근해 수정 시도
      expect(() => originalChunk.includedWords.add(Word(english: 'new', korean: '새로운')), 
             throwsA(isA<UnsupportedError>()));
      
      expect(() => originalChunk.wordExplanations['new'] = '새로운', 
             throwsA(isA<UnsupportedError>()));
    });
    
    test('getExplanationFor 메서드는 원본 객체를 변경하지 않아야 함', () {
      // 원본의 현재 상태 저장
      final originalExplanationsMap = Map<String, String>.from(originalChunk.wordExplanations);
      
      // 메서드 호출
      final explanation = originalChunk.getExplanationFor('test');
      
      // 원본은 변경되지 않아야 함
      expect(originalChunk.wordExplanations, equals(originalExplanationsMap));
      expect(explanation, equals('실험 또는 시험을 의미합니다.'));
    });
    
    test('getExplanationFor 메서드는 단어 변형을 인식해야 함', () {
      // 단수/복수형 테스트를 위한 Chunk 생성
      final chunk = originalChunk.addExplanation('word', '단어');
      
      // 단수형으로 저장된 단어를 복수형으로 조회
      expect(chunk.getExplanationFor('words'), equals('단어'));
      
      // 동사 변형을 위한 테스트용 Chunk 생성
      final verbChunk = chunk.addExplanation('study', '공부하다');
      
      // ing 형태로 조회
      expect(verbChunk.getExplanationFor('studying'), equals('공부하다'));
      
      // ed 형태로 조회
      expect(verbChunk.getExplanationFor('studied'), equals('공부하다'));
    });
  });
}
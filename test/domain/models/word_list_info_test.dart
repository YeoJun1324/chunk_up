import 'package:flutter_test/flutter_test.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/chunk.dart';

void main() {
  group('WordListInfo 불변성 테스트', () {
    late WordListInfo originalWordList;
    
    setUp(() {
      // 테스트용 WordListInfo 객체 초기화
      originalWordList = WordListInfo(
        name: '영어 기초 단어장',
        words: [
          Word(english: 'apple', korean: '사과'),
          Word(english: 'book', korean: '책'),
          Word(english: 'computer', korean: '컴퓨터'),
        ],
        chunks: [
          Chunk(
            title: '과일과 음식',
            englishContent: 'I like to eat apples.',
            koreanTranslation: '나는 사과 먹는 것을 좋아해요.',
            includedWords: [Word(english: 'apple', korean: '사과')],
          ),
        ],
        chunkCount: 1,
      );
    });

    test('copyWith 메서드는 원본 객체를 변경하지 않고 새 객체를 생성해야 함', () {
      // 원본의 현재 상태 저장
      final originalName = originalWordList.name;
      final originalWords = List<Word>.from(originalWordList.words);
      final originalChunks = originalWordList.chunks != null ? List<Chunk>.from(originalWordList.chunks!) : null;
      final originalChunkCount = originalWordList.chunkCount;
      
      // copyWith으로 새 객체 생성
      final newWordList = originalWordList.copyWith(
        name: '수정된 단어장',
        chunkCount: 2,
      );
      
      // 원본은 변경되지 않아야 함
      expect(originalWordList.name, equals(originalName));
      expect(originalWordList.words, equals(originalWords));
      expect(originalWordList.chunks, equals(originalChunks));
      expect(originalWordList.chunkCount, equals(originalChunkCount));
      
      // 새 객체는 변경된 값을 가져야 함
      expect(newWordList.name, equals('수정된 단어장'));
      expect(newWordList.chunkCount, equals(2));
      
      // 변경되지 않은 값은 원본과 동일해야 함
      expect(newWordList.words.length, equals(originalWordList.words.length));
      expect(newWordList.chunks?.length, equals(originalWordList.chunks?.length));
    });
    
    test('words 컬렉션은 불변이어야 함 (직접 수정 시도)', () {
      // words 리스트 직접 수정 시도
      expect(() => originalWordList.words.add(Word(english: 'new', korean: '새로운')), 
             throwsA(isA<UnsupportedError>()));
    });
    
    test('chunks 컬렉션은 불변이어야 함 (직접 수정 시도)', () {
      // chunks 리스트가 없는 경우 테스트 건너뛰기
      if (originalWordList.chunks == null) {
        return;
      }
      
      // chunks 리스트 직접 수정 시도
      expect(() => originalWordList.chunks!.add(
        Chunk(
          title: '새 단락',
          englishContent: 'This is a new chunk.',
          koreanTranslation: '이것은 새 단락입니다.',
          includedWords: [],
        )
      ), throwsA(isA<UnsupportedError>()));
    });
    
    test('계산 속성은 불변 객체의 정보를 올바르게 제공해야 함', () {
      // 계산 속성 테스트
      expect(originalWordList.wordCount, equals(3));
      
      // 복사본을 통해 words 변경
      final updatedWordList = originalWordList.copyWith(
        words: [
          ...originalWordList.words,
          Word(english: 'dog', korean: '개'),
          Word(english: 'cat', korean: '고양이'),
        ]
      );
      
      // 원본은 변경되지 않아야 함
      expect(originalWordList.wordCount, equals(3));
      
      // 새 객체는 업데이트된 값을 반영해야 함
      expect(updatedWordList.wordCount, equals(5));
    });
    
    test('contextProgress 계산 속성은 올바른 비율을 제공해야 함', () {
      // 기본 WordListInfo의 contextProgress
      final progress = originalWordList.contextProgress;
      
      // apple만 청크에 포함되어 있으므로 1/3 = 0.333...
      expect(progress, closeTo(1/3, 0.01));
      
      // 새 Word 생성 및 isInChunk 설정
      final chunkedWords = [
        Word(english: 'apple', korean: '사과', isInChunk: true),
        Word(english: 'book', korean: '책', isInChunk: true),
        Word(english: 'computer', korean: '컴퓨터'),
      ];
      
      // 새 WordListInfo 객체 생성
      final updatedWordList = originalWordList.copyWith(words: chunkedWords);
      
      // 원본은 변경되지 않아야 함
      expect(originalWordList.contextProgress, closeTo(1/3, 0.01));
      
      // 새 객체는 변경된 값을 반영해야 함 (2/3 = 0.666...)
      expect(updatedWordList.contextProgress, closeTo(2/3, 0.01));
      expect(updatedWordList.contextProgressPercent, equals(66));
    });
  });
}
# Freezed와 Riverpod 통합 가이드

## 1. 개요

이 문서는 Chunk Up 앱에 구현된 Freezed 불변 객체 패턴과 Riverpod 상태 관리 프레임워크에 대한 통합 가이드입니다. 이 두 기술의 도입은 코드의 유지보수성, 안정성, 그리고 가독성을 크게 향상시켰습니다.

## 2. 구현 내용 요약

### Freezed 구현

**적용된 모델 클래스:**
- `Word` - 단어 모델 클래스
- `Chunk` - 단락 모델 클래스
- `WordListInfo` - 단어장 정보 모델
- `WordListState` - 단어장 상태 모델

**주요 개선사항:**
- 불변 객체 패턴 적용으로 데이터 일관성 보장
- 자동 생성된 `copyWith` 메서드로 객체 복사 및 수정 용이성 향상
- JSON 직렬화/역직렬화 코드 자동 생성
- 유니온 타입과 패턴 매칭을 활용한 타입 안전성 향상
- 보일러플레이트 코드 감소

### Riverpod 구현

**적용된 Provider:**
- `wordListProvider` - 단어장 관리 상태 제공자

**주요 개선사항:**
- 상태 관리 아키텍처 개선
- 불변성 기반 상태 업데이트로 예측 가능한 상태 변화
- 선언적 상태 접근으로 코드 가독성 향상
- 의존성 주입 간소화
- 상태 변경 추적 용이성 증가

## 3. 시작하기

### 패키지 추가

```yaml
# 런타임 패키지
flutter_riverpod: ^2.6.1
freezed_annotation: ^3.0.0
json_annotation: ^4.9.0
hooks_riverpod: ^2.6.1

# 개발 패키지
build_runner: ^2.4.8
freezed: ^3.0.0
json_serializable: ^6.8.0
riverpod_lint: ^2.3.10
custom_lint: ^0.6.4
```

### 코드 생성 실행

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 4. Freezed 사용 방법

### 기본 모델 정의

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'word.freezed.dart';
part 'word.g.dart';

@freezed
class Word with _$Word {
  const factory Word({
    required String id,
    required String text,
    String? translation,
    String? explanation,
    @Default(false) bool isLearned,
    @Default({}) Map<String, dynamic> metadata,
  }) = _Word;

  factory Word.fromJson(Map<String, dynamic> json) => _$WordFromJson(json);
}
```

### 사용 예시

```dart
// 객체 생성
final word = Word(id: '1', text: 'apple', translation: '사과');

// 복사 및 수정 (불변성 유지)
final updatedWord = word.copyWith(translation: '애플', isLearned: true);

// JSON 변환
final json = word.toJson();
final fromJson = Word.fromJson(json);
```

## 5. Riverpod 사용 방법

### 상태 정의

```dart
@freezed
class WordListState with _$WordListState {
  const factory WordListState({
    @Default([]) List<WordListInfo> wordLists,
    @Default(false) bool isLoading,
    String? error,
  }) = _WordListState;
}
```

### Provider 정의

```dart
final wordListProvider = StateNotifierProvider<WordListNotifier, WordListState>((ref) {
  return WordListNotifier(
    wordListRepository: ref.watch(wordListRepositoryProvider),
  );
});

class WordListNotifier extends StateNotifier<WordListState> {
  final WordListRepository _wordListRepository;

  WordListNotifier({required WordListRepository wordListRepository})
      : _wordListRepository = wordListRepository,
        super(const WordListState());

  Future<void> loadWordLists() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final wordLists = await _wordListRepository.getWordLists();
      state = state.copyWith(wordLists: wordLists, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '단어장을 불러오는 중 오류가 발생했습니다: $e',
      );
    }
  }
}
```

### UI에서 사용

```dart
class WordListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordListState = ref.watch(wordListProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('단어장 목록')),
      body: wordListState.isLoading
          ? Center(child: CircularProgressIndicator())
          : wordListState.error != null
              ? Center(child: Text(wordListState.error!))
              : ListView.builder(
                  itemCount: wordListState.wordLists.length,
                  itemBuilder: (context, index) {
                    final wordList = wordListState.wordLists[index];
                    return ListTile(
                      title: Text(wordList.title),
                      subtitle: Text('${wordList.wordCount}개의 단어'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WordListDetailScreen(id: wordList.id),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // 새 단어장 추가 로직
        },
      ),
    );
  }
}
```

## 6. 해결된 주요 오류

### 제네릭 상수 생성자 오류
- 원인: Dart에서는 제네릭 타입 매개변수를 사용하는 상수 생성자를 만들 수 없음
- 해결: `const None<T>()` 대신 `None<T>()`를 사용하여 일반 생성자로 변경

### 상수 맵 타입 오류
- 원인: 타입이 명시되지 않은 빈 맵이 기본값으로 사용됨
- 해결: 빈 맵에 구체적인 타입(`const <String, String>{}`)을 지정

### 리다이렉팅 팩토리 생성자의 기본값 오류
- 원인: Freezed 패턴에서 리다이렉팅 팩토리 생성자 내의 매개변수에 기본값을 사용할 수 없음
- 해결: 기본값을 `@Default` 어노테이션으로 이동하고 필요한 경우 내부 구현 클래스에 편의 생성자 추가

### const 클래스에서의 assert 오류
- 원인: `const` 생성자에서는 `assert` 문을 사용할 수 없음
- 해결: 적절한 타입 체크와 런타임 검증으로 대체

## 7. 관련 파일

**모델 클래스:**
- `/lib/domain/models/freezed/word.dart`
- `/lib/domain/models/freezed/chunk.dart`
- `/lib/presentation/providers/riverpod/word_list_state.dart`

**생성된 파일:**
- `/lib/domain/models/freezed/word.freezed.dart`
- `/lib/domain/models/freezed/word.g.dart`
- `/lib/domain/models/freezed/chunk.freezed.dart`
- `/lib/domain/models/freezed/chunk.g.dart`
- `/lib/presentation/providers/riverpod/word_list_state.freezed.dart`
- `/lib/presentation/providers/riverpod/word_list_state.g.dart`

**Provider 구현:**
- `/lib/presentation/providers/riverpod/word_list_provider.dart`

## 8. 테스트 방법

1. 앱 실행 및 새로운 UI 확인
2. 설정 > Riverpod 예제 선택
3. 샘플 단어장, 단어, 단락 추가/삭제 테스트
4. 코드 생성 명령어 실행 후 재실행 및 동작 확인

## 9. 향후 개선 사항

- 기존 Provider 기반 코드를 점진적으로 Riverpod으로 마이그레이션
- Riverpod의 `family`, `autoDispose` 등 고급 기능 활용
- Freezed 유니온 타입을 활용한 오류 처리 개선

## 10. 결론

Freezed와 Riverpod의 도입으로 Chunk Up 앱의 코드 품질과 안정성이 크게 향상되었습니다. 불변성 패턴을 적용하여 데이터 일관성을 보장하고, 효율적인 상태 관리를 통해 앱의 예측 가능성을 높였습니다. 또한, 자동 코드 생성을 통해 보일러플레이트 코드를 줄이고 개발 생산성을 향상시켰습니다.

이번 구현을 통해 앱의 아키텍처가 현대적이고 견고한 방식으로 개선되었으며, 향후 기능 확장과 유지보수가 더욱 용이해질 것으로 기대됩니다.
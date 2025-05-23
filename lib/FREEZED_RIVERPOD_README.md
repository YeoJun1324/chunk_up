# Freezed 및 Riverpod 구현 가이드

이 문서는 ChunkUp 애플리케이션에서 Freezed 패키지와 Riverpod 상태 관리 라이브러리를 사용하는 방법에 대한 가이드입니다.

## Freezed 패키지

Freezed는 코드 생성을 통해 불변성(Immutability)을 쉽게 구현할 수 있게 해주는 Dart 패키지입니다.

### 주요 특징

- **불변 객체 생성**: 객체의 불변성을 쉽게 유지할 수 있습니다.
- **코드 생성**: 반복적인 보일러플레이트 코드를 자동으로 생성합니다.
- **copyWith()**: 손쉬운 객체 복사 및 수정이 가능합니다.
- **유니온 타입**: sealed 클래스와 유사한 패턴 매칭을 지원합니다.
- **JSON 직렬화**: JSON 변환을 쉽게 처리할 수 있습니다.

### 구현된 모델

현재 다음 모델이 Freezed를 사용하여 구현되었습니다:

1. `Word` (/lib/domain/models/freezed/word.dart)
2. `Chunk` (/lib/domain/models/freezed/chunk.dart)
3. `WordListInfo` & `WordListState` (/lib/presentation/providers/riverpod/word_list_state.dart)

### 코드 생성하기

Freezed 패키지를 사용하기 위해서는 다음 명령어를 실행하여 필요한 코드를 생성해야 합니다:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Riverpod 상태 관리

Riverpod은 Provider 패키지의 차세대 버전으로, 더 강력한 상태 관리 기능을 제공합니다.

### 주요 특징

- **컴파일 타임 안전성**: 타입 안전성이 향상되었습니다.
- **Provider 오버라이드**: 테스트 및 개발 과정에서 Provider 값을 쉽게 오버라이드할 수 있습니다.
- **Consumer 사용성 개선**: ref를 통한 더 직관적인 접근이 가능합니다.
- **자동 폐기(Auto-dispose)**: 자원 관리가 자동화되었습니다.

### 구현된 Provider

현재 다음 Provider가 구현되었습니다:

1. `wordListProvider` (/lib/presentation/providers/riverpod/word_list_provider.dart)

### 사용 예시 화면

Riverpod 사용 예시를 확인할 수 있는 화면이 추가되었습니다:

- `RiverpodExamplesScreen` (/lib/presentation/screens/riverpod_examples_screen.dart)

## 기존 Provider와 통합하기

기존 Provider 코드와의 호환성을 위해 다음과 같은 접근 방식을 사용하고 있습니다:

1. `main.dart`에서 `RiverpodContainer` 위젯을 사용하여 Riverpod ProviderScope를 추가
2. 점진적으로 기존 Provider 코드를 Riverpod으로 마이그레이션
3. 두 상태 관리 시스템을 동시에 사용하는 중간 단계 지원

## 다음 단계

1. 기존 Provider 기반 코드를 Riverpod으로 점진적으로 마이그레이션
2. 더 많은 모델에 Freezed 패턴 적용
3. StateNotifier를 더 광범위하게 활용하여 불변성 기반 상태 관리 개선
4. 테스트 코드 작성으로 Riverpod의 테스트 용이성 활용

## 참고 자료

- [Freezed 패키지](https://pub.dev/packages/freezed)
- [Riverpod 공식 문서](https://riverpod.dev/)
- [JSON Serializable](https://pub.dev/packages/json_serializable)
- [Flutter에서의 불변성 패턴](https://codewithandrea.com/articles/flutter-app-architecture-riverpod-introduction/)
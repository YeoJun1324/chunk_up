# Flutter Build Runner 명령어 가이드

이 문서는 ChunkUp 앱에서 코드 생성을 위한 `build_runner` 관련 명령어를 설명합니다.

## Freezed 및 JSON 직렬화 코드 생성

Freezed 패키지를 사용한 불변 객체 및 JSON 직렬화 코드를 생성하려면 다음 명령어를 사용하세요:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 주요 생성 대상 파일들

다음 파일들에 대한 코드 생성이 필요합니다:

- `lib/domain/models/freezed/word.dart`
- `lib/domain/models/freezed/chunk.dart`
- `lib/presentation/providers/riverpod/word_list_state.dart`

### 생성되는 파일들

명령어 실행 시 다음 파일들이 자동으로 생성됩니다:

- `word.freezed.dart`
- `word.g.dart`
- `chunk.freezed.dart`
- `chunk.g.dart`
- `word_list_state.freezed.dart`
- `word_list_state.g.dart`

## 지속적인 감시 모드

파일 변경을 감지하여 자동으로 코드를 생성하는 감시 모드를 실행하려면:

```bash
flutter pub run build_runner watch
```

## 기존 생성 파일 정리

생성된 파일들을 모두 삭제하려면:

```bash
flutter pub run build_runner clean
```

## 문제 해결

### 의존성 충돌 오류

만약 다음과 같은 오류가 발생한다면:
```
custom_lint >=0.1.0 <0.7.4 depends on freezed_annotation ^2.2.0 and chunk_up depends on freezed_annotation ^3.0.0, custom_lint >=0.1.0 <0.7.4 is forbidden.
```

다음과 같이 `custom_lint`와 `riverpod_lint` 버전을 업데이트하세요:
```yaml
custom_lint: ^0.7.5
riverpod_lint: ^2.3.13
```

### 충돌 오류

이미 생성된 파일과 충돌이 발생하는 경우 `--delete-conflicting-outputs` 플래그를 사용하여 기존 파일을 덮어쓰세요.

### Path 오류

Windows에서 경로 관련 오류가 발생하는 경우 아래 명령어를 시도해보세요:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### WSL에서 실행 문제

WSL에서 실행 시 줄 바꿈 문자(CRLF vs LF) 문제가 발생할 수 있습니다. 이 경우 다음과 같이 실행하세요:

```bash
dos2unix $(which flutter)
flutter pub run build_runner build --delete-conflicting-outputs
```

## 주의사항

코드 생성이 완료된 후에는 반드시 `part` 지시문의 주석을 해제해야 합니다:

```dart
// Before:
// part 'word.freezed.dart';
// part 'word.g.dart';

// After:
part 'word.freezed.dart';
part 'word.g.dart';
```

## 관련 패키지 설명

- **freezed**: 불변 객체, 유니온 타입, 패턴 매칭을 제공합니다.
- **json_serializable**: JSON 직렬화/역직렬화 코드를 생성합니다.
- **build_runner**: 코드 생성을 담당하는 도구입니다.

## 예제

`@freezed` 어노테이션을 사용한 클래스 정의:

```dart
@freezed
class Word with _$Word {
  const factory Word({
    required String english,
    required String korean,
    @Default(false) bool isInChunk,
  }) = _Word;

  factory Word.fromJson(Map<String, dynamic> json) => _$WordFromJson(json);
}
```
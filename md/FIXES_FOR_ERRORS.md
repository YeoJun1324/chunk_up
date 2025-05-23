# 오류 수정 내역

이 문서는 기존 Freezed 및 Riverpod 구현에서 발생한 오류들과 그 수정 내용을 정리합니다.

## 추가 오류 수정 (2025.05.15)

## 1. 제네릭 상수 생성자 오류

**오류**:
```
A constant creation can't use a type parameter as a type argument.
(const_with_type_parameters at [chunk_up] lib\core\utils\functional_helpers.dart:133)
```

**원인**:
Dart에서는 제네릭 타입 매개변수를 사용하는 상수 생성자(const constructor)를 만들 수 없습니다.

**수정**:
`const None<T>()` 대신 `None<T>()`를 사용하여 상수 생성자를 일반 생성자로 변경했습니다.

## 2. 상수 맵 타입 오류

**오류**:
```
Invalid constant value.
(invalid_constant at [chunk_up] lib\domain\models\freezed\chunk.dart:49)
```

**원인**:
타입이 명시되지 않은 빈 맵(`const {}`)이 기본값으로 사용되었습니다.

**수정**:
빈 맵에 구체적인 타입(`const <String, String>{}`)을 지정했습니다.

## 3. 리다이렉팅 팩토리 생성자의 기본값 오류

**오류**:
```
Default values aren't allowed in factory constructors that redirect to another constructor.
(default_value_in_redirecting_factory_constructor at [chunk_up] lib\presentation\providers\riverpod\word_list_state.dart:95)
```

**원인**:
Freezed 패턴에서 리다이렉팅 팩토리 생성자 내의 매개변수에 기본값을 사용할 수 없습니다.

**수정**:
1. 팩토리 생성자의 매개변수에서 기본값을 제거하고 해당 매개변수를 `required`로 변경했습니다.
2. 내부 구현 클래스(`_Error`)에 편의 생성자(`withDefaultList`)를 추가하여 빈 목록을 기본값으로 사용할 수 있게 했습니다.

## 4. 위젯 테스트 오류

**오류**:
```
The name 'MyApp' isn't a class.
(creation_with_non_type at [chunk_up] test\widget_test.dart:16)
```

**원인**:
기본 Flutter 테스트 템플릿이 `MyApp` 클래스를 참조하고 있지만, 실제 앱에서는 `ChunkVocabApp` 클래스를 사용하고 있습니다.

**수정**:
1. `MyApp` 대신 `ChunkVocabApp`을 사용하도록 테스트를 수정했습니다.
2. 의존성 주입과 함께 테스트할 수 있도록 `createTestableApp` 메서드를 추가했습니다.
3. 목(mock) 서비스 로케이터를 구현하여 테스트 환경을 설정했습니다.

## 5. const 클래스에서의 assert 오류

**오류**:
```
Invalid constant value.
(invalid_constant at [chunk_up] lib\domain\models\freezed\chunk.dart:49)
```

**원인**:
`const` 생성자에서는 `assert` 문을 사용할 수 없습니다.

**수정**:
`const` 제거 및 생성자 본문에서 유효성 검사를 수행하도록 변경했습니다.

## 6. 리다이렉트 생성자 매개변수 불일치 오류

**오류**:
```
The redirected constructor '_Error Function({required String message, required List<WordListInfo> wordLists})' has incompatible parameters with 'WordListState Function({required String message, List<WordListInfo> wordLists})'.
```

**원인**:
리다이렉트 팩토리 생성자와 타겟 생성자의 매개변수 타입이 일치하지 않습니다.

**수정**:
리다이렉트 생성자를 일반 팩토리 생성자로 변경하여 매개변수를 직접 처리하도록 했습니다.

## 7. 테스트 유틸리티 인터페이스 오류

**오류**:
```
The name 'WordListRepository' isn't a type, so it can't be used as a type argument.
```

**원인**:
구현체 대신 인터페이스를 사용해야 합니다.

**수정**:
- `WordListRepository` → `WordListRepositoryInterface`
- `ChunkRepository` → `ChunkRepositoryInterface`
- 필요한 의존성을 포함한 모의 구현체 추가

## 일반적인 주의사항

1. **제네릭 상수 생성자**: Dart에서는 제네릭 타입 매개변수와 함께 상수 생성자를 사용할 수 없습니다. 대신 일반 생성자를 사용하세요.

2. **상수 컬렉션의 타입 명시**: 상수 컬렉션(맵, 리스트 등)을 사용할 때는 구체적인 타입을 명시하는 것이 좋습니다.

3. **Freezed 팩토리 생성자**: Freezed를 사용할 때 리다이렉팅 팩토리 생성자에서는 기본값을 사용하지 마세요. 기본값은 내부 구현 클래스에서 제공하거나, 편의 생성자를 사용하세요.

4. **테스트 설정**: 위젯 테스트를 작성할 때는 모든 필요한 의존성을 제공하는 설정 코드를 작성하세요. 특히 서비스 로케이터나 Provider를 사용하는 앱에서는 테스트용 목(mock) 구현체가 필요합니다.

5. **const와 assert**: 상수 생성자에서는 assert 문을 사용할 수 없습니다. 대신 정규 생성자 본문에서 조건 검사를 수행하세요.

6. **인터페이스와 구현체**: 다른 클래스를 확장하거나 구현할 때는 구체적인 구현체 대신 인터페이스를 사용하세요.
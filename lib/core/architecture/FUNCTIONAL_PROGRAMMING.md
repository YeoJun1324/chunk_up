# 함수형 프로그래밍과 불변성 패턴

## 함수형 프로그래밍 원칙

함수형 프로그래밍은 불변성 패턴과 자연스럽게 잘 어울립니다. 함수형 프로그래밍의 주요 원칙은 다음과 같습니다:

1. **순수 함수 (Pure Functions)**
   - 동일한 입력에 대해 항상 동일한 출력을 반환
   - 부수 효과(Side Effects) 없음
   - 외부 상태에 의존하지 않음

2. **불변성 (Immutability)**
   - 데이터는 생성된 후 변경될 수 없음
   - 변경이 필요할 때는 새 객체 생성

3. **함수 합성 (Function Composition)**
   - 여러 함수를 연결하여 복잡한 작업 수행
   - 작은 단위 함수들의 조합으로 프로그램 구성

## 다트(Dart)에서 함수형 프로그래밍

다트는 객체지향 언어이지만, 함수형 프로그래밍 패러다임도 지원합니다:

```dart
// 순수 함수 예제
int add(int a, int b) => a + b;

// 고차 함수(Higher-Order Function) 예제
List<int> mapDoubled(List<int> numbers) {
  return numbers.map((n) => n * 2).toList();
}

// 함수 합성 예제
var result = [1, 2, 3, 4]
    .where((n) => n % 2 == 0)  // 짝수만 필터링
    .map((n) => n * n)         // 제곱
    .fold(0, (a, b) => a + b); // 합계
```

## 불변성과 함수형 프로그래밍의 통합

불변성 패턴과 함수형 프로그래밍을 함께 사용하는 방법:

### 1. 컬렉션 변환 연산자 활용

```dart
// 불변 컬렉션과 함수형 변환 연산자
List<String> processNames(List<String> names) {
  return List.unmodifiable(
    names
      .where((name) => name.length > 3)  // 길이가 3보다 큰 이름만 필터링
      .map((name) => name.toUpperCase())  // 대문자로 변환
      .toList()
  );
}
```

### 2. 옵션(Option) 패턴

```dart
// 옵션 패턴 활용 (null 대신 Option 타입 사용)
abstract class Option<T> {
  bool get isDefined;
  T getOrElse(T defaultValue);
  Option<R> map<R>(R Function(T) f);
  Option<R> flatMap<R>(Option<R> Function(T) f);
}

class Some<T> extends Option<T> {
  final T _value;
  Some(this._value);
  
  @override
  bool get isDefined => true;
  
  @override
  T getOrElse(T defaultValue) => _value;
  
  @override
  Option<R> map<R>(R Function(T) f) => Some(f(_value));
  
  @override
  Option<R> flatMap<R>(Option<R> Function(T) f) => f(_value);
}

class None<T> extends Option<T> {
  @override
  bool get isDefined => false;
  
  @override
  T getOrElse(T defaultValue) => defaultValue;
  
  @override
  Option<R> map<R>(R Function(T) f) => None<R>();
  
  @override
  Option<R> flatMap<R>(Option<R> Function(T) f) => None<R>();
}
```

### 3. 함수형 상태 관리

```dart
// 함수형 상태 업데이트 패턴
class TodoList {
  final List<String> todos;
  
  const TodoList(this.todos);
  
  TodoList addTodo(String todo) => 
    TodoList([...todos, todo]);
  
  TodoList removeTodo(String todo) =>
    TodoList(todos.where((t) => t != todo).toList());
  
  TodoList map(String Function(String) mapper) =>
    TodoList(todos.map(mapper).toList());
}
```

## 함수형 오류 처리

```dart
// Either 타입을 사용한 함수형 오류 처리
abstract class Either<L, R> {
  bool get isLeft;
  bool get isRight;
  L getLeft();
  R getRight();
  Either<L, T> map<T>(T Function(R) f);
  Either<L, T> flatMap<T>(Either<L, T> Function(R) f);
}

class Left<L, R> extends Either<L, R> {
  final L _value;
  Left(this._value);
  
  @override
  bool get isLeft => true;
  
  @override
  bool get isRight => false;
  
  @override
  L getLeft() => _value;
  
  @override
  R getRight() => throw Exception("Cannot get right value from Left");
  
  @override
  Either<L, T> map<T>(T Function(R) f) => Left<L, T>(_value);
  
  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R) f) => Left<L, T>(_value);
}

class Right<L, R> extends Either<L, R> {
  final R _value;
  Right(this._value);
  
  @override
  bool get isLeft => false;
  
  @override
  bool get isRight => true;
  
  @override
  L getLeft() => throw Exception("Cannot get left value from Right");
  
  @override
  R getRight() => _value;
  
  @override
  Either<L, T> map<T>(T Function(R) f) => Right<L, T>(f(_value));
  
  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R) f) => f(_value);
}
```

## 결론

함수형 프로그래밍과 불변성 패턴을 함께 사용하면 다음과 같은 이점이 있습니다:

1. **디버깅 용이성**: 부수 효과가 없어 디버깅이 쉬움
2. **테스트 용이성**: 순수 함수는 테스트가 간단함
3. **병렬 처리 안전성**: 불변 객체는 여러 스레드에서 안전하게 사용 가능
4. **코드 예측 가능성**: 상태 변경이 투명하게 이루어짐
5. **버그 감소**: 복잡한 상태 변경으로 인한 버그 감소

Flutter 애플리케이션에서 불변성 패턴과 함수형 프로그래밍 원칙을 적용하면 더 견고하고 유지보수하기 쉬운 코드를 작성할 수 있습니다.
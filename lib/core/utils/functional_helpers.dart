/// 함수형 프로그래밍 헬퍼
///
/// 함수형 프로그래밍 패턴을 적용하기 위한 다양한 유틸리티 함수와 확장을 제공합니다.

/// 함수 합성을 위한 헬퍼 확장
extension FunctionComposition<A, B> on B Function(A) {
  /// 두 함수를 합성하여 새로운 함수를 반환합니다.
  ///
  /// 예: `(int a) => a * 2).compose((int b) => b + 1)`는
  /// (int a) => (a * 2) + 1과 같은 함수를 반환합니다.
  C Function(A) compose<C>(C Function(B) g) => (A a) => g(this(a));
}

/// 컬렉션 처리를 위한 함수형 확장
extension FunctionalIterableExtension<T> on Iterable<T> {
  /// map + where 연산을 한 번에 수행
  ///
  /// predicate를 만족하는 요소만 mapper를 통해 변환하여 반환합니다.
  Iterable<R> mapWhere<R>(R Function(T) mapper, bool Function(T) predicate) sync* {
    for (final item in this) {
      if (predicate(item)) {
        yield mapper(item);
      }
    }
  }

  /// 컬렉션의 각 요소에 대해 액션을 수행하고 동일한 컬렉션을 반환합니다.
  ///
  /// 이는 함수형 파이프라인에서 부수 효과(로깅 등)를 수행할 때 유용합니다.
  Iterable<T> tap(void Function(T) action) {
    return map((item) {
      action(item);
      return item;
    });
  }

  /// 컬렉션의 모든 요소가 조건을 만족하는지 확인합니다.
  bool all(bool Function(T) predicate) {
    for (final item in this) {
      if (!predicate(item)) return false;
    }
    return true;
  }

  /// 컬렉션의 요소 중 하나라도 조건을 만족하는지 확인합니다.
  bool any(bool Function(T) predicate) {
    for (final item in this) {
      if (predicate(item)) return true;
    }
    return false;
  }

  /// 컬렉션의 요소 중 조건을 만족하는 것이 없는지 확인합니다.
  bool none(bool Function(T) predicate) => !any(predicate);

  /// 컬렉션을 그룹화합니다.
  Map<K, List<T>> groupBy<K>(K Function(T) keySelector) {
    final map = <K, List<T>>{};
    for (final element in this) {
      final key = keySelector(element);
      map.putIfAbsent(key, () => []).add(element);
    }
    return map;
  }

  /// 컬렉션의 요소들을 주어진 분리자로 구분하여 하나의 문자열로 합칩니다.
  String joinToString({
    String separator = ', ',
    String prefix = '',
    String postfix = '',
    String transform(T element)?,
  }) {
    final buffer = StringBuffer(prefix);
    var isFirst = true;
    
    for (final element in this) {
      if (!isFirst) buffer.write(separator);
      isFirst = false;
      
      final text = transform != null ? transform(element) : element.toString();
      buffer.write(text);
    }
    
    buffer.write(postfix);
    return buffer.toString();
  }
}

/// 옵션 타입 (Optional)
///
/// null 대신 Option 타입을 사용하여 null 체크를 더 안전하게 처리합니다.
abstract class Option<T> {
  const Option();
  
  bool get isDefined;
  bool get isEmpty => !isDefined;
  
  T getOrElse(T defaultValue);
  T? getOrNull();
  
  Option<R> map<R>(R Function(T) mapper);
  Option<R> flatMap<R>(Option<R> Function(T) mapper);
  
  Option<T> filter(bool Function(T) predicate);
  
  void forEach(void Function(T) action);
  
  R fold<R>(R ifEmpty, R Function(T) ifDefined);
}

/// 값이 있는 옵션
class Some<T> extends Option<T> {
  final T value;
  const Some(this.value);
  
  @override
  bool get isDefined => true;
  
  @override
  T getOrElse(T defaultValue) => value;
  
  @override
  T? getOrNull() => value;
  
  @override
  Option<R> map<R>(R Function(T) mapper) => Some(mapper(value));
  
  @override
  Option<R> flatMap<R>(Option<R> Function(T) mapper) => mapper(value);
  
  @override
  Option<T> filter(bool Function(T) predicate) =>
      predicate(value) ? this : None<T>();
  
  @override
  void forEach(void Function(T) action) => action(value);
  
  @override
  R fold<R>(R ifEmpty, R Function(T) ifDefined) => ifDefined(value);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Some && other.value == value;
  
  @override
  int get hashCode => value.hashCode;
  
  @override
  String toString() => 'Some($value)';
}

/// 값이 없는 옵션
class None<T> extends Option<T> {
  const None();
  
  @override
  bool get isDefined => false;
  
  @override
  T getOrElse(T defaultValue) => defaultValue;
  
  @override
  T? getOrNull() => null;
  
  @override
  Option<R> map<R>(R Function(T) mapper) => const None();
  
  @override
  Option<R> flatMap<R>(Option<R> Function(T) mapper) => const None();
  
  @override
  Option<T> filter(bool Function(T) predicate) => const None();
  
  @override
  void forEach(void Function(T) action) {}
  
  @override
  R fold<R>(R ifEmpty, R Function(T) ifDefined) => ifEmpty;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is None;
  
  @override
  int get hashCode => 0;
  
  @override
  String toString() => 'None';
}

/// 객체를 Option으로 변환하는 확장
extension OptionExtension<T> on T? {
  Option<T> get asOption => this == null ? None<T>() : Some<T>(this as T);
}

/// Either 타입 (함수형 오류 처리)
///
/// 성공과 실패를 명시적으로 표현하는 타입입니다.
abstract class Either<L, R> {
  const Either();
  
  bool get isLeft;
  bool get isRight => !isLeft;
  
  L getLeftOrThrow();
  R getRightOrThrow();
  
  Either<L, T> map<T>(T Function(R) mapper);
  Either<L, T> flatMap<T>(Either<L, T> Function(R) mapper);
  
  Either<T, R> mapLeft<T>(T Function(L) mapper);
  
  R getOrElse(R Function(L) orElse);
  
  T fold<T>(T Function(L) ifLeft, T Function(R) ifRight);
}

/// 왼쪽 값 (주로 오류를 나타냄)
class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
  
  @override
  bool get isLeft => true;
  
  @override
  L getLeftOrThrow() => value;
  
  @override
  R getRightOrThrow() => throw Exception('Cannot get right value from Left');
  
  @override
  Either<L, T> map<T>(T Function(R) mapper) => Left<L, T>(value);
  
  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R) mapper) => Left<L, T>(value);
  
  @override
  Either<T, R> mapLeft<T>(T Function(L) mapper) => Left<T, R>(mapper(value));
  
  @override
  R getOrElse(R Function(L) orElse) => orElse(value);
  
  @override
  T fold<T>(T Function(L) ifLeft, T Function(R) ifRight) => ifLeft(value);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Left && other.value == value;
  
  @override
  int get hashCode => value.hashCode;
  
  @override
  String toString() => 'Left($value)';
}

/// 오른쪽 값 (주로 성공 결과를 나타냄)
class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
  
  @override
  bool get isLeft => false;
  
  @override
  L getLeftOrThrow() => throw Exception('Cannot get left value from Right');
  
  @override
  R getRightOrThrow() => value;
  
  @override
  Either<L, T> map<T>(T Function(R) mapper) => Right<L, T>(mapper(value));
  
  @override
  Either<L, T> flatMap<T>(Either<L, T> Function(R) mapper) => mapper(value);
  
  @override
  Either<T, R> mapLeft<T>(T Function(L) mapper) => Right<T, R>(value);
  
  @override
  R getOrElse(R Function(L) orElse) => value;
  
  @override
  T fold<T>(T Function(L) ifLeft, T Function(R) ifRight) => ifRight(value);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Right && other.value == value;
  
  @override
  int get hashCode => value.hashCode;
  
  @override
  String toString() => 'Right($value)';
}

/// Either를 생성하는 유틸리티 함수
Either<Exception, T> tryCatch<T>(T Function() fn) {
  try {
    return Right(fn());
  } on Exception catch (e) {
    return Left(e);
  }
}

/// Future<Either>를 다루기 위한 유틸리티 함수
Future<Either<L, R>> futureEither<L, R>(Future<R> future, L Function(Object) onError) async {
  try {
    final result = await future;
    return Right(result);
  } catch (e) {
    return Left(onError(e));
  }
}
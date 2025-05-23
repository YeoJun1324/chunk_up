/// null 안전성 헬퍼 확장 클래스
///
/// null 처리를 더 우아하게 하기 위한 확장 메서드들을 제공합니다.

/// String 확장
extension StringNullSafety on String? {
  /// null 또는 빈 문자열인지 확인
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// null 또는 공백 문자열인지 확인
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  /// null인 경우 기본값 반환, 아니면 현재 값 반환
  String orDefault(String defaultValue) => this ?? defaultValue;

  /// null이 아니고 비어있지 않은 경우에만 변환 함수 적용
  String? let(String Function(String value) transform) {
    if (isNullOrEmpty) return null;
    return transform(this!);
  }
}

/// List 확장
extension ListNullSafety<T> on List<T>? {
  /// null 또는 빈 리스트인지 확인
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// null인 경우 빈 리스트 반환, 아니면 현재 리스트 반환
  List<T> orEmpty() => this ?? [];

  /// null이 아니고 비어있지 않은 경우에만 변환 함수 적용
  List<R>? mapOrNull<R>(R Function(T value) transform) {
    if (isNullOrEmpty) return null;
    return this!.map(transform).toList();
  }

  /// 안전한 리스트 복사본 반환
  /// 
  /// null인 경우 빈 리스트 반환, 아니면 불변 리스트 반환
  List<T> safeUnmodifiable() {
    if (this == null) return const [];
    return List.unmodifiable(this!);
  }
}

/// Map 확장
extension MapNullSafety<K, V> on Map<K, V>? {
  /// null 또는 빈 맵인지 확인
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// null인 경우 빈 맵 반환, 아니면 현재 맵 반환
  Map<K, V> orEmpty() => this ?? {};

  /// 키가 존재하는지 안전하게 확인
  bool containsKeyOrNull(K key) => this?.containsKey(key) ?? false;

  /// 키에 대한 값을 안전하게 반환
  V? getOrNull(K key) => this?[key];

  /// 키에 대한 값을 안전하게 반환하거나 기본값 제공
  V getOrDefault(K key, V defaultValue) => this?[key] ?? defaultValue;

  /// 안전한 맵 복사본 반환
  /// 
  /// null인 경우 빈 맵 반환, 아니면 불변 맵 반환
  Map<K, V> safeUnmodifiable() {
    if (this == null) return const {};
    return Map.unmodifiable(this!);
  }
}

/// 일반적인 객체 확장
extension ObjectNullSafety<T> on T? {
  /// null인 경우 기본값 반환, 아니면 현재 값 반환
  T orDefault(T defaultValue) => this ?? defaultValue;

  /// null이 아닌 경우에만 변환 함수 적용
  R? let<R>(R Function(T value) transform) {
    if (this == null) return null;
    return transform(this as T);
  }

  /// null이 아닌 경우에만 변환 함수 적용, null이면 기본값 반환
  R letOrDefault<R>(R Function(T value) transform, R defaultValue) {
    if (this == null) return defaultValue;
    return transform(this as T);
  }
}
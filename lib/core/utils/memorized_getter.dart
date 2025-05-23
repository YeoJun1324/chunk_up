/// 메모이제이션 유틸리티 클래스
///
/// 계산 비용이 큰 게터(getter)의 결과를 캐싱하기 위한 믹스인입니다.
/// 불변 객체와 함께 사용하면 효율적입니다.
class MemoizedGetter {
  final Map<String, dynamic> _cache = {};

  /// 게터 결과를 메모이제이션(캐싱)합니다.
  ///
  /// [key]를 사용하여 캐시에서 값을 찾고, 없으면 [compute] 함수를 실행하여
  /// 결과를 계산하고 캐시에 저장합니다.
  ///
  /// 예시:
  /// ```dart
  /// int get expensiveCalculation => memoize('expensive', () {
  ///   // 복잡한 계산...
  ///   return result;
  /// });
  /// ```
  T memoize<T>(String key, T Function() compute) {
    if (!_cache.containsKey(key)) {
      _cache[key] = compute();
    }
    return _cache[key] as T;
  }

  /// 특정 키의 캐시를 무효화합니다.
  void invalidateCache(String key) {
    _cache.remove(key);
  }

  /// 전체 캐시를 초기화합니다.
  void clearCache() {
    _cache.clear();
  }
}

/// 메모이제이션을 위한 함수 확장
extension MemoizeFunction<T> on T Function() {
  /// 메모이제이션된 함수를 생성합니다.
  /// 
  /// 같은 함수를 여러 번 호출해도 실제 계산은 한 번만 수행됩니다.
  /// 
  /// 예시:
  /// ```dart
  /// final expensiveCalculation = (() {
  ///   // 복잡한 계산...
  ///   return result;
  /// }).memoize();
  /// ```
  T Function() memoize() {
    T? result;
    bool hasResult = false;
    
    return () {
      if (!hasResult) {
        result = this();
        hasResult = true;
      }
      return result as T;
    };
  }
}
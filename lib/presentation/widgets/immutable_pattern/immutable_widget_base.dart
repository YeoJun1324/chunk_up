import 'package:flutter/material.dart';

/// 불변 상태를 관리하는 StatefulWidget의 기본 클래스
///
/// 불변성 패턴을 사용하는 위젯에 대한 표준화된 베이스 클래스를 제공합니다.
/// 상태 변경 시 항상 새 상태 객체를 생성하여 불변성을 유지합니다.
abstract class ImmutableWidgetBase<T> extends StatefulWidget {
  const ImmutableWidgetBase({Key? key}) : super(key: key);
}

/// 불변 상태를 관리하는 State의 기본 클래스
///
/// 상태 변경 로직을 표준화하고, 불변성을 유지하는 데 도움이 됩니다.
abstract class ImmutableStateBase<T, W extends ImmutableWidgetBase<T>> extends State<W> {
  /// 불변 상태 객체
  late T _state;

  /// 초기 상태 생성
  @protected
  T createInitialState();

  @override
  void initState() {
    super.initState();
    _state = createInitialState();
  }

  /// 현재 상태 getter
  @protected
  T get state => _state;

  /// 상태 업데이트 메서드
  ///
  /// 새 상태 객체로 업데이트하고 화면을 다시 그립니다.
  @protected
  void updateState(T newState) {
    if (newState != _state) {
      setState(() {
        _state = newState;
      });
      onStateChanged(newState);
    }
  }

  /// 상태 변경 후 호출되는 콜백
  ///
  /// 필요에 따라 오버라이드하여 상태 변경 후 로직을 처리할 수 있습니다.
  @protected
  void onStateChanged(T newState) {
    // 기본 구현은 비어 있음. 하위 클래스에서 필요에 따라 오버라이드
  }

  /// 비동기 작업 처리 헬퍼
  ///
  /// 비동기 작업 중 로딩 상태 처리와 오류 처리를 간소화합니다.
  @protected
  Future<void> performAsyncAction(
    Future<T> Function() action,
    {required T Function(T currentState) onLoadingStart,
    required T Function(T currentState, Object error) onError}
  ) async {
    // 로딩 시작 상태로 업데이트
    updateState(onLoadingStart(state));

    try {
      // 비동기 작업 실행
      final newState = await action();
      // 성공 시 새 상태로 업데이트
      updateState(newState);
    } catch (error) {
      // 오류 발생 시 오류 상태로 업데이트
      updateState(onError(state, error));
    }
  }
}

/// 불변 상태의 기본 인터페이스
///
/// 모든 불변 상태 클래스가 구현해야 하는 인터페이스입니다.
abstract class ImmutableState<T> {
  /// 새 인스턴스로 복사하는 메서드
  T copyWith();
  
  /// 동등성 비교 (equals 구현)
  @override
  bool operator ==(Object other);
  
  /// 해시 코드 구현
  @override
  int get hashCode;
}
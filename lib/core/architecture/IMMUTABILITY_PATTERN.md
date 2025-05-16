# 불변성 패턴 가이드 (Immutability Pattern Guide)

## 개요

이 문서는 Chunk Up 애플리케이션에서 사용하는 불변성(Immutability) 패턴에 대한 설명과 구현 가이드를 제공합니다. 불변성 패턴은 애플리케이션의 상태 관리를 더 예측 가능하고 유지보수하기 쉽게 만들어 줍니다.

## 불변성 원칙

불변성 원칙은 다음과 같습니다:

1. **객체의 상태는 생성 후 변경되지 않아야 합니다.**
2. **상태를 변경해야 할 경우, 새로운 객체를 생성해야 합니다.**
3. **모든 프로퍼티는 `final`로 선언하여 변경을 방지합니다.**
4. **컬렉션은 불변 컬렉션을 사용하거나 복사본을 반환해야 합니다.**

## 모델 클래스 구현 패턴

모든 모델 클래스는 다음과 같은 패턴을 따라야 합니다:

```dart
class SomeModel {
  // 모든 프로퍼티는 final로 선언
  final String id;
  final String name;
  final List<String> items;

  // 생성자에서 컬렉션은 불변 컬렉션으로 변환
  SomeModel({
    required this.id,
    required this.name,
    List<String>? items,
  }) : items = List.unmodifiable(items ?? []);

  // copyWith 메서드로 상태 변경 지원
  SomeModel copyWith({
    String? id,
    String? name,
    List<String>? items,
  }) {
    return SomeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? List<String>.from(this.items),
    );
  }

  // 헬퍼 메서드는 항상 새 객체를 반환
  SomeModel addItem(String item) {
    if (items.contains(item)) {
      return this; // 이미 있으면 동일 객체 반환
    }
    
    final newItems = List<String>.from(items)..add(item);
    return copyWith(items: newItems);
  }
}
```

## Provider 구현 패턴

상태 관리 Provider 클래스는 다음과 같은 패턴을 따라야 합니다:

```dart
class SomeProvider with ChangeNotifier {
  // 내부 상태 변수
  List<SomeModel> _items = [];
  
  // 불변 상태 접근자
  List<SomeModel> get items => List.unmodifiable(_items);
  
  // 상태 변경 메서드
  void addItem(SomeModel item) {
    // 새 목록 생성
    final newItems = List<SomeModel>.from(_items)..add(item);
    
    // 내부 상태 업데이트
    _updateItems(newItems);
  }
  
  // 단일 아이템 업데이트
  void updateItem(String id, String newName) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    
    // 새 목록 생성 후 특정 아이템만 교체
    final newItems = List<SomeModel>.from(_items);
    newItems[index] = _items[index].copyWith(name: newName);
    
    // 내부 상태 업데이트
    _updateItems(newItems);
  }
  
  // 내부 상태 업데이트 통합 메서드
  void _updateItems(List<SomeModel> newItems) {
    _items = newItems;
    notifyListeners();
  }
}
```

## StatefulWidget에서 불변성 패턴

StatefulWidget에서 불변성 패턴을 적용할 때는 다음과 같은 접근법을 사용합니다:

1. **상태를 변경해야 할 때마다 새 객체를 생성합니다.**
2. **부모로부터 업데이트 콜백을 받아 상태 변경을 전파합니다.**
3. **또는 상태 관리 라이브러리를 사용하여 상태 변경을 전파합니다.**

```dart
// 불변 상태 클래스
class ScreenState {
  final String title;
  final List<String> items;
  
  ScreenState({
    required this.title,
    List<String>? items,
  }) : items = List.unmodifiable(items ?? []);
  
  ScreenState copyWith({
    String? title,
    List<String>? items,
  }) {
    return ScreenState(
      title: title ?? this.title,
      items: items ?? List<String>.from(this.items),
    );
  }
}

// StatefulWidget에서 사용
class _MyScreenState extends State<MyScreen> {
  late ScreenState _state;
  
  @override
  void initState() {
    super.initState();
    _state = ScreenState(title: 'Initial Title');
  }
  
  void _updateTitle(String newTitle) {
    setState(() {
      // 새 상태 객체 생성
      _state = _state.copyWith(title: newTitle);
    });
  }
}
```

## 주의사항

1. **중첩된 객체 업데이트**: 중첩된 객체를 업데이트할 때는 중첩 구조의 모든 레벨에서 불변성을 유지해야 합니다.
2. **성능 고려**: 큰 객체나 깊은 객체 구조에서는 불필요한 복사를 피하기 위해 선택적 복사 전략을 사용할 수 있습니다.
3. **불변성 라이브러리**: 복잡한 객체 구조에서는 `freezed`와 같은 불변성 라이브러리 사용을 고려하세요.

## 예시 코드

애플리케이션의 다음 클래스들은 불변성 패턴의 좋은 예시를 제공합니다:

- `lib/domain/models/word.dart`
- `lib/domain/models/chunk.dart`
- `lib/domain/models/word_list_info.dart`
- `lib/domain/models/folder.dart`
- `lib/presentation/providers/word_list_notifier.dart`
- `lib/presentation/providers/folder_notifier.dart`
- `lib/presentation/screens/chunk_result_screen.dart`의 `ChunkResultData` 클래스

## 불변성 패턴의 이점

1. **예측 가능한 상태**: 객체가 변경되지 않으므로 상태 변화 추적이 용이합니다.
2. **동시성 안전**: 불변 객체는 여러 스레드에서 안전하게 공유될 수 있습니다.
3. **버그 감소**: "변경하면 안 되는" 객체를 실수로 변경하는 버그를 방지합니다.
4. **참조 동등성**: 객체가 변경되었는지 쉽게 확인할 수 있습니다.
5. **쉬운 실행 취소/다시 실행**: 이전 상태를 저장하고 복원하기 쉽습니다.

## 향후 개선 사항

불변성 패턴을 더욱 견고하게 구현하기 위한 향후 개선 사항:

1. **Freezed 라이브러리 도입 고려**: 코드 생성을 통해 불변 객체를 쉽게 생성할 수 있습니다.
2. **Riverpod 또는 더 고급 상태 관리 솔루션 도입 고려**: 불변성을 더 잘 지원하는 상태 관리 라이브러리를 사용하면 좋습니다.
3. **불변성 테스트 추가**: 객체가 실제로 불변인지 확인하는 테스트를 추가합니다.
4. **컬렉션 작업 최적화**: 대량의 컬렉션 작업에서 불필요한 복사를 줄이는 최적화 방법을 적용합니다.

## 결론

불변성 패턴은 앱의 안정성과 유지보수성을 크게 향상시킵니다. 모든 개발자가 이 패턴을 숙지하고 일관되게 적용해야 합니다. 질문이나 제안이 있으면 팀 내에서 논의하세요.
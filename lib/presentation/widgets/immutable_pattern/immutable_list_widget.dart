import 'package:flutter/material.dart';

/// 불변 리스트 아이템 클래스
class ImmutableListItem {
  final String id;
  final String title;
  final bool isCompleted;

  const ImmutableListItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  /// 불변성 패턴을 위한 복사 생성 메서드
  ImmutableListItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return ImmutableListItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// 완료 상태 토글
  ImmutableListItem toggleCompleted() {
    return copyWith(isCompleted: !isCompleted);
  }
}

/// 불변 리스트 상태 클래스
class ImmutableListState {
  final List<ImmutableListItem> items;
  final bool isLoading;
  final String? errorMessage;

  const ImmutableListState({
    List<ImmutableListItem>? items,
    this.isLoading = false,
    this.errorMessage,
  }) : items = items ?? const [];

  /// 초기 상태
  factory ImmutableListState.initial() {
    return const ImmutableListState();
  }

  /// 불변성 패턴을 위한 복사 생성 메서드
  ImmutableListState copyWith({
    List<ImmutableListItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ImmutableListState(
      items: items ?? List<ImmutableListItem>.from(this.items),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// 아이템 추가
  ImmutableListState addItem(ImmutableListItem item) {
    final newItems = List<ImmutableListItem>.from(items)..add(item);
    return copyWith(items: newItems, clearError: true);
  }

  /// 아이템 제거
  ImmutableListState removeItem(String id) {
    final newItems = items.where((item) => item.id != id).toList();
    return copyWith(items: newItems, clearError: true);
  }

  /// 아이템 업데이트
  ImmutableListState updateItem(String id, ImmutableListItem Function(ImmutableListItem) updater) {
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1) return this;

    final newItems = List<ImmutableListItem>.from(items);
    newItems[index] = updater(items[index]);
    return copyWith(items: newItems, clearError: true);
  }

  /// 아이템 완료 상태 토글
  ImmutableListState toggleItemCompleted(String id) {
    return updateItem(id, (item) => item.toggleCompleted());
  }

  /// 로딩 상태로 변경
  ImmutableListState loading() {
    return copyWith(isLoading: true, clearError: true);
  }

  /// 오류 상태로 변경
  ImmutableListState withError(String message) {
    return copyWith(isLoading: false, errorMessage: message);
  }

  /// 완료된 아이템 수
  int get completedCount => items.where((item) => item.isCompleted).length;

  /// 전체 아이템 수
  int get totalCount => items.length;

  /// 완료 비율
  double get completionRatio => totalCount == 0 ? 0.0 : completedCount / totalCount;
}

/// 불변성 패턴을 적용한 리스트 위젯
///
/// StatefulWidget에서 불변성 패턴을 사용하는 방법을 보여줍니다.
/// 리스트 아이템 관리에 불변성 패턴을 적용한 예시입니다.
class ImmutableListWidget extends StatefulWidget {
  const ImmutableListWidget({Key? key}) : super(key: key);

  @override
  State<ImmutableListWidget> createState() => _ImmutableListWidgetState();
}

class _ImmutableListWidgetState extends State<ImmutableListWidget> {
  // 불변 상태 객체
  ImmutableListState _state = ImmutableListState.initial();
  
  // 텍스트 필드 컨트롤러
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialItems();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 초기 아이템 로드 시뮬레이션
  Future<void> _loadInitialItems() async {
    // 로딩 상태로 변경
    _updateState(_state.loading());

    try {
      // 네트워크 요청 시뮬레이션
      await Future.delayed(const Duration(seconds: 1));

      // 초기 아이템 생성
      final initialItems = [
        ImmutableListItem(id: '1', title: '불변성 패턴 학습하기'),
        ImmutableListItem(id: '2', title: '테스트 코드 작성하기'),
        ImmutableListItem(id: '3', title: '예제 위젯 구현하기'),
      ];

      // 새 상태 업데이트
      _updateState(ImmutableListState(items: initialItems));
    } catch (e) {
      // 오류 상태로 변경
      _updateState(_state.withError('아이템을 로드하는 중 오류가 발생했습니다: $e'));
    }
  }

  // 불변 상태를 업데이트하기 위한 메서드
  void _updateState(ImmutableListState newState) {
    setState(() {
      _state = newState;
    });
  }

  // 새 아이템 추가
  void _addItem() {
    if (_controller.text.isEmpty) return;

    final newItem = ImmutableListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _controller.text,
    );

    _updateState(_state.addItem(newItem));
    _controller.clear();
  }

  // 아이템 삭제
  void _removeItem(String id) {
    _updateState(_state.removeItem(id));
  }

  // 아이템 완료 상태 토글
  void _toggleItemCompleted(String id) {
    _updateState(_state.toggleItemCompleted(id));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '불변성 패턴 리스트 예제',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '이 리스트는 모든 상태 변경에서 불변성 패턴을 사용합니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // 아이템 추가 폼
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: '새 항목 추가',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 진행 상태 표시
            LinearProgressIndicator(
              value: _state.completionRatio,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '${_state.completedCount}/${_state.totalCount} 완료 (${(_state.completionRatio * 100).toInt()}%)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),

            // 에러 메시지
            if (_state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade50,
                width: double.infinity,
                child: Text(
                  _state.errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 아이템 목록
            if (_state.isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ] else if (_state.items.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('항목이 없습니다. 위에서 새 항목을 추가하세요.'),
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _state.items.length,
                  itemBuilder: (context, index) {
                    final item = _state.items[index];
                    return ListTile(
                      leading: Checkbox(
                        value: item.isCompleted,
                        onChanged: (_) => _toggleItemCompleted(item.id),
                        activeColor: Colors.orange,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          color: item.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeItem(item.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
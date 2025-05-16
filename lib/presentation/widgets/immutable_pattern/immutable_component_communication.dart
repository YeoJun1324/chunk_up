import 'package:flutter/material.dart';

/// 불변 데이터 모델
class ImmutableDataModel {
  final String id;
  final String title;
  final String description;
  final int count;
  final bool isActive;

  const ImmutableDataModel({
    required this.id,
    required this.title,
    this.description = '',
    this.count = 0,
    this.isActive = false,
  });

  /// 불변성 패턴을 위한 복사 생성 메서드
  ImmutableDataModel copyWith({
    String? id,
    String? title,
    String? description,
    int? count,
    bool? isActive,
  }) {
    return ImmutableDataModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      count: count ?? this.count,
      isActive: isActive ?? this.isActive,
    );
  }

  /// 카운트 증가
  ImmutableDataModel incrementCount() {
    return copyWith(count: count + 1);
  }

  /// 카운트 감소
  ImmutableDataModel decrementCount() {
    return copyWith(count: count > 0 ? count - 1 : 0);
  }

  /// 활성 상태 토글
  ImmutableDataModel toggleActive() {
    return copyWith(isActive: !isActive);
  }
}

/// 부모 위젯
///
/// 자식 컴포넌트 간 통신을 불변성 패턴을 사용하여 구현한 예제입니다.
class ImmutableParentWidget extends StatefulWidget {
  const ImmutableParentWidget({Key? key}) : super(key: key);

  @override
  State<ImmutableParentWidget> createState() => _ImmutableParentWidgetState();
}

class _ImmutableParentWidgetState extends State<ImmutableParentWidget> {
  // 불변 데이터 모델 관리
  final List<ImmutableDataModel> _items = [
    ImmutableDataModel(
      id: '1',
      title: '항목 1',
      description: '첫 번째 항목 설명',
    ),
    ImmutableDataModel(
      id: '2',
      title: '항목 2',
      description: '두 번째 항목 설명',
    ),
    ImmutableDataModel(
      id: '3',
      title: '항목 3',
      description: '세 번째 항목 설명',
    ),
  ];

  // 선택된 항목 ID
  String? _selectedItemId;

  // 항목 선택 핸들러
  void _onSelectItem(String id) {
    setState(() {
      _selectedItemId = id;
    });
  }

  // 항목 업데이트 핸들러
  void _onUpdateItem(ImmutableDataModel updatedItem) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == updatedItem.id);
      if (index != -1) {
        // 불변성 유지를 위해 새 목록 생성
        final newItems = List<ImmutableDataModel>.from(_items);
        newItems[index] = updatedItem;
        
        // 새 목록으로 교체
        _items.clear();
        _items.addAll(newItems);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 현재 선택된 항목 찾기
    final selectedItem = _items.firstWhere(
      (item) => item.id == _selectedItemId,
      orElse: () => _items.isNotEmpty ? _items.first : ImmutableDataModel(
        id: '0',
        title: '항목이 없습니다',
      ),
    );

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '불변성 패턴 컴포넌트 통신 예제',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '자식 컴포넌트 간 통신에 불변성 패턴을 사용하는 예제입니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // 컴포넌트 구성
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측 목록 컴포넌트
                Expanded(
                  flex: 1,
                  child: ItemListComponent(
                    items: _items,
                    selectedItemId: _selectedItemId,
                    onSelectItem: _onSelectItem,
                  ),
                ),
                const SizedBox(width: 16),
                
                // 우측 세부정보 및 수정 컴포넌트
                Expanded(
                  flex: 2,
                  child: ItemDetailComponent(
                    item: selectedItem,
                    onUpdateItem: _onUpdateItem,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 항목 목록 컴포넌트
class ItemListComponent extends StatelessWidget {
  final List<ImmutableDataModel> items;
  final String? selectedItemId;
  final Function(String) onSelectItem;

  const ItemListComponent({
    Key? key,
    required this.items,
    this.selectedItemId,
    required this.onSelectItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.id == selectedItemId;

          return ListTile(
            title: Text(item.title),
            subtitle: Text(
              '카운트: ${item.count} • ${item.isActive ? "활성" : "비활성"}',
              style: const TextStyle(fontSize: 12),
            ),
            selected: isSelected,
            selectedTileColor: Colors.orange.shade50,
            onTap: () => onSelectItem(item.id),
            leading: CircleAvatar(
              backgroundColor: item.isActive ? Colors.green : Colors.grey,
              child: Text(
                item.count.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 항목 세부정보 및 수정 컴포넌트
class ItemDetailComponent extends StatelessWidget {
  final ImmutableDataModel item;
  final Function(ImmutableDataModel) onUpdateItem;

  const ItemDetailComponent({
    Key? key,
    required this.item,
    required this.onUpdateItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Switch(
                value: item.isActive,
                onChanged: (_) => onUpdateItem(item.toggleActive()),
                activeColor: Colors.orange,
              ),
            ],
          ),
          const Divider(),
          
          // 설명
          const Text(
            '설명:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(item.description.isEmpty ? '설명이 없습니다.' : item.description),
          const SizedBox(height: 16),
          
          // 카운트 조작
          Row(
            children: [
              const Text(
                '카운트:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                backgroundColor: item.isActive ? Colors.green : Colors.grey,
                child: Text(
                  item.count.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.remove_circle),
                onPressed: () => onUpdateItem(item.decrementCount()),
                color: Colors.red,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () => onUpdateItem(item.incrementCount()),
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 상태 정보
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${item.id}'),
                Text('활성 상태: ${item.isActive ? "활성" : "비활성"}'),
                Text('카운트: ${item.count}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
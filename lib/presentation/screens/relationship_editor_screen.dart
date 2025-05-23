// lib/presentation/screens/relationship_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/domain/models/character.dart';
import 'package:chunk_up/core/services/enhanced_character_service.dart';
import 'package:chunk_up/core/services/series_service.dart';
import 'package:uuid/uuid.dart';

class RelationshipEditorScreen extends StatefulWidget {
  final String seriesId;
  final VoidCallback onSave;

  const RelationshipEditorScreen({
    Key? key,
    required this.seriesId,
    required this.onSave,
  }) : super(key: key);

  @override
  State<RelationshipEditorScreen> createState() => _RelationshipEditorScreenState();
}

class _RelationshipEditorScreenState extends State<RelationshipEditorScreen> {
  final EnhancedCharacterService _characterService = EnhancedCharacterService();
  final SeriesService _seriesService = SeriesService();
  
  List<Character> _characters = [];
  List<CharacterRelationship> _relationships = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final characters = await _seriesService.getCharactersInSeries(widget.seriesId);
      final relationships = await _seriesService.getRelationshipsInSeries(widget.seriesId);
      
      setState(() {
        _characters = characters;
        _relationships = relationships;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRelationshipDialog({CharacterRelationship? relationship}) {
    showDialog(
      context: context,
      builder: (context) => RelationshipDialog(
        characters: _characters,
        relationship: relationship,
        onSave: (newRelationship) async {
          await _characterService.saveRelationship(newRelationship);
          await _seriesService.addRelationshipToSeries(widget.seriesId, newRelationship.id);
          await _loadData();
        },
      ),
    );
  }

  void _deleteRelationship(CharacterRelationship relationship) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('관계 삭제'),
        content: const Text('이 관계를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _characterService.deleteRelationship(relationship.id);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관계 설정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.onSave();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_characters.length < 2)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '관계를 설정하려면 최소 2명의 캐릭터가 필요합니다.',
                            style: TextStyle(color: Colors.orange.shade700),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _relationships.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _relationships.length) {
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.add_circle_outline),
                              title: const Text('새 관계 추가'),
                              onTap: () => _showRelationshipDialog(),
                            ),
                          );
                        }
                        
                        final relationship = _relationships[index];
                        return FutureBuilder<List<String>>(
                          future: _getCharacterNames(relationship),
                          builder: (context, snapshot) {
                            final names = snapshot.data ?? ['로딩중...', '로딩중...'];
                            return Card(
                              child: ListTile(
                                title: Text('${names[0]} ↔ ${names[1]}'),
                                subtitle: relationship.description.isNotEmpty
                                    ? Text(
                                        relationship.description,
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : const Text(
                                        '관계 설명 없음',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey,
                                        ),
                                      ),
                                trailing: PopupMenuButton<String>(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('편집'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('삭제', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showRelationshipDialog(relationship: relationship);
                                    } else if (value == 'delete') {
                                      _deleteRelationship(relationship);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Future<List<String>> _getCharacterNames(CharacterRelationship relationship) async {
    try {
      // 이미 로드된 캐릭터 목록에서 찾기
      final characterA = _characters.firstWhere(
        (c) => c.id == relationship.characterAId,
        orElse: () => Character(
          id: relationship.characterAId,
          name: '알 수 없음',
          seriesId: '',
          seriesName: '',
          description: '',
        ),
      );
      final characterB = _characters.firstWhere(
        (c) => c.id == relationship.characterBId,
        orElse: () => Character(
          id: relationship.characterBId,
          name: '알 수 없음',
          seriesId: '',
          seriesName: '',
          description: '',
        ),
      );
      
      return [characterA.name, characterB.name];
    } catch (e) {
      debugPrint('관계 캐릭터 이름 가져오기 오류: $e');
      return ['오류', '오류'];
    }
  }

  String _getRelationshipTypeName(RelationshipType type) {
    switch (type) {
      case RelationshipType.romantic: return '연인';
      case RelationshipType.friendship: return '친구';
      case RelationshipType.rivalry: return '라이벌';
      case RelationshipType.familial: return '가족';
      case RelationshipType.mentor: return '스승/제자';
      case RelationshipType.enemy: return '적대';
      case RelationshipType.colleague: return '동료';
      case RelationshipType.master: return '주종';
      case RelationshipType.complex: return '복잡한 관계';
    }
  }

  String _getRelationshipStatusName(RelationshipStatus status) {
    switch (status) {
      case RelationshipStatus.harmonious: return '화목함';
      case RelationshipStatus.tense: return '긴장됨';
      case RelationshipStatus.conflicted: return '갈등중';
      case RelationshipStatus.estranged: return '소원함';
      case RelationshipStatus.developing: return '발전중';
      case RelationshipStatus.broken: return '깨짐';
      case RelationshipStatus.normal: return '평범함';
    }
  }
}

class RelationshipDialog extends StatefulWidget {
  final List<Character> characters;
  final CharacterRelationship? relationship;
  final Function(CharacterRelationship) onSave;

  const RelationshipDialog({
    Key? key,
    required this.characters,
    this.relationship,
    required this.onSave,
  }) : super(key: key);

  @override
  State<RelationshipDialog> createState() => _RelationshipDialogState();
}

class _RelationshipDialogState extends State<RelationshipDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _characterAId;
  String? _characterBId;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.relationship != null) {
      _characterAId = widget.relationship!.characterAId;
      _characterBId = widget.relationship!.characterBId;
      _descriptionController.text = widget.relationship!.description;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final relationship = CharacterRelationship(
        id: widget.relationship?.id ?? const Uuid().v4(),
        characterAId: _characterAId!,
        characterBId: _characterBId!,
        type: RelationshipType.complex,  // 기본값으로 complex 사용
        status: RelationshipStatus.normal,  // 기본값으로 normal 사용
        description: _descriptionController.text.trim(),
      );
      
      widget.onSave(relationship);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.relationship == null ? '관계 추가' : '관계 편집'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _characterAId,
                decoration: const InputDecoration(labelText: '캐릭터 A'),
                items: widget.characters.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                onChanged: (value) => setState(() => _characterAId = value),
                validator: (value) => value == null ? '캐릭터를 선택하세요' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _characterBId,
                decoration: const InputDecoration(labelText: '캐릭터 B'),
                items: widget.characters.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                onChanged: (value) => setState(() => _characterBId = value),
                validator: (value) {
                  if (value == null) return '캐릭터를 선택하세요';
                  if (value == _characterAId) return '다른 캐릭터를 선택하세요';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '관계 설명',
                  hintText: '두 캐릭터의 관계를 설명하세요',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '관계 설명을 입력하세요';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('저장'),
        ),
      ],
    );
  }

  String _getRelationshipTypeName(RelationshipType type) {
    switch (type) {
      case RelationshipType.romantic: return '연인';
      case RelationshipType.friendship: return '친구';
      case RelationshipType.rivalry: return '라이벌';
      case RelationshipType.familial: return '가족';
      case RelationshipType.mentor: return '스승/제자';
      case RelationshipType.enemy: return '적대';
      case RelationshipType.colleague: return '동료';
      case RelationshipType.master: return '주종';
      case RelationshipType.complex: return '복잡한 관계';
    }
  }

  String _getRelationshipStatusName(RelationshipStatus status) {
    switch (status) {
      case RelationshipStatus.harmonious: return '화목함';
      case RelationshipStatus.tense: return '긴장됨';
      case RelationshipStatus.conflicted: return '갈등중';
      case RelationshipStatus.estranged: return '소원함';
      case RelationshipStatus.developing: return '발전중';
      case RelationshipStatus.broken: return '깨짐';
      case RelationshipStatus.normal: return '평범함';
    }
  }
}
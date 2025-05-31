// lib/presentation/screens/relationship_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/domain/models/character.dart';
import 'package:chunk_up/domain/services/character/enhanced_character_service.dart';
import 'package:chunk_up/domain/services/series/series_service.dart';
import 'package:uuid/uuid.dart';
import '../widgets/labeled_border_container.dart';

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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.relationship == null ? Icons.add_link : Icons.edit,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.relationship == null ? '관계 추가' : '관계 편집',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LabeledDropdown<String>(
                        label: '캐릭터 A',
                        hint: '캐릭터를 선택하세요',
                        isRequired: true,
                        value: _characterAId,
                        focusedBorderColor: Theme.of(context).primaryColor,
                        items: widget.characters.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                child: Text(c.name[0]),
                              ),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _characterAId = value),
                      ),
                      const SizedBox(height: 16),
                      LabeledDropdown<String>(
                        label: '캐릭터 B',
                        hint: '캐릭터를 선택하세요',
                        isRequired: true,
                        value: _characterBId,
                        focusedBorderColor: Theme.of(context).primaryColor,
                        items: widget.characters
                            .where((c) => c.id != _characterAId)
                            .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                child: Text(c.name[0]),
                              ),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _characterBId = value),
                      ),
                      const SizedBox(height: 16),
                      LabeledTextField(
                        label: '관계 설명',
                        hint: '두 캐릭터의 관계를 설명하세요',
                        isRequired: true,
                        controller: _descriptionController,
                        maxLines: 4,
                        focusedBorderColor: Theme.of(context).primaryColor,
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
            ),
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_characterAId == null || _characterBId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('캐릭터를 선택하세요'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (_characterAId == _characterBId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('서로 다른 캐릭터를 선택하세요'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        _save();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
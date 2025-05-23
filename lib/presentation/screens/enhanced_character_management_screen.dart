// lib/presentation/screens/enhanced_character_management_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:chunk_up/domain/models/series.dart';
import 'package:chunk_up/domain/models/character.dart';
import 'package:chunk_up/core/services/series_service.dart';
import 'package:chunk_up/core/services/enhanced_character_service.dart';
import 'character_detail_screen.dart';
import 'character_detail_view.dart';
import 'relationship_editor_screen.dart';
import 'series_editor_dialog.dart';

class EnhancedCharacterManagementScreen extends StatefulWidget {
  const EnhancedCharacterManagementScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedCharacterManagementScreen> createState() => _EnhancedCharacterManagementScreenState();
}

class _EnhancedCharacterManagementScreenState extends State<EnhancedCharacterManagementScreen> {
  late final SeriesService _seriesService;
  late final EnhancedCharacterService _characterService;
  
  List<Series> _seriesList = [];
  Map<String, List<Character>> _charactersBySeries = {};
  String? _selectedSeriesId;
  Character? _selectedCharacter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _seriesService = GetIt.instance<SeriesService>();
    _characterService = GetIt.instance<EnhancedCharacterService>();
    // 화면이 빌드된 후에 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      debugPrint('EnhancedCharacterManagement: 데이터 로드 시작');
      
      // 타임아웃 설정 (5초)
      final series = await _seriesService.getAllSeries().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('EnhancedCharacterManagement: 시리즈 로드 타임아웃');
          return [];
        },
      );
      
      debugPrint('EnhancedCharacterManagement: ${series.length}개의 시리즈 로드됨');
      
      // 각 시리즈의 캐릭터 로드
      final charactersBySeries = <String, List<Character>>{};
      for (final s in series) {
        try {
          final characters = await _seriesService.getCharactersInSeries(s.id).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('EnhancedCharacterManagement: ${s.name} 캐릭터 로드 타임아웃');
              return [];
            },
          );
          charactersBySeries[s.id] = characters;
          debugPrint('EnhancedCharacterManagement: ${s.name}에 ${characters.length}명의 캐릭터');
        } catch (e) {
          debugPrint('EnhancedCharacterManagement: ${s.name} 캐릭터 로드 오류: $e');
          charactersBySeries[s.id] = [];
        }
      }
      
      if (mounted) {
        setState(() {
          _seriesList = series;
          _charactersBySeries = charactersBySeries;
          if (_selectedSeriesId == null && series.isNotEmpty) {
            _selectedSeriesId = series.first.id;
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('EnhancedCharacterManagement: 데이터 로드 오류: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 중 오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSeriesTree() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '시리즈 목록',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddSeriesDialog,
                  tooltip: '시리즈 추가',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _seriesList.length,
              itemBuilder: (context, index) {
                final series = _seriesList[index];
                final isSelected = series.id == _selectedSeriesId;
                final characters = _charactersBySeries[series.id] ?? [];
                
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    key: PageStorageKey(series.id),
                    initiallyExpanded: isSelected,
                    leading: Icon(
                      Icons.folder,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                    title: Text(
                      series.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    subtitle: Text('${characters.length}명의 캐릭터'),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('편집'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('삭제', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) => _handleSeriesAction(series, value),
                    ),
                    onExpansionChanged: (expanded) {
                      if (expanded) {
                        setState(() => _selectedSeriesId = series.id);
                      }
                    },
                    children: [
                      ...characters.map((character) => ListTile(
                        contentPadding: const EdgeInsets.only(left: 56, right: 16),
                        leading: CircleAvatar(
                          child: Text(character.name[0]),
                          backgroundColor: _selectedCharacter?.id == character.id
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade400,
                        ),
                        title: Text(character.name),
                        subtitle: character.tags.isNotEmpty 
                            ? Text(
                                character.tags.join(' · '),
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        selected: _selectedCharacter?.id == character.id,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.red.shade400,
                          onPressed: () => _confirmDeleteCharacter(character),
                        ),
                        onTap: () {
                          _showEditCharacterDialog(character);
                        },
                      )),
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 56, right: 16),
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text('캐릭터 추가'),
                        onTap: () => _showAddCharacterDialog(series),
                      ),
                      if (characters.length >= 2)
                        ListTile(
                          contentPadding: const EdgeInsets.only(left: 56, right: 16),
                          leading: const Icon(Icons.people_outline),
                          title: const Text('관계 설정'),
                          onTap: () => _showRelationshipEditor(series),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  void _showAddSeriesDialog() {
    showDialog(
      context: context,
      builder: (context) => SeriesEditorDialog(
        onSave: (series) async {
          await _seriesService.saveSeries(series);
          await _loadData();
        },
      ),
    );
  }

  void _showAddCharacterDialog(Series series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterDetailScreen(
          seriesId: series.id,
          seriesName: series.name,
          onSave: (character) async {
            await _characterService.saveCharacter(character);
            await _seriesService.addCharacterToSeries(series.id, character.id);
            await _loadData();
          },
        ),
      ),
    );
  }

  void _showEditCharacterDialog(Character character) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterDetailScreen(
          character: character,
          seriesId: character.seriesId,
          seriesName: character.seriesName,
          onSave: (updatedCharacter) async {
            await _characterService.saveCharacter(updatedCharacter);
            await _loadData();
            setState(() {
              _selectedCharacter = updatedCharacter;
            });
          },
        ),
      ),
    );
  }

  void _showRelationshipEditor(Series series) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RelationshipEditorScreen(
          seriesId: series.id,
          onSave: () async {
            await _loadData();
          },
        ),
      ),
    );
  }

  void _handleSeriesAction(Series series, String action) async {
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (context) => SeriesEditorDialog(
            series: series,
            onSave: (updated) async {
              await _seriesService.saveSeries(updated);
              await _loadData();
            },
          ),
        );
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('시리즈 삭제'),
            content: Text('${series.name} 시리즈와 모든 캐릭터를 삭제하시겠습니까?'),
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
          await _seriesService.deleteSeries(series.id);
          await _loadData();
          setState(() {
            _selectedSeriesId = null;
            _selectedCharacter = null;
          });
        }
        break;
    }
  }

  void _confirmDeleteCharacter(Character character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캐릭터 삭제'),
        content: Text('${character.name} 캐릭터를 삭제하시겠습니까?'),
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
      await _characterService.deleteCharacter(character.id);
      await _seriesService.removeCharacterFromSeries(character.seriesId, character.id);
      await _loadData();
      setState(() {
        _selectedCharacter = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캐릭터 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSeriesTree(),
    );
  }
}
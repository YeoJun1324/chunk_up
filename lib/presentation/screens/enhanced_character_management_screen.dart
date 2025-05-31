// lib/presentation/screens/enhanced_character_management_screen.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:chunk_up/domain/models/series.dart';
import 'package:chunk_up/domain/models/character.dart';
import 'package:chunk_up/domain/services/series/series_service.dart';
import 'package:chunk_up/domain/services/character/enhanced_character_service.dart';
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
  bool _isSelectionMode = false;
  Set<String> _selectedCharacterIds = {};

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black54 : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.orange.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder_special,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '시리즈 목록',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : null,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _showAddSeriesDialog,
                    tooltip: '시리즈 추가',
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _seriesList.length,
                itemBuilder: (context, index) {
                  final series = _seriesList[index];
                  final isSelected = series.id == _selectedSeriesId;
                  final characters = _charactersBySeries[series.id] ?? [];
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.withOpacity(0.1)
                          : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.orange.withOpacity(0.5)
                            : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: isDarkMode ? Colors.white70 : null,
                        ),
                      ),
                      child: ExpansionTile(
                        key: PageStorageKey(series.id),
                        initiallyExpanded: isSelected,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.orange
                                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: isDarkMode 
                                    ? Colors.deepPurple.withOpacity(0.4)
                                    : Theme.of(context).primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Icon(
                            Icons.folder,
                            color: isSelected 
                                ? Colors.white 
                                : Colors.orange.shade300,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          series.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected 
                                ? Colors.orange
                                : (isDarkMode ? Colors.white70 : null),
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Container(
                          margin: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${characters.length}명',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text('편집'),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text('삭제', style: TextStyle(color: Colors.red)),
                              ),
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
                      ...characters.map((character) {
                        final isCharacterSelected = _selectedCharacter?.id == character.id;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCharacterSelected
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.only(left: 48, right: 12),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCharacterSelected
                                    ? Colors.orange
                                    : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                                shape: BoxShape.circle,
                                boxShadow: isCharacterSelected ? [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                              child: Center(
                                child: Text(
                                  character.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: isCharacterSelected 
                                        ? Colors.white 
                                        : (isDarkMode ? Colors.white70 : Colors.black87),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              character.name,
                              style: TextStyle(
                                fontWeight: isCharacterSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isDarkMode ? Colors.white.withOpacity(0.9) : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: character.tags.isNotEmpty 
                                ? Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    child: Wrap(
                                      spacing: 4,
                                      children: character.tags.take(3).map((tag) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDarkMode 
                                              ? Colors.grey.shade800 
                                              : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDarkMode 
                                                ? Colors.grey.shade400 
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                      )).toList(),
                                    ),
                                  )
                                : null,
                            trailing: _isSelectionMode
                                ? Checkbox(
                                    value: _selectedCharacterIds.contains(character.id),
                                    activeColor: Colors.orange,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedCharacterIds.add(character.id);
                                        } else {
                                          _selectedCharacterIds.remove(character.id);
                                        }
                                      });
                                    },
                                  )
                                : Icon(
                                    Icons.chevron_right,
                                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                                  ),
                            onTap: () {
                              if (_isSelectionMode) {
                                setState(() {
                                  if (_selectedCharacterIds.contains(character.id)) {
                                    _selectedCharacterIds.remove(character.id);
                                  } else {
                                    _selectedCharacterIds.add(character.id);
                                  }
                                });
                              } else {
                                _showEditCharacterDialog(character);
                              }
                            },
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedCharacterIds.add(character.id);
                                });
                              }
                            },
                          ),
                        );
                      }),
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showAddCharacterDialog(series),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '캐릭터 추가',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (characters.length >= 2)
                        Container(
                          margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showRelationshipEditor(series),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '관계 설정',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                      ),
                    ),
                  );
                },
              ),
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
    debugPrint('=== Showing edit dialog for character: ${character.name} ===');
    debugPrint('Character ID: ${character.id}');
    debugPrint('Series ID: ${character.seriesId}');
    debugPrint('Series Name: ${character.seriesName}');
    debugPrint('Tags: ${character.tags}');
    
    try {
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
    } catch (error, stackTrace) {
      debugPrint('❌ Navigation error: $error');
      debugPrint('Stack trace: $stackTrace');
    }
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

  void _confirmDeleteSelectedCharacters() async {
    final count = _selectedCharacterIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('캐릭터 삭제'),
        content: Text('선택한 $count개의 캐릭터를 삭제하시겠습니까?'),
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
      for (final characterId in _selectedCharacterIds) {
        final character = _charactersBySeries.values
            .expand((chars) => chars)
            .firstWhere((c) => c.id == characterId);
        await _characterService.deleteCharacter(character.id);
        await _seriesService.removeCharacterFromSeries(character.seriesId, character.id);
      }
      await _loadData();
      setState(() {
        _isSelectionMode = false;
        _selectedCharacterIds.clear();
        _selectedCharacter = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedCharacterIds.clear();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isSelectionMode 
              ? '${_selectedCharacterIds.length}개 선택' 
              : '캐릭터 관리'),
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedCharacterIds.clear();
                    });
                  },
                )
              : null,
          actions: [
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _selectedCharacterIds.isNotEmpty
                    ? () => _confirmDeleteSelectedCharacters()
                    : null,
                tooltip: '선택한 캐릭터 삭제',
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: '새로고침',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.grey[50],
                child: _buildSeriesTree(),
              ),
      ),
    );
  }
}
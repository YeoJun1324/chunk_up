// lib/presentation/screens/character_selection_modal.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:chunk_up/domain/models/character.dart';
import 'package:chunk_up/domain/models/series.dart';
import 'package:chunk_up/domain/services/character/enhanced_character_service.dart';
import 'package:chunk_up/domain/services/series/series_service.dart';

class CharacterSelectionModal extends StatefulWidget {
  final List<String> initialSelection;
  final Function(List<String>) onConfirm;

  const CharacterSelectionModal({
    Key? key,
    required this.initialSelection,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<CharacterSelectionModal> createState() => _CharacterSelectionModalState();
}

class _CharacterSelectionModalState extends State<CharacterSelectionModal> {
  late final EnhancedCharacterService _characterService;
  late final SeriesService _seriesService;
  
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedCharacters = [];
  Map<String, List<Character>> _charactersBySeries = {};
  List<Series> _allSeries = [];
  Map<String, List<Character>> _filteredCharactersBySeries = {};
  Set<String> _expandedSeries = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _characterService = GetIt.instance<EnhancedCharacterService>();
    _seriesService = GetIt.instance<SeriesService>();
    _selectedCharacters = List<String>.from(widget.initialSelection);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final series = await _seriesService.getAllSeries();
      final charactersBySeries = <String, List<Character>>{};
      
      for (final s in series) {
        final characters = await _seriesService.getCharactersInSeries(s.id);
        if (characters.isNotEmpty) {
          charactersBySeries[s.id] = characters;
        }
      }
      
      setState(() {
        _allSeries = series;
        _charactersBySeries = charactersBySeries;
        _filteredCharactersBySeries = Map<String, List<Character>>.from(charactersBySeries);
        
        // 선택된 캐릭터가 있는 시리즈는 자동으로 확장
        for (final seriesId in _charactersBySeries.keys) {
          if (_charactersBySeries[seriesId]!.any((char) => 
              _selectedCharacters.contains(char.name))) {
            _expandedSeries.add(seriesId);
          }
        }
      });
    } catch (e) {
      debugPrint('캐릭터 데이터 로드 오류: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterCharacters(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredCharactersBySeries = Map<String, List<Character>>.from(_charactersBySeries);
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    final filtered = <String, List<Character>>{};
    
    for (final entry in _charactersBySeries.entries) {
      final filteredCharacters = entry.value.where((character) =>
        character.name.toLowerCase().contains(lowercaseQuery) ||
        character.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery))
      ).toList();
      
      if (filteredCharacters.isNotEmpty) {
        filtered[entry.key] = filteredCharacters;
      }
    }
    
    setState(() {
      _filteredCharactersBySeries = filtered;
      _expandedSeries = Set<String>.from(filtered.keys); // 검색 시 모든 시리즈 확장
    });
  }

  void _toggleCharacter(String characterName) {
    setState(() {
      if (_selectedCharacters.contains(characterName)) {
        _selectedCharacters.remove(characterName);
      } else {
        _selectedCharacters.add(characterName);
      }
    });
  }

  void _selectAllFromSeries(String seriesId) {
    setState(() {
      final characters = _filteredCharactersBySeries[seriesId] ?? [];
      for (final character in characters) {
        if (!_selectedCharacters.contains(character.name)) {
          _selectedCharacters.add(character.name);
        }
      }
    });
  }

  void _deselectAllFromSeries(String seriesId) {
    setState(() {
      final characters = _filteredCharactersBySeries[seriesId] ?? [];
      for (final character in characters) {
        _selectedCharacters.remove(character.name);
      }
    });
  }

  Widget _buildSeriesSection(String seriesId) {
    final series = _allSeries.firstWhere((s) => s.id == seriesId);
    final characters = _filteredCharactersBySeries[seriesId] ?? [];
    final allSelected = characters.every((char) => _selectedCharacters.contains(char.name));
    final someSelected = characters.any((char) => _selectedCharacters.contains(char.name));
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(seriesId),
          initiallyExpanded: _expandedSeries.contains(seriesId),
          onExpansionChanged: (expanded) {
            setState(() {
              if (expanded) {
                _expandedSeries.add(seriesId);
              } else {
                _expandedSeries.remove(seriesId);
              }
            });
          },
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    series.name.substring(0, 1),
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${characters.length}명',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (someSelected && !allSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${characters.where((c) => _selectedCharacters.contains(c.name)).length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Checkbox(
                value: allSelected,
                tristate: true,
                activeColor: Colors.orange,
                onChanged: (value) {
                  if (value == true) {
                    _selectAllFromSeries(seriesId);
                  } else {
                    _deselectAllFromSeries(seriesId);
                  }
                },
              ),
            ],
          ),
          children: characters.map((character) {
            final isSelected = _selectedCharacters.contains(character.name);
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: isSelected ? Colors.orange : Colors.grey[300],
                child: Text(
                  character.name.substring(0, 1),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                character.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: character.tags.isNotEmpty
                  ? Text(
                      character.tags.join(' · '),
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Checkbox(
                value: isSelected,
                activeColor: Colors.orange,
                onChanged: (_) => _toggleCharacter(character.name),
              ),
              onTap: () => _toggleCharacter(character.name),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  '캐릭터 선택',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedCharacters.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedCharacters.length}명 선택',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '캐릭터 이름 또는 태그로 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterCharacters('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
              ),
              onChanged: _filterCharacters,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Character list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCharactersBySeries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? '등록된 캐릭터가 없습니다'
                                  : '검색 결과가 없습니다',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _filteredCharactersBySeries.length,
                        itemBuilder: (context, index) {
                          final seriesId = _filteredCharactersBySeries.keys.elementAt(index);
                          return _buildSeriesSection(seriesId);
                        },
                      ),
          ),
          
          // Bottom actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_selectedCharacters.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCharacters.clear();
                        });
                      },
                      child: const Text('모두 해제'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(_selectedCharacters);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
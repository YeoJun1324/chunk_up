// lib/presentation/screens/character_management_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/core/services/character_service.dart';
import 'package:chunk_up/presentation/screens/character_creation_screen.dart';

class CharacterManagementScreen extends StatefulWidget {
  const CharacterManagementScreen({super.key});

  @override
  State<CharacterManagementScreen> createState() => _CharacterManagementScreenState();
}

class _CharacterManagementScreenState extends State<CharacterManagementScreen> {
  final CharacterService _characterService = CharacterService();
  List<Character> _characters = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }
  
  Future<void> _loadCharacters() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final characters = await _characterService.getCharacters();
      setState(() {
        _characters = characters;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('캐릭터 목록 로드 중 오류 발생: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteCharacter(Character character) async {
    try {
      final result = await _characterService.deleteCharacter(character.name);
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${character.name} 캐릭터가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCharacters(); // 목록 새로고침
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${character.name} 캐릭터 삭제에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, Character character) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('캐릭터 삭제'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('${character.name} 캐릭터를 삭제하시겠습니까?'),
                const SizedBox(height: 10),
                const Text('삭제된 캐릭터는 복구할 수 없습니다.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCharacter(character);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToEditScreen(Character character) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterEditScreen(character: character),
      ),
    );
    
    if (result != null) {
      _loadCharacters(); // 편집 후 목록 새로고침
    }
  }

  Future<void> _navigateToCreateScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CharacterCreationScreen(),
      ),
    );
    
    if (result != null) {
      _loadCharacters(); // 생성 후 목록 새로고침
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 다크 모드 감지
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('캐릭터 관리'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _characters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.face_outlined,
                        size: 80,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '캐릭터가 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '새 캐릭터를 추가해보세요!',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _navigateToCreateScreen,
                        icon: const Icon(Icons.add),
                        label: const Text('캐릭터 추가하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 설명 카드
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        color: isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isDarkMode ? Colors.blue.shade800.withOpacity(0.5) : Colors.blue.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '청크 생성 시 캐릭터를 선택하여 특별한 패턴과 말투로 내용을 생성할 수 있습니다.',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.blue.shade100 : Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // 캐릭터 목록
                    Expanded(
                      child: ListView.builder(
                        itemCount: _characters.length,
                        itemBuilder: (context, index) {
                          final character = _characters[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(
                                character.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('출처: ${character.source}'),
                                  Text(
                                    character.details.length > 50
                                        ? '${character.details.substring(0, 50)}...'
                                        : character.details,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Text(
                                  character.name.isNotEmpty 
                                    ? character.name.substring(0, 1)
                                    : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _navigateToEditScreen(character),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _showDeleteConfirmation(context, character),
                                  ),
                                ],
                              ),
                              onTap: () => _navigateToEditScreen(character),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: !_isLoading && _characters.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToCreateScreen,
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              tooltip: '캐릭터 추가',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
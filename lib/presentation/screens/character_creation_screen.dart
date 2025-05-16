// lib/screens/character_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/core/services/character_service.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sourceController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isLoading = false;

  // 디바이스 바닥 패딩 키
  final bottomPaddingKey = GlobalKey();

  @override
  void dispose() {
    _nameController.dispose();
    _sourceController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _saveCharacter() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final newCharacter = Character(
          name: _nameController.text.trim(),
          source: _sourceController.text.trim(),
          details: _detailsController.text.trim(),
        );

        // Check if character name already exists
        final characterService = CharacterService();
        final existingCharacters = await characterService.getCharacters();
        final isNameTaken = existingCharacters.any((c) => c.name == newCharacter.name);

        if (isNameTaken) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('같은 이름의 캐릭터가 이미 존재합니다.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isLoading = false;
            });
          }
          return;
        }

        // Save character
        await characterService.addCharacter(newCharacter);

        if (mounted) {
          Navigator.pop(context, newCharacter.name);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newCharacter.name} 캐릭터가 추가되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 디바이스 하단 패딩 계산
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('새 캐릭터 추가'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomPadding + 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Character name
                  const Text(
                    '캐릭터 이름:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '예: 존 왓슨',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '캐릭터 이름을 입력해주세요.';
                      }
                      if (value.trim().length < 2) {
                        return '2글자 이상 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Source
                  const Text(
                    '작품명 (출처):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _sourceController,
                    decoration: const InputDecoration(
                      hintText: '예: 셜록 홈즈 시리즈',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '캐릭터의 출처를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Character details
                  const Text(
                    '캐릭터 설정:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _detailsController,
                    decoration: const InputDecoration(
                      hintText: '캐릭터의 성격, 말투, 배경 등을 입력해주세요.\n',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 8,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '캐릭터 설정을 입력해주세요.';
                      }
                      if (value.trim().length < 20) {
                        return '더 자세한 설정을 입력해주세요 (최소 20자).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tips
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              '캐릭터 설정 팁',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• 캐릭터의 성격, 말투, 어휘 사용 습관을 자세히 적어주세요.\n'
                              '• 캐릭터가 처한 상황이나 세계관에 대한 설명도 도움이 됩니다.\n'
                              '• 캐릭터의 주요 관계나 갈등 요소를 포함하면 더 풍부한 맥락을 만들 수 있습니다.\n'
                              '• 너무 짧은 설명보다는 자세한 설명이 더 좋은 결과를 얻을 수 있습니다.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCharacter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '캐릭터 저장하기',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // 네비게이터 바 고려한 추가 공간
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
            ),
        ],
      ),
    ));
  }
}

class CharacterEditScreen extends StatefulWidget {
  final Character character;

  const CharacterEditScreen({
    super.key,
    required this.character,
  });

  @override
  State<CharacterEditScreen> createState() => _CharacterEditScreenState();
}

class _CharacterEditScreenState extends State<CharacterEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _sourceController;
  late TextEditingController _detailsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character.name);
    _sourceController = TextEditingController(text: widget.character.source);
    _detailsController = TextEditingController(text: widget.character.details);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sourceController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _updateCharacter() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 업데이트된 캐릭터 생성
        final updatedCharacter = Character(
          name: _nameController.text.trim(),
          source: _sourceController.text.trim(),
          details: _detailsController.text.trim(),
          createdAt: widget.character.createdAt, // 원래 생성일 유지
        );

        // 기존 캐릭터를 업데이트
        final characterService = CharacterService();
        await characterService.updateCharacter(widget.character.name, updatedCharacter);

        if (mounted) {
          Navigator.pop(context, updatedCharacter.name);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updatedCharacter.name} 캐릭터가 업데이트되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.character.name} 편집'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Character name
                  const Text(
                    '캐릭터 이름:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: '예: 해리 포터, 타노스',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '캐릭터 이름을 입력해주세요.';
                      }
                      if (value.trim().length < 2) {
                        return '2글자 이상 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Source
                  const Text(
                    '작품명 (출처):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _sourceController,
                    decoration: const InputDecoration(
                      hintText: '예: 해리 포터 시리즈, 마블 시네마틱 유니버스',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '캐릭터의 출처를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Character details
                  const Text(
                    '캐릭터 설정:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _detailsController,
                    decoration: const InputDecoration(
                      hintText: '캐릭터의 성격, 말투, 배경 등을 자세히 입력해주세요.\n'
                          '예: 해리 포터는 용감하고 충동적이며, 친구들을 소중히 여깁니다. 마법 학교에 다니며, 볼드모트와 대립합니다.',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 8,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '캐릭터 설정을 입력해주세요.';
                      }
                      if (value.trim().length < 20) {
                        return '더 자세한 설정을 입력해주세요 (최소 20자).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateCharacter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '캐릭터 업데이트',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // 네비게이터 바 고려한 추가 공간
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CharacterManagementScreen extends StatefulWidget {
  const CharacterManagementScreen({super.key});

  @override
  State<CharacterManagementScreen> createState() => _CharacterManagementScreenState();
}

class _CharacterManagementScreenState extends State<CharacterManagementScreen> {
  List<Character> _characters = [];
  bool _isLoading = true;
  final CharacterService _characterService = CharacterService();

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('캐릭터 목록을 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCharacter(Character character) async {
    // 다크 모드 감지
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 기본 캐릭터인지 확인
    final isDefaultCharacter = _characterService.defaultCharacters
        .any((c) => c.name == character.name);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단 경고 아이콘
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.red.shade900.withOpacity(0.8) : Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.red.shade800 : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_forever,
                        size: 36,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${character.name} 삭제',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),

              // 내용
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  children: [
                    Text(
                      '정말로 이 캐릭터를 삭제하시겠습니까?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (isDefaultCharacter) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode ? Colors.blue.shade800 : Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '이 캐릭터는 기본 제공되는 캐릭터입니다.',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                              ),
                              foregroundColor: isDarkMode ? Colors.white : Colors.grey.shade700,
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              try {
                                await _characterService.deleteCharacter(character.name);
                                await _loadCharacters();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${character.name} 캐릭터가 삭제되었습니다.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('캐릭터 삭제 중 오류가 발생했습니다: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('삭제'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addNewCharacter() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const CharacterCreationScreen(),
      ),
    );

    if (result != null) {
      await _loadCharacters();
    }
  }

  void _showCharacterDetails(Character character) {
    // 다크 모드 감지
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 기본 캐릭터 여부 확인
    final isDefaultCharacter = _characterService.defaultCharacters
        .any((defaultChar) => defaultChar.name == character.name);

    // 포맷된 날짜 생성
    final formattedDate =
        '${character.createdAt.year}년 ${character.createdAt.month}월 ${character.createdAt.day}일';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 부분
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.orange.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange,
                      radius: 24,
                      child: Text(
                        character.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  character.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDefaultCharacter) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '기본',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            character.source,
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 내용 부분
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 캐릭터 설정 라벨
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 20,
                              color: isDarkMode
                                ? Colors.orange.shade300
                                : Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '캐릭터 설정',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode
                                  ? Colors.orange.shade300
                                  : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 캐릭터 설정 내용
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              character.details,
                              style: TextStyle(
                                height: 1.5,
                                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                              height: 1,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '생성일: $formattedDate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 버튼 영역
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 닫기 버튼
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                        ),
                        foregroundColor: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('닫기'),
                    ),
                    const SizedBox(width: 12),
                    // 편집 버튼
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editCharacter(character);
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('편집'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editCharacter(Character character) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterEditScreen(character: character),
      ),
    );

    if (result != null) {
      await _loadCharacters();
    }
  }

  Widget _buildCharacterTile(Character character) {
    // 기본 캐릭터인지 확인
    final isDefaultCharacter = _characterService.defaultCharacters
        .any((defaultChar) => defaultChar.name == character.name);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(character.name),
        subtitle: Text(
          character.source,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Text(
            character.name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDefaultCharacter)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '기본',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('편집'),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 10),
                        () => _editCharacter(character),
                  ),
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () => Future.delayed(
                    const Duration(milliseconds: 10),
                        () => _deleteCharacter(character),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showCharacterDetails(character),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('캐릭터 관리'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _characters.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 추가된 캐릭터가 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '우측 하단 버튼을 눌러 새 캐릭터를 추가해보세요',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _characters.length,
        itemBuilder: (context, index) {
          final character = _characters[index];
          return _buildCharacterTile(character);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCharacter,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
// lib/screens/character_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:chunk_up/core/services/character_service.dart';
import 'package:chunk_up/core/services/subscription_service.dart';
import 'package:chunk_up/di/service_locator.dart';

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
  late SubscriptionService _subscriptionService;
  bool _hasSubscription = false;
  bool _isCheckingSubscription = true;

  // 디바이스 바닥 패딩 키
  final bottomPaddingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeSubscription();
  }

  Future<void> _initializeSubscription() async {
    setState(() {
      _isCheckingSubscription = true;
    });

    try {
      // 구독 서비스가 등록되었는지 확인
      if (!getIt.isRegistered<SubscriptionService>()) {
        getIt.registerLazySingleton<SubscriptionService>(() => SubscriptionService());
      }

      _subscriptionService = getIt<SubscriptionService>();
      _hasSubscription = _subscriptionService.canCreateCharacter;

      debugPrint('❕ 캐릭터 생성 화면: 구독 상태 = $_hasSubscription');
    } catch (e) {
      debugPrint('❌ 캐릭터 생성 화면: 구독 서비스 접근 실패: $e');
      _hasSubscription = false;
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSubscription = false;
        });
      }
    }
  }

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
  
  // 구독이 필요한 경우 보여줄 화면
  Widget _buildSubscriptionRequiredView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outlined,
              size: 80,
              color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
            ),
            const SizedBox(height: 24),
            Text(
              '캐릭터 생성은 구독자 전용 기능입니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '캐릭터를 생성하여 당신만의 특별한 단어 학습 환경을 만들려면 기본 또는 프리미엄 구독이 필요합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.orange.shade200,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '구독 플랜 혜택:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureRow(
                    '커스텀 캐릭터 생성',
                    '원하는 대로 캐릭터를 만들고 설정할 수 있습니다',
                    true,
                  ),
                  _buildFeatureRow(
                    '고급 AI 모델 사용',
                    '더 똑똑하고 정확한 AI 모델로 학습합니다',
                    true,
                  ),
                  _buildFeatureRow(
                    '더 많은 단어로 청크 생성',
                    '최대 20개 단어를 포함한 청크를 생성합니다',
                    true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/subscription');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                minimumSize: const Size(200, 50),
              ),
              child: const Text(
                '구독 플랜 보기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                '돌아가기',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 구독 혜택 행 위젯
  Widget _buildFeatureRow(String title, String description, bool isAvailable) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable 
                ? Colors.green
                : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 디바이스 하단 패딩 계산
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('새 캐릭터 추가'),
      ),
      body: _isCheckingSubscription
          ? const Center(child: CircularProgressIndicator())
          : !_hasSubscription
              ? _buildSubscriptionRequiredView()
              : SafeArea(
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
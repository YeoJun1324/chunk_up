// lib/screens/create_chunk_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'select_words_screen.dart';
import 'chunk_result_screen.dart';
import 'package:chunk_up/core/services/api_service.dart';
import 'package:chunk_up/core/services/error_service.dart';
import 'package:chunk_up/core/services/character_service.dart';
import 'package:chunk_up/core/services/subscription_service.dart';
import 'package:chunk_up/core/services/ad_service.dart';
import 'character_creation_screen.dart';
import 'package:chunk_up/core/utils/business_exception.dart';
import 'package:chunk_up/domain/usecases/generate_chunk_use_case.dart';
import 'package:chunk_up/di/service_locator.dart';
import 'package:chunk_up/core/constants/app_constants.dart';
import 'package:chunk_up/core/constants/error_messages.dart';
import 'package:chunk_up/presentation/widgets/labeled_border_container.dart';

class CreateChunkScreen extends StatefulWidget {
  const CreateChunkScreen({super.key});

  @override
  State<CreateChunkScreen> createState() => _CreateChunkScreenState();
}

class _CreateChunkScreenState extends State<CreateChunkScreen> {
  final ErrorService _errorService = ErrorService();
  WordListInfo? _selectedWordList;
  String? _selectedWordListName;
  List<Word> _selectedWords = [];
  String? _selectedCharacter;
  bool _isLoading = false;
  final TextEditingController _scenarioController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  late final GenerateChunkUseCase _generateChunkUseCase;
  late SubscriptionService _subscriptionService;
  late AdService _adService;
  bool _isCheckingSubscription = true;

  List<String> _characterOptions = [];

  @override
  void initState() {
    super.initState();
    _loadCharacterOptions();
    // getIt을 사용하여 의존성 주입
    _generateChunkUseCase = getIt<GenerateChunkUseCase>();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // 구독 서비스 초기화
      if (!getIt.isRegistered<SubscriptionService>()) {
        getIt.registerLazySingleton<SubscriptionService>(() => SubscriptionService());
      }
      _subscriptionService = getIt<SubscriptionService>();

      // 광고 서비스 초기화 - 이미 등록된 인스턴스 확인
      if (!getIt.isRegistered<AdService>()) {
        getIt.registerLazySingleton<AdService>(() => AdService());
      }

      // 광고 서비스 인스턴스 가져오기
      _adService = getIt<AdService>();

      // 광고 서비스가 초기화되지 않았다면 초기화
      if (!_adService.isInitialized) {
        await _adService.initialize();
      }

      // 전면 광고가 로드되지 않았다면 로드
      if (!_adService.isInterstitialAdLoaded) {
        await _adService.loadInterstitialAd();
      }

      debugPrint('✅ 청크 생성 화면: 서비스 초기화 완료');
    } catch (e) {
      debugPrint('❌ 청크 생성 화면: 서비스 초기화 실패: $e');
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
    _scenarioController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CreateChunkScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCharacterOptions();
  }

  final CharacterService _characterService = CharacterService(); // Singleton 인스턴스 사용

  Future<void> _loadCharacterOptions() async {
    try {
      final characters = await _characterService.getCharacters();
      final List<String> options = characters.map((c) => c.name).toList();

      // 중복 제거 및 필터링 강화
      final Set<String> uniqueOptions = {};
      for (String option in options) {
        if (option.trim().isNotEmpty &&
            option != '(캐릭터 없음)' &&
            option != '캐릭터 없음' &&
            option != '기본' &&
            option != '캐릭터 새로 추가...') {  // 이 줄 추가
          uniqueOptions.add(option.trim());
        }
      }

      final filteredOptions = uniqueOptions.toList();

      setState(() {
        _characterOptions = filteredOptions;

        // 현재 선택된 캐릭터가 유효한지 확인
        if (_selectedCharacter != null &&
            _selectedCharacter != '캐릭터 새로 추가...' &&
            !_characterOptions.contains(_selectedCharacter)) {
          _selectedCharacter = null;
        }
      });
    } catch (e) {
      print('Error loading character options: $e');
      setState(() {
        _characterOptions = [];
        _selectedCharacter = null; // 에러 시 null로 설정
      });
    }
  }

  void _onCharacterChanged(String? newValue) async {
    if (newValue == null) {
      setState(() {
        _selectedCharacter = null;
      });
      return;
    }

    if (newValue == '캐릭터 새로 추가...') {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const CharacterCreationScreen(),
        ),
      );

      if (result != null) {
        await _loadCharacterOptions();
        setState(() {
          _selectedCharacter = result;
        });
      } else {
        // 취소한 경우 이전 선택 유지 또는 null로 설정
        setState(() {
          _selectedCharacter = null;
        });
      }
    } else {
      setState(() {
        _selectedCharacter = newValue;
      });
    }
  }

  /// 단어 선택 화면에서 단어 선택 - 불변성 패턴 적용
  void _selectWords() async {
    await _errorService.handleVoidError(
      operation: 'selectWords',
      context: context,
      showDialog: false,
      action: () async {
        if (_selectedWordList == null) {
          throw BusinessException(
            message: '단어장을 먼저 선택하세요.',
            type: BusinessErrorType.validationError,
          );
        }

        final List<Word>? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SelectWordsScreen(
              wordList: _selectedWordList!,
              // 불변성 유지를 위해 새 리스트 생성
              initiallySelectedWords: List<Word>.from(_selectedWords),
            ),
          ),
        );

        if (result != null) {
          setState(() {
            // 불변성 유지를 위해 새 리스트 생성하여 할당
            _selectedWords = List<Word>.from(result);
          });
        }
      },
    );
  }

  Future<void> _generateChunk() async {
    await _errorService.handleVoidError(  // ErrorHandlingPolicy 대신 ErrorService 사용
      operation: 'generateChunk',
      context: context,
      action: () async {
        if (_selectedWordList == null || _selectedWords.isEmpty) {
          throw BusinessException(
            message: '단어장을 선택하고, 생성할 단어를 선택해주세요.',
            type: BusinessErrorType.validationError,
          );
        }

        if (_selectedWords.length < AppConstants.minWordsForChunk ||
            _selectedWords.length > AppConstants.maxWordsForChunk) {
          throw BusinessException(
            message: ErrorMessages.wordCountOutOfRange,
            type: BusinessErrorType.invalidWordCount,
          );
        }

        // 청크 생성 시작 전에 무료 사용자인 경우 광고 표시
        final shouldShowAd = _subscriptionService.shouldShowAds;
        if (shouldShowAd) {
          debugPrint('💰 무료 사용자 청크 생성 - 광고 표시');

          // 광고 로드 및 표시
          bool adShown = false;

          // 로딩 표시 (광고 준비 중)
          setState(() {
            _isLoading = true;
          });

          // 광고 표시 시도
          try {
            if (_adService.isInterstitialAdLoaded) {
              adShown = await _adService.showInterstitialAd();
            } else {
              // 광고가 로드되지 않은 경우 로드 시도
              await _adService.loadInterstitialAd();
              if (_adService.isInterstitialAdLoaded) {
                adShown = await _adService.showInterstitialAd();
              }
            }

            if (adShown) {
              debugPrint('✅ 청크 생성 전 광고 표시 성공');
            } else {
              debugPrint('⚠️ 광고 표시 실패 또는 로드 실패, 청크 생성 계속 진행');
            }
          } catch (e) {
            debugPrint('❌ 광고 표시 중 오류: $e');
          }
        } else {
          debugPrint('💎 구독 사용자 청크 생성 - 광고 없음');
        }

        // API 서비스 테스트 (디버깅용)
        debugPrint('🔄 청크 생성 전 API 테스트');
        final apiService = getIt<ApiService>();
        final apiTestResult = await apiService.testApiConnection();
        debugPrint('🔌 API 테스트 결과: ${apiTestResult ? "성공" : "실패"}');

        setState(() {
          _isLoading = true;
        });

        final params = GenerateChunkParams(
          selectedWords: _selectedWords,
          wordListName: _selectedWordList!.name,
          character: _selectedCharacter,
          scenario: _scenarioController.text.trim(),
          details: _detailsController.text.trim(),
        );

        final chunk = await _generateChunkUseCase.call(params);

        // 청크를 먼저 저장
        await Provider.of<WordListNotifier>(context, listen: false)
            .addChunkToWordList(_selectedWordList!.name, chunk);

        if (!mounted) return;

        Map<String, dynamic> aiResult = {
          'title': chunk.title,
          'englishChunk': chunk.englishContent,
          'koreanTranslation': chunk.koreanTranslation,
          'wordExplanations': chunk.wordExplanations,
          'chunkId': chunk.id,
          'isSaved': true, // 이미 저장되었음을 표시
          'originalGenerationParams': {
            'wordListName': _selectedWordList!.name,
            'words': _selectedWords.map((w) => {'english': w.english, 'korean': w.korean}).toList(),
            'character': _selectedCharacter,
            'scenario': _scenarioController.text.trim(),
            'details': _detailsController.text.trim(),
          },
        };

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChunkResultScreen(
              result: aiResult,
              wordListInfo: _selectedWordList!,
              selectedWords: _selectedWords,
            ),
          ),
        ).then((_) {
          // 결과 화면에서 돌아올 때 상태 초기화
          setState(() {
            _selectedWords = [];
            _selectedCharacter = null;
            _selectedWordListName = null;  // 이것도 초기화
            _selectedWordList = null;
            _scenarioController.clear();
            _detailsController.clear();
          });
        });
      },
      onRetry: _generateChunk,
    ).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wordListNotifier = Provider.of<WordListNotifier>(context);
    final availableWordListsFromProvider = wordListNotifier.wordLists;

    // 디바이스 하단 패딩 계산
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chunk 생성 설정'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomPadding + 24.0), // 하단 패딩 추가
                child: AbsorbPointer(  // 로딩 중에는 상호작용 차단
                  absorbing: _isLoading,
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                LabeledDropdown<String?>(
                  label: '1. 단어장 선택',
                  hint: '포함할 단어가 있는 단어장을 선택하세요',
                  isRequired: true,
                  value: _selectedWordListName,
                  items: availableWordListsFromProvider.map((WordListInfo list) {
                    return DropdownMenuItem<String?>(
                      value: list.name,
                      child: Text(list.name),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedWordListName = newValue;
                      if (newValue != null) {
                        _selectedWordList = availableWordListsFromProvider
                            .firstWhere((list) => list.name == newValue);
                      } else {
                        _selectedWordList = null;
                      }
                      _selectedWords = [];
                    });
                  },
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                ),
                const SizedBox(height: 16),

                LabeledBorderContainer(
                  label: '2. 단어 선택 (5~25개)',
                  isRequired: true,
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                  hasValue: _selectedWords.isNotEmpty, // 단어가 선택되었는지 여부
                  child: InkWell(
                    onTap: _selectedWordList == null ? null : _selectWords,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedWords.isEmpty
                                ? '단어 선택하기'
                                : '단어 ${_selectedWords.length}개 선택됨',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedWordList == null
                                  ? Colors.grey.shade400
                                  : Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                          Icon(
                            Icons.checklist_rtl,
                            color: _selectedWordList == null
                                ? Colors.grey.shade400
                                : Colors.orange,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                if (_selectedWords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _selectedWords
                          .map((word) => Chip(
                        label: Text(word.english),
                        avatar: CircleAvatar(
                            child: Text(word.english.substring(0,1).toUpperCase())),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: (){
                          setState(() {
                            // 불변성 패턴 적용 - 기존 리스트를 직접 수정하지 않고 새 리스트 생성
                            _selectedWords = _selectedWords
                                .where((w) => w.english != word.english)
                                .toList();
                          });
                        },
                      ))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 24),

                Builder(
                  builder: (context) {
                    final List<DropdownMenuItem<String?>> items = [];

                    // null 항목 추가
                    items.add(const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('캐릭터 없음'),
                    ));

                    // 캐릭터 옵션 추가
                    for (String option in _characterOptions) {
                      items.add(DropdownMenuItem<String?>(
                        value: option,
                        child: Text(option),
                      ));
                    }

                    // "캐릭터 새로 추가..." 옵션은 마지막에 한 번만 추가
                    items.add(const DropdownMenuItem<String?>(
                      value: '캐릭터 새로 추가...',
                      child: Text('캐릭터 새로 추가...'),
                    ));

                    // 디버깅을 위해 추가
                    print('Selected character: $_selectedCharacter');
                    print('Available items: ${items.map((e) => e.value).toList()}');

                    return LabeledDropdown<String?>(
                      key: ValueKey(_selectedCharacter), // key 추가
                      label: '3. 캐릭터 선택',
                      hint: '캐릭터 선택 (선택사항)',
                      value: _selectedCharacter,
                      items: items,
                      onChanged: _onCharacterChanged,
                      borderColor: Colors.grey.shade300,
                      focusedBorderColor: Colors.orange,
                      labelColor: Colors.black87,
                    );
                  },
                ),
                const SizedBox(height: 24),

                LabeledTextField(
                  label: '4. 시나리오',
                  hint: '예: 셜록 홈즈가 안개 낀 런던 거리에서 단서를 찾고 있다.',
                  controller: _scenarioController,
                  maxLines: 2,
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                ),
                const SizedBox(height: 24),

                LabeledTextField(
                  label: '5. 세부 사항',
                  hint: '캐릭터 말투, 배경 설정, 원하는 글의 스타일, 출력 길이 등 세부적인 요구사항을 적어주세요.',
                  controller: _detailsController,
                  maxLines: 4,
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                ),
                const SizedBox(height: 32),

                const SizedBox(height: 16),
                const Text(
                  '* 표시는 필수 입력 항목입니다',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Chunk Up!'),
                  onPressed: _isLoading ? null : _generateChunk,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    SizedBox(height: 20),
                    Text(
                      _selectedWords.length > 10
                          ? "많은 단어를 처리중입니다...\n잠시만 기다려 주세요."
                          : "AI가 단락을 생성 중입니다...\n잠시만 기다려 주세요.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
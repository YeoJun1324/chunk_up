// lib/screens/create_chunk_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chunk_up/presentation/providers/word_list_notifier.dart';
import 'package:chunk_up/domain/models/word.dart';
import 'package:chunk_up/domain/models/word_list_info.dart';
import 'select_words_screen.dart';
import 'chunk_result_screen.dart';
import 'package:chunk_up/domain/services/api_service_interface.dart';
import 'package:chunk_up/infrastructure/error/error_service.dart';
import 'package:chunk_up/domain/services/character/enhanced_character_service.dart';
import 'package:chunk_up/data/services/subscription/subscription_service.dart';
import 'package:chunk_up/data/services/ads/ad_service.dart';
import 'enhanced_character_management_screen.dart';
import 'character_selection_modal.dart';
import 'word_list_selection_modal.dart';
import 'package:chunk_up/core/utils/business_exception.dart';
import 'package:chunk_up/domain/usecases/generate_chunk_use_case.dart';
import 'package:chunk_up/di/service_locator.dart';
import 'package:chunk_up/core/constants/app_constants.dart';
import 'package:chunk_up/core/constants/error_messages.dart';
import 'package:chunk_up/core/constants/subscription_constants.dart';
import 'package:chunk_up/core/constants/prompt_templates.dart';
import 'package:chunk_up/core/constants/prompt_config.dart';
import 'package:chunk_up/presentation/widgets/labeled_border_container.dart';
import 'package:chunk_up/core/theme/app_colors.dart';
import 'package:chunk_up/presentation/widgets/app_button.dart';
import 'package:chunk_up/presentation/widgets/app_card.dart';
import 'package:chunk_up/presentation/widgets/app_text_field.dart';
import 'package:chunk_up/core/utils/ui_helpers.dart';
import 'package:chunk_up/core/constants/character_constants.dart';
import 'package:chunk_up/data/services/auth/auth_service_extended.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateChunkScreen extends StatefulWidget {
  final List<Word>? preSelectedWords;
  final String? wordListName;
  
  const CreateChunkScreen({
    super.key,
    this.preSelectedWords,
    this.wordListName,
  });

  @override
  State<CreateChunkScreen> createState() => _CreateChunkScreenState();
}

class _CreateChunkScreenState extends State<CreateChunkScreen> {
  late final ErrorService _errorService;
  WordListInfo? _selectedWordList;
  String? _selectedWordListName;
  List<Word> _selectedWords = [];
  List<String> _selectedCharacters = [];
  // AI 모델 선택 제거 - 오직 Gemini만 사용
  bool _isLoading = false;
  final TextEditingController _scenarioController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  late final GenerateChunkUseCase _generateChunkUseCase;
  late SubscriptionService _subscriptionService;
  late AdService _adService;
  bool _isCheckingSubscription = true;
  AuthServiceExtended? _authService;
  
  // 새로운 프롬프트 개선 기능 관련 변수
  OutputFormat? _selectedOutputFormat;
  String? _selectedTimePoint;
  EmotionalState? _selectedEmotionalState;
  Tone? _selectedTone;
  bool _showAdvancedSettings = false;
  final TextEditingController _timePointController = TextEditingController();

  List<String> _characterOptions = [];

  @override
  void initState() {
    super.initState();
    // getIt을 사용하여 의존성 주입
    _generateChunkUseCase = getIt<GenerateChunkUseCase>();
    _enhancedCharacterService = getIt<EnhancedCharacterService>();
    _errorService = getIt<ErrorService>();
    
    // 전달받은 단어들과 단어장 설정
    if (widget.preSelectedWords != null && widget.wordListName != null) {
      _selectedWords = List.from(widget.preSelectedWords!);
      _selectedWordListName = widget.wordListName;
      // 나중에 단어장 정보를 가져오기 위해 설정
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setWordListFromName();
      });
    }
    
    _loadCharacterOptions();
    _initializeServices();
  }
  
  void _setWordListFromName() {
    if (_selectedWordListName != null) {
      final wordListNotifier = Provider.of<WordListNotifier>(context, listen: false);
      try {
        _selectedWordList = wordListNotifier.wordLists.firstWhere(
          (list) => list.name == _selectedWordListName,
        );
      } catch (e) {
        debugPrint('단어장을 찾을 수 없습니다: $_selectedWordListName');
      }
    }
  }

  Future<void> _initializeServices() async {
    try {
      // DI 컨테이너에서 등록된 서비스들을 가져오기만 함 (등록은 하지 않음)
      _subscriptionService = getIt<SubscriptionService>();
      _adService = getIt<AdService>();
      
      // 인증 서비스 초기화
      try {
        if (getIt.isRegistered<AuthServiceExtended>()) {
          _authService = getIt<AuthServiceExtended>();
        }
      } catch (e) {
        debugPrint('⚠️ AuthService 초기화 실패: $e');
      }

      // 광고 서비스 상태 확인 및 초기화
      if (!_adService.isInitialized) {
        await _adService.initialize();
      }

      // 전면 광고가 로드되지 않았다면 로드
      if (!_adService.isInterstitialAdLoaded) {
        await _adService.loadInterstitialAd();
      }
      
      // AI 모델 설정 제거 - 오직 Gemini만 사용

      debugPrint('✅ 청크 생성 화면: 서비스 초기화 완료');
    } catch (e) {
      debugPrint('❌ 청크 생성 화면: 서비스 초기화 실패: $e');
      // 서비스 가져오기 실패 시 기본값으로 설정
      _setFallbackServices();
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSubscription = false;
        });
      }
    }
  }

  // AI 모델 설정 메서드 제거 - 오직 Gemini만 사용

  void _setFallbackServices() {
    // 서비스 가져오기 실패 시 기본값 설정
    debugPrint('⚠️ 서비스 초기화 실패');
  }

  void _showLoginRequiredDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.login,
                    color: Colors.orange,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '로그인이 필요합니다',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '청크 생성 기능을 사용하려면\n구글 계정으로 로그인해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                            ),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // 설정 화면으로 이동
                          Navigator.pushNamed(context, '/settings');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '로그인하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scenarioController.dispose();
    _detailsController.dispose();
    _timePointController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CreateChunkScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCharacterOptions();
  }

  late final EnhancedCharacterService _enhancedCharacterService;

  Future<void> _loadCharacterOptions() async {
    try {
      // Enhanced 캐릭터 서비스에서만 가져오기
      final enhancedCharacters = await _enhancedCharacterService.getAllCharacters();
      final List<String> options = enhancedCharacters.map((c) => c.name).toList();

      // 상수를 사용한 필터링
      final filteredOptions = CharacterConstants.filterCharacterNames(options);

      setState(() {
        _characterOptions = filteredOptions;

        // 현재 선택된 캐릭터들이 유효한지 확인
        _selectedCharacters = _selectedCharacters.where((character) =>
            CharacterConstants.isValidCharacterName(character) &&
            _characterOptions.contains(character)
        ).toList();
      });
    } catch (e) {
      print('Error loading character options: $e');
      setState(() {
        _characterOptions = [];
        _selectedCharacters = []; // 에러 시 빈 리스트로 설정
      });
    }
  }

  void _showCharacterSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CharacterSelectionModal(
        initialSelection: _selectedCharacters,
        onConfirm: (selectedCharacters) {
          setState(() {
            _selectedCharacters = selectedCharacters;
          });
          // 캐릭터 옵션 다시 로드
          _loadCharacterOptions();
        },
      ),
    );
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
        // 로그인 체크
        if (_authService == null || _authService!.currentUser == null) {
          _showLoginRequiredDialog();
          return;
        }
        
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

        // 생성 가능 여부 확인 및 차감 처리
        final canGenerate = await _subscriptionService.canGenerateChunk();
        if (!canGenerate) {
          if (_subscriptionService.isPremium) {
            debugPrint('❌ 프리미엄 사용자 크레디트 부족');
            throw BusinessException(
              message: '이번 달 크레디트가 모두 소진되었습니다. 다음 달을 기다려주세요.',
              type: BusinessErrorType.validationError,
            );
          } else {
            debugPrint('❌ 무료 사용자 평생 생성 횟수 초과');
            throw BusinessException(
              message: '평생 무료 생성 횟수(5회)를 모두 사용했습니다. 프리미엄으로 업그레이드하세요.',
              type: BusinessErrorType.validationError,
            );
          }
        }
        
        // 생성 횟수/크레디트 차감
        await _subscriptionService.useGeneration();
        
        if (_subscriptionService.isPremium) {
          final remainingCredits = _subscriptionService.remainingCredits;
          debugPrint('💎 프리미엄 사용자: 1 크레디트 차감 완료 (남은 크레디트: $remainingCredits)');
        } else {
          final remainingGenerations = _subscriptionService.remainingGenerations;
          debugPrint('💸 무료 생성 횟수 차감 완료 (남은 횟수: $remainingGenerations)');
        }
        // API 서비스 테스트 (디버깅용)
        debugPrint('🔄 청크 생성 전 API 테스트');
        final apiService = getIt<ApiServiceInterface>();
        final apiTestResult = await apiService.testApiConnection();
        debugPrint('🔌 API 테스트 결과: ${apiTestResult ? "성공" : "실패"}');

        setState(() {
          _isLoading = true;
        });

        // 고급 설정 생성
        final advancedSettings = (_timePointController.text.trim().isNotEmpty || 
                                 _selectedEmotionalState != null || 
                                 _selectedTone != null ||
                                 _detailsController.text.trim().isNotEmpty)
            ? AdvancedSettings(
                timePoint: _timePointController.text.trim().isNotEmpty
                    ? TimePoint.custom
                    : null,
                customTimePoint: _timePointController.text.trim().isNotEmpty
                    ? _timePointController.text.trim()
                    : null,
                emotionalState: _selectedEmotionalState,
                tone: _selectedTone,
                customSetting: _detailsController.text.trim().isNotEmpty 
                    ? _detailsController.text.trim() 
                    : null,
              )
            : null;

        final params = GenerateChunkParams(
          selectedWords: _selectedWords,
          wordListName: _selectedWordList!.name,
          character: _selectedCharacters,
          scenario: _scenarioController.text.trim(),
          details: _detailsController.text.trim(),
          modelOverride: null, // 모델 선택 제거 - 오직 Gemini만 사용
          outputFormat: _selectedOutputFormat ?? OutputFormat.narrative,
          advancedSettings: advancedSettings,
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
          'usedModel': chunk.usedModel, // 사용된 모델 정보 추가
          'isSaved': true, // 이미 저장되었음을 표시
          'originalGenerationParams': {
            'wordListName': _selectedWordList!.name,
            'words': _selectedWords.map((w) => {'english': w.english, 'korean': w.korean}).toList(),
            'character': _selectedCharacters,
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
            _selectedCharacters = [];
            _selectedWordListName = null;
            _selectedWordList = null;
            _scenarioController.clear();
            _detailsController.clear();
            _selectedOutputFormat = null;
            _selectedTimePoint = null;
            _timePointController.clear();
            _selectedEmotionalState = null;
            _selectedTone = null;
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

  // Chip 빌더 메소드들
  Widget _buildOutputFormatChip(OutputFormat format, String label, IconData icon) {
    final isSelected = _selectedOutputFormat == format;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      selectedColor: Colors.orange,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedOutputFormat = format;
          } else {
            _selectedOutputFormat = null;
          }
        });
      },
    );
  }

  // AI 모델 선택 아이템 빌더 제거 - 오직 Gemini만 사용

  Widget _buildEmotionalStateChip(EmotionalState emotionalState, String label) {
    final isSelected = _selectedEmotionalState == emotionalState;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.purple,
      onSelected: (selected) {
        setState(() {
          _selectedEmotionalState = selected ? emotionalState : null;
        });
      },
    );
  }

  Widget _buildToneChip(Tone tone, String label) {
    final isSelected = _selectedTone == tone;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.teal,
      onSelected: (selected) {
        setState(() {
          _selectedTone = selected ? tone : null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wordListNotifier = Provider.of<WordListNotifier>(context);
    final availableWordListsFromProvider = wordListNotifier.wordLists;

    // 디바이스 하단 패딩 계산
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Chunk 생성 설정'),
        ),
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
                LabeledBorderContainer(
                  label: '1. 단어장 선택',
                  isRequired: true,
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                  hasValue: _selectedWordList != null,
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => WordListSelectionModal(
                          selectedWordListName: _selectedWordListName,
                          onWordListSelected: (wordList) {
                            setState(() {
                              _selectedWordList = wordList;
                              _selectedWordListName = wordList.name;
                              _selectedWords = [];
                            });
                          },
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedWordListName ?? '단어장을 선택하세요',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedWordListName != null
                                    ? Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black87
                                    : Colors.grey.shade400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
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
                          .asMap()
                          .entries
                          .map((entry) => Chip(
                        label: Text(entry.value.english),
                        avatar: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: (){
                          setState(() {
                            // 불변성 패턴 적용 - 기존 리스트를 직접 수정하지 않고 새 리스트 생성
                            _selectedWords = _selectedWords
                                .where((w) => w.english != entry.value.english)
                                .toList();
                          });
                        },
                      ))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 24),

                // AI 모델 선택 UI 제거 - 오직 Gemini만 사용
                
                // 캐릭터 선택 (다중 선택 가능)
                LabeledBorderContainer(
                  label: '3. 캐릭터 선택',
                  isRequired: false,
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                  hasValue: _selectedCharacters.isNotEmpty,
                  child: InkWell(
                    onTap: _showCharacterSelectionModal,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedCharacters.isEmpty
                                          ? '캐릭터를 선택하세요'
                                          : '${_selectedCharacters.length}명의 캐릭터 선택됨',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: _selectedCharacters.isEmpty ? FontWeight.normal : FontWeight.w600,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (_selectedCharacters.isEmpty)
                                      Text(
                                        '탭하여 캐릭터 목록 보기',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.people_outline,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ],
                          ),
                          if (_selectedCharacters.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._selectedCharacters.take(4).map((character) => 
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.orange,
                                          child: Text(
                                            character.substring(0, 1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          character,
                                          style: TextStyle(
                                            color: Colors.orange[700],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).toList(),
                                if (_selectedCharacters.length > 4)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '+${_selectedCharacters.length - 4}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 출력 형식 선택 (선택사항)
                LabeledBorderContainer(
                  label: '4. 출력 형식 선택 (선택사항)',
                  isRequired: false,
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                  hasValue: _selectedOutputFormat != null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _buildOutputFormatChip(OutputFormat.dialogue, '대화문', Icons.chat),
                        _buildOutputFormatChip(OutputFormat.monologue, '독백', Icons.person),
                        _buildOutputFormatChip(OutputFormat.narrative, '나레이션', Icons.book),
                        _buildOutputFormatChip(OutputFormat.thought, '내적 독백', Icons.psychology),
                        _buildOutputFormatChip(OutputFormat.letter, '편지/일기', Icons.email),
                        _buildOutputFormatChip(OutputFormat.description, '상황 묘사', Icons.landscape),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                LabeledTextField(
                  label: '5. 시나리오',
                  hint: '예: 셜록 홈즈가 안개 낀 런던 거리에서 단서를 찾고 있다.',
                  controller: _scenarioController,
                  maxLines: 2,
                  borderColor: Colors.grey.shade300,
                  focusedBorderColor: Colors.orange,
                  labelColor: Colors.black87,
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 24),

                // 고급 설정 확장 패널
                Card(
                  child: ExpansionTile(
                    title: Text('6. 고급 설정 (선택사항)'),
                    leading: Icon(Icons.settings, color: Colors.grey),
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _showAdvancedSettings = expanded;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 시점 입력
                            LabeledTextField(
                              label: '시점',
                              hint: '예: 도로시가 토네이도 후 깨어났을 때, 에메랄드 시티 도착 직전, 오즈를 만나는 장면 등',
                              controller: _timePointController,
                              maxLines: 1,
                              borderColor: Colors.grey.shade300,
                              focusedBorderColor: Colors.orange,
                              labelColor: Colors.black87,
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 16),
                            
                            // 감정 상태 선택
                            LabeledBorderContainer(
                              label: '감정 상태',
                              borderColor: Colors.grey.shade300,
                              focusedBorderColor: Colors.orange,
                              labelColor: Colors.black87,
                              hasValue: _selectedEmotionalState != null,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: [
                                    _buildEmotionalStateChip(EmotionalState.desperate, '절망적인'),
                                    _buildEmotionalStateChip(EmotionalState.determined, '결의에 찬'),
                                    _buildEmotionalStateChip(EmotionalState.confused, '혼란스러운'),
                                    _buildEmotionalStateChip(EmotionalState.melancholic, '우울한'),
                                    _buildEmotionalStateChip(EmotionalState.hopeful, '희망적인'),
                                    _buildEmotionalStateChip(EmotionalState.angry, '분노한'),
                                    _buildEmotionalStateChip(EmotionalState.peaceful, '평온한'),
                                    _buildEmotionalStateChip(EmotionalState.anxious, '불안한'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // 톤 선택
                            LabeledBorderContainer(
                              label: '톤/분위기',
                              borderColor: Colors.grey.shade300,
                              focusedBorderColor: Colors.orange,
                              labelColor: Colors.black87,
                              hasValue: _selectedTone != null,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: [
                                    _buildToneChip(Tone.serious, '진지한'),
                                    _buildToneChip(Tone.tragic, '비극적인'),
                                    _buildToneChip(Tone.hopeful, '희망적인'),
                                    _buildToneChip(Tone.dark, '어두운'),
                                    _buildToneChip(Tone.nostalgic, '향수적인'),
                                    _buildToneChip(Tone.tense, '긴장감 있는'),
                                    _buildToneChip(Tone.intimate, '친밀한'),
                                    _buildToneChip(Tone.philosophical, '철학적인'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            LabeledTextField(
                              label: '세부 사항',
                              hint: '추가 요구사항을 입력해주세요',
                              controller: _detailsController,
                              maxLines: 3,
                              borderColor: Colors.grey.shade300,
                              focusedBorderColor: Colors.orange,
                              labelColor: Colors.black87,
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  '* 표시는 필수 입력 항목입니다',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),

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
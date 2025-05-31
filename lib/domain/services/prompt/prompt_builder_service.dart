import 'package:chunk_up/core/constants/prompt_config.dart';
import 'package:chunk_up/core/constants/prompt_templates.dart';
import 'package:flutter/material.dart';

/// 프롬프트 빌더 서비스
/// 유지보수성과 확장성을 고려한 프롬프트 생성 서비스
class PromptBuilderService {
  // Singleton 패턴
  static final PromptBuilderService _instance = PromptBuilderService._internal();
  factory PromptBuilderService() => _instance;
  PromptBuilderService._internal();

  /// 프롬프트 빌드
  String buildPrompt({
    required List<String> words,
    required OutputFormat outputFormat,
    required int minLength,
    required int maxLength,
    String? characterName,
    String? characterDescription,
    String? characterPersonality,
    String? characterSetting,
    String? scenario,
    AdvancedSettings? advancedSettings,
    List<String>? additionalCharacterNames,
    String? relationshipContext,
  }) {
    try {
      // 템플릿 기반 프롬프트 생성
      String prompt = PromptTemplates.basePromptTemplate;
      
      // 1. 단어 목록 삽입
      prompt = prompt.replaceAll('{words}', words.join(', '));
      
      // 2. 출력 형식 지시문 삽입
      final formatInstruction = PromptTemplates.formatInstructions[outputFormat] ?? 
                               PromptTemplates.formatInstructions[OutputFormat.narrative]!;
      prompt = prompt.replaceAll('{outputFormat}', formatInstruction);
      
      // 3. 길이 설정
      prompt = prompt.replaceAll('{minLength}', minLength.toString());
      prompt = prompt.replaceAll('{maxLength}', maxLength.toString());
      
      // 4. 고급 컨텍스트 삽입
      String advancedContext = '';
      if (advancedSettings != null) {
        final advancedParts = <String>[];
        advancedParts.add('🔧 ADVANCED CONTEXT:');
        _addAdvancedSettingsParts(advancedParts, advancedSettings);
        if (advancedParts.length > 1) {
          advancedContext = advancedParts.join('\n');
        }
      }
      prompt = prompt.replaceAll('{advancedContext}', advancedContext);
      
      // 5. 캐릭터 컨텍스트 삽입
      String characterContext = '';
      if (relationshipContext?.isNotEmpty == true) {
        // 관계 컨텍스트가 있으면 사용
        characterContext = '👥 CHARACTERS & RELATIONSHIPS:\n' + relationshipContext!;
      } else if (characterName != null) {
        // 개별 캐릭터 정보만 사용
        characterContext = '👤 ' + _buildCharacterContext(
          name: characterName,
          description: characterDescription,
          personality: characterPersonality,
          setting: characterSetting,
        );
        
        // 추가 캐릭터들
        if (additionalCharacterNames?.isNotEmpty == true) {
          for (final name in additionalCharacterNames!) {
            characterContext += '\n👤 CHARACTER: $name';
          }
        }
      }
      prompt = prompt.replaceAll('{characterContext}', characterContext);
      
      // 6. 시나리오 컨텍스트 삽입
      String scenarioContext = '';
      if (scenario?.isNotEmpty == true && _validateScenario(scenario!)) {
        scenarioContext = '🎬 SCENARIO:\n$scenario\n\nIncorporate this scenario naturally into the content.';
      }
      prompt = prompt.replaceAll('{scenarioContext}', scenarioContext);
      
      // 7. 검증 및 최적화
      prompt = _optimizePrompt(prompt);
      
      debugPrint('📝 Generated prompt length: ${prompt.length} characters');
      return prompt;
      
    } catch (e) {
      debugPrint('❌ Error building prompt: $e');
      // 에러 발생 시 기본 프롬프트 반환
      return _buildFallbackPrompt(words, minLength, maxLength);
    }
  }

  /// 필수 섹션들 추가
  void _addRequiredSections(List<String> sections, Map<String, dynamic> values) {
    // 정렬된 순서대로 섹션 추가
    final sortedSections = PromptConfig.sections.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    
    for (final section in sortedSections) {
      if (section.required) {
        final content = section.render(values);
        if (content.isNotEmpty) {
          sections.add(content);
        }
      }
    }
    
    // 단어 목록 추가
    if (values['words'] != null) {
      sections.add('VOCABULARY WORDS TO INCLUDE:\n${(values['words'] as List<String>).join(', ')}');
    }
  }

  /// 출력 형식 섹션 추가
  void _addFormatSection(List<String> sections, OutputFormat format) {
    final config = PromptConfig.formatConfigs[format];
    if (config != null) {
      sections.add(config.instruction);
      
      // 예시가 있으면 추가
      if (config.examples.isNotEmpty) {
        sections.add('Examples:\n${config.examples.map((e) => '- $e').join('\n')}');
      }
    }
  }

  /// 고급 설정 섹션 추가
  void _addAdvancedSettingsSection(List<String> sections, AdvancedSettings settings) {
    final advancedParts = <String>[];
    _addAdvancedSettingsParts(advancedParts, settings);
    if (advancedParts.isNotEmpty) {
      sections.add('ADVANCED CONTEXT:\n${advancedParts.join('\n')}');
    }
  }
  
  /// 고급 설정 파트 추가 (재사용 가능)
  void _addAdvancedSettingsParts(List<String> parts, AdvancedSettings settings) {
    // 시점 추가
    if (settings.timePoint != null) {
      if (settings.timePoint == TimePoint.custom && settings.customTimePoint != null) {
        parts.add('- Time Point: ${settings.customTimePoint}');
      } else {
        final config = PromptConfig.advancedOptions['timePoint'];
        final option = config?.options[settings.timePoint];
        if (option != null) {
          parts.add('- Time Point: ${option.description}');
        }
      }
    }
    
    // 감정 상태 추가
    if (settings.emotionalState != null) {
      final config = PromptConfig.advancedOptions['emotionalState'];
      final option = config?.options[settings.emotionalState];
      if (option != null) {
        parts.add('- Emotional State: ${option.description}');
      }
    }
    
    // 톤 추가
    if (settings.tone != null) {
      final config = PromptConfig.advancedOptions['tone'];
      final option = config?.options[settings.tone];
      if (option != null) {
        parts.add('- Tone: ${option.description}');
      }
    }
    
    // 커스텀 설정 추가
    if (settings.customSetting?.isNotEmpty == true) {
      parts.add('- Setting: ${settings.customSetting}');
    }
    
    // 특별 요소 추가
    if (settings.specialElements?.isNotEmpty == true) {
      parts.add('- Special Elements: ${settings.specialElements!.join(', ')}');
    }
  }

  /// 캐릭터 컨텍스트 빌드 (신식 CHARACTER: 형식)
  String _buildCharacterContext({
    required String name,
    String? description,
    String? personality,
    String? setting,
  }) {
    final parts = <String>[];
    parts.add('CHARACTER: $name');
    
    if (setting?.isNotEmpty == true) {
      parts.add('- From: $setting');
    }
    
    if (description?.isNotEmpty == true) {
      parts.add('- Description: $description');
    }
    
    if (personality?.isNotEmpty == true) {
      parts.add('- Personality: $personality');
    }
    
    // 캐릭터별 오버라이드 적용
    final override = PromptConfig.characterOverrides[name];
    if (override != null) {
      if (override.additionalContext != null) {
        parts.add('- ${override.additionalContext}');
      }
      if (override.styleGuide != null) {
        parts.add('- Style: ${override.styleGuide}');
      }
    }
    
    return parts.join('\n');
  }
  
  /// 캐릭터 섹션 추가 (구식 - 더 이상 사용하지 않음)
  @Deprecated('Use _buildCharacterContext instead')
  void _addCharacterSection(
    List<String> sections, {
    required String name,
    String? description,
    String? personality,
    String? setting,
  }) {
    final characterParts = <String>['CHARACTER CONTEXT:'];
    characterParts.add('- Character: $name');
    
    if (description?.isNotEmpty == true) {
      characterParts.add('- Description: $description');
    }
    
    if (personality?.isNotEmpty == true) {
      characterParts.add('- Personality: $personality');
    }
    
    if (setting?.isNotEmpty == true) {
      characterParts.add('- Setting: $setting');
    }
    
    // 캐릭터별 오버라이드 적용
    final override = PromptConfig.characterOverrides[name];
    if (override != null) {
      if (override.additionalContext != null) {
        characterParts.add('- ${override.additionalContext}');
      }
      if (override.styleGuide != null) {
        characterParts.add('- Style: ${override.styleGuide}');
      }
    }
    
    characterParts.add('\nWrite in a way that reflects this character\'s personality and situation.');
    sections.add(characterParts.join('\n'));
  }

  /// 시나리오 섹션 추가
  void _addScenarioSection(List<String> sections, String scenario) {
    // 시나리오 검증
    if (_validateScenario(scenario)) {
      sections.add('SCENARIO:\n$scenario\n\nIncorporate this scenario naturally into the content.');
    }
  }

  /// 시나리오 검증
  bool _validateScenario(String scenario) {
    // 금지된 구문 확인
    for (final phrase in PromptValidationRules.prohibitedPhrases) {
      if (scenario.contains(phrase)) {
        debugPrint('⚠️ Scenario contains prohibited phrase: $phrase');
        return true; // 경고만 하고 계속 진행
      }
    }
    
    // 길이 확인
    if (scenario.length < PromptValidationRules.minScenarioLength) {
      debugPrint('⚠️ Scenario too short');
    }
    
    if (scenario.length > PromptValidationRules.maxScenarioLength) {
      debugPrint('⚠️ Scenario too long');
    }
    
    return true;
  }

  /// 프롬프트 최적화 및 필터링
  String _optimizePrompt(String prompt) {
    // 깊은 생각 모드를 유도하는 키워드/구문 필터링
    prompt = _filterDeepThinkingPrompts(prompt);
    
    // 중복 줄바꿈 제거
    prompt = prompt.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // 앞뒤 공백 제거
    prompt = prompt.trim();
    
    // 프롬프트 길이 체크
    if (prompt.length > 4000) {
      debugPrint('⚠️ Prompt is very long: ${prompt.length} characters');
    }
    
    return prompt;
  }
  
  /// 깊은 생각 모드를 유도하는 키워드/구문 필터링
  String _filterDeepThinkingPrompts(String prompt) {
    // 필터링할 키워드/구문 목록
    final deepThinkingPatterns = [
      // 직접적인 사고 요청
      RegExp(r'<thinking>.*?</thinking>', caseSensitive: false, dotAll: true),
      RegExp(r'think\s+step\s+by\s+step', caseSensitive: false),
      RegExp(r'think\s+carefully', caseSensitive: false),
      RegExp(r'think\s+deeply', caseSensitive: false),
      RegExp(r'reason\s+through', caseSensitive: false),
      RegExp(r'reasoning\s+process', caseSensitive: false),
      RegExp(r"let'?s\s+think", caseSensitive: false),
      RegExp(r'show\s+your\s+(reasoning|thinking|work)', caseSensitive: false),
      RegExp(r'explain\s+your\s+(reasoning|thinking|thought\s+process)', caseSensitive: false),
      
      // 단계별 사고 요청
      RegExp(r'step[\s-]by[\s-]step', caseSensitive: false),
      RegExp(r'break\s+down\s+your\s+thinking', caseSensitive: false),
      RegExp(r'walk\s+me\s+through', caseSensitive: false),
      RegExp(r'detailed\s+reasoning', caseSensitive: false),
      
      // 메타인지적 요청
      RegExp(r'reflect\s+on', caseSensitive: false),
      RegExp(r'consider\s+carefully', caseSensitive: false),
      RegExp(r'analyze\s+deeply', caseSensitive: false),
      RegExp(r'deliberate\s+on', caseSensitive: false),
      
      // Chain of Thought 관련
      RegExp(r'chain\s+of\s+thought', caseSensitive: false),
      RegExp(r'CoT', caseSensitive: true),
      
      // 특수 토큰/마커
      RegExp(r'</?think>', caseSensitive: false),
      RegExp(r'</?reasoning>', caseSensitive: false),
      RegExp(r'</?reflection>', caseSensitive: false),
    ];
    
    String filteredPrompt = prompt;
    int filterCount = 0;
    
    // 각 패턴에 대해 필터링 적용
    for (final pattern in deepThinkingPatterns) {
      if (filteredPrompt.contains(pattern)) {
        filteredPrompt = filteredPrompt.replaceAll(pattern, '');
        filterCount++;
      }
    }
    
    // 필터링 로깅
    if (filterCount > 0) {
      debugPrint('🚫 Filtered $filterCount deep thinking patterns from prompt');
    }
    
    // 필터링 후 빈 줄 정리
    filteredPrompt = filteredPrompt.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
    
    return filteredPrompt;
  }

  /// 폴백 프롬프트 생성
  String _buildFallbackPrompt(List<String> words, int minLength, int maxLength) {
    return PromptTemplates.basePromptTemplate
        .replaceAll('{words}', words.join(', '))
        .replaceAll('{minLength}', minLength.toString())
        .replaceAll('{maxLength}', maxLength.toString())
        .replaceAll('{outputFormat}', PromptTemplates.formatInstructions[OutputFormat.narrative] ?? '')
        .replaceAll('{advancedContext}', '')
        .replaceAll('{characterContext}', '')
        .replaceAll('{scenarioContext}', '')
        .trim();
  }

  /// 프롬프트 품질 점수 계산 (디버깅/분석용)
  Map<String, dynamic> analyzePromptQuality({
    required String prompt,
    required List<String> words,
    String? scenario,
  }) {
    final analysis = <String, dynamic>{};
    
    // 기본 메트릭
    analysis['promptLength'] = prompt.length;
    analysis['wordCount'] = words.length;
    
    // 구조 분석
    analysis['hasSections'] = {
      'requirements': prompt.contains('REQUIREMENTS:'),
      'format': prompt.contains('FORMAT:'),
      'character': prompt.contains('CHARACTER:'),
      'scenario': prompt.contains('SCENARIO:'),
      'advanced': prompt.contains('ADVANCED CONTEXT:'),
    };
    
    // 품질 점수
    int qualityScore = 0;
    
    // 적절한 길이 (1000-3000자)
    if (prompt.length >= 1000 && prompt.length <= 3000) qualityScore += 20;
    
    // 모든 필수 섹션 포함
    if (analysis['hasSections']['requirements'] && 
        analysis['hasSections']['format']) qualityScore += 30;
    
    // 추가 컨텍스트
    if (analysis['hasSections']['character'] || 
        analysis['hasSections']['scenario']) qualityScore += 20;
    
    // 고급 설정
    if (analysis['hasSections']['advanced']) qualityScore += 10;
    
    // 시나리오 품질
    if (scenario != null) {
      bool hasRecommended = PromptValidationRules.recommendedPhrases
          .any((phrase) => scenario.contains(phrase));
      if (hasRecommended) qualityScore += 10;
      
      bool hasProhibited = PromptValidationRules.prohibitedPhrases
          .any((phrase) => scenario.contains(phrase));
      if (!hasProhibited) qualityScore += 10;
    }
    
    analysis['qualityScore'] = qualityScore;
    analysis['qualityGrade'] = _getQualityGrade(qualityScore);
    
    return analysis;
  }

  /// 품질 등급 계산
  String _getQualityGrade(int score) {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    return 'D';
  }
}
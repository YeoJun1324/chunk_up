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
      // 프롬프트 섹션들을 순서대로 조립
      final sections = <String>[];
      
      // 1. 필수 섹션들 추가
      _addRequiredSections(sections, {
        'words': words,
        'minLength': minLength,
        'maxLength': maxLength,
      });
      
      // 2. 출력 형식 추가
      _addFormatSection(sections, outputFormat);
      
      // 3. 고급 설정 추가
      if (advancedSettings != null) {
        _addAdvancedSettingsSection(sections, advancedSettings);
      }
      
      // 4. 캐릭터 정보 추가
      if (characterName != null) {
        _addCharacterSection(sections, 
          name: characterName,
          description: characterDescription,
          personality: characterPersonality,
          setting: characterSetting,
        );
      }
      
      // 5. 추가 캐릭터 정보 추가
      if (additionalCharacterNames?.isNotEmpty == true) {
        for (final name in additionalCharacterNames!) {
          // 추가 캐릭터는 간단한 정보만 추가
          sections.add('CHARACTER: $name');
        }
      }
      
      // 6. 관계 컨텍스트 추가
      if (relationshipContext?.isNotEmpty == true) {
        sections.add(relationshipContext!);
      }
      
      // 7. 시나리오 추가
      if (scenario?.isNotEmpty == true) {
        _addScenarioSection(sections, scenario!);
      }
      
      // 8. 검증 및 최적화
      final prompt = _optimizePrompt(sections.join('\n\n'));
      
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
    
    // 시점 추가
    if (settings.timePoint != null) {
      if (settings.timePoint == TimePoint.custom && settings.customTimePoint != null) {
        advancedParts.add('- Time Point: ${settings.customTimePoint}');
      } else {
        final config = PromptConfig.advancedOptions['timePoint'];
        final option = config?.options[settings.timePoint];
        if (option != null) {
          advancedParts.add('- Time Point: ${option.description}');
        }
      }
    }
    
    // 감정 상태 추가
    if (settings.emotionalState != null) {
      final config = PromptConfig.advancedOptions['emotionalState'];
      final option = config?.options[settings.emotionalState];
      if (option != null) {
        advancedParts.add('- Emotional State: ${option.description}');
      }
    }
    
    // 톤 추가
    if (settings.tone != null) {
      final config = PromptConfig.advancedOptions['tone'];
      final option = config?.options[settings.tone];
      if (option != null) {
        advancedParts.add('- Tone: ${option.description}');
      }
    }
    
    // 커스텀 설정 추가
    if (settings.customSetting?.isNotEmpty == true) {
      advancedParts.add('- Setting: ${settings.customSetting}');
    }
    
    // 특별 요소 추가
    if (settings.specialElements?.isNotEmpty == true) {
      advancedParts.add('- Special Elements: ${settings.specialElements!.join(', ')}');
    }
    
    if (advancedParts.isNotEmpty) {
      sections.add('ADVANCED CONTEXT:\n${advancedParts.join('\n')}');
    }
  }

  /// 캐릭터 섹션 추가
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

  /// 프롬프트 최적화
  String _optimizePrompt(String prompt) {
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

  /// 폴백 프롬프트 생성
  String _buildFallbackPrompt(List<String> words, int minLength, int maxLength) {
    return '''
Create an educational paragraph using these English words: ${words.join(', ')}

Requirements:
- Use each word exactly once
- Length: $minLength-$maxLength words
- Natural flow and context
- Educational content

Return JSON format:
{
  "englishContent": "...",
  "koreanTranslation": "...",
  "wordExplanations": {
    "word1": "이 단어가 문맥에서 어떻게 사용되었는지 한국어로 설명",
    "word2": "이 단어가 문맥에서 어떻게 사용되었는지 한국어로 설명"
  }
}
''';
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
import 'prompt_templates.dart';

/// 프롬프트 설정을 관리하는 클래스
/// 유지보수성을 위해 프롬프트 관련 설정을 중앙화
class PromptConfig {
  // 프롬프트 버전 관리
  static const String version = '1.0.0';
  
  // 프롬프트 구성 요소를 모듈화
  static const Map<String, PromptSection> sections = {
    'intro': PromptSection(
      id: 'intro',
      content: 'You are a creative writer helping students learn vocabulary through contextual stories.',
      required: true,
      order: 1,
    ),
    'task': PromptSection(
      id: 'task',
      content: 'TASK: Create a cohesive and engaging paragraph that naturally incorporates ALL the following vocabulary words.',
      required: true,
      order: 2,
    ),
    'requirements': PromptSection(
      id: 'requirements',
      template: '''
REQUIREMENTS:
1. Use EVERY word from the list at least once
2. Maintain natural flow - words should fit contextually
3. Keep the content appropriate and educational
4. Length: {minLength}-{maxLength} words
5. Make the content engaging and memorable
6. Ensure vocabulary usage helps students understand word meanings through context''',
      required: true,
      order: 5,
      variables: ['minLength', 'maxLength'],
    ),
    'outputFormat': PromptSection(
      id: 'outputFormat',
      template: '''
OUTPUT FORMAT:
Return a JSON object with this structure:
{
  "englishContent": "The generated paragraph in English",
  "koreanTranslation": "Korean translation of the paragraph",
  "wordExplanations": {
    "word1": "이 단어가 문맥에서 어떻게 사용되었는지 한국어로 설명",
    "word2": "이 단어가 문맥에서 어떻게 사용되었는지 한국어로 설명"
  }
}''',
      required: true,
      order: 10,
    ),
    'reminder': PromptSection(
      id: 'reminder',
      content: 'Remember: Quality over complexity. Focus on creating content that helps students learn.',
      required: true,
      order: 11,
    ),
  };

  // 출력 형식별 프롬프트 설정
  static final Map<OutputFormat, FormatConfig> formatConfigs = {
    OutputFormat.dialogue: FormatConfig(
      name: '대화문',
      icon: 'chat',
      instruction: '''
FORMAT: Write as a dialogue between characters
- Use quotation marks for speech
- Include dialogue tags (he said, she replied, etc.)
- Show character interactions and reactions
- Natural conversation flow
- Each character should speak in their unique voice and style''',
      examples: [
        '"I\'ve been looking for this book everywhere," Sarah exclaimed.',
        'John replied, "Maybe we should check the library\'s rare collection."',
      ],
    ),
    OutputFormat.monologue: FormatConfig(
      name: '독백',
      icon: 'person',
      instruction: '''
FORMAT: Write as a character's monologue
- First-person perspective from the character
- Direct address to audience or specific person
- Emotional and personal tone
- Character's voice and speaking style
- Internal thoughts and feelings revealed''',
      examples: [
        'I stand before you today, not as a hero, but as someone who has learned...',
        'You might wonder why I chose this path. Let me tell you...',
      ],
    ),
    OutputFormat.narrative: FormatConfig(
      name: '나레이션',
      icon: 'book',
      instruction: '''
FORMAT: Write as third-person narrative
- Descriptive storytelling style
- Include actions, thoughts, and environment
- Balanced pace with scene-setting
- Literary narrative voice
- Show don't tell approach''',
      examples: [
        'The morning sun cast long shadows across the empty street...',
        'She moved through the crowd, her eyes searching for a familiar face...',
      ],
    ),
    OutputFormat.thought: FormatConfig(
      name: '내적 독백',
      icon: 'psychology',
      instruction: '''
FORMAT: Write as internal thoughts/stream of consciousness
- First-person internal perspective
- Raw, unfiltered thoughts
- Fragmented or flowing as appropriate
- Intimate and psychological
- Character's personality reflected in thought patterns''',
      examples: [
        'Why did I say that? I should have kept quiet. No, wait...',
        'The rain... it reminds me of that day. I can almost smell...',
      ],
    ),
    OutputFormat.letter: FormatConfig(
      name: '편지/일기',
      icon: 'email',
      instruction: '''
FORMAT: Write as a letter or diary entry
- Written communication format
- Date/greeting as appropriate
- Personal writing style
- Character's voice in written form
- Closing signature matching the character''',
      examples: [
        'Dear Friend, I hope this letter finds you well...',
        'Day 42: The expedition continues, and I must record...',
      ],
    ),
    OutputFormat.description: FormatConfig(
      name: '상황 묘사',
      icon: 'landscape',
      instruction: '''
FORMAT: Write as scene/situation description
- Focus on environment and atmosphere
- Sensory details
- Character actions and positions
- Mood and tone setting
- Cinematic description style''',
      examples: [
        'The abandoned factory loomed against the storm clouds...',
        'In the corner of the bustling café, two figures sat...',
      ],
    ),
  };

  // 고급 설정 구성
  static const Map<String, AdvancedOptionConfig> advancedOptions = {
    'timePoint': AdvancedOptionConfig(
      id: 'timePoint',
      label: '시점',
      type: OptionType.single,
      options: <TimePoint, OptionDetail>{
        TimePoint.beforeEvent: OptionDetail(
          label: '사건 전',
          description: 'Before the main event, building anticipation',
          promptHint: 'Set the scene before the main action',
        ),
        TimePoint.duringEvent: OptionDetail(
          label: '사건 중',
          description: 'During the main event, in the heat of the moment',
          promptHint: 'Focus on immediate action and reactions',
        ),
        TimePoint.afterEvent: OptionDetail(
          label: '사건 후',
          description: 'After the event, dealing with consequences',
          promptHint: 'Show aftermath and reflection',
        ),
        TimePoint.flashback: OptionDetail(
          label: '회상',
          description: 'A flashback to an earlier time',
          promptHint: 'Connect past events to present',
        ),
        TimePoint.climax: OptionDetail(
          label: '클라이맥스',
          description: 'At the climactic moment of tension',
          promptHint: 'Maximum tension and stakes',
        ),
        TimePoint.resolution: OptionDetail(
          label: '해결 후',
          description: 'After resolution, finding peace or closure',
          promptHint: 'Show new equilibrium',
        ),
      },
    ),
    'emotionalState': AdvancedOptionConfig(
      id: 'emotionalState',
      label: '감정 상태',
      type: OptionType.single,
      options: <EmotionalState, OptionDetail>{
        EmotionalState.desperate: OptionDetail(
          label: '절망적인',
          description: 'Feeling desperate and at wit\'s end',
          promptHint: 'Show character at their lowest',
        ),
        EmotionalState.determined: OptionDetail(
          label: '결의에 찬',
          description: 'Filled with determination and resolve',
          promptHint: 'Show unwavering commitment',
        ),
        EmotionalState.confused: OptionDetail(
          label: '혼란스러운',
          description: 'Confused and uncertain about the situation',
          promptHint: 'Reflect inner conflict',
        ),
        EmotionalState.melancholic: OptionDetail(
          label: '우울한',
          description: 'Melancholic and contemplative mood',
          promptHint: 'Subtle sadness and reflection',
        ),
        EmotionalState.hopeful: OptionDetail(
          label: '희망적인',
          description: 'Hopeful despite the circumstances',
          promptHint: 'Light in darkness',
        ),
        EmotionalState.angry: OptionDetail(
          label: '분노한',
          description: 'Angry and frustrated',
          promptHint: 'Show controlled or explosive anger',
        ),
        EmotionalState.peaceful: OptionDetail(
          label: '평온한',
          description: 'At peace with the situation',
          promptHint: 'Calm acceptance',
        ),
        EmotionalState.anxious: OptionDetail(
          label: '불안한',
          description: 'Anxious and worried about what\'s to come',
          promptHint: 'Show nervousness and worry',
        ),
      },
    ),
    'tone': AdvancedOptionConfig(
      id: 'tone',
      label: '톤/분위기',
      type: OptionType.single,
      options: <Tone, OptionDetail>{
        Tone.serious: OptionDetail(
          label: '진지한',
          description: 'Serious and weighty tone',
          promptHint: 'Gravitas and importance',
        ),
        Tone.tragic: OptionDetail(
          label: '비극적인',
          description: 'Tragic and sorrowful atmosphere',
          promptHint: 'Inevitable sadness',
        ),
        Tone.hopeful: OptionDetail(
          label: '희망적인',
          description: 'Hopeful and optimistic tone',
          promptHint: 'Positive outlook',
        ),
        Tone.dark: OptionDetail(
          label: '어두운',
          description: 'Dark and ominous mood',
          promptHint: 'Foreboding atmosphere',
        ),
        Tone.nostalgic: OptionDetail(
          label: '향수적인',
          description: 'Nostalgic and reminiscent feeling',
          promptHint: 'Bittersweet memories',
        ),
        Tone.tense: OptionDetail(
          label: '긴장감 있는',
          description: 'Tense and suspenseful atmosphere',
          promptHint: 'Edge of seat tension',
        ),
        Tone.intimate: OptionDetail(
          label: '친밀한',
          description: 'Intimate and personal tone',
          promptHint: 'Close and personal',
        ),
        Tone.philosophical: OptionDetail(
          label: '철학적인',
          description: 'Philosophical and contemplative mood',
          promptHint: 'Deep thoughts and meaning',
        ),
      },
    ),
  };

  // 캐릭터별 프롬프트 커스터마이징
  static const Map<String, CharacterPromptOverride> characterOverrides = {
    '셜록 홈즈': CharacterPromptOverride(
      additionalContext: 'Use deductive reasoning and observational details.',
      vocabularyHints: 'Include detective-related vocabulary when possible.',
      styleGuide: 'Analytical, precise language with occasional dry wit.',
    ),
    '어린 왕자': CharacterPromptOverride(
      additionalContext: 'Use simple yet profound observations about life.',
      vocabularyHints: 'Focus on emotional and philosophical vocabulary.',
      styleGuide: 'Innocent, questioning tone with deep insights.',
    ),
    '도로시 게일': CharacterPromptOverride(
      additionalContext: 'Show homesickness and wonder at new experiences.',
      vocabularyHints: 'Balance everyday vocabulary with fantastical elements.',
      styleGuide: 'Earnest, brave, with Midwestern American speech patterns.',
    ),
  };
}

/// 프롬프트 섹션 정의
class PromptSection {
  final String id;
  final String? content;
  final String? template;
  final bool required;
  final int order;
  final List<String>? variables;

  const PromptSection({
    required this.id,
    this.content,
    this.template,
    required this.required,
    required this.order,
    this.variables,
  });

  String render(Map<String, dynamic>? values) {
    if (content != null) return content!;
    if (template != null && values != null) {
      String result = template!;
      variables?.forEach((variable) {
        if (values.containsKey(variable)) {
          result = result.replaceAll('{$variable}', values[variable].toString());
        }
      });
      return result;
    }
    return '';
  }
}

/// 출력 형식 설정
class FormatConfig {
  final String name;
  final String icon;
  final String instruction;
  final List<String> examples;

  const FormatConfig({
    required this.name,
    required this.icon,
    required this.instruction,
    required this.examples,
  });
}

/// 고급 옵션 설정
class AdvancedOptionConfig {
  final String id;
  final String label;
  final OptionType type;
  final Map<dynamic, OptionDetail> options;

  const AdvancedOptionConfig({
    required this.id,
    required this.label,
    required this.type,
    required this.options,
  });
}

/// 옵션 상세 정보
class OptionDetail {
  final String label;
  final String description;
  final String promptHint;

  const OptionDetail({
    required this.label,
    required this.description,
    required this.promptHint,
  });
}

/// 옵션 타입
enum OptionType {
  single,
  multiple,
  text,
}

/// 캐릭터별 프롬프트 오버라이드
class CharacterPromptOverride {
  final String? additionalContext;
  final String? vocabularyHints;
  final String? styleGuide;

  const CharacterPromptOverride({
    this.additionalContext,
    this.vocabularyHints,
    this.styleGuide,
  });
}

/// 프롬프트 품질 검증 규칙
class PromptValidationRules {
  static const int minWordCount = 5;
  static const int maxWordCount = 25;
  static const int minScenarioLength = 10;
  static const int maxScenarioLength = 200;
  
  static const List<String> prohibitedPhrases = [
    '몇 화',
    '몇 분',
    '몇 초',
    'episode',
    'minute',
    'second',
  ];
  
  static const List<String> recommendedPhrases = [
    '상황',
    '감정',
    '분위기',
    'situation',
    'feeling',
    'atmosphere',
  ];
}
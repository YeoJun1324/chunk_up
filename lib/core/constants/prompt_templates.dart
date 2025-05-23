import 'prompt_config.dart';

/// 프롬프트 템플릿 상수 및 관련 설정
class PromptTemplates {
  // 출력 형식별 프롬프트 지시문
  static const Map<OutputFormat, String> formatInstructions = {
    OutputFormat.dialogue: """
FORMAT: Write as a dialogue between characters
- Use quotation marks for speech
- Include dialogue tags (he said, she replied, etc.)
- Show character interactions and reactions
- Natural conversation flow
- Each character should speak in their unique voice and style""",
    
    OutputFormat.monologue: """
FORMAT: Write as a character's monologue
- First-person perspective from the character
- Direct address to audience or specific person
- Emotional and personal tone
- Character's voice and speaking style
- Internal thoughts and feelings revealed""",
    
    OutputFormat.narrative: """
FORMAT: Write as third-person narrative
- Descriptive storytelling style
- Include actions, thoughts, and environment
- Balanced pace with scene-setting
- Literary narrative voice
- Show don't tell approach""",
    
    OutputFormat.thought: """
FORMAT: Write as internal thoughts/stream of consciousness
- First-person internal perspective
- Raw, unfiltered thoughts
- Fragmented or flowing as appropriate
- Intimate and psychological
- Character's personality reflected in thought patterns""",
    
    OutputFormat.letter: """
FORMAT: Write as a letter or diary entry
- Written communication format
- Date/greeting as appropriate
- Personal writing style
- Character's voice in written form
- Closing signature matching the character""",
    
    OutputFormat.description: """
FORMAT: Write as scene/situation description
- Focus on environment and atmosphere
- Sensory details
- Character actions and positions
- Mood and tone setting
- Cinematic description style""",
  };

  // 시점별 설명
  static const Map<TimePoint, String> timePointDescriptions = {
    TimePoint.beforeEvent: "Before the main event, building anticipation",
    TimePoint.duringEvent: "During the main event, in the heat of the moment",
    TimePoint.afterEvent: "After the event, dealing with consequences",
    TimePoint.flashback: "A flashback to an earlier time",
    TimePoint.climax: "At the climactic moment of tension",
    TimePoint.resolution: "After resolution, finding peace or closure",
  };

  // 감정 상태별 설명
  static const Map<EmotionalState, String> emotionalDescriptions = {
    EmotionalState.desperate: "Feeling desperate and at wit's end",
    EmotionalState.determined: "Filled with determination and resolve",
    EmotionalState.confused: "Confused and uncertain about the situation",
    EmotionalState.melancholic: "Melancholic and contemplative mood",
    EmotionalState.hopeful: "Hopeful despite the circumstances",
    EmotionalState.angry: "Angry and frustrated",
    EmotionalState.peaceful: "At peace with the situation",
    EmotionalState.anxious: "Anxious and worried about what's to come",
  };

  // 톤별 설명
  static const Map<Tone, String> toneDescriptions = {
    Tone.serious: "Serious and weighty tone",
    Tone.tragic: "Tragic and sorrowful atmosphere",
    Tone.hopeful: "Hopeful and optimistic tone",
    Tone.dark: "Dark and ominous mood",
    Tone.nostalgic: "Nostalgic and reminiscent feeling",
    Tone.tense: "Tense and suspenseful atmosphere",
    Tone.intimate: "Intimate and personal tone",
    Tone.philosophical: "Philosophical and contemplative mood",
  };

  // 기본 프롬프트 템플릿
  static const String basePromptTemplate = """
You are a creative writer helping students learn vocabulary through contextual stories.

TASK: Create a cohesive and engaging paragraph that naturally incorporates ALL the following vocabulary words.

VOCABULARY WORDS TO INCLUDE:
{words}

{formatInstruction}

{advancedContext}

REQUIREMENTS:
1. Use EVERY word from the list at least once
2. Maintain natural flow - words should fit contextually
3. Keep the content appropriate and educational
4. Length: {minLength}-{maxLength} words
5. Make the content engaging and memorable
6. Ensure vocabulary usage helps students understand word meanings through context

{characterContext}

{scenarioContext}

OUTPUT FORMAT:
Return a JSON object with this structure:
{
  "englishContent": "The generated paragraph in English",
  "koreanTranslation": "Korean translation of the paragraph",
  "wordExplanations": {
    "word1": "이 단어가 문맥에서 어떻게 사용되었는지 한국어로 설명",
    "word2": "이 단어가 문맥에서 어떻게 사용되었는지 한국어로 설명"
  }
}

Remember: Quality over complexity. Focus on creating content that helps students learn.
""";

  // 캐릭터 컨텍스트 템플릿
  static const String characterContextTemplate = """
CHARACTER CONTEXT:
- Character: {characterName}
- Description: {characterDescription}
- Personality: {characterPersonality}
- Setting: {characterSetting}

Write in a way that reflects this character's personality and situation.
""";

  // 시나리오 컨텍스트 템플릿
  static const String scenarioContextTemplate = """
SCENARIO:
{scenario}

Incorporate this scenario naturally into the content.
""";

  // 고급 컨텍스트 템플릿
  static const String advancedContextTemplate = """
ADVANCED CONTEXT:
{timePoint}
{emotionalState}
{tone}
{customSetting}
{specialElements}
""";
}

// 출력 형식 열거형
enum OutputFormat {
  dialogue,     // 대화문
  monologue,    // 독백
  narrative,    // 나레이션
  letter,       // 편지/일기
  thought,      // 내적 독백
  description,  // 상황 묘사
}

// 시점 열거형
enum TimePoint {
  beforeEvent,    // 사건 전
  duringEvent,    // 사건 중
  afterEvent,     // 사건 후
  flashback,      // 회상
  climax,         // 클라이맥스
  resolution,     // 해결 후
  custom,         // 사용자 정의
}

// 감정 상태 열거형
enum EmotionalState {
  desperate,      // 절망적인
  determined,     // 결의에 찬
  confused,       // 혼란스러운
  melancholic,    // 우울한
  hopeful,        // 희망적인
  angry,          // 분노한
  peaceful,       // 평온한
  anxious,        // 불안한
}

// 톤 열거형
enum Tone {
  serious,        // 진지한
  tragic,         // 비극적인
  hopeful,        // 희망적인
  dark,           // 어두운
  nostalgic,      // 향수적인
  tense,          // 긴장감 있는
  intimate,       // 친밀한
  philosophical,  // 철학적인
}

// 고급 설정 클래스
class AdvancedSettings {
  final TimePoint? timePoint;
  final String? customTimePoint;
  final EmotionalState? emotionalState;
  final Tone? tone;
  final String? customSetting;
  final List<String>? specialElements;

  const AdvancedSettings({
    this.timePoint,
    this.customTimePoint,
    this.emotionalState,
    this.tone,
    this.customSetting,
    this.specialElements,
  });

  // 고급 컨텍스트를 문자열로 변환
  String toContextString() {
    final parts = <String>[];
    
    if (timePoint != null) {
      parts.add('- Time Point: ${PromptTemplates.timePointDescriptions[timePoint]}');
    }
    
    if (emotionalState != null) {
      parts.add('- Emotional State: ${PromptTemplates.emotionalDescriptions[emotionalState]}');
    }
    
    if (tone != null) {
      parts.add('- Tone: ${PromptTemplates.toneDescriptions[tone]}');
    }
    
    if (customSetting?.isNotEmpty == true) {
      parts.add('- Setting: $customSetting');
    }
    
    if (specialElements?.isNotEmpty == true) {
      parts.add('- Special Elements: ${specialElements!.join(', ')}');
    }
    
    return parts.isEmpty ? '' : parts.join('\n');
  }
}

// 프롬프트 빌더 헬퍼 클래스
class PromptBuilder {
  static String buildPrompt({
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
  }) {
    String prompt = PromptTemplates.basePromptTemplate;
    
    // 단어 목록 삽입
    prompt = prompt.replaceAll('{words}', words.join(', '));
    
    // 출력 형식 지시문 삽입
    prompt = prompt.replaceAll(
      '{formatInstruction}', 
      PromptTemplates.formatInstructions[outputFormat] ?? ''
    );
    
    // 길이 설정
    prompt = prompt.replaceAll('{minLength}', minLength.toString());
    prompt = prompt.replaceAll('{maxLength}', maxLength.toString());
    
    // 고급 컨텍스트 삽입
    final advancedContext = advancedSettings?.toContextString() ?? '';
    prompt = prompt.replaceAll('{advancedContext}', advancedContext);
    
    // 캐릭터 컨텍스트 삽입
    if (characterName?.isNotEmpty == true) {
      String characterContext = PromptTemplates.characterContextTemplate;
      characterContext = characterContext.replaceAll('{characterName}', characterName!);
      characterContext = characterContext.replaceAll('{characterDescription}', characterDescription ?? '');
      characterContext = characterContext.replaceAll('{characterPersonality}', characterPersonality ?? '');
      characterContext = characterContext.replaceAll('{characterSetting}', characterSetting ?? '');
      prompt = prompt.replaceAll('{characterContext}', characterContext);
    } else {
      prompt = prompt.replaceAll('{characterContext}', '');
    }
    
    // 시나리오 컨텍스트 삽입
    if (scenario?.isNotEmpty == true) {
      String scenarioContext = PromptTemplates.scenarioContextTemplate;
      scenarioContext = scenarioContext.replaceAll('{scenario}', scenario!);
      prompt = prompt.replaceAll('{scenarioContext}', scenarioContext);
    } else {
      prompt = prompt.replaceAll('{scenarioContext}', '');
    }
    
    return prompt.trim();
  }
}
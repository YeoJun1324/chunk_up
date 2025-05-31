// lib/core/constants/prompt_templates.dart
import 'prompt_config.dart';

/// 프롬프트 템플릿 상수
class PromptTemplates {
  // 기본 프롬프트 템플릿
  static const String basePromptTemplate = """
You are an expert educational content creator specializing in contextual vocabulary learning.

Your task is to create an engaging, natural story that teaches vocabulary through context.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 VOCABULARY WORDS TO INCLUDE:
{words}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 REQUIREMENTS:
• Word Count: Between {minLength} and {maxLength} words
• Include ALL vocabulary words naturally in the content
• Each word should be used in a meaningful context that demonstrates its meaning
• The content should flow naturally and be engaging

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{outputFormat}

{characterContext}

{scenarioContext}

{advancedContext}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 OUTPUT FORMAT (JSON):
```json
{
  "title": "Creative title for the content",
  "englishContent": "The main content in English with vocabulary words naturally integrated",
  "koreanTranslation": "Natural Korean translation of the entire content",
  "wordMappings": {
    "vocabulary_word_1": "한국어 뜻",
    "vocabulary_word_2": "한국어 뜻"
  },
  "wordExplanations": {
    "vocabulary_word_1": "한국어 뜻: 이 문맥에서 이 단어가 어떻게 사용되었는지에 대한 설명",
    "vocabulary_word_2": "한국어 뜻: 이 문맥에서 이 단어가 어떻게 사용되었는지에 대한 설명"
  }
}
```

⚠️ CRITICAL REQUIREMENTS:

📝 CONTENT REQUIREMENTS:
• Title: Creative and relevant to the story content
• Vocabulary: Each vocabulary word MUST appear in the English content
• Story: Keep coherent and engaging throughout
• NO EMPHASIS: Do NOT use *, _, **, or any other markers to emphasize vocabulary words or translations
• PLAIN TEXT ONLY: All vocabulary words must appear as plain text in the English content
• NO MARKDOWN: Avoid bold, italic, or any markdown formatting in the content

🎭 CANON COMPLIANCE (when using existing works/characters):
• If the character is from an existing work (movie, book, game, etc.), strictly maintain:
  - Character personality, speech patterns, and behavioral traits
  - World-building rules and lore consistency
  - Canonical relationships and power dynamics
  - Setting-appropriate technology, magic systems, or physics
  - Timeline consistency if a specific time point is mentioned
• Examples:
  - Sherlock Holmes: Victorian-era setting, deductive reasoning, British mannerisms
  - Harry Potter characters: Consistent with magical rules, house traits, British wizarding culture
  - Marvel/DC characters: Respect established powers, relationships, and universe rules
• Do NOT introduce elements that contradict the source material

🔄 TRANSLATION REQUIREMENTS:
• Korean translation: Natural translation without special formatting
• 1:1 Mapping: SAME NUMBER of sentences in English and Korean
  - Count sentences by ||| delimiters
  - Each English ||| must have corresponding Korean |||
  - Complex sentences (colons, semicolons, lists) remain as single units

📊 JSON FIELD REQUIREMENTS:
• wordMappings: English word → Korean translation
• wordExplanations: Korean format required - THIS FIELD IS MANDATORY
  - Structure: "한국어 뜻: 문맥상 사용 설명"
  - Example: "포괄적인: 이 문맥에서는 사건 파일이 모든 관련 정보를 빠짐없이 담고 있다는 의미로 사용되었습니다"
  - MUST include explanations for ALL vocabulary words
  - Do NOT leave wordExplanations empty or omit this field

⚡ SENTENCE DELIMITER RULES (|||):
• Add ||| at the end of EVERY sentence WITHOUT any following space
• Sentence ending guidelines:
  a) Standard: End at . ! ? + ||| (NO SPACE)
     ✓ Dr. Watson observed the temperature was 98.6 degrees.|||
     ✗ Dr.||| Watson observed...
  
  b) Dialogue + Attribution: Keep together
     ✓ "Hello," he said.|||
     ✓ "Hmm," Watson pondered.|||
     ✗ "Hello,"|||
  
  c) Lists/Enumerations: Single sentence
     ✓ Holmes noted: first, the time; second, the place.|||
  
  d) Ellipsis/Dash: End at punctuation
     ✓ "I was thinking..."|||He paused.|||
     ✓ "Wait—"|||The door slammed.|||
  
  e) Parentheses/Brackets: Include in sentence
     ✓ The report stated (see Appendix A).|||
  
  f) Interjections/Onomatopoeia:
     ✓ "Aha!"|||Bang!||| (standalone)
     ✓ "Click!" went the lock.||| (with attribution)

⚠️ CRITICAL: NO SPACE after |||
⚠️ FINAL CHECK: English and Korean MUST have EXACTLY the same number of ||| delimiters

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
""";

  // 출력 형식별 지시문
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
    
    OutputFormat.letter: """
FORMAT: Write as a letter or diary entry
- Written communication format
- Date/greeting as appropriate
- Personal writing style
- Character's voice in written form
- Closing signature matching the character""",
    
    OutputFormat.thought: """
FORMAT: Write as internal thoughts/stream of consciousness
- First-person internal perspective
- Raw, unfiltered thoughts
- Fragmented or flowing as appropriate
- Intimate and psychological
- Character's personality reflected in thought patterns""",
    
    OutputFormat.description: """
FORMAT: Write as scene/situation description
- Focus on environment and atmosphere
- Sensory details
- Character actions and positions
- Mood and tone setting
- Cinematic description style""",
  };

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
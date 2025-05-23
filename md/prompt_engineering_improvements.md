# 프롬프트 엔지니어링 개선사항 문서

## 현재 상황 분석

### 기존 GenerateChunkUseCase의 문제점
1. **단일 details 필드로 모든 맥락 정보를 처리** - 구체성 부족
2. **출력 형식 고정** - 대화문, 독백, 나레이션 등 다양한 형식 지원 불가
3. **AI 지식 한계 미고려** - 구체적인 에피소드 정보 요구 시 부정확한 결과
4. **사용자 가이드 부족** - 좋은 프롬프트 작성법에 대한 안내 없음

## 주요 개선사항

### 1. 출력 형식 선택 기능 추가

```dart
enum OutputFormat {
  dialogue,     // 대화문 - 캐릭터 간 대화
  monologue,    // 독백 - 한 캐릭터의 연설/고백
  narrative,    // 나레이션 - 3인칭 서술
  letter,       // 편지/일기 - 문서 형식
  thought,      // 내적 독백 - 생각의 흐름
  description,  // 상황 묘사 - 환경/상황 중심
}
```

**구현 방법:**
- GenerateChunkParams에 outputFormat 필드 추가
- 각 형식별 프롬프트 템플릿 작성
- UI에서 ChoiceChip으로 형식 선택 인터페이스 제공

### 2. 세분화된 고급 설정 시스템

기존 `details` 필드를 다음과 같이 세분화:

```dart
class AdvancedSettings {
  final TimePoint? timePoint;           // 시점 (사건 전/중/후)
  final EmotionalState? emotionalState; // 감정 상태
  final Tone? tone;                     // 분위기/톤
  final String? customSetting;          // 구체적 배경/환경
  final List<String>? specialElements;  // 포함할 특별 요소들
  final Relationship? relationship;     // 캐릭터 간 관계
}

enum TimePoint {
  beforeEvent,    // 사건 전
  duringEvent,    // 사건 중  
  afterEvent,     // 사건 후
  flashback,      // 회상
  climax,         // 클라이맥스
  resolution,     // 해결 후
}

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
```

### 3. 프롬프트 템플릿 시스템 개선

```dart
class EnhancedPromptTemplate {
  // 출력 형식별 프롬프트 지시문
  static Map<OutputFormat, String> formatInstructions = {
    OutputFormat.dialogue: """
FORMAT: Write as a dialogue between characters
- Use quotation marks for speech
- Include dialogue tags (he said, she replied, etc.)
- Show character interactions and reactions
- Natural conversation flow
""",
    
    OutputFormat.monologue: """
FORMAT: Write as a character's monologue
- First-person perspective from the character
- Direct address to audience or specific person
- Emotional and personal tone
- Character's voice and speaking style
""",
    
    OutputFormat.narrative: """
FORMAT: Write as third-person narrative
- Descriptive storytelling style
- Include actions, thoughts, and environment
- Balanced pace with scene-setting
- Literary narrative voice
""",
    
    OutputFormat.thought: """
FORMAT: Write as internal thoughts/stream of consciousness
- First-person internal perspective
- Raw, unfiltered thoughts
- Fragmented or flowing as appropriate
- Intimate and psychological
""",
  };
  
  // 고급 설정을 프롬프트에 반영
  static String buildAdvancedContext(AdvancedSettings advanced) {
    String context = "\n\nADVANCED CONTEXT:\n";
    
    if (advanced.timePoint != null) {
      context += "- Time Point: ${_getTimePointDescription(advanced.timePoint!)}\n";
    }
    
    if (advanced.emotionalState != null) {
      context += "- Emotional State: ${_getEmotionalDescription(advanced.emotionalState!)}\n";
    }
    
    if (advanced.tone != null) {
      context += "- Tone: ${_getToneDescription(advanced.tone!)}\n";
    }
    
    if (advanced.customSetting?.isNotEmpty == true) {
      context += "- Setting: ${advanced.customSetting}\n";
    }
    
    if (advanced.specialElements?.isNotEmpty == true) {
      context += "- Special Elements: ${advanced.specialElements!.join(', ')}\n";
    }
    
    return context;
  }
}
```

### 4. AI 지식 한계 대응 방안

**문제:** AI가 구체적인 에피소드나 세부 장면을 정확히 모를 수 있음

**해결책:**
1. **일반적 상황 표현 유도**
   ```dart
   // 피해야 할 방식
   "3화 마지막 장면에서..."
   
   // 권장하는 방식  
   "베아트리체가 배틀러를 조롱하며 우위에 서 있는 상황에서..."
   ```

2. **캐릭터 상태 중심 가이드**
   ```dart
   class ContextGuideHelper {
     static List<String> getContextExamples(String character) {
       switch(character.toLowerCase()) {
         case "오카베":
           return [
             "수많은 시간도약으로 지쳐있는 상태",
             "마유리의 죽음을 막지 못해 절망한 상황", 
             "크리스와의 관계에서 갈등하는 순간",
           ];
       }
     }
   }
   ```

3. **상황 템플릿 제공**
   ```dart
   class ContextTemplate {
     final String title;
     final String description;
     final String promptGuideline;
     
     static List<ContextTemplate> getTemplatesFor(String series) {
       // 시리즈별 일반적 상황 템플릿 제공
     }
   }
   ```

### 5. 사용자 가이드 시스템

```dart
class UserGuideWidget extends StatelessWidget {
  Widget buildContextGuide() {
    return Card(
      child: ExpansionTile(
        title: Text("💡 더 좋은 결과를 위한 팁"),
        children: [
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text("좋은 예시"),
            subtitle: Text("마유리가 죽은 직후 절망에 빠진 오카베가 크리스에게..."),
          ),
          ListTile(
            leading: Icon(Icons.cancel, color: Colors.red),
            title: Text("피할 예시"), 
            subtitle: Text("12화 15분 32초 장면에서..."),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "구체적인 화수나 시간보다는 캐릭터의 감정 상태나 상황을 설명해주시면 더 정확한 결과를 얻을 수 있습니다.",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 6. UI/UX 개선사항

**점진적 정보 공개 (Progressive Disclosure) 적용:**

```dart
class EnhancedGenerationWidget extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 기본 설정 (항상 표시)
        CharacterSelectionWidget(),
        ScenarioInputWidget(),
        WordSelectionWidget(),
        
        // 출력 형식 선택 (중요하므로 기본에 포함)
        OutputFormatSelectionWidget(),
        
        // 고급 설정 (선택사항)
        ExpansionTile(
          title: Text("고급 설정 (선택사항)"),
          children: [
            TimePointSelector(),
            EmotionalStateSelector(), 
            ToneSelector(),
            CustomSettingInput(),
            SpecialElementsInput(),
          ],
        ),
        
        // 사용자 가이드
        UserGuideWidget(),
        
        // 생성 버튼
        GenerateButton(),
      ],
    );
  }
}
```

### 7. 캐릭터 관리 시스템 개선

**시리즈별 폴더 구조:**

```dart
class Series {
  final String id;
  final String name;
  final String description;
  final List<Character> characters;
  final List<CharacterRelationship> relationships;
  final SeriesSettings settings;
  
  Series({
    required this.id,
    required this.name,
    required this.description,
    this.characters = const [],
    this.relationships = const [],
    required this.settings,
  });
}

class Character {
  final String id;
  final String name;
  final String seriesId;
  final String description;
  final String personality;
  final List<String> catchPhrases;
  final List<String> abilities;
  final String backgroundInfo;
  final String imageUrl;
  final List<String> tags;
  
  Character({
    required this.id,
    required this.name,
    required this.seriesId,
    required this.description,
    this.personality = '',
    this.catchPhrases = const [],
    this.abilities = const [],
    this.backgroundInfo = '',
    this.imageUrl = '',
    this.tags = const [],
  });
}

class CharacterRelationship {
  final String id;
  final String characterAId;
  final String characterBId;
  final RelationshipType type;
  final String description;
  final RelationshipStatus status;
  final List<String> keyEvents;
  
  CharacterRelationship({
    required this.id,
    required this.characterAId,
    required this.characterBId,
    required this.type,
    required this.description,
    this.status = RelationshipStatus.normal,
    this.keyEvents = const [],
  });
}

enum RelationshipType {
  romantic,        // 연인/로맨스
  friendship,      // 친구
  rivalry,         // 라이벌
  familial,        // 가족
  mentor,          // 스승/제자
  enemy,           // 적대관계
  colleague,       // 동료
  master,          // 주종관계
  complex,         // 복잡한 관계
}

enum RelationshipStatus {
  harmonious,      // 화목한
  tense,           // 긴장된
  conflicted,      // 갈등 중
  estranged,       // 소원한
  developing,      // 발전 중
  broken,          // 깨진
  normal,          // 평범한
}
```

**캐릭터 관리 UI 설계:**

```dart
class CharacterManagementScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("캐릭터 관리")),
      body: Row(
        children: [
          // 좌측 시리즈 폴더 트리
          Expanded(
            flex: 1,
            child: SeriesFolderTreeWidget(),
          ),
          
          // 우측 캐릭터 상세 관리
          Expanded(
            flex: 2,
            child: CharacterDetailWidget(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}

class SeriesFolderTreeWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return TreeView(
      nodes: [
        TreeNode(
          content: SeriesFolder(name: "슈타인즈 게이트"),
          children: [
            TreeNode(content: CharacterTile(name: "오카베 린타로")),
            TreeNode(content: CharacterTile(name: "마키세 크리스")),
            TreeNode(content: CharacterTile(name: "시이나 마유리")),
            TreeNode(content: RelationshipFolder()),
          ],
        ),
        TreeNode(
          content: SeriesFolder(name: "역전재판"),
          children: [
            TreeNode(content: CharacterTile(name: "나루호도 류이치")),
            TreeNode(content: CharacterTile(name: "미츠루기 레이지")),
            TreeNode(content: RelationshipFolder()),
          ],
        ),
      ],
    );
  }
}
```

**관계 관리 시스템:**

```dart
class RelationshipManager {
  // 관계 생성
  static CharacterRelationship createRelationship({
    required String characterAId,
    required String characterBId,
    required RelationshipType type,
    required String description,
  }) {
    return CharacterRelationship(
      id: generateId(),
      characterAId: characterAId,
      characterBId: characterBId,
      type: type,
      description: description,
    );
  }
  
  // 관계를 프롬프트에 반영
  static String buildRelationshipContext(
    String characterAId, 
    String characterBId,
    List<CharacterRelationship> relationships
  ) {
    final relationship = relationships.firstWhere(
      (r) => (r.characterAId == characterAId && r.characterBId == characterBId) ||
             (r.characterAId == characterBId && r.characterBId == characterAId),
      orElse: () => null,
    );
    
    if (relationship == null) return "";
    
    return """
RELATIONSHIP CONTEXT:
- Type: ${_getRelationshipTypeName(relationship.type)}
- Status: ${_getRelationshipStatusName(relationship.status)}
- Description: ${relationship.description}
- Consider this relationship dynamic in the dialogue/interaction
""";
  }
}
```

**관계 설정 UI:**

```dart
class RelationshipEditor extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("캐릭터 관계 설정", style: Theme.of(context).textTheme.headline6),
            
            // 캐릭터 A 선택
            DropdownButtonFormField<Character>(
              decoration: InputDecoration(labelText: "캐릭터 A"),
              items: availableCharacters.map((char) => 
                DropdownMenuItem(value: char, child: Text(char.name))
              ).toList(),
              onChanged: (value) => setState(() => characterA = value),
            ),
            
            // 캐릭터 B 선택  
            DropdownButtonFormField<Character>(
              decoration: InputDecoration(labelText: "캐릭터 B"),
              items: availableCharacters.map((char) => 
                DropdownMenuItem(value: char, child: Text(char.name))
              ).toList(),
              onChanged: (value) => setState(() => characterB = value),
            ),
            
            // 관계 유형
            DropdownButtonFormField<RelationshipType>(
              decoration: InputDecoration(labelText: "관계 유형"),
              items: RelationshipType.values.map((type) => 
                DropdownMenuItem(
                  value: type, 
                  child: Text(_getRelationshipTypeName(type))
                )
              ).toList(),
              onChanged: (value) => setState(() => relationshipType = value),
            ),
            
            // 관계 상태
            DropdownButtonFormField<RelationshipStatus>(
              decoration: InputDecoration(labelText: "현재 상태"),
              items: RelationshipStatus.values.map((status) => 
                DropdownMenuItem(
                  value: status, 
                  child: Text(_getRelationshipStatusName(status))
                )
              ).toList(),
              onChanged: (value) => setState(() => relationshipStatus = value),
            ),
            
            // 관계 설명
            TextField(
              decoration: InputDecoration(
                labelText: "관계 설명",
                hintText: "두 캐릭터의 관계를 구체적으로 설명하세요",
              ),
              maxLines: 3,
              onChanged: (value) => relationshipDescription = value,
            ),
            
            // 주요 사건들
            TextField(
              decoration: InputDecoration(
                labelText: "주요 사건 (선택사항)",
                hintText: "관계에 영향을 준 중요한 사건들",
              ),
              onChanged: (value) => keyEvents = value.split(','),
            ),
            
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveRelationship,
              child: Text("관계 저장"),
            ),
          ],
        ),
      ),
    );
  }
}
```

**관계 시각화:**

```dart
class RelationshipGraph extends StatelessWidget {
  final List<Character> characters;
  final List<CharacterRelationship> relationships;
  
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      child: CustomPaint(
        painter: RelationshipGraphPainter(
          characters: characters,
          relationships: relationships,
        ),
        child: Container(),
      ),
    );
  }
}

class RelationshipGraphPainter extends CustomPainter {
  final List<Character> characters;
  final List<CharacterRelationship> relationships;
  
  RelationshipGraphPainter({
    required this.characters,
    required this.relationships,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 캐릭터들을 원형으로 배치
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 3;
    
    // 캐릭터 노드 그리기
    for (int i = 0; i < characters.length; i++) {
      final angle = (i * 2 * math.pi) / characters.length;
      final position = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      
      _drawCharacterNode(canvas, position, characters[i]);
    }
    
    // 관계 연결선 그리기
    for (final relationship in relationships) {
      _drawRelationshipLine(canvas, relationship);
    }
  }
  
  void _drawCharacterNode(Canvas canvas, Offset position, Character character) {
    // 캐릭터 아바타/아이콘 그리기
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(position, 30, paint);
    
    // 캐릭터 이름 표시
    final textPainter = TextPainter(
      text: TextSpan(
        text: character.name,
        style: TextStyle(color: Colors.black, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(
      position.dx - textPainter.width / 2,
      position.dy + 35,
    ));
  }
  
  void _drawRelationshipLine(Canvas canvas, CharacterRelationship relationship) {
    // 관계 유형에 따른 선 스타일 변경
    final paint = Paint()
      ..color = _getRelationshipColor(relationship.type)
      ..strokeWidth = _getRelationshipWidth(relationship.type)
      ..style = PaintingStyle.stroke;
    
    // 점선 처리 (적대관계 등)
    if (relationship.type == RelationshipType.enemy) {
      paint.strokeWidth = 2;
      // 점선 효과 구현
    }
    
    // 두 캐릭터 위치 찾아서 연결선 그리기
    // ... 구현 생략
  }
}
```

**프롬프트 통합:**

```dart
class EnhancedPromptBuilder {
  String buildPromptWithRelationships(
    GenerateChunkParams params,
    List<CharacterRelationship> relationships,
  ) {
    String prompt = buildBasePrompt(params);
    
    // 다중 캐릭터 시나리오인 경우 관계 정보 추가
    if (params.involvedCharacters?.length > 1) {
      for (int i = 0; i < params.involvedCharacters.length - 1; i++) {
        for (int j = i + 1; j < params.involvedCharacters.length; j++) {
          final relationshipContext = RelationshipManager.buildRelationshipContext(
            params.involvedCharacters[i].id,
            params.involvedCharacters[j].id,
            relationships,
          );
          
          if (relationshipContext.isNotEmpty) {
            prompt += relationshipContext;
          }
        }
      }
    }
    
    return prompt;
  }
}
```

## 구현 우선순위

### Phase 1 (필수)
1. **출력 형식 선택 기능** - 즉시 체감할 수 있는 개선
2. **기본 고급 설정** - TimePoint, EmotionalState, Tone만 우선 구현
3. **프롬프트 템플릿 분리** - 유지보수성 향상

### Phase 2 (중요) 
1. **캐릭터 관리 시스템** - 시리즈별 폴더 구조 구현
2. **사용자 가이드 시스템** - 사용자 교육 효과
3. **상황 템플릿 제공** - AI 지식 한계 보완

### Phase 3 (고급)
1. **캐릭터 관계 시스템** - 관계 정의 및 프롬프트 반영
2. **관계 시각화** - 그래프 형태의 관계 관리 UI
3. **특별 요소 관리** - 시리즈별 특수 요소 데이터베이스
4. **프롬프트 품질 검증** - 자동 품질 평가 시스템

## 예상 효과

1. **사용자 경험 향상**: 더 구체적이고 원하는 스타일의 결과물 생성
2. **교육적 가치 증대**: 다양한 형식의 글을 통한 학습 효과
3. **AI 활용 최적화**: AI의 강점은 살리고 한계는 보완
4. **앱 차별화**: 단순한 단어 학습을 넘어선 맞춤형 콘텐츠 생성

## 기술적 고려사항

1. **프롬프트 길이 관리**: 고급 설정 추가로 인한 프롬프트 길이 증가 모니터링
2. **API 비용 최적화**: 불필요한 설정은 생략하도록 로직 구현
3. **캐시 시스템**: 자주 사용되는 프롬프트 템플릿 캐싱
4. **A/B 테스트**: 기존 방식 대비 개선된 방식의 품질 비교 측정

---

*이 문서는 영어 단어 학습 앱의 프롬프트 생성 품질 향상을 위한 종합적인 개선 방안을 제시합니다. 구현 시 사용자 피드백을 수집하여 지속적으로 개선해나가는 것을 권장합니다.*
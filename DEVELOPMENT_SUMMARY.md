# ChunkUp 개발 진행 요약

## 개요
ChunkUp은 영어 단어를 문맥 속에서 학습할 수 있도록 AI가 스토리를 생성해주는 Flutter 기반 모바일 앱입니다.

## 주요 작업 내용

### 1. 캐릭터 관리 시스템 전면 개편
- **구식 시스템 제거**
  - `CharacterService`, `CharacterCreationScreen`, `CharacterManagementScreen` 삭제
  - 모든 참조를 새로운 `EnhancedCharacterService`로 교체
  - `CharacterMigrationHelper`를 통한 자동 데이터 마이그레이션

- **신식 시스템 구현**
  - 시리즈별 캐릭터 그룹화
  - 캐릭터 간 관계 설정 기능
  - 향상된 캐릭터 관리 UI

### 2. 저작권 이슈 해결
- **제거된 캐릭터**
  - 역전재판 시리즈 (나루호도 류이치, 아야사토 마요이)
  - 슈타인즈 게이트 시리즈 (오카베 린타로, 마키세 크리스)
  
- **추가된 공개 도메인 캐릭터**
  - 셜록 홈즈 시리즈: 셜록 홈즈, 왓슨 박사
  - 어린 왕자: 어린 왕자
  - 오즈의 마법사: 도로시
  - 이상한 나라의 앨리스: 앨리스

### 3. UI/UX 개선

#### 3.1 캐릭터 관리 화면
- 레이아웃 단순화 (전체 화면 활용)
- "시리즈를 선택하세요" 메시지 제거
- 캐릭터 클릭 시 바로 편집 화면으로 이동
- 각 캐릭터에 삭제 버튼 추가

#### 3.2 캐릭터 편집 화면
- 세련된 디자인 적용 (LabeledTextField, LabeledBorderContainer 사용)
- 시리즈 정보 강조 표시
- 대표 대사와 태그 UI 개선
- 주황색 포커스 효과를 회색으로 변경

#### 3.3 청크 생성 화면의 캐릭터 선택
- 모달 방식의 전체 화면 선택 UI
- 시리즈별 그룹화 및 확장/축소 가능
- 실시간 검색 기능
- 시리즈별 일괄 선택/해제
- 선택된 캐릭터 미리보기

### 4. 프롬프트 개선
- 단어 설명 형식 변경: "이 단어가 문맥에서 어떻게 사용되었는지 한국어로 설명"
- 향상된 프롬프트 템플릿 시스템

### 5. 버그 수정
- GlobalKey 중복 오류 해결 (MainScreen Singleton 패턴 적용)
- RenderFlex overflow 오류 수정 (캐릭터 태그 표시)
- Premium 사용자의 Claude 3 Haiku 호출 문제 수정

### 6. 관계 설정 간소화
- 관계 유형과 상태 필드 제거
- 관계 설명만 입력하도록 UI 단순화

## 현재 상태
- 기본 기능은 모두 정상 작동
- 일부 불안정한 부분이 있을 수 있음
- 추가 테스트 및 안정화 필요

## 주요 파일 구조
```
lib/
├── core/
│   ├── services/
│   │   ├── enhanced_character_service.dart (새로운 캐릭터 서비스)
│   │   └── series_service.dart (시리즈 관리)
│   └── utils/
│       └── character_migration_helper.dart (마이그레이션 헬퍼)
├── presentation/
│   └── screens/
│       ├── enhanced_character_management_screen.dart (캐릭터 관리)
│       ├── character_detail_screen.dart (캐릭터 편집)
│       ├── character_selection_modal.dart (캐릭터 선택 모달)
│       └── relationship_editor_screen.dart (관계 설정)
└── domain/
    └── models/
        └── character.dart (캐릭터 모델)
```

## 다음 단계 제안
1. 앱 전체적인 안정성 테스트
2. 사용자 피드백 수집 및 반영
3. 추가 공개 도메인 캐릭터 확보
4. 성능 최적화
5. 에러 처리 강화

## 민감한 파일
- `.env.local` (API 키 포함)
- 개인 정보가 포함된 설정 파일들
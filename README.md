# Chunk Up - AI 기반 어휘 학습 앱

Chunk Up은 단어 학습 효율성을 높이기 위한 AI 기반 어휘 학습 앱입니다. 사용자가 학습하고자 하는 단어를 선택하면, AI가 해당 단어들을 모두 포함하는 의미 있는 문단(Chunk)을 생성해 컨텍스트 기반 학습을 지원합니다.

## 핵심 기능

1. **단어장 관리**: 단어를 영어와 한국어 쌍으로 저장하고 관리
2. **AI 단락 생성**: 선택한 단어들을 모두 포함하는 의미 있는 영어 단락과 한국어 번역 생성
3. **맞춤형 캐릭터 및 시나리오**: 사용자가 선호하는 캐릭터와 상황 설정 가능
4. **단어 해설**: 각 단어에 대한 맥락 기반 설명 제공
5. **학습 모드**: 생성된 단락을 통한 문장 기반 학습 지원
6. **복습 알림**: 망각 곡선에 기반한 복습 일정 제안
7. **다크 모드**: 완전한 라이트/다크 모드 지원

## 기술 스택

- **프레임워크**: Flutter
- **아키텍처**: 클린 아키텍처 (Clean Architecture)
- **상태 관리**: 
  - Provider
  - Riverpod & Freezed (최신 기능)
- **데이터 저장**: SharedPreferences, 파일 시스템
- **API 통신**: 자체 API 서비스 클래스
- **AI 서비스**: Claude API

## 아키텍처

Chunk Up은 다음과 같은 계층 구조를 따릅니다:

1. **프레젠테이션 계층** (`lib/presentation/`)
   - 화면 (screens): 사용자에게 보여지는 UI 컴포넌트
   - 위젯 (widgets): 재사용 가능한 UI 컴포넌트
   - 상태 관리 (providers): Provider/Riverpod 패턴 기반 상태 관리

2. **도메인 계층** (`lib/domain/`)
   - 모델 (models): 앱의 주요 데이터 모델 (Word, Chunk, WordListInfo 등)
   - 유스케이스 (usecases): 비즈니스 로직을 캡슐화한 클래스

3. **데이터 계층** (`lib/data/`)
   - 데이터 소스 (datasources): 로컬 및 원격 데이터 액세스
   - 저장소 (repositories): 데이터 소스와 도메인 계층 중개

4. **코어** (`lib/core/`)
   - 유틸리티 (utils): 공통 유틸리티 함수
   - 서비스 (services): 앱 전체에서 사용되는 서비스
   - 상수 (constants): 앱 상수 및 설정

5. **의존성 주입** (`lib/di/`)
   - 서비스 로케이터 (service_locator.dart): 의존성 주입 관리

## 설치 및 실행

### 설치 방법

```bash
# 저장소 복제
git clone https://github.com/yourusername/chunk_up.git
cd chunk_up

# 환경 변수 파일 설정
cp .env.example .env
# .env 파일을 편집하여 필요한 API 키 설정

# 의존성 설치
flutter pub get

# 코드 생성 (Freezed와 같은 코드 생성기를 위한 명령)
flutter pub run build_runner build --delete-conflicting-outputs
```

### 개발 시작하기

```bash
# 개발 모드로 실행
flutter run

# 디버그 모드로 실행
flutter run --debug
```

## 구현된 패턴

Chunk Up 앱에는 여러 현대적인 소프트웨어 개발 패턴이 구현되어 있습니다:

1. **불변성 패턴 (Immutability Pattern)**
   - 모든 핵심 모델에 적용된 불변성으로 예측 가능한 상태 관리
   - `copyWith()` 메서드를 통한 객체 수정

2. **Freezed를 통한 불변 객체**
   - 코드 생성을 통한 자동화된 불변 객체 구현
   - JSON 직렬화/역직렬화 자동 생성

3. **Riverpod 상태 관리**
   - 선언적이고 효율적인 상태 관리
   - 의존성 주입 간소화

## 문서

자세한 개발 문서는 `/md` 디렉토리에서 찾을 수 있습니다:

- [아키텍처 설계](md/ARCHITECTURE.md)
- [Freezed & Riverpod 가이드](md/FREEZED_RIVERPOD_GUIDE.md)
- [불변성 패턴](md/IMMUTABILITY_PATTERNS.md)
- [다크 모드 구현](md/DARK_MODE_IMPLEMENTATION.md)
- [릴리즈 체크리스트](md/RELEASE_CHECKLIST.md)

## 라이센스

이 프로젝트는 개인 프로젝트로, 모든 권리는 소유자에게 있습니다.
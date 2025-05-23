# 구독 시스템 구현 문서

## 구현된 기능

1. **구독 플랜 시스템**
   - FREE (무료): 기본 기능, 제한된 기능, 광고 포함
   - BASIC ($2.99/월): 고급 기능 사용, 광고 제거
   - PREMIUM ($5.99/월): 고급 AI 모델, 모든 기능 사용

2. **인앱 구매 연동**
   - in_app_purchase 패키지 사용
   - 구독 관리, 복원 기능
   - 결제 검증 (서버 측 구현 필요)

3. **광고 시스템**
   - AdMob 연동
   - 배너 광고 표시
   - 리워드 광고 구현

4. **구글 계정 연동**
   - 구글 로그인
   - 데이터 백업 (구글 드라이브)

5. **프롬프트 캐싱**
   - 동일 요청 캐싱
   - 요청 최적화

## 구현 파일 목록

### 상수 정의:
- `/lib/core/constants/subscription_constants.dart` - 구독 관련 상수

### 모델:
- `/lib/domain/models/subscription_plan.dart` - 구독 플랜 모델 정의

### 서비스:
- `/lib/core/services/subscription_service.dart` - 구독 관리
- `/lib/core/services/ad_service.dart` - 광고 처리
- `/lib/core/services/auth_service.dart` - 인증 관리
- `/lib/core/services/backup_service.dart` - 데이터 백업
- `/lib/core/services/api_service.dart` - API 서비스 (구독에 따른 AI 모델 사용)

### UI:
- `/lib/presentation/screens/subscription_screen.dart` - 구독 관리 화면

## 추가 필요 작업

1. **앱 통합**
   - 라우팅 설정
   - 구독 상태에 따른 기능 제한 적용
   - 네비게이션 메뉴에 구독 화면 추가

2. **배포 준비**
   - 스토어 등록 (앱스토어/플레이스토어)
   - 인앱 결제 제품 등록
   - 광고 유닛 생성

3. **서버 측 작업**
   - 구독 검증 API 구현 
   - 사용자 데이터 관리
   - 분석 및 모니터링

## 사용 방법

### 구독 서비스 사용
```dart
final subscriptionService = getIt<SubscriptionService>();

// 구독 상태 확인
final currentPlan = subscriptionService.currentStatus;

// AI 모델 가져오기
final aiModel = subscriptionService.getCurrentAiModel();

// 기능 제한 확인
if (subscriptionService.canUseTestFeature) {
  // 테스트 기능 사용
}

// 출력 횟수 증가
await subscriptionService.incrementGenerationCount();
```

### 광고 표시
```dart
final adService = getIt<AdService>();

// 배너 광고
final bannerWidget = adService.getBannerAdWidget();
if (bannerWidget != null) {
  // UI에 광고 추가
}

// 리워드 광고
await adService.showRewardedAd(
  onRewarded: () {
    // 보상 지급
  },
  onFailed: () {
    // 실패 처리
  },
);
```

### 구글 로그인
```dart
final authService = getIt<AuthService>();

// 로그인
await authService.signInWithGoogle();

// 로그인 상태 확인
if (authService.isAuthenticated) {
  // 로그인된 사용자 정보
  final user = authService.userProfile;
}
```

### 백업 서비스
```dart
final backupService = getIt<BackupService>();

// 백업
await backupService.backup();

// 복원
await backupService.restore();
```

## 참고 사항

- 모든 구독 및 결제 관련 기능은 앱 출시 전에 실제 환경에서 반드시 테스트해야 합니다.
- 인앱 구매 관련 정책은 애플과 구글의 최신 정책을 확인해야 합니다.
- 프로덕션 환경에서는 서버 측 검증을 반드시 구현해야 합니다.
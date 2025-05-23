# iOS 빌드 및 출시 가이드

이 문서는 Chunk Up 앱을 iOS 기기에서 실행하거나 App Store에 출시하기 위한 단계별 가이드입니다.

## 1. 사전 준비 사항

### 필수 요구사항
- Mac 컴퓨터 (macOS)
- Xcode 최신 버전 설치 (App Store에서 다운로드)
- 애플 개발자 계정 (앱 테스트만 하려면 무료 계정도 가능)
- 실제 앱 출시를 위한 Apple Developer Program 등록 ($99/년)
- Cocoapods 설치 (`sudo gem install cocoapods` 또는 `brew install cocoapods`)

### 현재 프로젝트 상태
현재 프로젝트에는 기본적인 iOS 구성 파일이 포함되어 있습니다:
- Info.plist (앱 정보 및 권한 설정)
- Runner.xcodeproj (Xcode 프로젝트 파일)
- Runner.xcworkspace (Xcode 워크스페이스)
- 앱 아이콘 및 런치 스크린

## 2. iOS 빌드 설정 완료하기

### 1) Flutter 의존성 설치
```bash
cd /home/duwns/chunk_up
flutter pub get
```

### 2) iOS 관련 패키지 설치
```bash
cd ios
pod install
```
만약 오류가 발생한다면, pod 레포지토리를 업데이트 후 다시 시도:
```bash
pod repo update
pod install
```

### 3) Info.plist 추가 설정
아래의 항목들이 이미 설정되어 있는지 확인하고, 필요한 경우 추가합니다:

```xml
<!-- Flutter TTS 권한 (iOS 10 이상) -->
<key>NSSpeechRecognitionUsageDescription</key>
<string>음성 기능을 사용하여 단어를 읽어주기 위해 필요합니다</string>

<!-- 알림 권한 -->
<key>NSUserNotificationUsageDescription</key>
<string>학습 알림을 위해 알림 권한이 필요합니다</string>
```

### 4) 번들 ID 설정
Runner.xcodeproj 파일을 Xcode로 열고 다음을 확인/수정합니다:
- 번들 식별자 (com.example.chunkUp을 실제 사용할 식별자로 변경)
- 앱 버전과 빌드 번호
- 배포 타겟 (최소 iOS 버전)

## 3. iOS 디바이스에서 테스트

### 1) 개발용 기기 등록
1. Xcode를 통해 Apple ID로 로그인
2. Xcode > Preferences > Accounts에서 Apple ID 추가
3. 테스트할 실제 기기를 등록

### 2) 개발 빌드 실행
```bash
flutter run -d ios
```

### 3) 릴리스 빌드 생성 및 테스트
```bash
flutter build ios --release
```

이후 Xcode에서 Product > Archive를 선택하여 아카이브 빌드를 생성합니다.

## 4. App Store 출시 준비

### 1) App Store Connect 설정
1. [App Store Connect](https://appstoreconnect.apple.com)에 로그인
2. My Apps에서 '+'를 클릭하여 새 앱 생성
3. 앱 정보 입력 (이름, 번들 ID, SKU, 언어 등)

### 2) 인증서 및 프로비저닝 프로파일 설정
1. [Apple Developer](https://developer.apple.com) 포털에서 인증서 생성
   - App Store 배포용 인증서 (Distribution Certificate)
   - 앱 ID 생성 및 구성
   - 프로비저닝 프로파일 생성
2. 생성한 인증서와 프로비저닝 프로파일을 Xcode에 추가

### 3) 스크린샷 및 메타데이터 준비
1. 다양한 iPhone 및 iPad 크기에 맞는 스크린샷 (최소 5.5", 6.5")
2. 앱 아이콘 (1024x1024 픽셀) 준비
3. 앱 설명, 키워드, 지원 URL 등 준비
4. 개인정보 처리방침 URL 준비 (필수)

## 5. 앱 출시 과정

### 1) TestFlight를 통한 테스트
1. Xcode에서 Archive 생성
2. Archive를 App Store Connect에 업로드
3. TestFlight 설정 후 내부 테스터 또는 외부 테스터 초대
4. 피드백 수집 및 필요한 경우 빌드 업데이트

### 2) App Store 제출
1. TestFlight 테스트 완료 후 동일한 빌드로 App Store 심사 제출
2. App Store Connect에서 '앱 심사 제출' 버튼 클릭
3. 심사 과정 모니터링 (일반적으로 1-3일 소요)
4. 필요한 경우 심사관의 질문에 답변
5. 승인 후 출시 일정 설정 (즉시 또는 특정 날짜)

## 6. 추가 iOS 특정 고려사항

### 접근성 지원
- VoiceOver 지원 확인
- 동적 텍스트 크기 지원 확인
- 색상 대비 확인

### 프라이버시 관련 요구사항
- 앱이 수집하는 데이터에 대한 App Privacy 정보 입력
- iOS 14.5 이상: App Tracking Transparency 구현
- IDFA 사용 여부 명시

### 성능 최적화
- 메모리 사용량 최적화
- 배터리 사용량 최적화
- 앱 크기 최적화 (App Thinning, Bitcode 등)

## 7. 문제 해결

### 일반적인 빌드 오류
- Podfile 관련 오류: `pod deintegrate && pod install`
- 서명 오류: Xcode에서 자동 서명 사용 또는 수동 서명 설정 확인
- 빌드 오류: `flutter clean && flutter pub get` 후 다시 시도

### 아카이브 및 업로드 문제
- App Store Connect API 키 설정
- Application Loader 사용 (Xcode의 일부)
- Transporter 앱 사용 (별도 다운로드)

### 심사 거부 대응
- 거부 사유 분석
- 필요한 수정 적용
- 심사관과의 소통 (Resolution Center 활용)

## 8. 중요 참고 사항

1. **iOS 환경 접근**: iOS 빌드를 위해서는 반드시 macOS 환경이 필요합니다. Windows 또는 Linux 환경에서는 직접 iOS 빌드가 불가능합니다.

2. **앱 서명 및 인증서 관리**: 인증서와 프로비저닝 프로파일은 정기적으로 갱신이 필요합니다. 만료 전에 갱신하는 것이 중요합니다.

3. **Apple 심사 가이드라인**: App Store 출시 전 [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)를 검토하여 앱이 모든 요구사항을 충족하는지 확인하세요.

4. **Flutter iOS 통합 관련 문제**: Flutter 앱의 iOS 빌드 관련 최신 정보는 [Flutter.dev의 iOS FAQ](https://flutter.dev/docs/development/ios-project-migration)를 참조하세요.
# ChunkUp 앱 릴리스 가이드

## 앱 서명 및 Google Play 업로드 준비

### 키스토어 생성

릴리스 빌드를 위해서는 서명 키가 필요합니다. 아래 명령을 실행하여 키스토어를 생성하세요:

```bash
keytool -genkey -v -keystore android/keystores/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass chunkup123 -keypass chunkup123 -dname "CN=ChunkUp, OU=Developer, O=ChunkUp, L=Seoul, ST=Seoul, C=KR"
```

> 참고: 위 명령은 JDK가 설치된 환경에서 실행해야 합니다.

### 앱 번들 빌드 (AAB)

Google Play에 업로드하기 위한 Android App Bundle을 빌드하려면 다음 명령을 실행하세요:

```bash
# 앱 번들(AAB) 빌드
flutter build appbundle
```

생성된 AAB 파일은 `build/app/outputs/bundle/release/app-release.aab`에 위치합니다.

### APK 빌드 (다른 스토어 배포용)

다른 스토어에 배포하기 위한 APK를 빌드하려면 다음 명령을 실행하세요:

```bash
# APK 빌드
flutter build apk --release
```

생성된 APK 파일은 `build/app/outputs/flutter-apk/app-release.apk`에 위치합니다.

## Google Play Console 업로드 프로세스

1. [Google Play Console](https://play.google.com/console)에 로그인합니다.
2. 앱 대시보드에서 '출시 > 앱 버전 생성'으로 이동합니다.
3. '내부 테스트' 채널을 선택합니다.
4. '릴리스 생성' 버튼을 클릭합니다.
5. '앱 번들 및 APK' 섹션에서 '앱 번들 업로드' 버튼을 클릭하고 빌드한 AAB 파일을 업로드합니다.
6. 출시 정보를 입력하고 '저장' 버튼을 클릭합니다.
7. '검토' 버튼을 클릭하여 출시 준비를 마칩니다.

## Play 앱 서명 설정

Google Play Console에 처음 앱을 업로드할 때 Play 앱 서명을 설정하라는 메시지가 표시됩니다. 이 과정에서 Play Console은 앱의 서명 키를 관리하게 됩니다.

1. 앱을 업로드하면 Play 앱 서명 설정 화면이 표시됩니다.
2. '계속' 버튼을 클릭하여 Play 앱 서명을 활성화합니다.
3. 기존 앱을 업데이트하는 경우 키스토어를 업로드하라는 메시지가 표시될 수 있습니다.

## 중요한 보안 사항

- `key.properties` 파일과 키스토어(`.jks` 파일)는 버전 관리 시스템에 커밋하지 마세요.
- 키스토어 비밀번호와 관련 정보를 안전하게 백업하세요. 키를 분실하면 앱을 더 이상 업데이트할 수 없습니다.
- `android/app/build.gradle.kts` 파일에 키스토어 정보를 직접 하드코딩하지 마세요.

## 프로덕션 릴리스 체크리스트

프로덕션 릴리스 전에 다음 사항을 확인하세요:

1. 앱 아이콘이 모든 해상도로 올바르게 설정되었는지 확인
2. `AndroidManifest.xml`에 필요한 모든 권한이 선언되어 있는지 확인
3. 앱 버전 코드와 버전 이름이 올바르게 업데이트되었는지 확인
4. 프로덕션 API 키가 설정되어 있는지 확인
5. 디버그 코드와 로그가 제거되었는지 확인
6. 모든 스크린에서 UI 테스트 진행
7. 다양한 기기에서 성능 테스트 진행
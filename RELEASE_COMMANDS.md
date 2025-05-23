# ChunkUp 앱 릴리스 명령어

아래 명령어들을 순서대로 실행하여 ChunkUp 앱을 릴리스 빌드하고 Google Play에 업로드할 준비를 하세요.

## 1. 키스토어 생성 (최초 1회만 실행)

```bash
# 키스토어 디렉토리 생성
mkdir -p android/keystores

# 키스토어 파일 생성 (JDK가 설치된 환경에서 실행)
keytool -genkey -v -keystore android/keystores/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass chunkup123 -keypass chunkup123 -dname "CN=ChunkUp, OU=Developer, O=ChunkUp, L=Seoul, ST=Seoul, C=KR"
```

## 2. 앱 번들(AAB) 빌드

Google Play에 업로드하기 위한 App Bundle을 생성합니다:

```bash
# 의존성 업데이트
flutter pub get

# 앱 번들 빌드
flutter build appbundle --release
```

생성된 AAB 파일은 `build/app/outputs/bundle/release/app-release.aab`에 위치합니다.

## 3. APK 빌드 (선택 사항)

다른 스토어 배포 또는 테스트를 위한 APK를 생성합니다:

```bash
# APK 빌드
flutter build apk --release
```

생성된 APK 파일은 `build/app/outputs/flutter-apk/app-release.apk`에 위치합니다.

## 4. 테스트 빌드 (내부 테스트용)

개발 테스트용 빌드를 생성합니다:

```bash
# 디버그 빌드
flutter build apk --debug

# 프로필 빌드 (성능 분석용)
flutter build apk --profile
```

## 5. 업로드 파일 확인

```bash
# AAB 파일 확인
ls -la build/app/outputs/bundle/release/

# APK 파일 확인
ls -la build/app/outputs/flutter-apk/
```

## 중요 참고사항

1. **키스토어 보안**: `key.properties` 파일과 키스토어는 절대 버전 관리 시스템에 커밋하지 마세요.
2. **백업**: 키스토어 파일과 비밀번호를 안전한 곳에 백업하세요. 키를 분실하면 앱을 더 이상 업데이트할 수 없습니다.
3. **앱 서명 키 등록**: Google Play Console에 처음 업로드할 때 Play 앱 서명을 설정해야 합니다.

자세한 내용은 `RELEASE.md` 파일을 참조하세요.